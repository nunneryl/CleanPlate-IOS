// In file: MapService.swift

import MapKit
import UIKit

/// A service class to handle interactions with Apple Maps.
class MapService {

    /// Finds the canonical map item by searching for a name and address string.
    func findVerifiedMapItem(name: String, address: String) async throws -> MKMapItem {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(name), \(address)"
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        // For an address search, the first result from Apple is the most reliable.
        if let firstMatch = response.mapItems.first {
            return firstMatch
        } else {
            throw MapServiceError.noResultsFound
        }
    }
    
    /// Opens the map item in Apple Maps, showing the rich Place Card.
    func open(mapItem: MKMapItem) {
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }

    enum MapServiceError: Error, LocalizedError {
        case noResultsFound
        var errorDescription: String? {
            return "Could not find this location on Apple Maps."
        }
    }
}
