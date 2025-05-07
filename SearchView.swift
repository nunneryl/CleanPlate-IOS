import SwiftUI
import os
import FirebaseAnalytics // <-- ADDED IMPORT

// MARK: - Animated Button Style
struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.white) // Explicit color for button text
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue) // Explicit color for button background
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2) // Explicit shadow color
    }
}

struct SearchView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "SearchView")

    // Using EnvironmentObject to get view model from parent
    @EnvironmentObject var viewModel: SearchViewModel
    @FocusState private var isSearchFieldFocused: Bool

    // Add environment variable for size class
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // <-- Added

    init() {
        // Optional: Customize list appearance if needed
        // UITableView.appearance().backgroundColor = .clear
        // UITableViewCell.appearance().backgroundColor = .clear
    }

    var body: some View {
        // Root NavigationView for this tab's content
        NavigationView { // <-- Modifier will be added to this NavigationView
            ZStack {
                // Background
                Color(UIColor.systemBackground) // <-- Good: Adaptive background
                    .ignoresSafeArea()

                // Main Content
                VStack(spacing: 20) {
                    // Header and search bar section
                    VStack(spacing: 20) {
                        headerSection // Uses horizontalSizeClass now
                        searchBar
                    }
                    // Adjust top padding to provide space from the top edge
                    .padding(.top, 20) // Reduced top padding

                    // Conditional content based on search state
                    if viewModel.searchTerm.isEmpty && viewModel.restaurants.isEmpty && !viewModel.isLoading && !viewModel.hasPerformedSearch {
                        // Initial disclaimer view (centered)
                        Spacer()
                        disclaimerText // Extracted disclaimer text view
                        Spacer()

                    } else if viewModel.errorMessage != nil {
                        // Error view (centered)
                        Spacer()
                        errorView
                        Spacer()
                    } else if viewModel.isLoading {
                         // Loading view replaces list
                        SkeletonLoadingView()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
                    } else if !viewModel.restaurants.isEmpty {
                        // Search results list
                        mainSearchResults
                            .refreshable {
                                await viewModel.performSearch()
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: !viewModel.restaurants.isEmpty)
                    } else if !viewModel.searchTerm.isEmpty && viewModel.restaurants.isEmpty && !viewModel.isLoading && viewModel.hasPerformedSearch {
                        // Empty search results view (centered)
                        Spacer()
                        emptySearchResultsView
                        Spacer()
                    } else {
                        // Fallback empty space if needed
                        Spacer()
                    }
                }
                 // Removed bottom padding to allow skyline footer positioning
                // .padding(.bottom, 50)

                // Footer image (skyline) - positioned as a background element above tab bar
                VStack {
                    Spacer() // Pushes image to the bottom
                    Image("nyc_footer") // <-- IMPORTANT: Ensure this has Dark Mode variant in Assets.xcassets
                        .resizable()
                        .scaledToFit()
                        .opacity(0.08) // Adjust opacity as needed
                        .frame(maxWidth: .infinity)
                        // Let the system handle bottom safe area for the tab bar
                        // .padding(.bottom, 49) // Removed fixed padding
                }

            } // End of ZStack
            // Modifiers for the content WITHIN the NavigationView
            .navigationTitle("") // Keep title area blank if desired
            .navigationBarHidden(true) // Keep the navigation bar hidden
            .onAppear { // <-- This applies to the ZStack's content lifecycle
                logger.info("SearchView content appeared.") // Keep your existing log
                setupNotificationObservers()
            }
            .onDisappear {
                removeNotificationObservers()
            }
        } // End of NavigationView
        .navigationViewStyle(.stack) // <--- MODIFIER ADDED HERE TO FORCE STACK STYLE
        // .preferredColorScheme(.light) // <--- REMOVED THIS LINE TO ENABLE DARK MODE SUPPORT
        .onAppear { // <-- ***** ADDED FIREBASE .onAppear MODIFIER HERE *****
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "Search",
                                          AnalyticsParameterScreenClass: "\(SearchView.self)"])
            print("Analytics: Logged screen_view event for Search")
        } // <-- ***** END FIREBASE MODIFIER *****
    }

    // MARK: - Subviews

    private var disclaimerText: some View {
        Text("CleanPlate provides NYC restaurant inspection data for informational purposes.\n\nHealth ratings are just one factor to consider when choosing where to eat.")
            .font(.system(size: horizontalSizeClass == .compact ? 12 : 14))
            .italic()
            .foregroundColor(.secondary) // <-- Good: Adaptive color
            .multilineTextAlignment(.center)
            .padding(.horizontal, horizontalSizeClass == .compact ? 20 : 30)
    }

    private var emptySearchResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass") // SF Symbol adapts
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.6)) // Gray adapts reasonably
                .padding(.bottom, 10)

            Text("No restaurants found")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary) // <-- Good: Adaptive color

            VStack(alignment: .leading, spacing: 16) {
                Text("Try these search tips:")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary) // <-- Good: Adaptive color

                // Tip 1
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill") // SF Symbol adapts
                        .foregroundColor(.blue) // Explicit color acceptable
                        .font(.system(size: 14))
                        .frame(width: 20, height: 20)
                    Text("Check the spelling of the restaurant name")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary) // <-- Good: Adaptive color
                        .fixedSize(horizontal: false, vertical: true)
                }
                // Tip 2
                HStack(alignment: .top, spacing: 10) {
                     Image(systemName: "checkmark.circle.fill") // SF Symbol adapts
                        .foregroundColor(.blue) // Explicit color acceptable
                        .font(.system(size: 14))
                        .frame(width: 20, height: 20)
                    Text("Try a shorter version of the name (e.g., 'Joe' instead of 'Joe's Pizza')")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary) // <-- Good: Adaptive color
                        .fixedSize(horizontal: false, vertical: true)
                }
                 // Tip 3
                HStack(alignment: .top, spacing: 10) {
                     Image(systemName: "checkmark.circle.fill") // SF Symbol adapts
                        .foregroundColor(.blue) // Explicit color acceptable
                        .font(.system(size: 14))
                        .frame(width: 20, height: 20)
                    Text("Some restaurants might not be in the database if they're new or recently changed names")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary) // <-- Good: Adaptive color
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            // Clear Search Button
            Button {
                viewModel.resetSearch()
            } label: {
                Text("Clear Search")
            }
            .buttonStyle(PrimaryButtonStyle()) // Uses explicit button style
            .padding(.top, 16)

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 30)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground)) // <-- Good: Adaptive background
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: viewModel.searchTerm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No restaurants found for your search. Try checking spelling, using a shorter name, or clearing your search.")
    }

    private var headerSection: some View {
        // Use conditional spacing based on size class
        VStack(spacing: horizontalSizeClass == .compact ? 4 : 6) {
            Image(systemName: "fork.knife.circle.fill") // SF Symbol adapts
                .resizable()
                .scaledToFit()
                // Use conditional frame size
                .frame(width: horizontalSizeClass == .compact ? 50 : 60, height: horizontalSizeClass == .compact ? 50 : 60)
                .foregroundColor(.blue) // Explicit color acceptable
                .shadow(radius: 2)
                .accessibilityLabel("CleanPlate app logo")
                .onTapGesture {
                    viewModel.resetSearch()
                    // Dismiss keyboard if it's showing
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

            Text("CleanPlate")
                // Use conditional font size
                .font(.system(size: horizontalSizeClass == .compact ? 26 : 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary) // <-- Good: Adaptive color

            Text("Your Guide to Safe & Smart Dining")
                 // Use conditional font size
                .font(.system(size: horizontalSizeClass == .compact ? 14 : 16, weight: .regular, design: .rounded))
                .foregroundColor(.secondary) // <-- Good: Adaptive color
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var searchBar: some View {
        HStack {
            TextField("Search for a restaurant", text: $viewModel.searchTerm)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.primary) // <-- Good: Adaptive color
                .padding(10)
                .background(Color(.systemGray5)) // <-- Good: Adaptive background
                .cornerRadius(8)
                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 1) // Softer shadow
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
                .onSubmit {
                    submitSearch()
                }
                .accessibilityLabel("Search for restaurants")

            Button {
                submitSearch()
            } label: {
                Image(systemName: "magnifyingglass") // SF Symbol adapts
                    .font(.title3) // Slightly smaller icon
                    .padding(10)
                    .foregroundColor(.white) // Explicit color for button
                    .background(Color.blue) // Explicit color for button
                    .cornerRadius(8)
                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 1) // Softer shadow
            }
            .buttonStyle(AnimatedButtonStyle()) // Keep animated style
            .accessibilityLabel("Search")
        }
        .padding(.horizontal) // Add horizontal padding to the HStack
    }

    private var errorView: some View {
        VStack(spacing: 12) {
             Image(systemName: "exclamationmark.triangle.fill") // SF Symbol adapts
                .font(.largeTitle)
                .foregroundColor(.red) // Explicit color acceptable for error

            Text(viewModel.errorMessage ?? "An error occurred")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.red) // Explicit color acceptable for error
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await viewModel.performSearch()
                }
            } label: {
                Text("Try Again")
            }
             .buttonStyle(PrimaryButtonStyle()) // Uses explicit button style
             .accessibilityLabel("Try search again")
        }
        .padding()
        .background(Color(.systemGray6)) // <-- Good: Adaptive background
        .cornerRadius(10)
        .shadow(radius: 2)
    }

    private var mainSearchResults: some View {
        List(viewModel.restaurants) { restaurant in
            NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                VStack(alignment: .leading, spacing: 4) { // Adjust spacing
                    Text(restaurant.dba ?? "Unknown Restaurant")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary) // <-- Good: Adaptive color
                        .lineLimit(1)

                    Text("\(formatStreet(restaurant.street ?? "")), \(formatBorough(restaurant.boro ?? "")), \(restaurant.zipcode ?? "")")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary) // <-- Good: Adaptive color
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(.vertical, 4) // Add some vertical padding inside the row
            }
            // Remove explicit white background for default list appearance
            // .listRowBackground(Color.white) // Let system handle list row background
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(restaurant.dba ?? "Unknown Restaurant"), \(formatStreet(restaurant.street ?? "")), \(formatBorough(restaurant.boro ?? ""))")
            .accessibilityHint("Tap to view details and inspection history")
        }
        .listStyle(PlainListStyle()) // Use PlainListStyle
        // Remove background color to use the ZStack's background
        // .background(Color.clear) // Let system handle list background
    }

    // MARK: - Helper Methods

    private func submitSearch() {
        // Dismiss keyboard
        isSearchFieldFocused = false
        // Perform search
        Task {
            await viewModel.performSearch()
            // Log search event after performing the search
            Analytics.logEvent("search_initiated", parameters: [
                "search_term": (viewModel.searchTerm.isEmpty ? "N/A" : viewModel.searchTerm) as NSObject
            ])
            print("Analytics: Logged search_initiated for term: \(viewModel.searchTerm)")
        }
    }

    private func formatStreet(_ street: String) -> String {
        // Simple replacements for common abbreviations
        var formatted = street
        if formatted.lowercased().contains("avenue") {
             formatted = formatted.replacingOccurrences(of: "AVENUE", with: "Ave", options: .caseInsensitive)
        }
        if formatted.lowercased().contains("street") {
             formatted = formatted.replacingOccurrences(of: "STREET", with: "St", options: .caseInsensitive)
        }
         if formatted.lowercased().contains("place") {
             formatted = formatted.replacingOccurrences(of: "PLACE", with: "Pl", options: .caseInsensitive)
        }
         if formatted.lowercased().contains("road") {
             formatted = formatted.replacingOccurrences(of: "ROAD", with: "Rd", options: .caseInsensitive)
        }
         if formatted.lowercased().contains("boulevard") {
             formatted = formatted.replacingOccurrences(of: "BOULEVARD", with: "Blvd", options: .caseInsensitive)
        }
        // Add more replacements as needed
        return formatted
    }


    private func formatBorough(_ boro: String) -> String {
        // Use titlecased borough names
        switch boro.uppercased() {
            case "MANHATTAN": return "Manhattan"
            case "BROOKLYN": return "Brooklyn"
            case "QUEENS": return "Queens"
            case "BRONX": return "Bronx"
            case "STATEN ISLAND": return "Staten Island"
            default: return boro // Return original if not recognized
        }
    }

    private func setupNotificationObservers() {
         // Set up notification observer for home tab tapped
         NotificationCenter.default.addObserver(
             forName: .homeTabTapped,
             object: nil,
             queue: .main) { _ in
                 Task { @MainActor in
                     viewModel.resetSearch()
                     // Dismiss keyboard if it's showing
                     UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                 }
             }

         // Set up notification observer for resetting search
         NotificationCenter.default.addObserver(
             forName: .resetSearch,
             object: nil,
             queue: .main) { _ in
                 Task { @MainActor in
                     viewModel.resetSearch()
                 }
             }
    }

    private func removeNotificationObservers() {
         // Remove observers when view disappears
         NotificationCenter.default.removeObserver(
             self,
             name: .homeTabTapped,
             object: nil
         )
         NotificationCenter.default.removeObserver(
             self,
             name: .resetSearch,
             object: nil
         )
    }

} // End of SearchView struct

// MARK: - Skeleton Loading View
struct SkeletonLoadingView: View {
    // No changes needed here, use your existing code
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading search results")
    }
}

struct SkeletonRow: View {
    // No changes needed here, use your existing code
     @State private var isAnimating = false // Keep animation state local

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                SkeletonRectangle(width: 200, height: 20)
                SkeletonRectangle(width: 250, height: 16)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6)) // <-- Good: Adaptive background
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1) // Softer shadow
    }
}

struct SkeletonRectangle: View {
    // No changes needed here, use your existing code
    let width: CGFloat
    let height: CGFloat
    @State private var isAnimating = false // Keep animation state local

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    // Adjusted gradient colors for subtlety
                    gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05), Color.gray.opacity(0.1)]), // Gray adapts reasonably
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .mask(
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: width, height: height)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            // Adjusted shimmer gradient
                            gradient: Gradient(colors: [.clear, Color.gray.opacity(0.1), .clear]), // Gray adapts reasonably
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? width * 1.5 : -width * 1.5) // Adjust offset for smoother animation
            )
            .onAppear {
                // Slightly slower animation
                withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}
