// MARK: - UPDATED FILE: RecentlyGradedListView.swift

import SwiftUI

struct RecentlyGradedListView: View {
    @StateObject private var viewModel = RecentlyGradedListViewModel()
    @State private var isShowingFilterSheet = false
    
    private var isFilterActive: Bool {
        return viewModel.boroFilter != .any || viewModel.gradeFilter != .any
    }
    
    init() {}

    var body: some View {
        VStack {
            if viewModel.isLoading && viewModel.restaurants.isEmpty {
                ProgressView().frame(maxHeight: .infinity)
            } else if !viewModel.filteredRestaurants.isEmpty || (viewModel.boroFilter != .any || viewModel.gradeFilter != .any) {
                // Show the list if there are results OR if a filter is active
                Form {
                    Section(header: Text("Filters")) {
                        Picker("Borough", selection: $viewModel.boroFilter) {
                            ForEach(BoroOption.allCases) { boro in Text(boro.rawValue).tag(boro) }
                        }
                        Picker("Grade", selection: $viewModel.gradeFilter) {
                            ForEach([GradeOption.any, .a, .b, .c], id: \.self) { grade in Text(grade.rawValue).tag(grade) }
                        }
                    }
                    
                    if !viewModel.filteredRestaurants.isEmpty {
                        Section(header: Text("Restaurants (\(viewModel.filteredRestaurants.count))")) {
                            ForEach(viewModel.filteredRestaurants) { restaurant in
                                NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(restaurant.dba ?? "Unknown")
                                        Text("\(formatStreet(restaurant.street ?? "")), \(formatBorough(restaurant.boro ?? ""))")
                                            .font(.subheadline).foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    } else {
                        // Empty state for when filters result in no matches
                        Section {
                            Text("No restaurants match your selected filters.")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                // Fallback for when the list is loading or empty with no filters active
                Text("Loading...")
                    .foregroundColor(.secondary)
                    .frame(maxHeight: .infinity)
            }
        }
        .navigationTitle("Recently Graded")
        .task {
            await viewModel.loadContent()
        }
    }
    
    // --- HELPER FUNCTIONS WITH FULL IMPLEMENTATION ---
    private func formatStreet(_ street: String) -> String {
        var formatted = street
        if formatted.lowercased().contains("avenue") {
            formatted = formatted.replacingOccurrences(of: "AVENUE", with: "Ave", options: .caseInsensitive)
        }
        if formatted.lowercased().contains("street") {
            formatted = formatted.replacingOccurrences(of: "STREET", with: "St", options: .caseInsensitive)
        }
        return formatted
    }

    private func formatBorough(_ boro: String) -> String {
        return boro.capitalized
    }
}
