// In file: SearchView.swift

import SwiftUI
import os
import FirebaseAnalytics

// MARK: - Button Styles
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

// MARK: - Discovery Card View
struct DiscoveryCardView: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(restaurant.dba ?? "Restaurant")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(restaurant.formattedBoro)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            Spacer()
            HStack {
                Text(restaurant.relativeGradeDate)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                if let grade = restaurant.latestFinalGrade {
                    Image("Grade_\(grade)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
            }
        }
        .frame(width: 160, height: 100)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}


struct SearchView: View {
    @EnvironmentObject var viewModel: SearchViewModel
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var isShowingFilterSheet = false
    @State private var isRecentlyGradedExpanded = false

    private var isFilterActive: Bool {
        return viewModel.selectedBoro != .any ||
               viewModel.selectedGrade != .any ||
               viewModel.selectedCuisine != .any
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header and Search Bar are always visible
                VStack(spacing: 20) {
                    headerSection
                    searchBar
                }
                .padding(.top, 20)
                
                // The body now uses a switch on viewModel.state for cleaner logic
                switch viewModel.state {
                case .idle:
                    idleView
                    
                case .loading:
                    SkeletonLoadingView().transition(.opacity)
                
                // <<< THIS IS THE FIX: Combine .success and .loadingMore cases >>>
                case .success(let restaurants), .loadingMore(let restaurants):
                    if restaurants.isEmpty {
                        emptySearchResultsView
                    } else {
                        mainSearchResults(restaurants: restaurants)
                    }
                    
                case .error(let message):
                    errorView(message: message)
                }
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationTitle("").navigationBarHidden(true)
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
        .id(viewModel.navigationID)
        .onAppear {
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "Search", AnalyticsParameterScreenClass: "\(SearchView.self)"])
            Task {
                await viewModel.loadDiscoveryLists()
            }
        }
    }

    // MARK: - Subviews

    private var idleView: some View {
        VStack {
            if !viewModel.recentlyGradedRestaurants.isEmpty {
                discoveryListView
            }
            Spacer()
            disclaimerText
            Spacer()
        }
    }

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
                    .onSubmit { submitSearch() }

                if !viewModel.searchTerm.isEmpty {
                    Button {
                        HapticsManager.shared.impact(style: .light)
                        viewModel.resetSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(UIColor.systemGray2))
                    }
                    .padding(.trailing, 8)
                }
            }
            
            Button { submitSearch() } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }.buttonStyle(AnimatedButtonStyle())

            Button {
                HapticsManager.shared.impact(style: .light)
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
    
    private var discoveryListView: some View {
        VStack(spacing: 0) {
            Button(action: {
                HapticsManager.shared.impact(style: .light)
                withAnimation(.easeInOut(duration: 0.2)) { isRecentlyGradedExpanded.toggle() }
            }) {
                HStack {
                    Text("Recently Graded").font(.system(size: 20, weight: .bold, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold)).rotationEffect(.degrees(isRecentlyGradedExpanded ? 90 : 0))
                }
                .foregroundColor(.primary).padding(.horizontal).padding(.vertical, 8)
            }
            if isRecentlyGradedExpanded {
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        NavigationLink(destination: RecentlyGradedListView()) {
                            HStack(spacing: 4) {
                                Text("See All")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                    }.padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.recentlyGradedRestaurants) { restaurant in
                                NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                                    DiscoveryCardView(restaurant: restaurant)
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }.padding(.horizontal)
                    }.frame(height: 140)
                }
                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: -10)), removal: .opacity)).padding(.bottom, 8)
            }
        }
    }
    
    private func mainSearchResults(restaurants: [Restaurant]) -> some View {
        List {
            ForEach(restaurants) { restaurant in
                NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.dba ?? "Unknown Restaurant").font(.system(.headline, design: .rounded)).foregroundColor(.primary).lineLimit(1)
                        Text("\(restaurant.formattedStreet), \(restaurant.formattedBoro), \(restaurant.zipcode ?? "")").font(.system(.subheadline, design: .rounded)).foregroundColor(.secondary).lineLimit(2).minimumScaleFactor(0.8)
                    }.padding(.vertical, 4)
                }
                .onAppear {
                    if restaurant == restaurants.last {
                        Task { await viewModel.loadMoreContent() }
                    }
                }
            }
            
            if viewModel.isLoadingMore {
                 ProgressView()
                     .frame(maxWidth: .infinity, alignment: .center)
                     .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            HapticsManager.shared.impact(style: .medium)
            await viewModel.performSearch()
        }
    }
    
    private var disclaimerText: some View {
        VStack {
            Spacer()
            Text("CleanPlate provides NYC restaurant inspection data for informational purposes.\n\nHealth ratings are just one factor to consider when choosing where to eat.")
                .font(.system(size: horizontalSizeClass == .compact ? 14 : 16))
                .italic().foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal, horizontalSizeClass == .compact ? 30 : 40)
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
            Button {
                HapticsManager.shared.impact(style: .medium)
                viewModel.resetSearch()
            } label: { Text("Clear Search") }.buttonStyle(PrimaryButtonStyle()).padding(.top, 16)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 30).multilineTextAlignment(.leading)
    }

    private func errorView(message: String) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                 Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundColor(.red)
                Text(message).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(.red).multilineTextAlignment(.center).padding(.horizontal)
                Button {
                    HapticsManager.shared.impact(style: .medium)
                    Task { await viewModel.performSearch() }
                } label: { Text("Try Again") }.buttonStyle(PrimaryButtonStyle())
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
}

// Skeleton Views
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
