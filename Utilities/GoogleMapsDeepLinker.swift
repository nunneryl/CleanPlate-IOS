// In file: GoogleMapsDeepLinker.swift

import UIKit
import os

enum GoogleMapsDeepLinker {

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "GoogleMapsDeepLinker")

    private static let appStoreURL: URL? = URL(string: "https://apps.apple.com/us/app/google-maps/id585027354")
    private static let googleMapsScheme: URL? = URL(string: "comgooglemaps://")

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
}
