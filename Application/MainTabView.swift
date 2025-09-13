// In file: MainTabView.swift

import SwiftUI

extension Notification.Name {
    static let resetSearch = Notification.Name("resetSearch")
    static let switchToFoodSafetyTab = Notification.Name("switchToFoodSafetyTab")
    static let switchToSearchTab = Notification.Name("switchToSearchTab")
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
                    searchViewModel.resetSearch()
                }
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
            
            RecentlyGradedListView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Grade Updates")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(2)
            
            AboutView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
                .tag(3) //
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToFoodSafetyTab)) { _ in
            // Note: Food Safety is now tab 1
            self.selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToSearchTab)) { _ in
            self.selectedTab = 0
        }
    }
}
