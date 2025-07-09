// In RestaurantDetailView.swift

import SwiftUI
import os
import FirebaseAnalytics

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "RestaurantDetailView")

    private var shareableText: String {
        let restaurantName = restaurant.dba ?? "this restaurant"
        let status = currentDisplayStatus() ?? "Not Graded" // Uses the new status function
        let appStoreLink = "Download CleanPlate to search for any restaurant in NYC: https://apps.apple.com/us/app/cleanplate-nyc/id6745222863"
        
        let statusText: String
        switch status {
            case "A", "B", "C":
                statusText = "a New York City Department of Health Restaurant Inspection Grade \(status)"
            case "Grade_Pending":
                statusText = "a Grade Pending status"
            case "Closed":
                statusText = "a Closed by DOHMH status" // New share text for closed status
            default:
                statusText = "a 'Not Graded' status"
        }
        
        return """
        Here's the latest NYC health grade for \(restaurantName) via the CleanPlate app:
        
        It currently has \(statusText).
        
        New to CleanPlate? \(appStoreLink)
        """
    }
    
    private var addressURL: URL? {
        let address = formattedAddress()
        guard let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "http://maps.apple.com/?q=\(encodedAddress)")
    }
    
    @State private var isShowingShareSheet = false
    @State private var isMapVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                mapSection
                inspectionList
                faqLink
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationTitle("Restaurant Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { self.isShowingShareSheet = true } label: { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(items: [self.shareableText])
        }
        .onAppear {
            ReviewManager.shared.requestReviewIfAppropriate()
            logger.info("RestaurantDetailView appeared for \(restaurant.dba ?? "Unknown")")
            
            Analytics.logEvent(AnalyticsEventViewItem, parameters: [
                AnalyticsParameterItemID: restaurant.camis ?? "unknown",
                AnalyticsParameterItemName: restaurant.dba ?? "Unknown",
                AnalyticsParameterItemCategory: restaurant.cuisine_description ?? "N/A",
                "restaurant_boro": restaurant.boro ?? "N/A"
            ])
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(restaurant.dba ?? "Restaurant Name")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(formattedAddress())
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                if let cuisine = restaurant.cuisine_description, cuisine != "N/A" {
                    Text(cuisine)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            // This now uses our updated logic to get the correct image
            if let displayStatus = currentDisplayStatus() {
                        Image(gradeImageName(for: displayStatus))
                            .resizable().scaledToFit().frame(width: 72, height: 72)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var mapSection: some View {
        if let lat = restaurant.latitude, let lon = restaurant.longitude {
            VStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut) {
                        isMapVisible.toggle()
                    }
                }) {
                    HStack {
                        Text(isMapVisible ? "Hide Map" : "Show Map")
                        Image(systemName: isMapVisible ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                if isMapVisible {
                    StaticMapView(latitude: lat,
                                  longitude: lon,
                                  restaurantName: restaurant.dba ?? "Restaurant Location")
                        .padding(.horizontal)
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
            }
        }
    }
    
    private var inspectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inspections")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .padding(.horizontal)

            if !filteredInspections().isEmpty {
                ForEach(filteredInspections()) { inspection in
                    inspectionRow(inspection: inspection)
                        .padding(.horizontal)
                }
            } else {
                 Text("No inspection history found.").font(.system(size: 14)).foregroundColor(.secondary).padding()
            }
        }
    }
    
    private func inspectionRow(inspection: Inspection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(DateHelper.formatDate(inspection.inspection_date))
                .font(.system(size: 16, weight: .semibold))

            if let action = inspection.action?.lowercased() {
                
                if action.contains("closed by dohmh") {
                    HStack(alignment: .top) {
                        Text("Status:")
                            .font(.system(size: 14, weight: .semibold))
                        Text(inspection.action ?? "")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.red)
                    }
                } else if action.contains("re-opened by dohmh") {
                    VStack(alignment: .leading, spacing: 8) { // Use a VStack to show both status and grade
                        HStack(alignment: .top) {
                            Text("Status:")
                                .font(.system(size: 14, weight: .semibold))
                            Text(inspection.action ?? "")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.green)
                        }
                        // If a grade was assigned during re-opening, display it
                        if let grade = inspection.grade, !grade.isEmpty {
                            HStack {
                                Text("Grade Assigned:")
                                    .font(.system(size: 14))
                                Text(formattedGrade(grade))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(gradeColor(for: grade))
                            }
                        }
                    }
                } else {
                    // Fallback to the normal grade display for all other cases
                    displayGrade(for: inspection)
                }
                
            } else {
                // Fallback for inspections with no action text
                displayGrade(for: inspection)
            }
            // --- END MODIFIED LOGIC BLOCK ---

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

    private func displayGrade(for inspection: Inspection) -> some View {
        HStack {
            Text("Grade:")
                .font(.system(size: 14))
            if let grade = inspection.grade, !grade.isEmpty, grade != "N/A" {
                Text(formattedGrade(grade))
                    .font(.system(size: 14, weight: .bold)).foregroundColor(gradeColor(for: grade))
            } else {
                Text("No Grade Assigned")
                    .font(.system(size: 14, weight: .regular)).foregroundColor(.gray)
            }
        }
    }

    // And ensure you have this helper function as well
    private func formattedGrade(_ gradeCode: String?) -> String {
        guard let grade = gradeCode, !grade.isEmpty else {
            return "Not Graded"
        }
        switch grade {
            case "A", "B", "C": return "Grade \(grade)"
            case "Z": return "Grade Pending"
            case "P": return "Grade Pending (Re-opening)"
            case "N": return "Not Yet Graded"
            default: return "N/A"
        }
    }

    private var faqLink: some View {
        Link("NYC Health Dept Info", destination: URL(string: "https://a816-health.nyc.gov/ABCEatsRestaurants/#!/faq")!)
            .font(.system(size: 16, weight: .semibold)).foregroundColor(.blue).padding(.top, 10)
    }
    
    private func formattedAddress() -> String {
        [restaurant.building, restaurant.street, restaurant.boro, restaurant.zipcode]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private func filteredInspections() -> [Inspection] {
        (restaurant.inspections ?? []).sorted {
            guard let date1 = DateHelper.parseDate($0.inspection_date), let date2 = DateHelper.parseDate($1.inspection_date) else { return false }
            return date1 > date2
        }
    }

    // --- LOGIC UPDATES ARE HERE ---

    /// This function now determines the primary status of the restaurant (Closed, Graded, Pending, etc.)
    private func currentDisplayStatus() -> String? {
        guard let latestInspection = filteredInspections().first else {
            return "Not_Graded"
        }

        // 1. Check for a closure first. This is top priority.
        // It checks for both "Closed by DOHMH" and "re-closed by DOHMH"
        if let action = latestInspection.action?.lowercased(), action.contains("closed by dohmh") {
            return "Closed"
        }

        // 2. If not closed, proceed with the existing grade logic.
        if let grade = latestInspection.grade, ["Z", "P"].contains(grade) {
            return "Grade_Pending"
        }
        if let graded = filteredInspections().first(where: { ["A", "B", "C"].contains($0.grade ?? "") }) {
            return graded.grade
        }
        if filteredInspections().contains(where: { $0.grade == "N" }) {
            return "Not_Graded"
        }
        return "Grade_Pending"
    }

    /// This function now knows about the new "Closed" status and your 'closed_down' asset.
    private func gradeImageName(for status: String) -> String {
        switch status {
        case "A": return "Grade_A"
        case "B": return "Grade_B"
        case "C": return "Grade_C"
        case "Grade_Pending": return "Grade_Pending"
        case "Closed": return "closed_down" // <-- YOUR NEW ASSET
        default: return "Not_Graded"
        }
    }

    /// This function provides a color for the status.
    private func gradeColor(for status: String) -> Color {
        switch status {
        case "A": return .blue
        case "B": return .green
        case "C": return .orange
        case "Closed": return .red // <-- RED for closed status
        default: return .gray
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
