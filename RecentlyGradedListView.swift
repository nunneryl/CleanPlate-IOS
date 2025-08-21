// In file: RecentlyGradedListView.swift

import SwiftUI

struct RecentlyGradedListView: View {
    @StateObject private var viewModel = RecentlyGradedListViewModel()
    
    private enum SelectedTab: String, CaseIterable {
        case graded = "Graded"
        case closed = "Closed"
        case reopened = "Re-opened"
    }
    @State private var selectedTab: SelectedTab = .graded
    
    var body: some View {
        // The main VStack now correctly holds only the Picker and the Form
        VStack(spacing: 0) {
            // The Picker sits outside the Form to act as a top-level control
            Picker("Select a list", selection: $selectedTab) {
                ForEach(SelectedTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            // The main content area switches based on the view model's state
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
        .background(Color(.systemGroupedBackground)) // Use a grouped background color
        .navigationTitle("Grade & Status Changes")
        .task {
            await viewModel.loadContent()
        }
    }
    
    private var successView: some View {
        // --- THE FIX ---
        // The root of the content is now a Form, which is what the compiler expects
        // for this combination of Pickers and Sections.
        Form {
            // The filters appear conditionally as the first section
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
            
            // The content sections are displayed based on the selected tab
            switch selectedTab {
            case .graded:
                contentSection(for: viewModel.filteredRecentlyGraded,
                               emptyMessage: "No recently graded restaurants match your filters.")
            case .closed:
                contentSection(for: viewModel.recentlyClosedRestaurants,
                               emptyMessage: "No restaurants were recently closed by the DOHMH.",
                               header: "Recently Closed by DOHMH",
                               icon: "exclamationmark.triangle.fill", color: .red)
            case .reopened:
                contentSection(for: viewModel.recentlyReopenedRestaurants,
                               emptyMessage: "No recently closed restaurants have re-opened.",
                               header: "Recently Re-opened",
                               icon: "checkmark.circle.fill", color: .green)
            }
        }
    }
    
    // Helper view for the content of each list
    @ViewBuilder
    private func contentSection(for restaurants: [Restaurant], emptyMessage: String, header: String? = nil, icon: String? = nil, color: Color? = nil) -> some View {
        // We now use a custom header if provided, otherwise the section is anonymous
        Section(header: header != nil ? Text(header!) : nil) {
            if restaurants.isEmpty {
                Text(emptyMessage)
                    .foregroundColor(.secondary)
            } else {
                ForEach(restaurants) { restaurant in
                    NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                        restaurantRowView(restaurant: restaurant, icon: icon, color: color)
                    }
                }
            }
        }
    }
    
    // This reusable view for rows remains the same
    private func restaurantRowView(restaurant: Restaurant, icon: String? = nil, color: Color? = nil) -> some View {
        HStack {
            if let iconName = icon, let iconColor = color {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.dba ?? "Unknown")
                    .fontWeight(.semibold)
                Text("\(restaurant.formattedStreet), \(restaurant.formattedBoro)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
