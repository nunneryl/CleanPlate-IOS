// In file: SearchViewModel.swift

import SwiftUI
import Combine
import os
import FirebaseAnalytics

@MainActor
class SearchViewModel: ObservableObject {
    
    // MARK: - State Management
    enum SearchState {
        case idle
        case loading
        case success([Restaurant])
        case error(String)
        case loadingMore([Restaurant])
    }
    
    @Published var state: SearchState = .idle
    
    // MARK: - Search & Filter Properties
    @Published var searchTerm: String = ""
    @Published var selectedSort: SortOption = .relevance
    @Published var selectedBoro: BoroOption = .any
    @Published var selectedGrade: GradeOption = .any
    @Published var selectedCuisine: CuisineOption = .any
    
    // MARK: - Discovery & Recent Search Properties
    @Published var recentlyGradedRestaurants: [Restaurant] = []
    @Published var isLoadingDiscovery: Bool = false
    @Published var recentSearches: [RecentSearch] = []
    
    // MARK: - Navigation & Pagination
    @Published var navigationID = UUID()
    @Published private(set) var canLoadMorePages = true
    private var currentPage = 1
    private let perPage = 25

    // MARK: - Computed Properties
    var restaurants: [Restaurant] {
        switch state {
        case .success(let restaurants), .loadingMore(let restaurants):
            return restaurants
        default:
            return []
        }
    }
    
    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var isLoadingMore: Bool {
        if case .loadingMore = state { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = state { return message }
        return nil
    }
    
    var hasPerformedSearch: Bool {
        if case .idle = state { return false }
        return true
    }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "SearchViewModel")

    // MARK: - Initializer
    init() {
           let filterPublishers = Publishers.CombineLatest4($selectedSort, $selectedBoro, $selectedGrade, $selectedCuisine)
           
           filterPublishers
               .dropFirst()
               .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
               .sink { [weak self] _, _, _, _ in
                   guard let self = self, !self.searchTerm.isEmpty else { return }
                   Task { await self.performSearch() }
               }
               .store(in: &cancellables)
               
           // Listen for the "clear" notification
           NotificationCenter.default.publisher(for: .didClearRecentSearches)
               .receive(on: DispatchQueue.main)
               .sink { [weak self] _ in
                   self?.recentSearches = []
                   self?.logger.info("Cleared recent searches via notification.")
               }
               .store(in: &cancellables)
       }

    
    // MARK: - Public Methods
    func performSearch() async {
        await fetchRestaurants(isNewSearch: true)
    }

    func loadMoreContent() async {
        await fetchRestaurants(isNewSearch: false)
    }
    
    func loadIdleScreenContent() async {
        if case .success = self.state { return }
        guard !isLoadingDiscovery else { return }
        self.isLoadingDiscovery = true
        
        // Run both network calls in parallel for better performance
        async let gradedTask = APIService.shared.fetchRecentlyGraded()
        async let recentSearchesTask: () = self.fetchRecentSearches()
        
        do {
            let restaurants = try await gradedTask
            self.recentlyGradedRestaurants = restaurants
            logger.info("Successfully loaded \(restaurants.count) recently graded restaurants.")
        } catch {
            logger.error("Failed to load recently graded list: \(error.localizedDescription)")
        }
        
        await recentSearchesTask // Await the result of the searches fetch
        
        self.isLoadingDiscovery = false
    }

    func resetSearch() {
            searchTerm = ""
            state = .idle
            currentPage = 1
            canLoadMorePages = true
            
            selectedSort = .relevance
            selectedBoro = .any
            selectedGrade = .any
            selectedCuisine = .any
            
            self.navigationID = UUID()
            logger.info("Search state has been reset.")
        }
    
    func logSeeAllRecentlyGradedTapped() {
            Analytics.logEvent("view_recently_graded_all", parameters: nil)
            logger.info("Analytics event logged: view_recently_graded_all")
        }
    
    // --- NEW: Dedicated function to fetch recent searches ---
    func fetchRecentSearches() async {
        guard let token = AuthTokenProvider.token else {
            self.recentSearches = [] // Clear searches if user is logged out
            return
        }
        
        do {
            let searches = try await APIService.shared.fetchRecentSearches(token: token)
            self.recentSearches = searches
            logger.info("Successfully loaded \(searches.count) recent searches.")
        } catch {
            logger.error("Failed to load recent searches: \(error.localizedDescription)")
            self.recentSearches = [] // Clear on error
        }
    }
    
    // MARK: - Private Helpers
    private func fetchRestaurants(isNewSearch: Bool) async {
        guard !searchTerm.isEmpty else {
            resetSearch()
            return
        }
        
        if !isNewSearch && (isLoading || !canLoadMorePages) { return }
        
        if isNewSearch {
            state = .loading
            currentPage = 1
            canLoadMorePages = true
        } else {
            state = .loadingMore(restaurants)
            currentPage += 1
        }
        
        let filters = apiFilterParameters()
        
        do {
            let newRestaurants = try await APIService.shared.searchRestaurants(
                query: searchTerm, page: currentPage, perPage: perPage,
                grade: filters.grade, boro: filters.boro, cuisine: filters.cuisine, sort: filters.sort
            )
            
            let allRestaurants = isNewSearch ? newRestaurants : (restaurants + newRestaurants)
            state = .success(allRestaurants)
            
            if isNewSearch {
                if let token = AuthTokenProvider.token {
                    Task(priority: .background) {
                        try? await APIService.shared.saveRecentSearch(searchTerm: searchTerm, token: token)
                        logger.info("Attempted to save recent search: '\(self.searchTerm)'")
                        // --- MODIFIED: Immediately refresh the list after saving ---
                        await self.fetchRecentSearches()
                    }
                }
                Analytics.logEvent("search_performed", parameters: ["search_term": searchTerm, "result_count": newRestaurants.count])
            }
            
            canLoadMorePages = newRestaurants.count == perPage
            
        } catch {
            let errorMessage = (error as? APIError)?.description ?? "An unknown error occurred."
            state = .error(errorMessage)
            canLoadMorePages = false
            Analytics.logEvent("search_error", parameters: ["search_term": searchTerm, "error_message": errorMessage])
        }
    }
    
    private func apiFilterParameters() -> (sort: String?, grade: String?, boro: String?, cuisine: String?) {
        let sortValue = (selectedSort == .relevance) ? nil : selectedSort.rawValue
        let gradeValue = (selectedGrade == .any) ? nil : selectedGrade.rawValue
        let boroValue = (selectedBoro == .any) ? nil : selectedBoro.rawValue
        let cuisineValue = (selectedCuisine == .any) ? nil : selectedCuisine.rawValue
        
        return (sort: sortValue, grade: gradeValue, boro: boroValue, cuisine: cuisineValue)
    }
}
