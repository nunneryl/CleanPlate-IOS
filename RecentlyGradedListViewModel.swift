// MARK: - UPDATED FILE: RecentlyGradedListViewModel.swift

import Foundation

@MainActor
class RecentlyGradedListViewModel: ObservableObject {
    
    @Published var restaurants: [Restaurant] = []
    @Published var isLoading = false
    
    // Filter & Sort Properties
    @Published var boroFilter: BoroOption = .any
    @Published var gradeFilter: GradeOption = .any
    @Published var sortOption: SortOption = .dateDesc

    var filteredRestaurants: [Restaurant] {
        var processedList = restaurants
        
        // --- FILTERING LOGIC (UNCHANGED) ---
        if boroFilter != .any {
            processedList = processedList.filter { $0.boro?.caseInsensitiveCompare(boroFilter.rawValue) == .orderedSame }
        }
        
        if gradeFilter != .any {
            processedList = processedList.filter { restaurant in
                if let mostRecentGradedInspection = restaurant.inspections?.sorted(by: { $0.inspection_date ?? "" > $1.inspection_date ?? "" }).first(where: { ["A", "B", "C"].contains($0.grade ?? "") }) {
                    return mostRecentGradedInspection.grade == gradeFilter.rawValue
                }
                return false
            }
        }
        
        // --- SORTING LOGIC (UPDATED) ---
        // We only apply a new sort if the user has selected something other than the default.
        // The API already provides the list sorted by date.
        switch sortOption {
        case .nameAsc:
            processedList.sort { $0.dba ?? "" < $1.dba ?? "" }
        case .nameDesc:
            processedList.sort { $0.dba ?? "" > $1.dba ?? "" }
        case .gradeAsc:
            processedList.sort {
                let grade1 = $0.inspections?.first?.grade ?? "Z"
                let grade2 = $1.inspections?.first?.grade ?? "Z"
                return grade1 < grade2
            }
        case .dateDesc, .relevance:
            // Do nothing, trust the API's default sort order.
            break
        }
        
        return processedList
    }
    
    init() {}
    
    func loadContent() async {
        guard restaurants.isEmpty, !isLoading else { return }
        isLoading = true
        
        do {
            let newRestaurants = try await APIService.shared.fetchRecentlyGraded(limit: 100)
            self.restaurants = newRestaurants
        } catch {
            print("Error loading content: \(error)")
        }
        
        isLoading = false
    }
}
