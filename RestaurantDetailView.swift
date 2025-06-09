// MARK: - UPDATED AND COMPLETE FILE: RestaurantDetailView.swift

import SwiftUI
import os
import FirebaseAnalytics

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "RestaurantDetailView")

    /// Creates a user-friendly string to be shared.
    private var shareableText: String {
        let restaurantName = restaurant.dba ?? "this restaurant"
        let grade = currentDisplayGrade() ?? "Not Graded"
        let appStoreLink = "Download CleanPlate to search for any restaurant in NYC: https://apps.apple.com/us/app/cleanplate-nyc/id6745222863" // Remember to replace with your real link
        
        let gradeText: String
        switch grade {
            case "A", "B", "C":
                gradeText = "a New York City Department of Health Restaurant Inspection Grade \(grade)"
            case "Grade_Pending":
                gradeText = "a Grade Pending status"
            default:
                gradeText = "a 'Not Graded' status"
        }
        
        return """
        Here's the latest NYC health grade for \(restaurantName) via the CleanPlate app:
        
        It currently has \(gradeText).
        
        New to CleanPlate? \(appStoreLink)
        """
    }
    
    /// Creates a URL for Apple Maps from the restaurant's address.
    private var mapURL: URL? {
        let address = formattedAddress()
        guard let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "http://maps.apple.com/?q=\(encodedAddress)")
    }
    
    // State for showing the share sheet.
    @State private var isShowingShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
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
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(restaurant.dba ?? "Restaurant Name")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                if let url = mapURL {
                    Link(destination: url) {
                        Text(formattedAddress())
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.blue)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                            // ##### THIS IS THE FIX #####
                            // Explicitly set the alignment for multi-line text.
                            .multilineTextAlignment(.leading)
                    }
                } else {
                    Text(formattedAddress())
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                }

                if let cuisine = restaurant.cuisine_description, cuisine != "N/A" {
                    Text(cuisine)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
            }
            Spacer()

            if let displayGrade = currentDisplayGrade() {
                let imageName = gradeImageName(for: displayGrade)
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(gradeColor(for: displayGrade), lineWidth: 2)
                            .shadow(color: gradeColor(for: displayGrade).opacity(0.3), radius: 4, x: 0, y: 0)
                    )
            }
        }
        .padding()
    }
    
    // ----- HELPER VIEWS AND FUNCTIONS (RESTORED) -----
    
    private var inspectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inspections")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .padding(.horizontal)
                .padding(.bottom, 5)

            if !filteredInspections().isEmpty {
                ForEach(filteredInspections()) { inspection in
                    inspectionRow(inspection: inspection)
                        .padding(.horizontal)
                }
            } else {
                 Text("No inspection history found.")
                     .font(.system(size: 14, weight: .regular, design: .rounded))
                     .foregroundColor(.secondary)
                     .padding()
            }
        }
    }
    
    private func inspectionRow(inspection: Inspection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
           Text(DateHelper.formatDate(inspection.inspection_date))
               .font(.system(size: 16, weight: .semibold, design: .rounded))
               .foregroundColor(.primary)

           HStack {
               Text("Grade:")
                   .font(.system(size: 14, weight: .regular, design: .rounded))
               if let grade = inspection.grade, !grade.isEmpty, grade != "N/A" {
                   Text(grade == "Z" ? "Grade Pending" : grade == "P" ? "Grade Pending" : grade == "N" ? "Not Yet Graded" : "Grade \(grade)")
                       .font(.system(size: 14, weight: .bold, design: .rounded))
                       .foregroundColor(gradeColor(for: grade))
               } else {
                   Text("No Grade Assigned")
                       .font(.system(size: 14, weight: .regular, design: .rounded))
                       .foregroundColor(.gray)
               }
           }
           
           Text("Critical Flag: \(inspection.critical_flag ?? "N/A")")
               .font(.system(size: 14, weight: .regular, design: .rounded))

           if let violations = inspection.violations, !violations.isEmpty {
                DisclosureGroup("Violations (\(violations.count))") {
                    ViolationsView(violations: violations)
                        .padding(.top, 8)
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
           } else {
                Text("No violations listed for this inspection.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
           }
       }
       .padding()
       .frame(maxWidth: .infinity, alignment: .leading)
       .background(Color(UIColor.systemGray6))
       .cornerRadius(8)
    }

    private var faqLink: some View {
        Link("NYC Health Dept Info", destination: URL(string: "https://a816-health.nyc.gov/ABCEatsRestaurants/#!/faq")!)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.blue)
            .padding(.top, 20)
    }
    
    // MARK: - Helper Functions

    private func formattedAddress() -> String {
        let building = restaurant.building ?? ""
        let street = restaurant.street ?? ""
        let boro = restaurant.boro ?? ""
        let zipcode = restaurant.zipcode ?? ""
        
        return [building, street, boro, zipcode]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private func filteredInspections() -> [Inspection] {
        return (restaurant.inspections ?? []).sorted {
            guard let date1 = DateHelper.parseDate($0.inspection_date),
                  let date2 = DateHelper.parseDate($1.inspection_date) else {
                return false
            }
            return date1 > date2
        }
    }

    private func currentDisplayGrade() -> String? {
        let inspections = filteredInspections()
        if let latest = inspections.first, let grade = latest.grade, ["Z", "P"].contains(grade) {
            return "Grade_Pending"
        }
        if let graded = inspections.first(where: { ["A", "B", "C"].contains($0.grade ?? "") }) {
            return graded.grade
        }
        if inspections.contains(where: { $0.grade == "N" }) {
            return "Not_Graded"
        }
        return inspections.isEmpty ? "Not_Graded" : "Grade_Pending"
    }

    private func gradeImageName(for grade: String) -> String {
        switch grade {
        case "A": return "Grade_A"
        case "B": return "Grade_B"
        case "C": return "Grade_C"
        case "Grade_Pending": return "Grade_Pending"
        default: return "Not_Graded"
        }
    }

    private func gradeColor(for grade: String) -> Color {
        switch grade {
        case "A": return .blue
        case "B": return .green
        case "C": return .orange
        default: return .gray
        }
    }
}

// You will also need the ShareSheet helper struct if it's not already in this file.
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
