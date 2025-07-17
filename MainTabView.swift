// In file: MainTabView.swift

import SwiftUI

extension Notification.Name {
    static let resetSearch = Notification.Name("resetSearch")
    static let switchToFoodSafetyTab = Notification.Name("switchToFoodSafetyTab")
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var searchViewModel = SearchViewModel()
    
    private var tabSelection: Binding<Int> {
        Binding(
            get: {
                return selectedTab
            },
            set: { newTab in
                HapticsManager.shared.impact(style: .light)
                
                if newTab == selectedTab && newTab == 0 {
                    // If the home tab (0) is tapped while it's already selected...
                    searchViewModel.resetSearch()
                }
                // Always update the selected tab
                selectedTab = newTab
            }
        )
    }
    
    var body: some View {
        TabView(selection: tabSelection) {
            SearchView()
                .environmentObject(searchViewModel)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Home")
                }
                .tag(0)
            
            FoodSafetyFAQView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Food Safety")
                }
                .tag(1)
            
            AboutView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
                .tag(2)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToFoodSafetyTab)) { _ in
            self.selectedTab = 1
        }
    }
}
