// In file: ScreenshotDependencies.swift

import Foundation
import SwiftUI

#if DEBUG

// MARK: - Mock APIService

/// A mock version of the APIService that returns pre-defined data for screenshots and testing.
/// It inherits from the real APIService to ensure it has all the same functions.
class MockAPIService: APIService {
    
    // A tiny delay to simulate the feel of a real network request.
    private let mockNetworkDelay: UInt64 = 250_000_000 // 0.25 seconds in nanoseconds

    override func searchRestaurants(query: String, page: Int, perPage: Int, grade: String?, boro: String?, cuisine: String?, sort: String?) async throws -> [Restaurant] {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        
        if query.lowercased().contains("pizza") {
            return [PreviewMockData.mockRestaurants.first!]
        }
        return Array(PreviewMockData.mockRestaurants.prefix(5))
    }
    
    override func fetchRecentlyGraded() async throws -> [Restaurant] {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        return PreviewMockData.mockRestaurants
    }
    
    // --- MODIFIED: This function now correctly finds and returns closed restaurants ---
    override func fetchRecentActions() async throws -> RecentActionsResponse {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        
        // Filter the main mock data list to find restaurants closed by the DOHMH.
        let closedRestaurants = PreviewMockData.mockRestaurants.filter { restaurant in
            // Get the most recent inspection for the restaurant.
            guard let latestInspection = restaurant.inspections?.sorted(by: { $0.inspection_date ?? "" > $1.inspection_date ?? "" }).first else {
                return false
            }
            // Check if the 'action' field indicates it was closed.
            return latestInspection.action?.lowercased().contains("closed by dohmh") ?? false
        }
        
        // For now, we will keep re-opened empty unless we add data for it.
        return RecentActionsResponse(recently_closed: closedRestaurants, recently_reopened: [])
    }
    
    override func fetchRestaurantDetails(camis: String) async throws -> Restaurant {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        return PreviewMockData.mockRestaurants.first { $0.camis == camis } ?? PreviewMockData.mockRestaurants.first!
    }
    
    // For functions that don't return data, we just pretend they succeeded.
    override func submitReport(camis: String, issueType: String, comments: String) async throws {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        print("Mock: Report submitted.")
    }

    override func createUser(identityToken: String) async throws {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        print("Mock: User created.")
    }

    override func addFavorite(camis: String, token: String) async throws {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        print("Mock: Favorite added.")
    }

    override func removeFavorite(camis: String, token: String) async throws {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        print("Mock: Favorite removed.")
    }
    
    override func deleteUser(token: String) async throws {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        print("Mock: User deleted.")
    }

    override func fetchFavorites(token: String) async throws -> [Restaurant] {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        return Array(PreviewMockData.mockRestaurants.prefix(3))
    }
    
    override func saveRecentSearch(searchTerm: String, token: String) async throws {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        print("Mock: Recent search saved.")
    }
    
    override func fetchRecentSearches(token: String) async throws -> [RecentSearch] {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        return [
            RecentSearch(id: 1, search_term_display: "Tacos", created_at: "2025-08-26T12:00:00Z"),
            RecentSearch(id: 2, search_term_display: "Pizza Place Example", created_at: "2025-08-25T12:00:00Z"),
            RecentSearch(id: 3, search_term_display: "Downtown Diner", created_at: "2025-08-24T12:00:00Z")
        ]
    }

    override func clearRecentSearches(token: String) async throws {
        try await Task.sleep(nanoseconds: mockNetworkDelay)
        print("Mock: Recent searches cleared.")
    }
}


// MARK: - Mock AuthenticationManager

@MainActor
class MockAuthenticationManager: AuthenticationManager {
    
    override init() {
        super.init()
        self.authState = .signedIn(userID: "mock_user_123")
        let mockFavorites = Array(PreviewMockData.mockRestaurants.prefix(3))
        self.favorites = Dictionary(uniqueKeysWithValues: mockFavorites.map { ($0.camis!, $0) })
        self.recentSearches = [
            RecentSearch(id: 1, search_term_display: "Tacos", created_at: "2025-08-26T12:00:00Z"),
            RecentSearch(id: 2, search_term_display: "Pizza Place Example", created_at: "2025-08-25T12:00:00Z"),
            RecentSearch(id: 3, search_term_display: "Downtown Diner", created_at: "2025-08-24T12:00:00Z")
        ]
    }
    
    override func signIn(completion: (() -> Void)? = nil) {
        print("Mock: Sign in requested, but we're already signed in for screenshots.")
        completion?()
    }
    
    override func signOut() {
        print("Mock: Sign out requested.")
        self.authState = .signedOut
        self.favorites = [:]
        self.recentSearches = []
    }
    
    override func deleteAccount() async {
        print("Mock: Delete account requested.")
        signOut()
    }
    
    override func fetchFavorites() async {
        print("Mock: Fetch favorites requested (using pre-loaded data).")
    }
    
    override func fetchRecentSearches() async {
        print("Mock: Fetch recent searches requested (using pre-loaded data).")
    }
}

#endif
