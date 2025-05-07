import SwiftUI
import os
import FirebaseCore // <-- Import this

@main
struct NYCFoodRatingsApp: App {
    init() {
        // --- Add Firebase Initialization HERE ---
        FirebaseApp.configure() // <--- This is the only line needed for init
        print("Firebase configured successfully!") // Optional confirmation
        // --- End Firebase Initialization ---

        // Your existing launch time logging
        let launchStart = Date()
        let elapsed = Date().timeIntervalSince(launchStart)
        os_log("App launch time: %.2f seconds", elapsed)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
