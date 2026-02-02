// In file: RestaurantDetailView.swift

import SwiftUI
import os
import FirebaseAnalytics
import MapKit

struct RestaurantDetailView: View {
    @StateObject private var viewModel: RestaurantDetailViewModel
    
    init(restaurant: Restaurant) {
        _viewModel = StateObject(wrappedValue: RestaurantDetailViewModel(restaurant: restaurant))
    }

    var body: some View {
        VStack {
            switch viewModel.state {
            case .partial(let restaurant), .full(let restaurant):
                RestaurantContentView(
                    viewModel: viewModel,
                    restaurant: restaurant,
                    isLoading: (viewModel.state.isPartial),
                    submitReportAction: { issueType, comments in
                        viewModel.submitReport(for: restaurant, issueType: issueType, comments: comments)
                    }
                )
            case .error(let message):
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(message)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }
        }
        .navigationTitle("Restaurant Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadFullDetailsIfNeeded()
            await viewModel.fetchMapData()
        }
    }
}


// MARK: - Main Content View
struct RestaurantContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @ObservedObject var viewModel: RestaurantDetailViewModel
    
    let restaurant: Restaurant
    let isLoading: Bool
    let submitReportAction: (ReportIssueView.IssueType, String) -> Void
    
    @State private var isShowingShareSheet = false
    @State private var isMapVisible = false
    @State private var isShowingReportSheet = false
    @State private var isShowingSignInSheet = false
    @State private var showScoreInfo = false
    
    private var name: String { restaurant.dba ?? "Restaurant Name" }
    private var formattedAddress: String { restaurant.fullAddress() }
    private var cuisine: String? { restaurant.cuisine_description == "N/A" ? nil : restaurant.cuisine_description }
    private var inspections: [Inspection] {
        restaurant.inspections?.sorted {
            guard let date1 = DateHelper.parseDate($0.inspection_date), let date2 = DateHelper.parseDate($1.inspection_date) else { return false }
            return date1 > date2
        } ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                mapSection
                inspectionList
                reportIssueSection
                faqLink
            }
            .padding(.vertical)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { self.isShowingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Button(action: {
                    if case .signedIn = authManager.authState {
                        if authManager.isFavorite(restaurant) {
                            authManager.removeFavorite(restaurant)
                        } else {
                            authManager.addFavorite(restaurant)
                        }
                    } else {
                        isShowingSignInSheet = true
                    }
                }) {
                    Image(systemName: authManager.isFavorite(restaurant) ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(items: [Self.buildShareableText(for: restaurant)])
        }
        .sheet(isPresented: $isShowingReportSheet) {
            ReportIssueView { issueType, comments in
                submitReportAction(issueType, comments)
            }
        }
        .sheet(isPresented: $isShowingSignInSheet) {
            ProfileView()
        }
        
        .alert("Inspection Scores", isPresented: $showScoreInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\n\n0-13 = Grade A\n14-27 = Grade B\n28+ = Grade C")
        }

        .onAppear {
            Analytics.logEvent(AnalyticsEventViewItem, parameters: [
                AnalyticsParameterItemID: restaurant.camis ?? "unknown",
                AnalyticsParameterItemName: name,
                AnalyticsParameterItemCategory: restaurant.cuisine_description ?? "N/A",
                "restaurant_boro": restaurant.boro ?? "N/A"
            ])
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Group 1: Name + Address with Grade badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(formattedAddress)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(spacing: 4) {
                    Image(restaurant.displayGradeImageName)
                        .resizable().scaledToFit().frame(width: 72, height: 72)
                    if let gradeLabel = restaurant.gradeUpdatedLabel {
                        Text(gradeLabel)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            // Group 2: Cuisine, Rating, Hours (with breathing room)
            VStack(alignment: .leading, spacing: 6) {
                // Cuisine and price level
                if let cuisine = cuisine {
                    HStack(spacing: 4) {
                        Text(cuisine)
                        if let priceLevel = restaurant.displayPriceLevel {
                            Text("·")
                            Text(priceLevel)
                        }
                    }
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                }
                
                // Rating and reviews
                if let rating = restaurant.displayRating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        Text(rating)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        if let reviewCount = restaurant.displayReviewCount {
                            Text(reviewCount)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Open/Closed status with closing time
                if let isOpen = restaurant.isOpenNow {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isOpen ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        if isOpen {
                            if let closingTime = restaurant.closingTimeText {
                                Text("Open · Closes \(closingTime)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.green)
                            } else {
                                Text("Open")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text("Closed")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Group 3: Action buttons (horizontal row)
            HStack(spacing: 12) {
                // Website button
                if let website = restaurant.website,
                   let url = URL(string: website),
                   !website.isEmpty {
                    Button(action: {
                        Analytics.logEvent("tap_external_link", parameters: ["platform": "website", "restaurant_id": restaurant.camis ?? "unknown"])
                        UIApplication.shared.open(url)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.system(size: 14))
                            Text("Website")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Map button
                Button(action: { withAnimation(.easeInOut) { isMapVisible.toggle() } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "map")
                            .font(.system(size: 14))
                        Text("Map")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Image(systemName: isMapVisible ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }
    
    @ViewBuilder
    private var mapSection: some View {
        if isMapVisible {
            VStack(spacing: 0) {
                if viewModel.isLoadingMap {
                    ProgressView("Loading Map...")
                        .frame(height: 200)
                        .padding(.horizontal)
                } else if let coordinate = viewModel.displayCoordinate {
                    VStack(spacing: 0) {
                        MapSnapshotView(coordinate: coordinate)
                            .frame(height: 200)
                        
                        Button(action: { handleAppleMapsLink() }) {
                            HStack(spacing: 12) {
                                Image(systemName: "apple.logo").font(.title3)
                                Text("View on Apple Maps").font(.system(size: 15, weight: .semibold, design: .rounded))
                                Spacer()
                                Image(systemName: "arrow.up.forward.app.fill").foregroundColor(Color(uiColor: .tertiaryLabel))
                            }
                            .padding().background(Color(uiColor: .secondarySystemGroupedBackground))
                        }
                        .foregroundColor(.primary)
                        
                        Button(action: { handleGoogleLink() }) {
                            HStack(spacing: 12) {
                                Image("logo_google").resizable().aspectRatio(contentMode: .fit).frame(width: 24, height: 24)
                                Text("View on Google Maps").font(.system(size: 15, weight: .semibold, design: .rounded))
                                Spacer()
                                Image(systemName: "arrow.up.forward.app.fill").foregroundColor(Color(uiColor: .tertiaryLabel))
                            }
                            .padding().background(Color(uiColor: .secondarySystemGroupedBackground))
                        }
                        .foregroundColor(.primary)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                } else {
                    VStack {
                        Image(systemName: "mappin.slash.circle")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("Map Not Available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func handleAppleMapsLink() {
        Analytics.logEvent("tap_external_link", parameters: ["platform": "apple", "restaurant_id": restaurant.camis ?? "unknown"])
        if let mapItem = viewModel.getAppleMapItem() {
            mapItem.openInMaps()
        }
    }
    
    private func handleGoogleLink() {
        Analytics.logEvent("tap_external_link", parameters: ["platform": "google", "restaurant_id": restaurant.camis ?? "unknown"])
        GoogleMapsDeepLinker.openGoogleMaps(
            placeID: restaurant.google_place_id,
            placeName: restaurant.dba ?? "Restaurant",
            building: restaurant.building,
            street: restaurant.street,
            borough: restaurant.boro,
            zipcode: restaurant.zipcode,
            coordinate: viewModel.displayCoordinate
        )
    }
    
    private var inspectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Inspections")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                if isLoading {
                    ProgressView().padding(.leading, 4)
                }
            }
            .padding(.horizontal)
            
            if !inspections.isEmpty {
                ForEach(inspections) { inspection in
                    NavigationLink(destination: InspectionDetailView(inspection: inspection)) {
                        inspectionRow(for: inspection)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .transition(.opacity)
                }
            } else {
                Text("No inspection history found.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .animation(.easeInOut, value: inspections.count)
    }
    
    private func inspectionRow(for inspection: Inspection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(inspection.formattedDate)
                .font(.system(size: 16, weight: .semibold))
            
            if let action = inspection.action?.lowercased() {
                if action.contains("closed by dohmh") {
                    HStack(alignment: .top) {
                        Text("Status:").font(.system(size: 14, weight: .semibold))
                        Text(inspection.action ?? "")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.red)
                    }
                } else if action.contains("re-opened by dohmh") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("Status:").font(.system(size: 14, weight: .semibold))
                            Text(inspection.action ?? "")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.green)
                        }
                        if let grade = inspection.grade, !grade.isEmpty {
                            displayGrade(for: grade)
                        }
                    }
                } else {
                    displayGrade(for: inspection.grade)
                }
            } else {
                displayGrade(for: inspection.grade)
            }
            
            // Score display with info button
            if let scoreText = inspection.displayScore {
                HStack {
                    Text("Score:")
                        .font(.system(size: 14, weight: .semibold))
                    Text(scoreText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                    
                    Button(action: { showScoreInfo = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text("Critical Flag: \(inspection.critical_flag ?? "N/A")")
                .font(.system(size: 14))
            
            if let violations = inspection.violations, !violations.isEmpty {
                DisclosureGroup("Violations (\(violations.count))") { ViolationsView(violations: violations).padding(.top, 8) }
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.blue)
            } else {
                Text("No violations listed for this inspection.")
                    .font(.system(size: 14, weight: .regular)).foregroundColor(.secondary)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6)).cornerRadius(8)
    }
    
    private func displayGrade(for grade: String?) -> some View {
        HStack {
            Text("Grade:")
                .font(.system(size: 14))
            if let grade = grade, !grade.isEmpty, grade != "N/A" {
                Text(formattedGrade(grade))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(gradeColor(for: grade))
            } else {
                Text("No Grade Assigned")
                    .font(.system(size: 14, weight: .regular)).foregroundColor(.gray)
            }
        }
    }
    
    private var reportIssueSection: some View {
        VStack(alignment: .leading) {
            Divider().padding(.bottom, 8)
            Button(action: { self.isShowingReportSheet = true }) {
                HStack {
                    Image(systemName: "exclamationmark.bubble.fill")
                    Text("Report an Issue")
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(Color(.systemGray3))
                }
            }
            .foregroundColor(.primary)
            Text("See an issue with this restaurant's data, like a wrong address or a permanent closure? Let us know.")
                .font(.caption).foregroundColor(.secondary).padding(.top, 4)
        }
        .padding(.horizontal)
    }
    
    private var faqLink: some View {
        Link("NYC Health Dept Info", destination: URL(string: "https://a816-health.nyc.gov/ABCEatsRestaurants/#!/faq")!)
            .font(.system(size: 16, weight: .semibold)).foregroundColor(.blue).padding(.top, 10)
    }
    
    private static func formatAddress(for restaurant: Restaurant) -> String {
        return restaurant.fullAddress()
    }
    
    private static func buildShareableText(for restaurant: Restaurant) -> String {
        let appStoreLink = "Download CleanPlate to search for any restaurant in NYC: https://apps.apple.com/us/app/cleanplate-nyc/id6745222863"
        
        let grade = restaurant.displayGrade ?? "Not Graded"
        
        let statusText: String
        switch grade {
        case "A", "B", "C": statusText = "a New York City Department of Health Restaurant Inspection Grade \(grade)"
        case "Z", "P": statusText = "a Grade Pending status"
        default: statusText = "a 'Not Graded' status"
        }
        return "Here's the latest NYC health grade for \(restaurant.dba ?? "this restaurant") via the CleanPlate app:\n\nIt currently has \(statusText).\n\nNew to CleanPlate? \(appStoreLink)"
    }
    
    private func formattedGrade(_ gradeCode: String?) -> String {
        guard let grade = gradeCode, !grade.isEmpty else { return "Not Graded" }
        switch grade {
        case "A", "B", "C": return "Grade \(grade)"
        case "Z": return "Grade Pending"
        case "P": return "Grade Pending (Re-opening)"
        case "N": return "Not Yet Graded"
        default: return "N/A"
        }
    }
    
    private func gradeColor(for grade: String) -> Color {
        switch grade {
        case "A": return .blue
        case "B": return .green
        case "C": return .orange
        case "Z", "P", "N": return .gray
        default: return .gray
        }
    }
}
