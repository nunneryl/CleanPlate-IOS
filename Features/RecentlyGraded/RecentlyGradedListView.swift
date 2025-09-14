// In file: RecentlyGradedListView.swift

import SwiftUI

struct RecentlyGradedListView: View {
    @StateObject private var viewModel = RecentlyGradedListViewModel()
    
    // --- MODIFIED: Back to three tabs ---
    private enum SelectedTab: String, CaseIterable {
        case graded = "Graded"
        case closed = "Closed"
        case reopened = "Re-opened"
    }
    @State private var selectedTab: SelectedTab = .graded
    
    var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    Picker("Select a list", selection: $selectedTab) {
                        ForEach(SelectedTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    switch viewModel.state {
                    case .loading:
                        ProgressView("Loading...")
                            .frame(maxHeight: .infinity)
                        
                    case .error(let errorMessage):
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxHeight: .infinity)
                        
                    case .success:
                        successView
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Grade & Status Changes")
                .navigationBarTitleDisplayMode(.inline)
                .task {
                    await viewModel.loadContent()
                }
            }
            .navigationViewStyle(.stack)
        }
    
    private var successView: some View {
        Form {
            if selectedTab == .graded {
                Section(header: Text("Filter Graded List")) {
                    Picker("Borough", selection: $viewModel.selectedBoro) {
                        ForEach(BoroOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    Picker("Grade", selection: $viewModel.selectedGrade) {
                        ForEach(GradeOption.allCases.filter { $0 != .closed }) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }
            }

            switch selectedTab {
                        case .graded:
                            contentSection(for: viewModel.filteredRecentActivity,
                                           emptyMessage: "No recently graded restaurants match your filters.",
                                           tab: .graded) // <-- Pass tab
                        case .closed:
                            contentSection(for: viewModel.recentlyClosedRestaurants,
                                           emptyMessage: "No restaurants were recently closed by the DOHMH.",
                                           header: "Recently Closed by DOHMH",
                                           icon: "exclamationmark.triangle.fill", color: .red,
                                           tab: .closed) // <-- Pass tab
                        case .reopened:
                            contentSection(for: viewModel.recentlyReopenedRestaurants,
                                           emptyMessage: "No recently closed restaurants have re-opened.",
                                           header: "Recently Re-opened",
                                           icon: "checkmark.circle.fill", color: .green,
                                           tab: .reopened) // <-- Pass tab
                        }
        }
    }
    
    @ViewBuilder
        private func contentSection(for restaurants: [Restaurant], emptyMessage: String, header: String? = nil, icon: String? = nil, color: Color? = nil, tab: SelectedTab) -> some View {
            Section(header: header != nil ? Text(header!) : nil) {
                if restaurants.isEmpty {
                    Text(emptyMessage)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(restaurants) { restaurant in
                        NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                            // Pass the tab parameter down to the row view
                            restaurantRowView(restaurant: restaurant, icon: icon, color: color, tab: tab)
                        }
                    }
                }
            }
        }
    
    private func restaurantRowView(restaurant: Restaurant, icon: String? = nil, color: Color? = nil, tab: SelectedTab) -> some View {
            HStack {
                if let iconName = icon, let iconColor = color {
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                        .font(.headline)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.dba ?? "Unknown")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(restaurant.formattedStreet), \(restaurant.formattedBoro)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // --- THIS IS THE NEW LOGIC ---
                    // It displays the correct text based on the selected tab
                    switch tab {
                    case .graded:
                        if restaurant.update_type == "finalized" {
                            Text("Updated from Grade Pending")
                                .font(.caption)
                                .italic()
                                .foregroundColor(.secondary)
                        }
                        Text(restaurant.relativeGradeDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case .closed, .reopened:
                        Text(restaurant.relativeActionDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(restaurant.displayGradeImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .padding(.vertical, 6)
        }
}
