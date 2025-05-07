import SwiftUI
import os

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "RestaurantDetailView")
    
    var body: some View {
        ZStack {
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
        .onAppear {
            logger.info("RestaurantDetailView appeared for \(restaurant.dba ?? "Unknown", privacy: .public)")
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(restaurant.dba ?? "Restaurant Name")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(fullAddress())
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                
                if let cuisine = restaurant.cuisine_description, cuisine != "N/A" {
                    Text(cuisine)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            
            if let grade = mostRecentGrade() {
                Image(gradeImageName(for: grade))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .accessibilityLabel("Grade \(grade)")
            }
        }
        .padding()
    }
    
    private var inspectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inspections")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .padding(.vertical, 8)
                .padding(.bottom, 5)
            
            ForEach(restaurant.inspections ?? [], id: \.id) { inspection in
                VStack(alignment: .leading, spacing: 10) {
                    Text(DateHelper.formatDate(inspection.inspection_date))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Grade: \(inspection.grade ?? "N/A")")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Critical Flag: \(inspection.critical_flag ?? "N/A")")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Type: \(inspection.inspection_type ?? "N/A")")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if let violations = inspection.violations, !violations.isEmpty {
                        DisclosureGroup("Violations") {
                            ForEach(violations) { violation in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Code: \(violation.violation_code ?? "N/A")")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text(violation.violation_description ?? "No description available")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                                Divider()
                                    .background(Color.secondary)
                            }
                        }
                    } else {
                        Text("No violations listed.")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 3)
            }
        }
        .padding(.horizontal)
    }
    
    private var faqLink: some View {
        Link("NYC Health Dept Info", destination: URL(string: "https://a816-health.nyc.gov/ABCEatsRestaurants/#!/faq")!)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.blue)
            .padding(.top, 20)
    }
    
    // MARK: - Helper Functions
    private func fullAddress() -> String {
        [restaurant.building, restaurant.street, restaurant.zipcode]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
    
    private func mostRecentGrade() -> String? {
        restaurant.inspections?.first?.grade
    }
    
    private func gradeImageName(for grade: String) -> String {
        switch grade {
        case "A": return "Grade_A"
        case "B": return "Grade_B"
        case "C": return "Grade_C"
        case "Z": return "Grade_Pending"
        case "N": return "Not_Graded"
        default: return "Not_Graded"
        }
    }
}
