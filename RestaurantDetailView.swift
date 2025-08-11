// In file: RestaurantDetailView.swift

import SwiftUI
import os
import FirebaseAnalytics

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
                    restaurant: restaurant,
                    isLoading: (viewModel.state.isPartial), // Pass loading state
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
        }
    }
}

// Extension to easily check the state
extension RestaurantDetailViewModel.DetailState {
    var isPartial: Bool {
        if case .partial = self { return true }
        return false
    }
}

// MARK: - Main Content View
struct RestaurantContentView: View {
    let restaurant: Restaurant
    let isLoading: Bool // Receives loading state
    let submitReportAction: (ReportIssueView.IssueType, String) -> Void

    @State private var isShowingShareSheet = false
    @State private var isMapVisible = false
    @State private var isShowingReportSheet = false
    
    // All display logic is now here, pulled from the old ViewModel
    private var name: String { restaurant.dba ?? "Restaurant Name" }
    private var formattedAddress: String { Self.formatAddress(for: restaurant) }
    private var cuisine: String? { restaurant.cuisine_description == "N/A" ? nil : restaurant.cuisine_description }
    private var headerStatus: (imageName: String, text: String) {
        let status = Self.calculateCurrentDisplayStatus(for: restaurant)
        return (imageName: Self.gradeImageName(for: status), text: status)
    }
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
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.isShowingShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(items: [Self.buildShareableText(name: name, status: headerStatus.text)])
        }
        .sheet(isPresented: $isShowingReportSheet) {
            ReportIssueView { issueType, comments in
                submitReportAction(issueType, comments)
            }
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

    // All helper functions for display are now private to the View
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(formattedAddress)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                if let cuisine = cuisine {
                    Text(cuisine)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(headerStatus.imageName)
                .resizable().scaledToFit().frame(width: 72, height: 72)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var mapSection: some View {
        // This view logic doesn't need to change
        if let lat = restaurant.latitude, let lon = restaurant.longitude {
            VStack(spacing: 12) {
                Button(action: { withAnimation(.easeInOut) { isMapVisible.toggle() } }) {
                    HStack {
                        Text(isMapVisible ? "Hide Map" : "Show Map")
                        Image(systemName: isMapVisible ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .buttonStyle(.bordered).tint(.blue)
                
                if isMapVisible {
                    VStack(spacing: 0) {
                        StaticMapView(latitude: lat, longitude: lon, restaurantName: name)
                        if restaurant.google_place_id != nil {
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
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
            }
        }
    }
    
    // In file: RestaurantDetailView.swift (inside the RestaurantContentView struct)

    private var inspectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Inspections")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                if isLoading {
                    ProgressView()
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal)

            // The ForEach now iterates over the 'inspections' computed property
            if !inspections.isEmpty {
                ForEach(inspections) { inspection in
                    NavigationLink(destination: InspectionDetailView(inspection: inspection)) {
                         inspectionRow(for: inspection)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    // <<< NEW: This makes each new row fade in smoothly >>>
                    .transition(.opacity)
                }
            } else {
                 Text("No inspection history found.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        // <<< NEW: This animates the change in the list's size >>>
        .animation(.easeInOut, value: inspections.count)
    }
    
    private func inspectionRow(for inspection: Inspection) -> some View {
        // This view logic doesn't need to change
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
    
    // All these static helper functions are now self-contained in the View
    private static func formatAddress(for restaurant: Restaurant) -> String {
        [restaurant.building, restaurant.street, restaurant.boro, restaurant.zipcode].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
    
    private static func calculateCurrentDisplayStatus(for restaurant: Restaurant) -> String {
        let sortedInspections = restaurant.inspections?.sorted(by: {
            guard let date1 = DateHelper.parseDate($0.inspection_date), let date2 = DateHelper.parseDate($1.inspection_date) else { return false }
            return date1 > date2
        }) ?? []
        guard let latestInspection = sortedInspections.first else { return "Not_Graded" }
        if let action = latestInspection.action?.lowercased(), action.contains("closed by dohmh") { return "Closed" }
        if let grade = latestInspection.grade {
            switch grade {
            case "A", "B", "C": return grade
            case "Z", "P": return "Grade_Pending"
            case "N": return "Not_Graded"
            default: return "Grade_Pending"
            }
        } else { return "Grade_Pending" }
    }

    private static func gradeImageName(for status: String) -> String {
        switch status {
        case "A": return "Grade_A"
        case "B": return "Grade_B"
        case "C": return "Grade_C"
        case "Grade_Pending": return "Grade_Pending"
        case "Closed": return "closed_down"
        default: return "Not_Graded"
        }
    }
    
    private static func buildShareableText(name: String, status: String) -> String {
        let appStoreLink = "Download CleanPlate to search for any restaurant in NYC: https://apps.apple.com/us/app/cleanplate-nyc/id6745222863"
        let statusText: String
        switch status {
        case "A", "B", "C": statusText = "a New York City Department of Health Restaurant Inspection Grade \(status)"
        case "Grade_Pending": statusText = "a Grade Pending status"
        case "Closed": statusText = "a Closed by DOHMH status"
        default: statusText = "a 'Not Graded' status"
        }
        return "Here's the latest NYC health grade for \(name) via the CleanPlate app:\n\nIt currently has \(statusText).\n\nNew to CleanPlate? \(appStoreLink)"
    }
    
    private func handleGoogleLink() {
        guard let placeID = restaurant.google_place_id, let placeName = restaurant.dba else { return }
        Analytics.logEvent("tap_external_link", parameters: ["platform": "google", "restaurant_id": restaurant.camis ?? "unknown"])
        GoogleMapsDeepLinker.openGoogleMaps(for: placeID, placeName: placeName)
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
