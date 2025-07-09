// MARK: - UPDATED FILE: SearchViewModel.swift

import SwiftUI
import Combine
import os
import FirebaseAnalytics

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties for Search State
    @Published var searchTerm: String = ""
    @Published var restaurants: [Restaurant] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasPerformedSearch: Bool = false
    
    // --- NEW PROPERTY FOR NAVIGATION RESET ---
    @Published var navigationID = UUID()

    // MARK: - Published Properties for Discovery Lists
    @Published var recentlyGradedRestaurants: [Restaurant] = []
    @Published var isLoadingDiscovery: Bool = false
    
    // MARK: - Published Properties for Filters & Sorting
    @Published var selectedSort: SortOption = .relevance
    @Published var selectedBoro: BoroOption = .any
    @Published var selectedGrade: GradeOption = .any
    @Published var selectedCuisine: CuisineOption = .any

    // MARK: - Pagination State
    @Published private(set) var currentPage = 1
    @Published private(set) var canLoadMorePages = true
    private let perPage = 25

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

        let filterPublishers = Publishers.CombineLatest4($selectedSort, $selectedBoro, $selectedGrade, $selectedCuisine)
        
        filterPublishers
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _, _ in
                guard let self = self, !self.searchTerm.isEmpty else { return }
                Task {
                    await self.performSearch()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods for Discovery
    func loadDiscoveryLists() async {
        guard recentlyGradedRestaurants.isEmpty, !isLoadingDiscovery else { return }
        self.isLoadingDiscovery = true
        
        do {
            let restaurants = try await APIService.shared.fetchRecentlyGraded(limit: 20)
            self.recentlyGradedRestaurants = restaurants
            logger.info("Successfully loaded \(restaurants.count) recently graded restaurants for discovery.")
        } catch {
            logger.error("Failed to load discovery lists: \(error.localizedDescription)")
        }
        
        self.isLoadingDiscovery = false
    }

    // MARK: - Public Methods for Search
    func performSearch() async {
        guard !searchTerm.isEmpty else {
            resetSearch()
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil

        do {
            let filters = apiFilterParameters()
            
            let newRestaurants = try await APIService.shared.searchRestaurants(
                query: searchTerm,
                page: 1,
                perPage: perPage,
                grade: filters.grade,
                boro: filters.boro,
                cuisine: filters.cuisine,
                sort: filters.sort
            )
            
            Analytics.logEvent("search_performed", parameters: [
                           "search_term": searchTerm,
                           "result_count": newRestaurants.count,
                           "was_successful": true
                       ])
            
            restaurants = newRestaurants
            currentPage = 1
            canLoadMorePages = newRestaurants.count == perPage
            hasPerformedSearch = true

        } catch {
            errorMessage = (error as? APIError)?.description ?? "An unknown error occurred."
            
            Analytics.logEvent("search_performed", parameters: [
                "search_term": searchTerm,
                "was_successful": false,
                "error_message": errorMessage ?? "unknown"
            ])
            
            hasPerformedSearch = true
        }
        
        isLoading = false
    }

    func loadMoreContent() async {
        guard !isLoading, canLoadMorePages else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let filters = apiFilterParameters()
            
            let newRestaurants = try await APIService.shared.searchRestaurants(
                query: searchTerm,
                page: currentPage,
                perPage: perPage,
                grade: filters.grade,
                boro: filters.boro,
                cuisine: filters.cuisine,
                sort: filters.sort
            )
            
            restaurants.append(contentsOf: newRestaurants)
            canLoadMorePages = newRestaurants.count == perPage

        } catch {
            errorMessage = (error as? APIError)?.description
            canLoadMorePages = false
        }
        
        isLoading = false
    }

    @MainActor
    func resetSearch() {
        searchTerm = ""
        restaurants = []
        errorMessage = nil
        isLoading = false
        hasPerformedSearch = false
        
        currentPage = 1
        canLoadMorePages = true
        
        selectedSort = .relevance
        selectedBoro = .any
        selectedGrade = .any
        selectedCuisine = .any
        
        // --- THIS IS THE KEY UPDATE ---
        // Change the ID to force the NavigationView to reset
        self.navigationID = UUID()
        
        logger.info("Search state has been reset.")
    }
    
    // MARK: - Private Helpers
    private func apiFilterParameters() -> (sort: String?, grade: String?, boro: String?, cuisine: String?) {
        let sortValue = (selectedSort == .relevance) ? nil : selectedSort.rawValue
        let gradeValue = (selectedGrade == .any) ? nil : selectedGrade.rawValue
        let boroValue = (selectedBoro == .any) ? nil : selectedBoro.rawValue
        let cuisineValue = (selectedCuisine == .any) ? nil : selectedCuisine.rawValue
        
        return (sort: sortValue, grade: gradeValue, boro: boroValue, cuisine: cuisineValue)
    }
}
