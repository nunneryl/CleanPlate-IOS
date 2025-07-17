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
            processedList = processedList.filter { $0.latestFinalGrade == gradeFilter.rawValue }
        }
        
        // Sorting Logic
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
