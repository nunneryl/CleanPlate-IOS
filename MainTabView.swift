import SwiftUI

// Add this extension for notification names
extension Notification.Name {
    static let homeTabTapped = Notification.Name("homeTabTapped")
    static let resetSearch = Notification.Name("resetSearch")
    static let switchToFoodSafetyTab = Notification.Name("switchToFoodSafetyTab")
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var searchViewModel = SearchViewModel()
    
    // Keep track of previous tab for proper navigation
    @State private var previousTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home (Search)
            SearchView()
                .environmentObject(searchViewModel)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Home")
                }
                .tag(0)
            
            // Food Safety FAQ (in the middle)
            FoodSafetyFAQView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Food Safety")
                }
                .tag(1)
            
            // About Page (on the right)
            AboutView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
                .tag(2)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 0 {
                // Always clear the search when navigating to Home tab
                searchViewModel.resetSearch()
                
                // Force dismissal of any presented views by posting a notification
                NotificationCenter.default.post(name: .resetSearch, object: nil)
                
                // Dismiss keyboard if it's showing
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            // Update the previous tab
            previousTab = newValue
        }
        .onAppear {
            // Setup tab bar tap detection
            setupTabBarTapDetection()
            
            // Setup notification for switching to Food Safety tab
            NotificationCenter.default.addObserver(
                forName: .switchToFoodSafetyTab,
                object: nil,
                queue: .main) { notification in
                    // Store current tab before switching
                    previousTab = selectedTab
                    
                    // Switch to Food Safety tab (now index 1)
                    selectedTab = 1
                }
        }
    }
    
    private func setupTabBarTapDetection() {
        TabBarController.shared.setup()
    }
}

// Helper class to detect UITabBar taps
class TabBarController: NSObject, UITabBarControllerDelegate {
    static let shared = TabBarController()
    
    func setup() {
        // This is called after the tab bar appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let tabBarController = window.rootViewController?.children.first as? UITabBarController {
                tabBarController.delegate = self
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Check if we're selecting the already-selected home tab (index 0)
        if tabBarController.selectedIndex == 0 && viewController == tabBarController.viewControllers?[0] {
            NotificationCenter.default.post(name: .homeTabTapped, object: nil)
        }
    }
}
