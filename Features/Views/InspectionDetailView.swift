// In file: InspectionDetailView.swift

import SwiftUI
import os
import FirebaseAnalytics

struct InspectionDetailView: View {
    let inspection: Inspection
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "InspectionDetailView")

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                
                 if let violations = inspection.violations, !violations.isEmpty {
                     violationsSection(violations: violations)
                 } else {
                     noViolationsSection
                 }
                 
                externalResourcesSection
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Inspection Details")
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .onAppear {
            logger.info("InspectionDetailView appeared for inspection date: \(inspection.inspection_date ?? "N/A", privacy: .public)")

            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "Inspection Detail",
                                          AnalyticsParameterScreenClass: "\(InspectionDetailView.self)"])
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inspection Date: \(inspection.formattedDate)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

             HStack {
                 Text("Grade:")
                     .font(.system(size: 14, weight: .regular, design: .rounded))
                     .foregroundColor(.primary)

                 Text(inspection.displayGradeText)
                     .font(.system(size: 14, weight: .bold, design: .rounded))
                     .foregroundColor(inspection.displayGradeColor)
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
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }

     private func violationsSection(violations: [Violation]) -> some View {
         VStack(alignment: .leading, spacing: 10) {
             Text("Violations")
                 .font(.system(size: 16, weight: .semibold, design: .rounded))
                 .padding(.bottom, 4)
             ViolationsView(violations: violations)
         }
         .padding()
         .frame(maxWidth: .infinity, alignment: .leading)
         .background(Color(UIColor.systemGray6))
         .cornerRadius(8)
     }

     private var noViolationsSection: some View {
         VStack(alignment: .center, spacing: 10) { // Centered alignment
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
         .frame(maxWidth: .infinity) // Allow VStack to center its content
         .background(Color(UIColor.systemGray6))
         .cornerRadius(8)
     }


    private var externalResourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learn More")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .padding(.bottom, 4)

            Link(destination: URL(string: "https://www1.nyc.gov/site/doh/business/food-operators/letter-grading-for-restaurants.page")!) {
                 HStack {
                     Text("NYC Restaurant Inspection Guide")
                     Spacer()
                     Image(systemName: "chevron.right").font(.caption)
                 }
            }
                .font(.system(size: 14))
                .foregroundColor(.blue)

            Button(action: {
                NotificationCenter.default.post(name: .switchToFoodSafetyTab, object: nil)
            }) {
                HStack {
                    Text("View Food Safety FAQ")
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption)
                }
                .font(.system(size: 14))
                .foregroundColor(.blue)
            }

            Text("Restaurant grades provide useful information but reflect a single inspection on a specific day. Most violations are corrected quickly after inspection.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}
