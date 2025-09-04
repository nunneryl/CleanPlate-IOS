// StaticMapView.swift
import SwiftUI
import MapKit

/// A view that displays a non-interactive map pin for a restaurant's location.
/// Tapping the map opens the location in the Apple Maps app.
struct StaticMapView: View {
    let latitude: Double
    let longitude: Double
    let restaurantName: String

    @State private var region: MKCoordinateRegion
    private let annotationItems: [RestaurantLocation]
    
    init(latitude: Double, longitude: Double, restaurantName: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.restaurantName = restaurantName
        
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinates,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
        self.annotationItems = [RestaurantLocation(coordinate: coordinates)]
    }

    var body: some View {
        Map(coordinateRegion: .constant(region),
            interactionModes: [],
            annotationItems: annotationItems) { location in
            MapMarker(coordinate: location.coordinate, tint: .blue)
        }
        .frame(height: 160) // Keeping the smaller height
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
        .accessibilityLabel("Map showing restaurant location. Tap to open in Apple Maps.")
        .onTapGesture {
            // This function now contains the new search logic.
            openInAppleMaps()
        }
    }
    
    /// This function now searches for a Point of Interest (POI) before opening Apple Maps.
    private func openInAppleMaps() {
        // 1. Create a search request with the restaurant's name.
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = self.restaurantName
        
        // 2. Provide the map region as a hint to find the correct location.
        request.region = self.region
        
        // 3. Perform the search.
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            // 4. If the search finds a valid business (a mapItem), open it.
            if let mapItem = response?.mapItems.first {
                // This opens the rich "Place Card" with photos, reviews, etc.
                mapItem.openInMaps()
            } else {
                // 5. FALLBACK: If the search fails, open a simple pin like before.
                // This ensures the map always opens, even without an internet connection
                // or if Apple doesn't have the business listed.
                let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let placemark = MKPlacemark(coordinate: coordinates)
                let fallbackItem = MKMapItem(placemark: placemark)
                fallbackItem.name = self.restaurantName
                fallbackItem.openInMaps()
            }
        }
    }
}

struct RestaurantLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
