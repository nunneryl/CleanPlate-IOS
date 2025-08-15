// In file: NYCFoodRatingsApp.swift

import SwiftUI
import os
import FirebaseCore

@main
struct NYCFoodRatingsApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    init() {
        FirebaseApp.configure()
        print("Firebase configured successfully!")
        let launchStart = Date()
        let elapsed = Date().timeIntervalSince(launchStart)
        os_log("App launch time: %.2f seconds", elapsed)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                // <<< NEW: Make the authManager available to all child views >>>
                .environmentObject(authManager)
        }
    }
}
