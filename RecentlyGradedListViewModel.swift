// In file: RecentlyGradedListViewModel.swift

import Foundation

@MainActor
class RecentlyGradedListViewModel: ObservableObject {
    
    enum ListState {
        case loading
        case success([Restaurant])
        case error(String)
    }
    
    @Published var state: ListState = .loading
    
    // Filter & Sort Properties
    @Published var boroFilter: BoroOption = .any
    @Published var gradeFilter: GradeOption = .any
    @Published var sortOption: SortOption = .dateDesc

    // In file: RecentlyGradedListViewModel.swift

    var filteredRestaurants: [Restaurant] {
        guard case .success(let restaurants) = state else {
            return []
        }
        
        var processedList = restaurants
        
        // Filtering Logic
        if boroFilter != .any {
            processedList = processedList.filter { $0.boro?.caseInsensitiveCompare(boroFilter.rawValue) == .orderedSame }
        }
        
        if gradeFilter != .any {
            processedList = processedList.filter { restaurant in
                // Get the true most recent inspection for the restaurant
                guard let latestInspection = restaurant.inspections?.sorted(by: { $0.inspection_date ?? "" > $1.inspection_date ?? "" }).first else {
                    return false
                }
                
                let latestGrade = latestInspection.grade ?? ""

                switch gradeFilter {
                case .closed:
                    // Check if the latest action was a closure
                    return latestInspection.action?.lowercased().contains("closed by dohmh") == true
                case .pending:
                    // Check for pending grades
                    return latestGrade == "P" || latestGrade == "Z"
                case .any:
                    return true
                case .a, .b, .c:
                    return latestGrade == gradeFilter.rawValue
                }
            }
        }
        
        // Sorting Logic (remains unchanged)
        switch sortOption {
        case .nameAsc:
            processedList.sort { ($0.dba ?? "") < ($1.dba ?? "") }
        case .nameDesc:
            processedList.sort { ($0.dba ?? "") > ($1.dba ?? "") }
        case .gradeAsc:
            processedList.sort { ($0.latestFinalGrade ?? "Z") < ($1.latestFinalGrade ?? "Z") }
        case .dateDesc, .relevance:
            break
        }
        
        return processedList
    }
    
    init() {}
    
    func loadContent() async {
        if case .success = self.state {
            return
        }
        
        self.state = .loading
        do {
            let newRestaurants = try await APIService.shared.fetchRecentlyGraded(limit: 100)
            self.state = .success(newRestaurants)
        } catch {
            let errorMessage = (error as? APIError)?.description ?? "An unknown error occurred."
            self.state = .error(errorMessage)
        }
    }
}
