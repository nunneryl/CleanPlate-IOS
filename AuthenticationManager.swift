import Foundation
import AuthenticationServices

@MainActor
class AuthenticationManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    enum AuthState {
        case signedOut
        case signedIn(userID: String)
    }
    
    @Published var authState: AuthState = .signedOut
    @Published var favorites: [String: Restaurant] = [:]
    
    private var identityToken: String?
    private var postSignInAction: (() -> Void)?
    
    override init() {
        super.init()
        if let userID = KeychainHelper.getUserID(), let token = KeychainHelper.getToken() {
            self.authState = .signedIn(userID: userID)
            self.identityToken = token
            AuthTokenProvider.token = token
            Task {
                await fetchFavorites()
            }
            print("User is already signed in with ID: \(userID)")
        }
    }
        func signIn(completion: (() -> Void)? = nil) {
        self.postSignInAction = completion
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func signOut() {
        do {
            try KeychainHelper.deleteUserID()
            try KeychainHelper.deleteToken()
            self.authState = .signedOut
            self.favorites = [:]
            self.identityToken = nil
            AuthTokenProvider.token = nil
            print("User successfully signed out.")
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // In file: AuthenticationManager.swift

    func deleteAccount() async {
        guard let token = self.identityToken else {
            print("Error: Cannot delete account without an identity token.")
            return
        }
        
        do {
            try await APIService.shared.deleteUser(token: token)
            // If the API call is successful, perform a local sign out
            // to clear all data from the device.
            signOut()
            print("User account deleted successfully.")
        } catch {
            print("Error deleting user account: \(error)")
            // We could show an error to the user here in a real app
        }
    }
    
    
    // MARK: - Favorites Management
    
    func fetchFavorites() async {
        guard let token = self.identityToken else { return }
        do {
            let favoriteRestaurants = try await APIService.shared.fetchFavorites(token: token)
            var favoritesDict: [String: Restaurant] = [:]
            for restaurant in favoriteRestaurants {
                if let camis = restaurant.camis {
                    favoritesDict[camis] = restaurant
                }
            }
            self.favorites = favoritesDict
        } catch {
            print("Error fetching favorites: \(error)")
        }
    }

    func addFavorite(_ restaurant: Restaurant) {
        guard let camis = restaurant.camis, let token = self.identityToken else { return }
        self.favorites[camis] = restaurant // Optimistically update UI
        Task {
            do {
                try await APIService.shared.addFavorite(camis: camis, token: token)
            } catch {
                self.favorites.removeValue(forKey: camis) // Revert on failure
                print("Error adding favorite: \(error)")
            }
        }
    }
    
    func removeFavorite(_ restaurant: Restaurant) {
        guard let camis = restaurant.camis, let token = self.identityToken else { return }
        self.favorites.removeValue(forKey: camis) // Optimistically update UI
        Task {
            do {
                try await APIService.shared.removeFavorite(camis: camis, token: token)
            } catch {
                self.favorites[camis] = restaurant // Revert on failure
                print("Error removing favorite: \(error)")
            }
        }
    }
    
    func isFavorite(_ restaurant: Restaurant) -> Bool {
        guard let camis = restaurant.camis else { return false }
        return favorites[camis] != nil
    }

    // MARK: - Delegate Methods
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            print("Error: Missing or invalid identity token.")
            postSignInAction = nil // Clear action on failure
            return
        }
        
        let userID = appleIDCredential.user
        
        Task {
            do {
                try await APIService.shared.createUser(identityToken: identityToken)
                print("Successfully created user on our backend.")
                
                try KeychainHelper.save(userID: userID)
                try KeychainHelper.save(token: identityToken)
                
                self.identityToken = identityToken
                AuthTokenProvider.token = identityToken
                
                self.authState = .signedIn(userID: userID)
                await self.fetchFavorites()
                self.postSignInAction?()
                self.postSignInAction = nil // Clear the action so it doesn't run again.
                
            } catch {
                print("Error during sign in process: \(error)")
                self.postSignInAction = nil // Clear on error too.
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple failed with error: \(error.localizedDescription)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let allWindows = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        let keyWindow = allWindows.first { $0.isKeyWindow }
        return keyWindow ?? allWindows.first ?? UIWindow()
    }
}
