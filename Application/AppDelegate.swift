import UIKit
import UserNotifications
import os

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "AppDelegate")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - Push Token Registration

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        logger.info("Received APNs device token: \(tokenString.prefix(16), privacy: .public)...")
        PushNotificationManager.shared.didReceiveDeviceToken(tokenString)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error("Failed to register for remote notifications: \(error.localizedDescription, privacy: .public)")
    }

    // MARK: - Foreground Notification Display

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Notification Tap Handling

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let camis = userInfo["camis"] as? String {
            NotificationCenter.default.post(
                name: .didTapPushNotification,
                object: nil,
                userInfo: ["camis": camis]
            )
        }
        completionHandler()
    }
}
