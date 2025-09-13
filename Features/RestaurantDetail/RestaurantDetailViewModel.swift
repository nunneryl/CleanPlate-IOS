// In file: RestaurantDetailViewModel.swift
import SwiftUI
import os
import FirebaseAnalytics
import MapKit

@MainActor
class RestaurantDetailViewModel: ObservableObject {
    
    enum DetailState {
        case partial(Restaurant)
        case full(Restaurant)
        case error(String)
    }
    
    @Published var state: DetailState
    @Published var mapItem: MKMapItem?
    @Published var isLoadingMap: Bool = false
    
    private let mapService = MapService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "RestaurantDetailViewModel")

    init(restaurant: Restaurant) {
        self.state = .partial(restaurant)
    }
    
    func fetchCanonicalLocation() async {
        guard self.mapItem == nil, !isLoadingMap else { return }
        guard let restaurant = try? state.getRestaurant(), let name = restaurant.dba, !name.isEmpty else { return }
        
        self.isLoadingMap = true
        
        do {
            let foundMapItem = try await mapService.findVerifiedMapItem(name: name, address: restaurant.fullAddress())
            self.mapItem = foundMapItem
        } catch {
            logger.error("MKLocalSearch failed for '\(name)': \(error.localizedDescription)")
        }
        
        self.isLoadingMap = false
    }
    
    func loadFullDetailsIfNeeded() async {
        guard case .partial(let partialRestaurant) = state, let camis = partialRestaurant.camis else { return }
        do {
            let fullRestaurantDetails = try await APIService.shared.fetchRestaurantDetails(camis: camis)
            self.state = .full(fullRestaurantDetails)
        } catch {
            let apiError = error as? APIError ?? .unknown
            self.state = .error(apiError.description)
        }
    }
    
    func submitReport(for restaurant: Restaurant, issueType: ReportIssueView.IssueType, comments: String) {
        guard let camis = restaurant.camis else { return }
        Task {
            do {
                try await APIService.shared.submitReport(camis: camis, issueType: issueType.rawValue, comments: comments)
            } catch {
                logger.error("Report submission failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

// (The DetailState extension remains unchanged)
extension RestaurantDetailViewModel.DetailState {
    var isPartial: Bool {
        if case .partial = self { return true }
        return false
    }

    func getRestaurant() throws -> Restaurant {
        switch self {
        case .partial(let restaurant), .full(let restaurant):
            return restaurant
        case .error:
            throw NSError(domain: "StateError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No restaurant data in error state"])
        }
    }
}
