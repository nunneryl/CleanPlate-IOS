// In file: GoogleMapsDeepLinker.swift

import UIKit
import CoreLocation
import os

enum GoogleMapsDeepLinker {

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "GoogleMapsDeepLinker")

    private static let appStoreURL: URL? = URL(string: "https://apps.apple.com/us/app/google-maps/id585027354")
    private static let googleMapsScheme: URL? = URL(string: "comgooglemaps://")

    /// Opens Google Maps with a specific Place ID (most accurate)
    static func openGoogleMaps(for placeID: String, placeName: String) {
        guard let schemeURL = googleMapsScheme else {
            logger.error("Failed to create Google Maps scheme URL")
            return
        }

        // First, check if the Google Maps app is installed.
        guard UIApplication.shared.canOpenURL(schemeURL) else {
            // If not, open the App Store page.
            if let storeURL = appStoreURL {
                UIApplication.shared.open(storeURL)
            }
            return
        }

        // Ensure placeName can be percent encoded
        guard let encodedPlaceName = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("Failed to encode place name: \(placeName, privacy: .private)")
            return
        }

        let urlString = "comgooglemapsurl://www.google.com/maps/search/?api=1&query=\(encodedPlaceName)&query_place_id=\(placeID)"

        guard let url = URL(string: urlString) else {
            logger.error("Could not construct Google Maps URL")
            return
        }

        // Open the deep link.
        UIApplication.shared.open(url)
    }

    /// Opens Google Maps at specific coordinates with a label (fallback when no Place ID)
    static func openGoogleMaps(at coordinate: CLLocationCoordinate2D, label: String) {
        guard let schemeURL = googleMapsScheme else {
            logger.error("Failed to create Google Maps scheme URL")
            return
        }

        // Check if Google Maps app is installed
        guard UIApplication.shared.canOpenURL(schemeURL) else {
            // Fall back to Google Maps web URL (opens in browser or prompts to install)
            let webURLString = "https://www.google.com/maps/search/?api=1&query=\(coordinate.latitude),\(coordinate.longitude)"
            if let webURL = URL(string: webURLString) {
                UIApplication.shared.open(webURL)
            }
            return
        }

        // Encode the label
        let encodedLabel = label.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // Use coordinate-based URL
        let urlString = "comgooglemaps://?q=\(coordinate.latitude),\(coordinate.longitude)&label=\(encodedLabel)"

        guard let url = URL(string: urlString) else {
            logger.error("Could not construct Google Maps coordinate URL")
            return
        }

        UIApplication.shared.open(url)
    }

    /// Smart open: Uses Place ID if available, otherwise falls back to coordinates
    static func openGoogleMaps(
        placeID: String?,
        placeName: String,
        coordinate: CLLocationCoordinate2D?
    ) {
        // Priority 1: Use Place ID if available (most accurate)
        if let placeID = placeID, !placeID.isEmpty {
            openGoogleMaps(for: placeID, placeName: placeName)
            return
        }

        // Priority 2: Use coordinates if available
        if let coord = coordinate {
            openGoogleMaps(at: coord, label: placeName)
            return
        }

        // No data available - open App Store
        logger.warning("No Place ID or coordinates available for Google Maps")
        if let storeURL = appStoreURL {
            UIApplication.shared.open(storeURL)
        }
    }

    /// Checks if Google Maps app is installed
    static var isGoogleMapsInstalled: Bool {
        guard let schemeURL = googleMapsScheme else { return false }
        return UIApplication.shared.canOpenURL(schemeURL)
    }
}
