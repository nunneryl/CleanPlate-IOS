import SwiftUI
import os
import FirebaseAnalytics

// MARK: - Button Styles (Unchanged)
struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct SearchView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "SearchView")

    @EnvironmentObject var viewModel: SearchViewModel
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var isShowingFilterSheet = false

    // UPDATED to check the new CuisineOption enum
    private var isFilterActive: Bool {
        return viewModel.selectedBoro != .any ||
               viewModel.selectedGrade != .any ||
               viewModel.selectedCuisine != .any
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(spacing: 20) {
                        headerSection
                        searchBar
                    }
                    .padding(.top, 20)

                    if viewModel.isLoading && viewModel.restaurants.isEmpty {
                        SkeletonLoadingView().transition(.opacity)
                    } else if !viewModel.restaurants.isEmpty {
                        mainSearchResults
                    } else if viewModel.hasPerformedSearch && viewModel.restaurants.isEmpty && !viewModel.isLoading {
                        Spacer()
                        emptySearchResultsView
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.restaurants.isEmpty {
                        Spacer()
                        errorView(message: errorMessage)
                        Spacer()
                    } else {
                        Spacer()
                        disclaimerText
                        Spacer()
                    }
                }
                
                VStack {
                    Spacer()
                    Image("nyc_footer")
                        .resizable().scaledToFit().opacity(0.08).frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("").navigationBarHidden(true)
            .onAppear {
                logger.info("SearchView content appeared.")
                setupNotificationObservers()
            }
            .onDisappear(perform: removeNotificationObservers)
            // UPDATED to pass the new binding and remove the options array
            .sheet(isPresented: $isShowingFilterSheet) {
                FilterSortView(
                    sortSelection: $viewModel.selectedSort,
                    boroSelection: $viewModel.selectedBoro,
                    gradeSelection: $viewModel.selectedGrade,
                    cuisineSelection: $viewModel.selectedCuisine
                )
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "Search", AnalyticsParameterScreenClass: "\(SearchView.self)"])
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: horizontalSizeClass == .compact ? 4 : 6) {
            Image(systemName: "fork.knife.circle.fill").resizable().scaledToFit().frame(width: horizontalSizeClass == .compact ? 50 : 60, height: horizontalSizeClass == .compact ? 50 : 60).foregroundColor(.blue).shadow(radius: 2).onTapGesture {
                viewModel.resetSearch()
                isSearchFieldFocused = false
            }
            Text("CleanPlate").font(.system(size: horizontalSizeClass == .compact ? 26 : 32, weight: .bold, design: .rounded)).foregroundColor(.primary)
            Text("Your Guide to Safe & Smart Dining").font(.system(size: horizontalSizeClass == .compact ? 14 : 16, weight: .regular, design: .rounded)).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal, 20)
        }
    }

    private var searchBar: some View {
        HStack {
            ZStack(alignment: .trailing) {
                TextField("Search for a restaurant", text: $viewModel.searchTerm)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(10)
                    .padding(.trailing, 25)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 1)
                    .focused($isSearchFieldFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        submitSearch()
                    }

                if !viewModel.searchTerm.isEmpty {
                    Button {
                        viewModel.resetSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(UIColor.systemGray2))
                    }
                    .padding(.trailing, 8)
                }
            }
            
            Button {
                submitSearch()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 1)
            }
            .buttonStyle(AnimatedButtonStyle())
            .accessibilityLabel("Search")

            Button {
                isSearchFieldFocused = false
                isShowingFilterSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(isFilterActive ? .white : .blue)
                    .frame(width: 44, height: 44)
                    .background(isFilterActive ? Color.blue : Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }

    private var mainSearchResults: some View {
        List {
            ForEach(viewModel.restaurants) { restaurant in
                NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.dba ?? "Unknown Restaurant").font(.system(.headline, design: .rounded)).foregroundColor(.primary).lineLimit(1)
                        Text("\(formatStreet(restaurant.street ?? "")), \(formatBorough(restaurant.boro ?? "")), \(restaurant.zipcode ?? "")").font(.system(.subheadline, design: .rounded)).foregroundColor(.secondary).lineLimit(2).minimumScaleFactor(0.8)
                    }.padding(.vertical, 4)
                }
                .onAppear {
                    if restaurant == viewModel.restaurants.last {
                        Task {
                            await viewModel.loadMoreContent()
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(restaurant.dba ?? "Unknown Restaurant"), \(formatStreet(restaurant.street ?? "")), \(formatBorough(restaurant.boro ?? ""))")
                .accessibilityHint("Tap to view details and inspection history")
            }
            
            if viewModel.isLoading && !viewModel.restaurants.isEmpty {
                 ProgressView()
                     .frame(maxWidth: .infinity, alignment: .center)
                     .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.performSearch()
        }
    }
    
    private var disclaimerText: some View {
        VStack {
            Spacer()
            Text("CleanPlate provides NYC restaurant inspection data for informational purposes.\n\nHealth ratings are just one factor to consider when choosing where to eat.")
                .font(.system(size: horizontalSizeClass == .compact ? 14 : 16))
                .italic()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, horizontalSizeClass == .compact ? 30 : 40)
            Spacer()
        }
    }

    private var emptySearchResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass").font(.system(size: 40)).foregroundColor(.gray.opacity(0.6)).padding(.bottom, 10)
            Text("No restaurants found").font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundColor(.primary)
            VStack(alignment: .leading, spacing: 16) {
                Text("Try these search tips:").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(.secondary)
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue).font(.system(size: 14)).frame(width: 20, height: 20)
                    Text("Check the spelling of the restaurant name").font(.system(size: 14, design: .rounded)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                HStack(alignment: .top, spacing: 10) {
                     Image(systemName: "checkmark.circle.fill").foregroundColor(.blue).font(.system(size: 14)).frame(width: 20, height: 20)
                    Text("Try a shorter version of the name (e.g., 'Joe' instead of 'Joe's Pizza')").font(.system(size: 14, design: .rounded)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                 HStack(alignment: .top, spacing: 10) {
                     Image(systemName: "checkmark.circle.fill").foregroundColor(.blue).font(.system(size: 14)).frame(width: 20, height: 20)
                    Text("Some restaurants might not be in the database if they're new or recently changed names").font(.system(size: 14, design: .rounded)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
            Button { viewModel.resetSearch() } label: { Text("Clear Search") }.buttonStyle(PrimaryButtonStyle()).padding(.top, 16)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 30)
        .multilineTextAlignment(.leading)
    }

    private func errorView(message: String) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                 Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundColor(.red)
                Text(message).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(.red).multilineTextAlignment(.center).padding(.horizontal)
                Button { Task { await viewModel.performSearch() } } label: { Text("Try Again") }.buttonStyle(PrimaryButtonStyle()).accessibilityLabel("Try search again")
            }.padding().background(Color(.systemGray6)).cornerRadius(10).shadow(radius: 2)
            Spacer()
        }
        .padding()
    }
    
    private func submitSearch() {
        isSearchFieldFocused = false
        HapticsManager.shared.impact(style: .medium)
        Task {
            await viewModel.performSearch()
        }
    }

    private func formatStreet(_ street: String) -> String {
        var formatted = street
        if formatted.lowercased().contains("avenue") { formatted = formatted.replacingOccurrences(of: "AVENUE", with: "Ave", options: .caseInsensitive) }
        if formatted.lowercased().contains("street") { formatted = formatted.replacingOccurrences(of: "STREET", with: "St", options: .caseInsensitive) }
        return formatted
    }

    private func formatBorough(_ boro: String) -> String {
        return boro.capitalized
    }

    private func setupNotificationObservers() {
          NotificationCenter.default.addObserver(forName: .homeTabTapped, object: nil, queue: .main) { _ in Task { @MainActor in viewModel.resetSearch(); isSearchFieldFocused = false } }
          NotificationCenter.default.addObserver(forName: .resetSearch, object: nil, queue: .main) { _ in Task { @MainActor in viewModel.resetSearch() } }
    }

    private func removeNotificationObservers() {
          NotificationCenter.default.removeObserver(self, name: .homeTabTapped, object: nil)
          NotificationCenter.default.removeObserver(self, name: .resetSearch, object: nil)
    }
}

// Skeleton Views are unchanged
struct SkeletonLoadingView: View {
    var body: some View { VStack(spacing: 12) { ForEach(0..<5, id: \.self) { _ in SkeletonRow() } }.padding(.horizontal).accessibilityElement(children: .ignore).accessibilityLabel("Loading search results") }
}

struct SkeletonRow: View {
    @State private var isAnimating = false
    var body: some View { HStack(alignment: .top, spacing: 8) { VStack(alignment: .leading, spacing: 6) { SkeletonRectangle(width: 200, height: 20); SkeletonRectangle(width: 250, height: 16) }; Spacer() }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(.systemGray6)).cornerRadius(8).shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1) }
}

struct SkeletonRectangle: View {
    let width: CGFloat
    let height: CGFloat
    @State private var isAnimating = false
    var body: some View {
        RoundedRectangle(cornerRadius: 4).fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05), Color.gray.opacity(0.1)]), startPoint: .leading, endPoint: .trailing)).frame(width: width, height: height).mask(RoundedRectangle(cornerRadius: 4).frame(width: width, height: height)).overlay(RoundedRectangle(cornerRadius: 4).fill(LinearGradient(gradient: Gradient(colors: [.clear, Color.gray.opacity(0.1), .clear]), startPoint: .leading, endPoint: .trailing)).offset(x: isAnimating ? width * 1.5 : -width * 1.5)).onAppear { withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) { isAnimating = true } }
    }
}
