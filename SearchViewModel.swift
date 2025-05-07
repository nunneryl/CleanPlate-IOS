// SearchViewModel.swift

 import SwiftUI
 import Combine
 import os
 import FirebaseAnalytics // <-- Keep this import

 @MainActor
 class SearchViewModel: ObservableObject {
     @Published var searchTerm: String = ""
     @Published var restaurants: [Restaurant] = []
     @Published var isLoading: Bool = false
     @Published var errorMessage: String? = nil
     @Published var hasPerformedSearch: Bool = false // Keep this property

     private var cancellables = Set<AnyCancellable>()
     private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "SearchViewModel")

     init() {
         // Keep existing debouncer
         $searchTerm
             .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
             .sink { [weak self] term in
                 if term.isEmpty {
                     // Only clear if NOT in DEBUG mode with mock data active
                     #if !DEBUG
                     self?.restaurants = []
                     self?.hasPerformedSearch = false
                     self?.errorMessage = nil
                     #endif
                 }
             }
             .store(in: &cancellables)
     }

     // --- Helper to create URL ---
     private func createSearchURL(for term: String) -> URL? {
         let normalized = term
             .trimmingCharacters(in: .whitespacesAndNewlines)
         guard let encoded = normalized.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
             logger.error("Failed to percent-encode search term: \(normalized, privacy: .public)")
             return nil
         }
         // Ensure this URL points to your production backend
         return URL(string: "https://cleanplate-production.up.railway.app/search?name=\(encoded)")
     }

     // --- Helper to fetch and decode for one term ---
     private func fetchAndDecode(for term: String) async -> [Restaurant]? {
         guard let url = createSearchURL(for: term) else {
             return nil
         }

         var request = URLRequest(url: url)
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         request.timeoutInterval = 15

         logger.debug("Fetching URL: \(url.absoluteString, privacy: .public)")

         do {
             let (data, response) = try await URLSession.shared.data(for: request)

             guard let httpResponse = response as? HTTPURLResponse else {
                 logger.error("Invalid response type (not HTTPURLResponse) for term: \(term, privacy: .public)")
                 return nil
             }

             guard (200...299).contains(httpResponse.statusCode) else {
                  logger.error("HTTP Error \(httpResponse.statusCode) for term: \(term, privacy: .public)")
                  // Set specific error based on code or generic one
                  // Example: if httpResponse.statusCode == 429 { self.errorMessage = ... }
                  return nil
              }

             do {
                 let decoded = try JSONDecoder().decode([Restaurant].self, from: data)
                 logger.debug("Successfully decoded \(decoded.count) restaurants for term: \(term, privacy: .public)")
                 return decoded
             } catch {
                 logger.error("JSON decoding error for term '\(term, privacy: .public)': \(error.localizedDescription, privacy: .public)")
                 if let rawString = String(data: data, encoding: .utf8) {
                      logger.error("Raw data on decoding error (term: \(term)): \(rawString.prefix(500), privacy: .public)")
                 }
                 return nil
             }

         } catch let urlError as URLError {
             logger.error("Network error for term '\(term, privacy: .public)': \(urlError.localizedDescription, privacy: .public)")
             // Set network error message based on urlError.code
             // Example: if urlError.code == .notConnectedToInternet { ... }
             return nil
         } catch {
             logger.error("Unexpected error fetching term '\(term, privacy: .public)': \(error.localizedDescription, privacy: .public)")
             return nil
         }
     }


     @MainActor
     func performSearch() async {
         guard !searchTerm.isEmpty else { return }

         // --- MOCK DATA FOR SCREENSHOTS (DEBUG ONLY) ---
         #if DEBUG
         // Check if the search term triggers mock data (e.g., "mock")
         // Or simply always show mock data when search is performed in Debug
         logger.info("DEBUG MODE: Generating mock data instead of network request.")
         self.isLoading = true // Simulate loading briefly
         self.errorMessage = nil
         self.restaurants = generateMockRestaurants()
         self.hasPerformedSearch = true
         // Simulate network delay
         try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
         self.isLoading = false
         return // Exit early, skipping network call
         #endif
         // --- END MOCK DATA ---


         // --- Production Search Logic ---
         errorMessage = nil
         isLoading = true
         hasPerformedSearch = false
         restaurants = []

         let originalTerm = searchTerm
         logger.info("Performing search with original term: \(originalTerm, privacy: .public)")

         // Log Analytics Event
         Analytics.logEvent("search_initiated", parameters: ["search_term": originalTerm as NSObject])
         print("Analytics: Logged search_initiated event with term: \(originalTerm)")

         // Generate Search Term Variations
         var termsToSearch: [String] = [originalTerm]
         let searchTermLowercased = originalTerm.lowercased()
         if searchTermLowercased.contains(" and ") {
             let originalComponents = originalTerm.components(separatedBy: CharacterSet.whitespaces)
             let ampersandVersion = originalComponents.joined(separator: " ").replacingOccurrences(of: " and ", with: " & ", options: .caseInsensitive)
             let plusVersion = originalComponents.joined(separator: " ").replacingOccurrences(of: " and ", with: " + ", options: .caseInsensitive)

             if !termsToSearch.contains(where: { $0.caseInsensitiveCompare(ampersandVersion) == .orderedSame }) {
                 termsToSearch.append(ampersandVersion)
             }
             if !termsToSearch.contains(where: { $0.caseInsensitiveCompare(plusVersion) == .orderedSame }) && ampersandVersion.caseInsensitiveCompare(plusVersion) != .orderedSame {
                 termsToSearch.append(plusVersion)
             }
             logger.info("Generated search variations: \(termsToSearch.joined(separator: ", "), privacy: .public)")
         }

         // Perform Sequential Searches
         var combinedResults: [Restaurant] = []
         var encounteredError = false

         for term in termsToSearch {
             if let results = await fetchAndDecode(for: term) {
                 combinedResults.append(contentsOf: results)
             } else {
                 encounteredError = true
                 logger.warning("Search for term '\(term)' failed, continuing with other variations if any.")
                 // Set a generic error message if one wasn't set during fetch
                 if self.errorMessage == nil {
                      // Only set error if ALL searches fail later
                 }
             }
         }

         // Process Final Results
         isLoading = false
         hasPerformedSearch = true

         if combinedResults.isEmpty {
             logger.info("Search completed, no restaurants found for any variation of term: \(originalTerm, privacy: .public)")
             self.restaurants = []
             if encounteredError {
                 // All searches failed or returned no results amidst errors
                 self.errorMessage = "Search failed. Please check connection or try again."
             } // else: No error message needed, UI shows "No results found"

         } else {
             // We have some results
             logger.info("Search completed. Found \(combinedResults.count) raw results for variations of term: \(originalTerm, privacy: .public). Deduplicating...")

             // Deduplicate
             var uniqueResultsDict: [String: Restaurant] = [:]
             for restaurant in combinedResults {
                 // Use CAMIS as the unique key for deduplication
                 if let camis = restaurant.camis, uniqueResultsDict[camis] == nil {
                     uniqueResultsDict[camis] = restaurant
                 } else if restaurant.camis == nil {
                     // Handle restaurants without CAMIS if necessary (e.g., use name+address as key)
                     // For now, we might lose them in deduplication if CAMIS is nil
                     logger.warning("Restaurant found without CAMIS during deduplication: \(restaurant.dba ?? "N/A")")
                 }
             }
             let finalResults = Array(uniqueResultsDict.values)

             self.restaurants = finalResults
             self.errorMessage = nil // Clear any minor errors if we got results
             logger.info("Deduplication complete. Displaying \(finalResults.count) unique restaurants.")

             if encounteredError {
                 // Optionally show a non-blocking warning if some variations failed but we still got results
                 // self.errorMessage = "Some search variations failed, results may be incomplete."
                 logger.warning("Some search variations failed, but results were found.")
             }
         }
     }


     @MainActor
     func resetSearch() {
         searchTerm = ""
         // Debouncer handles clearing restaurants in production
         #if DEBUG
         // In Debug, explicitly clear mock data if needed, or let debouncer clear search term
         // If you want mock data to persist until next search, do nothing here.
         // If you want reset to clear mock data:
         // self.restaurants = []
         // self.hasPerformedSearch = false
         #endif
         errorMessage = nil
         isLoading = false
         // Only reset hasPerformedSearch if not in DEBUG or if you want reset to clear mock data
         #if !DEBUG
         hasPerformedSearch = false
         #endif
         logger.info("Search explicitly reset.")
     }


     // --- MOCK DATA GENERATION (DEBUG ONLY) ---
     #if DEBUG
     private func generateMockRestaurants() -> [Restaurant] {
         let mockViolation1 = Violation(violation_code: "04N", violation_description: "Filth flies or food/refuse/sewage-associated flies present in facility's food and/or non-food areas.")
         let mockViolation2 = Violation(violation_code: "08A", violation_description: "Facility not vermin proof. Harborage or conditions conducive to attracting vermin to the premises and/or allowing vermin to exist.")
         let mockViolation3 = Violation(violation_code: "06C", violation_description: "Food not protected from potential source of contamination during storage, preparation, transportation, display or service.")
         let mockViolation4 = Violation(violation_code: "10F", violation_description: "Non-food contact surface improperly constructed. Unacceptable material used.")
         let mockViolation5 = Violation(violation_code: "02G", violation_description: "Cold food item held above 41º F (smoked fish and reduced oxygen packaged foods above 38º F) except during necessary preparation.")
         let mockViolation6 = Violation(violation_code: "09C", violation_description: "Food contact surface not properly maintained.")


         let mockInspectionA = Inspection(
             inspection_date: "2025-03-15T00:00:00.000", // Use ISO 8601 format if your parser expects it
             critical_flag: "Not Critical",
             grade: "A",
             inspection_type: "Cycle Inspection / Initial Inspection",
             violations: [] // No violations for A grade
         )

         let mockInspectionB = Inspection(
             inspection_date: "2024-10-20T00:00:00.000",
             critical_flag: "Critical",
             grade: "B", // Changed to B
             inspection_type: "Cycle Inspection / Re-inspection",
             violations: [mockViolation1, mockViolation4] // Add some violations for B
         )

         let mockInspectionC = Inspection(
             inspection_date: "2024-04-05T00:00:00.000",
             critical_flag: "Critical",
             grade: "C", // Changed to C
             inspection_type: "Cycle Inspection / Initial Inspection",
             violations: [mockViolation2, mockViolation3, mockViolation5] // More violations for C
         )

         let mockInspectionPending = Inspection(
             inspection_date: "2025-04-20T00:00:00.000",
             critical_flag: "Critical",
             grade: "Z", // Grade Pending
             inspection_type: "Cycle Inspection / Initial Inspection",
             violations: [mockViolation5]
         )

         let mockInspectionNotGraded = Inspection(
             inspection_date: "2025-01-10T00:00:00.000",
             critical_flag: "Not Applicable",
             grade: "N", // Not Yet Graded
             inspection_type: "Pre-permit (Operational) / Initial Inspection",
             violations: []
         )


         let restaurant1 = Restaurant(
             camis: "MOCK0001",
             dba: "Neighborhood Cafe",
             boro: "MANHATTAN",
             building: "123",
             street: "Fictional Ave",
             zipcode: "10011",
             phone: "2125551212",
             latitude: 40.7359,
             longitude: -73.9911,
             cuisine_description: "Cafe/Variety",
             inspections: [mockInspectionA, mockInspectionB] // History with A and B
         )

         let restaurant2 = Restaurant(
             camis: "MOCK0002",
             dba: "Downtown Diner",
             boro: "BROOKLYN",
             building: "456",
             street: "Sample St",
             zipcode: "11201",
             phone: "7185553434",
             latitude: 40.6928,
             longitude: -73.9903,
             cuisine_description: "American Diner",
             inspections: [mockInspectionC, mockInspectionA] // History with C and A
         )

         let restaurant3 = Restaurant(
             camis: "MOCK0003",
             dba: "Test Kitchen",
             boro: "QUEENS",
             building: "78",
             street: "Example Blvd",
             zipcode: "11101",
             phone: "9175556789",
             latitude: 40.7484,
             longitude: -73.9352,
             cuisine_description: "Experimental",
             inspections: [mockInspectionPending, mockInspectionB] // History with Pending and B
         )

         let restaurant4 = Restaurant(
             camis: "MOCK0004",
             dba: "City Bistro (No Grade Yet)",
             boro: "MANHATTAN",
             building: "900",
             street: "Any Street",
             zipcode: "10023",
             phone: "6465559900",
             latitude: 40.7789,
             longitude: -73.9819,
             cuisine_description: "Modern European",
             inspections: [mockInspectionNotGraded] // Only 'Not Yet Graded' inspection
         )

         let restaurant5 = Restaurant(
             camis: "MOCK0005",
             dba: "Pizza Place Example",
             boro: "BRONX",
             building: "111",
             street: "Pizza Place",
             zipcode: "10458",
             phone: "7185551122",
             latitude: 40.8610,
             longitude: -73.8880,
             cuisine_description: "Pizza",
             inspections: [mockInspectionA] // Simple A grade
         )


         return [restaurant1, restaurant2, restaurant3, restaurant4, restaurant5]
     }
     #endif
     // --- END MOCK DATA GENERATION ---

 }
