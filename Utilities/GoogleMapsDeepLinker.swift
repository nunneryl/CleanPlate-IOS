// In file: GoogleMapsDeepLinker.swift

import UIKit

enum GoogleMapsDeepLinker {

    private static let appStoreURL = URL(string: "https://apps.apple.com/us/app/google-maps/id585027354")!
    private static let googleMapsScheme = URL(string: "comgooglemaps://")!

    static func openGoogleMaps(for placeID: String, placeName: String) {
        // First, check if the Google Maps app is installed.
        guard UIApplication.shared.canOpenURL(googleMapsScheme) else {
            // If not, open the App Store page.
            UIApplication.shared.open(appStoreURL)
            return
        }

        // CORRECTED: This uses a more direct custom URL scheme to ensure the
        // search parameters are passed to the Google Maps app correctly.
        let urlString = "comgooglemapsurl://www.google.com/maps/search/?api=1&query=\(placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&query_place_id=\(placeID)"

        guard let url = URL(string: urlString) else {
            print("Error: Could not construct Google Maps URL.")
            return
        }
        
        // Open the deep link.
        UIApplication.shared.open(url)
    }
}
