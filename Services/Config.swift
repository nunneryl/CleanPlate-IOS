import Foundation

enum AppEnvironment {
    case development
    case preview
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        // Check for preview scheme
        if ProcessInfo.processInfo.environment["PREVIEW_MODE"] == "1" {
            return .preview
        }
        return .development
        #else
        return .production
        #endif
    }
}

struct Config {
    static var apiBaseURL: String {
        switch AppEnvironment.current {
        case .development:
            return "https://cleanplate-production.up.railway.app"  // Or localhost for local dev
        case .preview:
            return "https://cleanplate-cleanplate-pr-24.up.railway.app"
        case .production:
            return "https://cleanplate-production.up.railway.app"
        }
    }
    
    // Add other environment-specific config here
    static var enableLogging: Bool {
        AppEnvironment.current != .production
    }
}
