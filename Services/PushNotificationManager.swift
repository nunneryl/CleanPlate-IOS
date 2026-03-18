import UIKit
import UserNotifications
import os

extension Notification.Name {
    static let didTapPushNotification = Notification.Name("didTapPushNotification")
}

@MainActor
class PushNotificationManager: ObservableObject {

    static let shared = PushNotificationManager()

    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "PushNotifications")
    private var pendingDeviceToken: String?

    private init() {
        Task {
            await refreshAuthorizationStatus()
        }
    }

    // MARK: - Permission Request

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            if granted {
                logger.info("Push notification permission granted")
                UIApplication.shared.registerForRemoteNotifications()
            } else {
                logger.info("Push notification permission denied")
            }
            return granted
        } catch {
            logger.error("Failed to request notification permission: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func registerIfAuthorized() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .authorized {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    // MARK: - Token Handling

    func didReceiveDeviceToken(_ token: String) {
        pendingDeviceToken = token

        // If user is signed in, send to backend immediately
        if let authToken = AuthTokenProvider.token {
            Task {
                await sendTokenToBackend(deviceToken: token, authToken: authToken)
            }
        }
    }

    func sendPendingTokenIfNeeded(authToken: String) {
        guard let deviceToken = pendingDeviceToken else { return }
        Task {
            await sendTokenToBackend(deviceToken: deviceToken, authToken: authToken)
        }
    }

    private func sendTokenToBackend(deviceToken: String, authToken: String) async {
        do {
            try await APIService.shared.registerPushToken(deviceToken: deviceToken, token: authToken)
            logger.info("Push token registered with backend")
        } catch {
            logger.error("Failed to register push token with backend: \(error.localizedDescription, privacy: .public)")
        }
    }

    func unregisterToken(authToken: String) async {
        guard let deviceToken = pendingDeviceToken else { return }
        do {
            try await APIService.shared.unregisterPushToken(deviceToken: deviceToken, token: authToken)
            logger.info("Push token unregistered from backend")
        } catch {
            logger.error("Failed to unregister push token: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Status

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }
}
