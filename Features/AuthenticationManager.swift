// In file: AuthenticationManager.swift

import Foundation
import AuthenticationServices

// A notification name to broadcast when recent searches are cleared.
extension Notification.Name {
    static let didClearRecentSearches = Notification.Name("didClearRecentSearches")
}

@MainActor
class AuthenticationManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    enum AuthState {
        case signedOut
        case signedIn(userID: String)
    }
    
    @Published var authState: AuthState = .signedOut
    @Published var favorites: [String: Restaurant] = [:]
    @Published var recentSearches: [RecentSearch] = []
    
    private var identityToken: String?
    private var postSignInAction: (() -> Void)?
    
    override init() {
        super.init()
        if let userID = KeychainHelper.getUserID(), let token = KeychainHelper.getToken() {
            self.authState = .signedIn(userID: userID)
            self.identityToken = token
            AuthTokenProvider.token = token
            Task {
                // Now fetches both when the app starts
                await fetchFavorites()
                await fetchRecentSearches()
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
            // --- MODIFIED ---
            self.recentSearches = [] // Clear searches on sign out
            self.identityToken = nil
            AuthTokenProvider.token = nil
            print("User successfully signed out.")
        } catch {
            print("Error signing out: \(error)")
        }
    }

    func deleteAccount() async {
        guard let token = self.identityToken else {
            print("Error: Cannot delete account without an identity token.")
            return
        }
        
        do {
            try await APIService.shared.deleteUser(token: token)
            signOut()
            print("User account deleted successfully.")
        } catch {
            print("Error deleting user account: \(error)")
        }
    }
    
    
    // MARK: - User Data Management
    
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

    func fetchRecentSearches() async {
        guard let token = self.identityToken else { return }
        do {
            let searches = try await APIService.shared.fetchRecentSearches(token: token)
            self.recentSearches = searches
        } catch {
            print("Error fetching recent searches: \(error)")
        }
    }
    
    func clearRecentSearches() {
           guard let token = self.identityToken else { return }
           
           let oldSearches = self.recentSearches
           self.recentSearches = []
           
           Task {
               do {
                   try await APIService.shared.clearRecentSearches(token: token)
                   // On success, post the notification
                   NotificationCenter.default.post(name: .didClearRecentSearches, object: nil)
               } catch {
                   self.recentSearches = oldSearches
                   print("Error clearing recent searches: \(error)")
               }
           }
       }


    func addFavorite(_ restaurant: Restaurant) {
        guard let camis = restaurant.camis, let token = self.identityToken else { return }
        self.favorites[camis] = restaurant
        Task {
            do {
                try await APIService.shared.addFavorite(camis: camis, token: token)
            } catch {
                self.favorites.removeValue(forKey: camis)
                print("Error adding favorite: \(error)")
            }
        }
    }
    
    func removeFavorite(_ restaurant: Restaurant) {
        guard let camis = restaurant.camis, let token = self.identityToken else { return }
        self.favorites.removeValue(forKey: camis)
        Task {
            do {
                try await APIService.shared.removeFavorite(camis: camis, token: token)
            } catch {
                self.favorites[camis] = restaurant
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
            postSignInAction = nil
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
                
                // Now fetches both after a new sign-in
                await self.fetchFavorites()
                await self.fetchRecentSearches()
                
                self.postSignInAction?()
                self.postSignInAction = nil
                
            } catch {
                print("Error during sign in process: \(error)")
                self.postSignInAction = nil
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
