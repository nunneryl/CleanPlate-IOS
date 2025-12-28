// In file: AuthenticationManager.swift

import Foundation
import AuthenticationServices
import os

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
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "AuthenticationManager")
    
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
            logger.info("User is already signed in with ID: \(userID, privacy: .private)")
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
            logger.info("User successfully signed out.")
        } catch {
            logger.error("Error signing out: \(error.localizedDescription, privacy: .public)")
        }
    }

    func deleteAccount() async {
        guard let token = self.identityToken else {
            logger.error("Cannot delete account without an identity token.")
            return
        }
        
        do {
            try await APIService.shared.deleteUser(token: token)
            signOut()
            logger.info("User account deleted successfully.")
        } catch {
            logger.error("Error deleting user account: \(error.localizedDescription, privacy: .public)")
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
            logger.error("Error fetching favorites: \(error.localizedDescription, privacy: .public)")
        }
    }

    func fetchRecentSearches() async {
        guard let token = self.identityToken else { return }
        do {
            let searches = try await APIService.shared.fetchRecentSearches(token: token)
            self.recentSearches = searches
        } catch {
            logger.error("Error fetching recent searches: \(error.localizedDescription, privacy: .public)")
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
                   logger.error("Error clearing recent searches: \(error.localizedDescription, privacy: .public)")
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
                logger.error("Error adding favorite: \(error.localizedDescription, privacy: .public)")
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
                logger.error("Error removing favorite: \(error.localizedDescription, privacy: .public)")
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
            logger.error("Missing or invalid identity token.")
            postSignInAction = nil
            return
        }
        
        let userID = appleIDCredential.user
        
        Task {
            do {
                try await APIService.shared.createUser(identityToken: identityToken)
                logger.info("Successfully created user on our backend.")
                
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
                logger.error("Error during sign in process: \(error.localizedDescription, privacy: .public)")
                self.postSignInAction = nil
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        logger.error("Sign in with Apple failed: \(error.localizedDescription, privacy: .public)")
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
