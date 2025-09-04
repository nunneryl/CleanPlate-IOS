// In a new file named AnalyticsLogger.swift

import Foundation
import FirebaseAnalytics

struct AnalyticsLogger {
    
    /// Logs an event when a user selects a restaurant from a list.
    /// - Parameters:
    ///   - source: The name of the list the user tapped from (e.g., "search_results").
    ///   - restaurant: The restaurant that was selected.
    static func logSelectRestaurant(from source: String, for restaurant: Restaurant) {
        Analytics.logEvent(AnalyticsEventSelectItem, parameters: [
            AnalyticsParameterItemListName: source,
            AnalyticsParameterItemID: restaurant.camis ?? "unknown",
            AnalyticsParameterItemName: restaurant.dba ?? "Unknown",
            "restaurant_boro": restaurant.boro ?? "N/A"
        ])
    }
}
