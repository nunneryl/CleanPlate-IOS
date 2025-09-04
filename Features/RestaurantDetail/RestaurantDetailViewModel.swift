// In file: RestaurantDetailViewModel.swift

import SwiftUI
import os
import FirebaseAnalytics

@MainActor
class RestaurantDetailViewModel: ObservableObject {
    
    // State management for loading full details
    enum DetailState {
        case partial(Restaurant)
        case full(Restaurant)
        case error(String)
    }
    
    @Published var state: DetailState
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "RestaurantDetailViewModel")

    // Initialize with the partial data so the screen isn't blank
    init(restaurant: Restaurant) {
        self.state = .partial(restaurant)
    }
    
    // Function to load the full details
    func loadFullDetailsIfNeeded() async {
        guard case .partial(let partialRestaurant) = state, let camis = partialRestaurant.camis else {
            // If we are not in the partial state, or have no camis, do nothing.
            return
        }
        
        do {
            logger.info("Fetching full details for CAMIS \(camis, privacy: .public)")
            let fullRestaurantDetails = try await APIService.shared.fetchRestaurantDetails(camis: camis)
            self.state = .full(fullRestaurantDetails)
            logger.info("Successfully fetched full details.")
        } catch {
            let apiError = error as? APIError ?? .unknown
            self.state = .error(apiError.description)
            logger.error("Failed to load full details for CAMIS \(camis, privacy: .public): \(apiError.description, privacy: .public)")
        }
    }
    
    // The report submission logic can stay here as it's a business logic task.
    func submitReport(for restaurant: Restaurant, issueType: ReportIssueView.IssueType, comments: String) {
        guard let camis = restaurant.camis else {
            logger.error("Cannot submit report, restaurant CAMIS is missing.")
            return
        }
        
        logger.info("Submitting issue report...")
        
        Task {
            do {
                try await APIService.shared.submitReport(
                    camis: camis,
                    issueType: issueType.rawValue,
                    comments: comments
                )
                logger.info("Report submission successful.")
                Analytics.logEvent("submit_issue_report", parameters: [
                    "issue_type": issueType.rawValue,
                    "has_comments": !comments.isEmpty,
                    AnalyticsParameterItemID: camis
                ])
                
            } catch {
                logger.error("Report submission failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
