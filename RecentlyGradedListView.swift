// In file: RecentlyGradedListView.swift

import SwiftUI

struct RecentlyGradedListView: View {
    @StateObject private var viewModel = RecentlyGradedListViewModel()
    
    init() {}

    var body: some View {
        VStack {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading...")
                    .frame(maxHeight: .infinity)
            
            case .error(let errorMessage):
                Text(errorMessage)
                    .foregroundColor(.secondary)
                    .frame(maxHeight: .infinity)
            
            case .success:
                restaurantList
            }
        }
        .navigationTitle("Recently Graded")
        .task {
            await viewModel.loadContent()
        }
    }
    
    // The main list view content, extracted for clarity
    private var restaurantList: some View {
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
                                Text("\(restaurant.formattedStreet), \(restaurant.formattedBoro)")
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            } else {
                Section {
                    Text("No restaurants match your selected filters.")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
