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
            async let activity = APIService.shared.fetchRecentActivity()
            async let actions = APIService.shared.fetchRecentActions()
            
            let (activityResults, actionResults) = try await (activity, actions)
            
            self.recentActivity = activityResults
            self.recentlyClosedRestaurants = actionResults.recently_closed
            self.recentlyReopenedRestaurants = actionResults.recently_reopened
            
            self.state = .success
            
        } catch {
            let errorMessage = (error as? APIError)?.description ?? "An unknown error occurred."
            self.state = .error(errorMessage)
        }
    }
}
