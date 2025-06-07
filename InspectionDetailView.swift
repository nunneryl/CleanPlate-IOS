import SwiftUI
import os
import FirebaseAnalytics // <-- ADDED IMPORT

struct InspectionDetailView: View {
    let inspection: Inspection
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "InspectionDetailView")

    var body: some View {
        ScrollView { // <-- Modifier will be added to this ScrollView
            VStack(spacing: 20) {
                headerSection
                // Embed ViolationsView directly if violations exist
                 if let violations = inspection.violations, !violations.isEmpty {
                     violationsSection(violations: violations) // Pass violations
                 } else {
                     noViolationsSection // Show a placeholder if no violations
                 }
                externalResourcesSection
                Spacer() // Pushes content up if ScrollView isn't full
            }
            .padding() // Padding around the entire VStack content
        }
        .navigationTitle("Inspection Details")
        .background(Color(UIColor.systemBackground).ignoresSafeArea()) // Use system background color
        .onAppear { // <-- ***** ADDED FIREBASE .onAppear MODIFIER HERE *****
            // Log existing message
            logger.info("InspectionDetailView appeared for inspection date: \(inspection.inspection_date ?? "N/A", privacy: .public)")

            // Log Screen View
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "Inspection Detail",
                                          AnalyticsParameterScreenClass: "\(InspectionDetailView.self)"])
            print("Analytics: Logged screen_view event for Inspection Detail")
        } // <-- ***** END FIREBASE MODIFIER *****
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inspection Date: \(DateHelper.formatDate(inspection.inspection_date))")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            // Display Grade with better handling for nil/empty/specific codes
             HStack {
                 Text("Grade:")
                     .font(.system(size: 14, weight: .regular, design: .rounded))
                     .foregroundColor(.primary)

                 Text(formattedGrade(inspection.grade)) // Use helper function
                     .font(.system(size: 14, weight: .regular, design: .rounded))
                      // Use a helper for color if needed, or keep simple
                     .foregroundColor(gradeColor(forGradeCode: inspection.grade))
             }


            Text("Type: \(inspection.inspection_type ?? "N/A")")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.primary)

            Text("Critical Flag: \(inspection.critical_flag ?? "N/A")")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6)) // Use system gray for background
        .cornerRadius(8)
    }

     // Updated Violations Section using ViolationsView
     private func violationsSection(violations: [Violation]) -> some View {
         VStack(alignment: .leading, spacing: 10) {
             Text("Violations")
                 .font(.system(size: 16, weight: .semibold, design: .rounded))
                 .padding(.bottom, 4) // Reduced bottom padding

             // Embed the ViolationsView
             ViolationsView(violations: violations)
         }
         .padding()
         .frame(maxWidth: .infinity, alignment: .leading)
         .background(Color(UIColor.systemGray6))
         .cornerRadius(8)
     }

     // Section to display when no violations are found
     private var noViolationsSection: some View {
         VStack(alignment: .leading, spacing: 10) {
             Image(systemName: "checkmark.circle.fill")
                         .font(.largeTitle)
                         .foregroundColor(.green)
                         .padding(.bottom, 4)

                     Text("No Violations Found")
                         .font(.system(size: 16, weight: .semibold, design: .rounded))

                     Text("This inspection did not result in any violations.")
                         .font(.system(size: 14, weight: .regular, design: .rounded))
                         .foregroundColor(.secondary)
                         .multilineTextAlignment(.center)
         }
         .padding()
         .frame(maxWidth: .infinity, alignment: .leading)
         .background(Color(UIColor.systemGray6))
         .cornerRadius(8)
     }


    private var externalResourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learn More")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .padding(.bottom, 4)

            Link("NYC Restaurant Inspection Guide",
                 destination: URL(string: "https://www1.nyc.gov/site/doh/business/food-operators/letter-grading-for-restaurants.page")!)
                .font(.system(size: 14))
                .foregroundColor(.blue)

            Button(action: {
                // Post notification to switch to Food Safety tab
                NotificationCenter.default.post(name: .switchToFoodSafetyTab, object: nil)
            }) {
                Text("View Food Safety FAQ")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }

            Text("Restaurant grades provide useful information but reflect a single inspection on a specific day. Most violations are corrected quickly after inspection.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }

     // Helper function to format grade display text
     private func formattedGrade(_ gradeCode: String?) -> String {
         guard let grade = gradeCode, !grade.isEmpty else {
             return "Not Graded"
         }
         switch grade {
             case "A", "B", "C": return "Grade \(grade)"
             case "Z": return "Grade Pending"
             case "P": return "Grade Pending (Re-opening)"
             case "N": return "Not Yet Graded"
             default: return "N/A" // Or "Unknown"
         }
     }

     // Optional: Helper function for grade color (can adjust colors)
     private func gradeColor(forGradeCode gradeCode: String?) -> Color {
         guard let grade = gradeCode else { return .gray }
         switch grade {
             case "A": return .blue
             case "B": return .green
             case "C": return .orange
             case "Z", "P", "N": return .gray
             default: return .gray
         }
     }

}
