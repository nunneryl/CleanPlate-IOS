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

    /// Opens Google Maps using a search query (name + address) to find the actual business listing
    /// This is the KEY method - searching by name+address finds the business page with reviews/photos
    static func openGoogleMaps(searchQuery: String) {
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("Failed to encode search query")
            return
        }

        // Check if Google Maps app is installed
        if let schemeURL = googleMapsScheme, UIApplication.shared.canOpenURL(schemeURL) {
            // Use app with search query
            let appUrlString = "comgooglemaps://?q=\(encodedQuery)"
            if let appUrl = URL(string: appUrlString) {
                UIApplication.shared.open(appUrl)
                return
            }
        }

        // Fall back to web URL with search API - this finds the actual business listing
        let webURLString = "https://www.google.com/maps/search/?api=1&query=\(encodedQuery)"
        if let webURL = URL(string: webURLString) {
            UIApplication.shared.open(webURL)
        }
    }

    /// Opens Google Maps at specific coordinates with a label (legacy fallback)
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

    /// Smart open: Uses Place ID if available, otherwise searches by name+address to find business listing
    static func openGoogleMaps(
        placeID: String?,
        placeName: String,
        building: String? = nil,
        street: String? = nil,
        borough: String? = nil,
        zipcode: String? = nil,
        coordinate: CLLocationCoordinate2D?
    ) {
        // Priority 1: Use Place ID if available (most accurate)
        if let placeID = placeID, !placeID.isEmpty {
            openGoogleMaps(for: placeID, placeName: placeName)
            return
        }

        // Priority 2: Search by name + properly formatted address
        // Format: "Restaurant Name, 123 Main Street, Manhattan, NY 10001"
        var addressParts: [String] = []
        
        // Combine building + street without comma: "2020 BROADWAY" not "2020, BROADWAY"
        if let building = building, let street = street, !building.isEmpty, !street.isEmpty {
            addressParts.append("\(building) \(street)")
        } else if let street = street, !street.isEmpty {
            addressParts.append(street)
        }
        
        if let borough = borough, !borough.isEmpty {
            addressParts.append(borough)
        }
        
        // Add "NY" to help Google know it's New York
        addressParts.append("NY")
        
        if let zipcode = zipcode, !zipcode.isEmpty {
            addressParts.append(zipcode)
        }
        
        let formattedAddress = addressParts.joined(separator: ", ")
        let searchQuery = "\(placeName), \(formattedAddress)"
        
        logger.info("Google Maps search query: \(searchQuery, privacy: .public)")
        openGoogleMaps(searchQuery: searchQuery)
    }


    /// Checks if Google Maps app is installed
    static var isGoogleMapsInstalled: Bool {
        guard let schemeURL = googleMapsScheme else { return false }
        return UIApplication.shared.canOpenURL(schemeURL)
    }
}
