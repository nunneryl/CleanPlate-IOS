import Foundation
import Combine
import os

@MainActor
class SearchViewModel: ObservableObject {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "SearchViewModel")
    
    // MARK: - Published Properties
    
    @Published var searchTerm = ""
    @Published var restaurants: [Restaurant] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var recentRestaurants: [Restaurant] = []
    
    // MARK: - Public Methods
    
    func performSearch() async {
        guard !searchTerm.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        logger.info("Performing search with term: \(self.searchTerm, privacy: .public)")
        
        do {
            let results = try await APIService.shared.searchRestaurants(query: searchTerm)
            restaurants = results
            isLoading = false
            logger.info("Search successful; found \(self.restaurants.count, privacy: .public) restaurants.")
        } catch let error as APIError {
            errorMessage = error.description
            isLoading = false
            logger.error("Error during search: \(error.description, privacy: .public)")
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
            isLoading = false
            logger.error("Unexpected error during search: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func loadRecentInspections() async {
        logger.info("Loading recent inspections")
        
        do {
            let results = try await APIService.shared.getRecentRestaurants()
            recentRestaurants = results
            logger.info("Loaded \(results.count) recent inspections")
        } catch let error as APIError {
            logger.error("Error loading recent restaurants: \(error.description, privacy: .public)")
        } catch {
            logger.error("Unexpected error: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func resetSearch() {
        searchTerm = ""
        restaurants = []
        errorMessage = nil
    }
}
