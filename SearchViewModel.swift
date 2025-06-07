// MARK: - FINAL CORRECTED FILE: SearchViewModel.swift

import SwiftUI
import Combine
import os
import FirebaseAnalytics

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchTerm: String = ""
    @Published var restaurants: [Restaurant] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasPerformedSearch: Bool = false

    // MARK: - Pagination State
    @Published private(set) var currentPage = 1
    @Published private(set) var canLoadMorePages = true
    private let perPage = 20

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "SearchViewModel")

    // MARK: - Initializer
    init() {
        $searchTerm
            .removeDuplicates()
            .sink { [weak self] term in
                if term.isEmpty {
                    self?.resetSearch()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    // ##### THIS IS THE CORRECTED FUNCTION #####
    /// Performs a search or refresh.
    /// For a refresh, it keeps the old data visible until the new data arrives.
    func performSearch() async {
        guard !searchTerm.isEmpty else {
            resetSearch()
            return
        }
        
        // Set loading state, but DO NOT clear the restaurants list yet.
        // This allows the old results to stay visible during the refresh.
        self.isLoading = true
        self.errorMessage = nil // Clear previous errors.

        logger.info("Performing new search/refresh for term: \(self.searchTerm, privacy: .public)")
        
        // Only log the analytics event on the first page load, not for every refresh.
        if currentPage == 1 {
            Analytics.logEvent("search_initiated", parameters: ["search_term": searchTerm as NSObject])
        }

        do {
            // Fetch the first page. A new search or a refresh should always start from page 1.
            let newRestaurants = try await APIService.shared.searchRestaurants(
                query: searchTerm,
                page: 1, // A refresh always fetches page 1.
                perPage: self.perPage
            )
            
            // ---- ATOMIC UPDATE ----
            // Now that we have the new data, update the state all at once.
            // This prevents the UI from showing an empty list temporarily.
            self.restaurants = newRestaurants
            self.currentPage = 1
            self.canLoadMorePages = newRestaurants.count == self.perPage
            self.hasPerformedSearch = true

        } catch {
            // If the refresh fails, set an error message.
            // We will keep the old (stale) results visible instead of showing an empty screen.
            self.errorMessage = (error as? APIError)?.description ?? "An unknown error occurred."
            self.hasPerformedSearch = true // An attempt was made.
        }
        
        // Finally, turn off the loading indicator.
        self.isLoading = false
    }

    /// Fetches the next page of results for infinite scroll.
    func loadMoreContent() async {
        guard !isLoading, canLoadMorePages else { return }
        
        isLoading = true
        currentPage += 1
        
        logger.info("Loading page \(self.currentPage) for term: \(self.searchTerm, privacy: .public)")

        do {
            let newRestaurants = try await APIService.shared.searchRestaurants(
                query: searchTerm,
                page: self.currentPage,
                perPage: self.perPage
            )
            
            restaurants.append(contentsOf: newRestaurants)
            canLoadMorePages = newRestaurants.count == perPage

        } catch {
            self.errorMessage = (error as? APIError)?.description
            canLoadMorePages = false
        }
        
        isLoading = false
    }

    /// Resets the search term and all state variables.
    @MainActor
    func resetSearch() {
        searchTerm = ""
        restaurants = []
        errorMessage = nil
        isLoading = false
        hasPerformedSearch = false
        
        currentPage = 1
        canLoadMorePages = true
        logger.info("Search state has been reset.")
    }
    
    // MARK: - Mock Data (Unchanged)
    #if DEBUG
    private func generateMockRestaurants() -> [Restaurant] {
         let mockViolation1 = Violation(violation_code: "04N", violation_description: "Filth flies or food/refuse/sewage-associated flies present in facility's food and/or non-food areas.")
         let mockViolation2 = Violation(violation_code: "08A", violation_description: "Facility not vermin proof. Harborage or conditions conducive to attracting vermin to the premises and/or allowing vermin to exist.")
         let mockViolation3 = Violation(violation_code: "06C", violation_description: "Food not protected from potential source of contamination during storage, preparation, transportation, display or service.")
         let mockViolation4 = Violation(violation_code: "10F", violation_description: "Non-food contact surface improperly constructed. Unacceptable material used.")
         let mockViolation5 = Violation(violation_code: "02G", violation_description: "Cold food item held above 41º F (smoked fish and reduced oxygen packaged foods above 38º F) except during necessary preparation.")
         let mockViolation6 = Violation(violation_code: "09C", violation_description: "Food contact surface not properly maintained.")
         let mockInspectionA = Inspection(inspection_date: "2025-03-15T00:00:00.000", critical_flag: "Not Critical", grade: "A", inspection_type: "Cycle Inspection / Initial Inspection", violations: [])
         let mockInspectionB = Inspection(inspection_date: "2024-10-20T00:00:00.000", critical_flag: "Critical", grade: "B", inspection_type: "Cycle Inspection / Re-inspection", violations: [mockViolation1, mockViolation4])
         let mockInspectionC = Inspection(inspection_date: "2024-04-05T00:00:00.000", critical_flag: "Critical", grade: "C", inspection_type: "Cycle Inspection / Initial Inspection", violations: [mockViolation2, mockViolation3, mockViolation5])
         let mockInspectionPending = Inspection(inspection_date: "2025-04-20T00:00:00.000", critical_flag: "Critical", grade: "Z", inspection_type: "Cycle Inspection / Initial Inspection", violations: [mockViolation5])
         let mockInspectionNotGraded = Inspection(inspection_date: "2025-01-10T00:00:00.000", critical_flag: "Not Applicable", grade: "N", inspection_type: "Pre-permit (Operational) / Initial Inspection", violations: [])
         let restaurant1 = Restaurant(camis: "MOCK0001", dba: "Neighborhood Cafe", boro: "MANHATTAN", building: "123", street: "Fictional Ave", zipcode: "10011", phone: "2125551212", latitude: 40.7359, longitude: -73.9911, cuisine_description: "Cafe/Variety", inspections: [mockInspectionA, mockInspectionB])
         let restaurant2 = Restaurant(camis: "MOCK0002", dba: "Downtown Diner", boro: "BROOKLYN", building: "456", street: "Sample St", zipcode: "11201", phone: "7185553434", latitude: 40.6928, longitude: -73.9903, cuisine_description: "American Diner", inspections: [mockInspectionC, mockInspectionA])
         let restaurant3 = Restaurant(camis: "MOCK0003", dba: "Test Kitchen", boro: "QUEENS", building: "78", street: "Example Blvd", zipcode: "11101", phone: "9175556789", latitude: 40.7484, longitude: -73.9352, cuisine_description: "Experimental", inspections: [mockInspectionPending, mockInspectionB])
         let restaurant4 = Restaurant(camis: "MOCK0004", dba: "City Bistro (No Grade Yet)", boro: "MANHATTAN", building: "900", street: "Any Street", zipcode: "10023", phone: "6465559900", latitude: 40.7789, longitude: -73.9819, cuisine_description: "Modern European", inspections: [mockInspectionNotGraded])
         let restaurant5 = Restaurant(camis: "MOCK0005", dba: "Pizza Place Example", boro: "BRONX", building: "111", street: "Pizza Place", zipcode: "10458", phone: "7185551122", latitude: 40.8610, longitude: -73.8880, cuisine_description: "Pizza", inspections: [mockInspectionA])
         return [restaurant1, restaurant2, restaurant3, restaurant4, restaurant5]
     }
    #endif
}
