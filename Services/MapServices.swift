// In file: MapService.swift

import MapKit
import CoreLocation
import os

/// A service class to handle map interactions with coordinate validation.
class MapService {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "MapService")

    /// Maximum distance (in meters) between NYC coords and search result to consider it valid
    private let maxValidationDistance: CLLocationDistance = 500 // ~1/3 mile

    // MARK: - Primary Methods

    /// Creates a map coordinate from NYC database lat/long (most reliable source)
    func coordinateFromDatabase(latitude: Double?, longitude: Double?) -> CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        guard CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: lat, longitude: lon)) else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Creates a simple MKMapItem from coordinates (for opening in Apple Maps)
    func mapItemFromCoordinates(coordinate: CLLocationCoordinate2D, name: String, address: String) -> MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        return mapItem
    }

    /// Searches for a rich Apple Maps Place Card and validates against known coordinates
    func findVerifiedMapItem(
        name: String,
        address: String,
        knownCoordinate: CLLocationCoordinate2D?
    ) async -> MapSearchResult {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(name), \(address)"

        // If we have known coordinates, hint the search region
        if let coord = knownCoordinate {
            request.region = MKCoordinateRegion(
                center: coord,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
        }

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            guard let firstMatch = response.mapItems.first else {
                logger.info("No Apple Maps results for '\(name)'")
                return .notFound
            }

            // Validate the result against known coordinates
            if let knownCoord = knownCoordinate {
                let distance = self.distance(from: knownCoord, to: firstMatch.placemark.coordinate)

                if distance <= maxValidationDistance {
                    logger.info("Apple Maps result validated: \(Int(distance))m from known location")
                    return .verified(firstMatch)
                } else {
                    logger.warning("Apple Maps result too far: \(Int(distance))m - using fallback")
                    return .unverified(firstMatch, distanceMeters: distance)
                }
            } else {
                // No known coordinates to validate against
                return .unverifiedNoReference(firstMatch)
            }

        } catch {
            logger.error("Apple Maps search failed: \(error.localizedDescription)")
            return .error(error)
        }
    }

    // MARK: - Distance Calculation

    /// Calculates distance in meters between two coordinates
    func distance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }

    // MARK: - Types

    enum MapSearchResult {
        case verified(MKMapItem)                           // Search result within 500m of known coords
        case unverified(MKMapItem, distanceMeters: Double) // Search result too far from known coords
        case unverifiedNoReference(MKMapItem)              // No known coords to validate against
        case notFound                                       // No search results
        case error(Error)                                   // Search failed

        var mapItem: MKMapItem? {
            switch self {
            case .verified(let item), .unverified(let item, _), .unverifiedNoReference(let item):
                return item
            case .notFound, .error:
                return nil
            }
        }

        var isVerified: Bool {
            if case .verified = self { return true }
            return false
        }
    }

    enum MapServiceError: Error, LocalizedError {
        case noResultsFound
        case invalidCoordinates

        var errorDescription: String? {
            switch self {
            case .noResultsFound:
                return "Could not find this location on Apple Maps."
            case .invalidCoordinates:
                return "Invalid coordinates for this restaurant."
            }
        }
    }
}
