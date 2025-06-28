// MARK: - FINAL VERSION (with Chevron) RestaurantDetailView.swift

import SwiftUI
import os
import FirebaseAnalytics

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "RestaurantDetailView")

    private var shareableText: String {
        let restaurantName = restaurant.dba ?? "this restaurant"
        let grade = currentDisplayGrade() ?? "Not Graded"
        let appStoreLink = "Download CleanPlate to search for any restaurant in NYC: https://apps.apple.com/us/app/cleanplate-nyc/id6745222863"
        
        let gradeText: String
        switch grade {
            case "A", "B", "C": gradeText = "a New York City Department of Health Restaurant Inspection Grade \(grade)"
            case "Grade_Pending": gradeText = "a Grade Pending status"
            default: gradeText = "a 'Not Graded' status"
        }
        
        return """
        Here's the latest NYC health grade for \(restaurantName) via the CleanPlate app:
        It currently has \(gradeText).
        New to CleanPlate? \(appStoreLink)
        """
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
                Button {
                    self.isShowingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
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
        HStack {
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
            if let displayGrade = currentDisplayGrade() {
                Image(gradeImageName(for: displayGrade))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
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
                    // --- THIS IS THE UPDATED PART ---
                    HStack {
                        Text(isMapVisible ? "Hide Map" : "Show Map")
                        // This image now dynamically changes based on the map's visibility
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
    
    // The rest of the file remains the same
    
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
           HStack {
               Text("Grade:").font(.system(size: 14))
               if let grade = inspection.grade, !grade.isEmpty, grade != "N/A" {
                   Text(grade == "Z" ? "Grade Pending" : grade == "P" ? "Grade Pending" : grade == "N" ? "Not Yet Graded" : "Grade \(grade)")
                       .font(.system(size: 14, weight: .bold)).foregroundColor(gradeColor(for: grade))
               } else {
                   Text("No Grade Assigned").font(.system(size: 14)).foregroundColor(.gray)
               }
           }
           Text("Critical Flag: \(inspection.critical_flag ?? "N/A")").font(.system(size: 14))
           if let violations = inspection.violations, !violations.isEmpty {
                DisclosureGroup("Violations (\(violations.count))") { ViolationsView(violations: violations).padding(.top, 8) }
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.blue)
           } else {
                Text("No violations listed for this inspection.").font(.system(size: 14)).foregroundColor(.secondary)
           }
       }
       .padding().frame(maxWidth: .infinity, alignment: .leading)
       .background(Color(UIColor.systemGray6)).cornerRadius(8)
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

    private func currentDisplayGrade() -> String? {
        if let latest = filteredInspections().first, let grade = latest.grade, ["Z", "P"].contains(grade) { return "Grade_Pending" }
        if let graded = filteredInspections().first(where: { ["A", "B", "C"].contains($0.grade ?? "") }) { return graded.grade }
        if filteredInspections().contains(where: { $0.grade == "N" }) { return "Not_Graded" }
        return filteredInspections().isEmpty ? "Not_Graded" : "Grade_Pending"
    }

    private func gradeImageName(for grade: String) -> String {
        switch grade {
            case "A": return "Grade_A"; case "B": return "Grade_B"; case "C": return "Grade_C"
            case "Grade_Pending": return "Grade_Pending"; default: return "Not_Graded"
        }
    }

    private func gradeColor(for grade: String) -> Color {
        switch grade { case "A": .blue; case "B": .green; case "C": .orange; default: .gray }
    }
}

// Helper views remain the same
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
