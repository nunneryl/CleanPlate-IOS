import Foundation

enum Environment {
    case development
    case preview
    case production
    
    static var current: Environment {
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
        switch Environment.current {
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
        Environment.current != .production
    }
}
