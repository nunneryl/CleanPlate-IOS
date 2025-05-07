import SwiftUI
import os

@main
struct NYCFoodRatingsApp: App {
    init() {
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
