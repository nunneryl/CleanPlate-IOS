// In file: RecentlyGradedListViewModel.swift

import Foundation
import Combine

@MainActor
class RecentlyGradedListViewModel: ObservableObject {
    
    enum ListState {
        case loading
        case success
        case error(String)
    }
    
    // MARK: - Published Properties
    
    @Published var state: ListState = .loading
    
    @Published var selectedBoro: BoroOption = .any
    @Published var selectedGrade: GradeOption = .any
    
    // --- Data Properties ---
    @Published var recentlyGradedRestaurants: [Restaurant] = []
    @Published var recentlyClosedRestaurants: [Restaurant] = []
    @Published var recentlyReopenedRestaurants: [Restaurant] = []
    
    // --- A computed property to hold the filtered list ---
    var filteredRecentlyGraded: [Restaurant] {
        var filteredList = recentlyGradedRestaurants

        // Apply Borough Filter
        if selectedBoro != .any {
            // We use case-insensitive comparison for robustness
            filteredList = filteredList.filter { $0.boro?.caseInsensitiveCompare(selectedBoro.rawValue) == .orderedSame }
        }

        // Apply Grade Filter
        if selectedGrade != .any {
            if selectedGrade == .pending {
                // "Grade Pending" can have multiple values in the data ('P' or 'Z')
                filteredList = filteredList.filter { ["P", "Z"].contains($0.mostRecentInspectionGrade ?? "") }
            } else {
                filteredList = filteredList.filter { $0.mostRecentInspectionGrade == selectedGrade.rawValue }
            }
        }
        
        return filteredList
    }

    init() {}
    
    func loadContent() async {
        guard recentlyGradedRestaurants.isEmpty else { return }
        
        self.state = .loading
        
        do {
            async let graded = APIService.shared.fetchRecentlyGraded()
            async let actions = APIService.shared.fetchRecentActions()
            
            let gradedResults = try await graded
            let actionResults = try await actions
            
            self.recentlyGradedRestaurants = gradedResults
            self.recentlyClosedRestaurants = actionResults.recently_closed
            self.recentlyReopenedRestaurants = actionResults.recently_reopened
            
            self.state = .success
            
        } catch {
            let errorMessage = (error as? APIError)?.description ?? "An unknown error occurred."
            self.state = .error(errorMessage)
        }
    }
}
