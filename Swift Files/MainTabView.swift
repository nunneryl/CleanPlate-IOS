import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Home (Search)
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Home")
                }
            
            // About Page
            AboutView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
            
            // FAQ Page
            FAQView()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("FAQ")
                }
        }
    }
}


