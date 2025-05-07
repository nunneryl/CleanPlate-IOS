import SwiftUI
import os
import FirebaseAnalytics // <-- ADDED IMPORT

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "RestaurantDetailView")

    var body: some View {
        ZStack { // <-- Modifier will be added to this ZStack
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    inspectionList
                    faqLink
                }
                .padding(.vertical)
            }
        }
        .onAppear { // <-- ***** MODIFIED FIREBASE .onAppear MODIFIER HERE *****
            // Your existing logger
            logger.info("RestaurantDetailView appeared for \(restaurant.dba ?? "Unknown", privacy: .public)")

            // Log Screen View
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "Restaurant Detail",
                                          AnalyticsParameterScreenClass: "\(RestaurantDetailView.self)"])
            print("Analytics: Logged screen_view event for Restaurant Detail")

            // Log Custom Event for Viewing Details
            Analytics.logEvent("view_restaurant_details", parameters: [
                "restaurant_id": (restaurant.camis ?? "N/A") as NSObject, // Use camis as ID
                "restaurant_name": (restaurant.dba ?? "N/A") as NSObject
            ])
            print("Analytics: Logged view_restaurant_details for \(restaurant.dba ?? "N/A")")
        } // <-- ***** END FIREBASE MODIFIER *****
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Restaurant Details for \(restaurant.dba ?? "Unknown Restaurant")")
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(restaurant.dba ?? "Restaurant Name")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(formattedAddress())
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

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
                    .accessibilityLabel(
                        displayGrade == "A" || displayGrade == "B" || displayGrade == "C"
                            ? "Health Grade \(displayGrade)"
                            : displayGrade == "Grade_Pending" ? "Grade Pending" : "Not Graded"
                    )
                    .accessibilityHint(
                        displayGrade == "A" || displayGrade == "B" || displayGrade == "C"
                            ? "The restaurant received a grade of \(displayGrade) on their most recent graded inspection"
                            : displayGrade == "Grade_Pending" ? "The restaurant's grade is currently pending" : "This restaurant has not been graded yet"
                    )
            }
        }
        .padding()
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: restaurant.id)
    }

    private var inspectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inspections")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .padding(.vertical, 8)
                .padding(.bottom, 5)

            // Display inspections using the helper function
            if !filteredInspections().isEmpty {
                ForEach(filteredInspections()) { inspection in
                    inspectionRow(inspection: inspection) // Use extracted row view
                }
            } else {
                 Text("No inspection history found.")
                     .font(.system(size: 14, weight: .regular, design: .rounded))
                     .foregroundColor(.secondary)
                     .padding()
            }


            // Updated disclaimer notice with new link text and URL
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Additional inspection data may be available.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Link("View NYC OpenData", destination: URL(string: "https://data.cityofnewyork.us/Health/DOHMH-New-York-City-Restaurant-Inspection-Results/43nn-pn8j/data_preview")!)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Additional inspection data may be available on NYC OpenData")
        }
        .padding(.horizontal)
    }

    // Extracted Row View for Inspection
    private func inspectionRow(inspection: Inspection) -> some View {
         VStack(alignment: .leading, spacing: 10) {
            Text(DateHelper.formatDate(inspection.inspection_date))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            HStack {
                Text("Grade:")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.primary)

                if let grade = inspection.grade {
                    if grade.isEmpty || grade == "N/A" {
                        Text("No Grade Assigned")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.gray)
                    } else {
                        switch grade {
                        case "A", "B", "C":
                            Text(grade)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(gradeColor(for: grade))
                        case "Z":
                            Text("Z - Grade Pending")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        case "P":
                            Text("P - Grade Pending Issued on Re-opening")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        case "N":
                            Text("N - Not Yet Graded")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        default:
                            Text("No Grade Assigned")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Text("No Grade Assigned")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.gray)
                }
            }

            Text("Critical Flag: \(inspection.critical_flag ?? "N/A")")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.primary)

            Text("Type: \(inspection.inspection_type ?? "N/A")")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.primary)

            // Use the separate ViolationsView if violations exist
            if let violations = inspection.violations, !violations.isEmpty {
                 DisclosureGroup {
                     // Embed the ViolationsView here
                     ViolationsView(violations: violations)
                         .padding(.top, 8) // Add padding above the violations list
                 } label: {
                     Text("Violations (\(violations.count))") // Show count
                         .font(.system(size: 14, weight: .bold, design: .rounded))
                         .foregroundColor(.blue)
                 }
                 .accessibilityHint("Tap to view health code violations for this inspection")
            } else {
                 Text("No violations listed for this inspection.")
                     .font(.system(size: 14, weight: .regular, design: .rounded))
                     .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        // Use system background for the card look
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1) // Soft shadow
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Inspection on \(DateHelper.formatDate(inspection.inspection_date))")
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: inspection.id)
    }


    private var faqLink: some View {
        Link("NYC Health Dept Info", destination: URL(string: "https://a816-health.nyc.gov/ABCEatsRestaurants/#!/faq")!)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.blue)
            .padding(.top, 20)
            .accessibilityHint("Opens NYC Health Department website in browser")
    }

    // MARK: - Helper Functions

    private func formattedAddress() -> String {
        let building = restaurant.building ?? ""
        let street = formatStreet(restaurant.street ?? "")
        let borough = formatBorough(restaurant.boro ?? "")
        let zipcode = restaurant.zipcode ?? ""

        // Construct address, handling potential empty parts gracefully
        var addressParts: [String] = []
        if !building.isEmpty { addressParts.append(building) }
        if !street.isEmpty { addressParts.append(street) }
        if !borough.isEmpty { addressParts.append(borough) }
        if !zipcode.isEmpty { addressParts.append("NY " + zipcode) } // Add state abbreviation

        return addressParts.joined(separator: ", ")
    }


    private func formatStreet(_ street: String) -> String {
        // Keep your existing street formatting logic
        if street.lowercased().contains("avenue") {
            let components = street.components(separatedBy: " ")
            if components.count >= 2, let number = Int(components[0]) {
                let suffix = getNumberSuffix(number)
                return "\(number)\(suffix) Ave"
            }
            return street.replacingOccurrences(of: "AVENUE", with: "Ave", options: .caseInsensitive)
        } else if street.lowercased().contains("street") {
            return street.replacingOccurrences(of: "STREET", with: "St", options: .caseInsensitive)
        }
        // Return original if no specific handling
        return street
    }

    private func getNumberSuffix(_ number: Int) -> String {
         // Keep your existing suffix logic
        let lastDigit = number % 10
        let lastTwoDigits = number % 100

        if lastTwoDigits >= 11 && lastTwoDigits <= 13 {
            return "th"
        }

        switch lastDigit {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    private func formatBorough(_ boro: String) -> String {
        // Keep your existing borough formatting logic
        let boroughs = ["MANHATTAN": "Manhattan", "BROOKLYN": "Brooklyn", "QUEENS": "Queens",
                      "BRONX": "Bronx", "STATEN ISLAND": "Staten Island"]
        return boroughs[boro.uppercased()] ?? boro
    }

    // Updated filteredInspections method with sorting
    private func filteredInspections() -> [Inspection] {
        let inspections = restaurant.inspections ?? []
        return inspections.filter { inspection in
            // Filter out placeholder dates (before 2000)
            if let dateStr = inspection.inspection_date,
               let date = DateHelper.parseDate(dateStr) {
                // Use a more reliable way to get Jan 1, 2000 midnight UTC
                var components = DateComponents()
                components.year = 2000
                components.month = 1
                components.day = 1
                components.timeZone = TimeZone(secondsFromGMT: 0)
                let year2000 = Calendar.current.date(from: components) ?? Date(timeIntervalSince1970: 946684800)
                return date >= year2000
            }
            // Keep inspections if date parsing fails, maybe log this?
            // logger.warning("Could not parse inspection date: \(inspection.inspection_date ?? "nil")")
            return true // Or return false if unparseable dates should be excluded
        }
        // Add this sorting to arrange by date (newest first)
        .sorted { firstInspection, secondInspection in
            guard let firstDateStr = firstInspection.inspection_date,
                  let secondDateStr = secondInspection.inspection_date,
                  let firstDate = DateHelper.parseDate(firstDateStr),
                  let secondDate = DateHelper.parseDate(secondDateStr) else {
                // Handle cases where one or both dates are nil/unparseable
                // Sort valid dates before invalid ones
                return firstInspection.inspection_date != nil && secondInspection.inspection_date == nil
            }
            // Sort newest first
            return firstDate > secondDate
        }
    }


    // Function to determine the most recent grade (for backward compatibility)
    private func mostRecentGrade() -> String? {
        // Keep existing logic
        return filteredInspections().first?.grade
    }

    // New function to get appropriate display grade
    private func currentDisplayGrade() -> String? {
        // Keep existing logic
        let inspections = filteredInspections()

        // First check if most recent inspection has Z or P (pending)
        if let latestInspection = inspections.first,
           let grade = latestInspection.grade,
           grade == "Z" || grade == "P" {
            return "Grade_Pending"
        }

        // Find most recent inspection with an actual grade (A, B, C)
        let gradedInspection = inspections.first { inspection in
            guard let grade = inspection.grade else { return false }
            return ["A", "B", "C"].contains(grade)
        }

        if let grade = gradedInspection?.grade {
            return grade
        }

        // If no A, B, C found, check for N (Not Graded)
        let notGradedInspection = inspections.first { inspection in
            return inspection.grade == "N"
        }

        if notGradedInspection != nil {
            return "Not_Graded"
        }

        // Default fallback if no valid grade/status found in history
        // Check if there are *any* inspections. If not, maybe return nil or specific status
        if inspections.isEmpty {
            return "Not_Graded" // Or perhaps a different status like "No History"
        }

        // If history exists but no A/B/C/N/Z/P found, default to Pending
        return "Grade_Pending"
    }


    // Updated function to get image name for grade
    private func gradeImageName(for grade: String) -> String {
        // Keep existing logic
        switch grade {
        case "A": return "Grade_A"
        case "B": return "Grade_B"
        case "C": return "Grade_C"
        case "Z", "P", "Grade_Pending": return "Grade_Pending"
        case "N", "Not_Graded": return "Not_Graded"
        default: return "Not_Graded" // Default for safety
        }
    }

    // Updated function to get color for grade
    private func gradeColor(for grade: String) -> Color {
         // Keep existing logic
        switch grade {
        case "A": return .blue
        case "B": return .green
        case "C": return .orange
        case "Z", "P", "Grade_Pending": return .gray
        case "N", "Not_Graded": return .gray
        default: return .gray // Default for safety
        }
    }
}
