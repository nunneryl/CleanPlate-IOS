// In file: NYCFoodRatingsApp.swift

import SwiftUI
import os
import FirebaseCore

@main
struct NYCFoodRatingsApp: App {

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "App")

    #if SCREENSHOTS
    @StateObject private var authManager = MockAuthenticationManager()
    #else
    @StateObject private var authManager = AuthenticationManager()
    #endif

    init() {
        #if SCREENSHOTS
        APIService.shared = MockAPIService()
        Self.logger.info("App starting in SCREENSHOT mode with mock data.")
        #else
        FirebaseApp.configure()
        Self.logger.info("App starting in LIVE mode.")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                // --- MODIFIED: Explicitly cast the object to the expected type ---
                .environmentObject(authManager as AuthenticationManager)
        }
    }
}
