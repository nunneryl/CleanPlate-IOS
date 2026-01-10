// In file: RestaurantDetailViewModel.swift
import SwiftUI
import os
import FirebaseAnalytics
import MapKit
import CoreLocation

@MainActor
class RestaurantDetailViewModel: ObservableObject {

    enum DetailState {
        case partial(Restaurant)
        case full(Restaurant)
        case error(String)
    }

    // MARK: - Published Properties

    @Published var state: DetailState
    @Published var isLoadingMap: Bool = false

    /// The coordinate to display on the map snapshot (from NYC database - most reliable)
    @Published var displayCoordinate: CLLocationCoordinate2D?

    /// Apple Maps item for opening rich Place Card (may be nil if search failed)
    @Published var appleMapItem: MKMapItem?

    /// Whether Apple Maps search was verified against NYC coordinates
    @Published var isAppleMapVerified: Bool = false

    // MARK: - Private Properties

    private let mapService = MapService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "RestaurantDetailViewModel")

    // MARK: - Initialization

    init(restaurant: Restaurant) {
        self.state = .partial(restaurant)
    }

    // MARK: - Map Methods

    /// Fetches map data using hybrid approach:
    /// 1. Use NYC coordinates for display (always reliable)
    /// 2. Search Apple Maps for rich Place Card (optional enhancement)
    func fetchMapData() async {
        guard !isLoadingMap else { return }
        guard let restaurant = try? state.getRestaurant() else { return }

        self.isLoadingMap = true

        // Step 1: Get NYC coordinates (primary source of truth)
        let nycCoordinate = mapService.coordinateFromDatabase(
            latitude: restaurant.latitude,
            longitude: restaurant.longitude
        )

        self.displayCoordinate = nycCoordinate

        // Step 2: Try to find Apple Maps Place Card for richer experience
        guard let name = restaurant.dba, !name.isEmpty else {
            self.isLoadingMap = false
            return
        }

        let searchResult = await mapService.findVerifiedMapItem(
            name: name,
            address: restaurant.fullAddress(),
            knownCoordinate: nycCoordinate
        )

        switch searchResult {
        case .verified(let mapItem):
            self.appleMapItem = mapItem
            self.isAppleMapVerified = true
            logger.info("Apple Maps: Verified match for '\(name)'")

        case .unverified(let mapItem, let distance):
            // Use NYC coordinates but keep the MKMapItem for place card
            self.appleMapItem = mapItem
            self.isAppleMapVerified = false
            logger.warning("Apple Maps: Unverified (\(Int(distance))m away) for '\(name)'")

        case .unverifiedNoReference(let mapItem):
            // No NYC coords to compare, use Apple's result
            self.appleMapItem = mapItem
            self.isAppleMapVerified = false
            // Also use Apple's coordinate for display if we don't have NYC coords
            if self.displayCoordinate == nil {
                self.displayCoordinate = mapItem.placemark.coordinate
            }

        case .notFound, .error:
            // Apple Maps search failed - we'll fall back to NYC coordinates
            self.appleMapItem = nil
            self.isAppleMapVerified = false
            logger.info("Apple Maps search failed for '\(name)' - using NYC coordinates")
        }

        self.isLoadingMap = false
    }

    /// Gets an MKMapItem for opening in Apple Maps
    /// Prefers verified Apple search result, falls back to NYC coordinates
    func getAppleMapItem() -> MKMapItem? {
        guard let restaurant = try? state.getRestaurant() else { return nil }

        // If we have a verified Apple Maps result, use it for rich Place Card
        if let appleItem = appleMapItem, isAppleMapVerified {
            return appleItem
        }

        // Otherwise, create a simple map item from NYC coordinates
        if let coord = displayCoordinate {
            return mapService.mapItemFromCoordinates(
                coordinate: coord,
                name: restaurant.dba ?? "Restaurant",
                address: restaurant.fullAddress()
            )
        }

        // Last resort: use unverified Apple result
        return appleMapItem
    }

    // MARK: - Detail Loading

    func loadFullDetailsIfNeeded() async {
        guard case .partial(let partialRestaurant) = state, let camis = partialRestaurant.camis else { return }
        do {
            var fullRestaurantDetails = try await APIService.shared.fetchRestaurantDetails(camis: camis)
            // Preserve update_type from the original restaurant (used for "Grade updated X days ago" label)
            if partialRestaurant.update_type != nil {
                fullRestaurantDetails = Restaurant(
                    camis: fullRestaurantDetails.camis,
                    dba: fullRestaurantDetails.dba,
                    boro: fullRestaurantDetails.boro,
                    building: fullRestaurantDetails.building,
                    street: fullRestaurantDetails.street,
                    zipcode: fullRestaurantDetails.zipcode,
                    phone: fullRestaurantDetails.phone,
                    latitude: fullRestaurantDetails.latitude,
                    longitude: fullRestaurantDetails.longitude,
                    cuisine_description: fullRestaurantDetails.cuisine_description,
                    grade: fullRestaurantDetails.grade,
                    grade_date: fullRestaurantDetails.grade_date,
                    foursquare_fsq_id: fullRestaurantDetails.foursquare_fsq_id,
                    google_place_id: fullRestaurantDetails.google_place_id,
                    inspections: fullRestaurantDetails.inspections,
                    update_type: partialRestaurant.update_type,
                    activity_date: fullRestaurantDetails.activity_date,
                    finalized_date: fullRestaurantDetails.finalized_date
                )
            }
            self.state = .full(fullRestaurantDetails)
        } catch {
            let apiError = error as? APIError ?? .unknown
            self.state = .error(apiError.localizedDescription)
        }
    }

    // MARK: - Report Submission

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

// MARK: - DetailState Extension

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
