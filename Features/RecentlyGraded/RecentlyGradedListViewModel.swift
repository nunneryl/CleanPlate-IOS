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
    
    @Published var recentActivity: [Restaurant] = []
    
    @Published var recentlyClosedRestaurants: [Restaurant] = []
    @Published var recentlyReopenedRestaurants: [Restaurant] = []
    
    // --- MODIFIED: This now filters using the new `displayGrade` property ---
    var filteredRecentActivity: [Restaurant] {
        var filteredList = recentActivity

        // Apply Borough Filter
        if selectedBoro != .any {
            filteredList = filteredList.filter { $0.boro?.caseInsensitiveCompare(selectedBoro.rawValue) == .orderedSame }
        }

        // Apply Grade Filter
        if selectedGrade != .any {
            if selectedGrade == .pending {
                // "Grade Pending" can have multiple values
                filteredList = filteredList.filter { ["P", "Z", "N"].contains($0.displayGrade ?? "") }
            } else {
                filteredList = filteredList.filter { $0.displayGrade == selectedGrade.rawValue }
            }
        }
        
        return filteredList
    }

    init() {}
    
    func loadContent() async {
        guard recentActivity.isEmpty else { return }
        
        self.state = .loading
        
        do {
            // Make a single, correct API call
            let actionResults = try await APIService.shared.fetchRecentActions()
            
            // Populate all three lists from the single response
            self.recentActivity = actionResults.recently_graded.sorted { r1, r2 in
                let date1 = r1.finalized_date ?? r1.grade_date ?? "0000-00-00"
                let date2 = r2.finalized_date ?? r2.grade_date ?? "0000-00-00"
                return date1 > date2
            }
            self.recentlyClosedRestaurants = actionResults.recently_closed
            self.recentlyReopenedRestaurants = actionResults.recently_reopened
            
            self.state = .success
            
        } catch {
            let errorMessage = (error as? APIError)?.localizedDescription ?? "An unknown error occurred."
            self.state = .error(errorMessage)
        }
    }
}
