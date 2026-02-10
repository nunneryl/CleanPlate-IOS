// In file: AuthenticationManager.swift

import Foundation
import AuthenticationServices
import os

// A notification name to broadcast when recent searches are cleared.
extension Notification.Name {
    static let didClearRecentSearches = Notification.Name("didClearRecentSearches")
}

enum AuthError: Error {
    case missingToken
    case notSignedIn
    case refreshFailed
}

@MainActor
class AuthenticationManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    enum AuthState: Equatable {
        case signedOut
        case signedIn(userID: String)
    }

    @Published var authState: AuthState = .signedOut
    @Published var favorites: [String: Restaurant] = [:]
    @Published var recentSearches: [RecentSearch] = []

    private var identityToken: String?
    private var postSignInAction: (() -> Void)?
    private var refreshContinuation: CheckedContinuation<String, Error>?
    private var activeRefreshTask: Task<String?, Never>?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "AuthenticationManager")

    override init() {
        super.init()

        // Wire up automatic token refresh for 401 recovery
        APIService.shared.onTokenExpired = { [weak self] in
            await self?.refreshToken()
        }

        if let userID = KeychainHelper.getUserID(), let token = KeychainHelper.getToken() {
            self.authState = .signedIn(userID: userID)
            self.identityToken = token
            AuthTokenProvider.token = token
            Task {
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
    
    
    // MARK: - Token Refresh

    /// Silently refreshes the Apple identity token when it expires.
    /// Coalesces concurrent refresh attempts into a single operation.
    func refreshToken() async -> String? {
        // If a refresh is already in progress, wait for its result
        if let existingTask = activeRefreshTask {
            return await existingTask.value
        }

        guard case .signedIn(let userID) = authState else { return nil }

        let task = Task<String?, Never> {
            defer { activeRefreshTask = nil }

            // Verify Apple credential is still authorized
            do {
                let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
                guard state == .authorized else {
                    logger.warning("Apple credential revoked, signing out")
                    signOut()
                    return nil
                }
            } catch {
                logger.error("Credential state check failed: \(error.localizedDescription)")
                return nil
            }

            // Request a fresh identity token from Apple
            do {
                let newToken = try await performSilentTokenRefresh()

                self.identityToken = newToken
                AuthTokenProvider.token = newToken
                try KeychainHelper.save(token: newToken)

                // Re-authenticate with backend (best-effort, don't block on failure)
                do {
                    try await APIService.shared.createUser(identityToken: newToken)
                } catch {
                    logger.warning("Backend re-auth during refresh: \(error.localizedDescription)")
                }

                logger.info("Apple identity token refreshed successfully")
                return newToken
            } catch {
                logger.error("Token refresh failed: \(error.localizedDescription)")
                return nil
            }
        }

        activeRefreshTask = task
        return await task.value
    }

    /// Checks whether the Apple credential is still valid. Signs out if revoked.
    func checkCredentialState() async {
        guard case .signedIn(let userID) = authState else { return }
        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
            if state != .authorized {
                logger.warning("Apple credential no longer valid on foreground check, signing out")
                signOut()
            }
        } catch {
            logger.error("Foreground credential state check failed: \(error.localizedDescription)")
        }
    }

    private func performSilentTokenRefresh() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.refreshContinuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
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

            // If this was a token refresh attempt, resume the continuation with an error
            if let continuation = refreshContinuation {
                refreshContinuation = nil
                continuation.resume(throwing: AuthError.missingToken)
                return
            }

            logger.error("Missing or invalid identity token.")
            postSignInAction = nil
            return
        }

        // Handle token refresh flow
        if let continuation = refreshContinuation {
            refreshContinuation = nil
            continuation.resume(returning: identityToken)
            return
        }

        // Handle normal sign-in flow
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
        // If this was a token refresh attempt, resume the continuation with the error
        if let continuation = refreshContinuation {
            refreshContinuation = nil
            continuation.resume(throwing: error)
            return
        }

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
