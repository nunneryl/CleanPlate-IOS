import SwiftUI
import FirebaseAnalytics // <-- ADDED IMPORT

struct FoodSafetyFAQView: View {
    var body: some View {
        // Root NavigationView for this tab's content
        NavigationView { // <-- Modifier will be added to this NavigationView
            List {
                // Restaurant Grading System
                Section(header: Text("Understanding NYC Restaurant Grades")) {
                    ForEach(gradingItems) { item in
                        DisclosureGroup(item.question) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.answer)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    // Allow text to wrap naturally
                                    .fixedSize(horizontal: false, vertical: true)

                                if item.hasExternalLink {
                                    Link(item.linkText, destination: URL(string: item.linkURL)!)
                                        .padding(.top, 8)
                                        .foregroundColor(.blue)
                                }
                            }
                            // Add padding inside the disclosure group content
                            .padding(.vertical, 4)
                        }
                        // Add padding around the entire disclosure group row
                       // .padding(.vertical, 4) // Removed redundant padding here
                    }
                }

                // Simplified Inspections & Violations Overview
                Section(header: Text("Inspections & Common Issues")) {
                    ForEach(inspectionItems) { item in
                        DisclosureGroup(item.question) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.answer)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                if item.hasExternalLink {
                                    Link(item.linkText, destination: URL(string: item.linkURL)!)
                                        .padding(.top, 8)
                                        .foregroundColor(.blue)
                                }
                            }
                             .padding(.vertical, 4)
                        }
                       // .padding(.vertical, 4)
                    }
                }

                // Food Safety Perspective
                Section(header: Text("Food Safety Perspective")) {
                    ForEach(perspectiveItems) { item in
                        DisclosureGroup(item.question) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.answer)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                if item.hasExternalLink {
                                    Link(item.linkText, destination: URL(string: item.linkURL)!)
                                        .padding(.top, 8)
                                        .foregroundColor(.blue)
                                }
                            }
                             .padding(.vertical, 4)
                        }
                       // .padding(.vertical, 4)
                    }
                }

                // External Resources Section
                Section(header: Text("Additional Resources")) {
                    Link("NYC Restaurant Inspection Guide",
                         destination: URL(string: "https://www1.nyc.gov/site/doh/business/food-operators/letter-grading-for-restaurants.page")!)
                        .padding(.vertical, 8) // Keep padding for standalone links
                }
            }
            .listStyle(GroupedListStyle()) // Grouped style often looks good for FAQs
            .navigationTitle("Food Safety FAQ")
        } // End of NavigationView
        .navigationViewStyle(.stack) // <--- MODIFIER ADDED HERE
        .onAppear { // <-- ***** ADDED FIREBASE .onAppear MODIFIER HERE *****
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "Food Safety FAQ",
                                          AnalyticsParameterScreenClass: "\(FoodSafetyFAQView.self)"])
            print("Analytics: Logged screen_view event for Food Safety FAQ")
        } // <-- ***** END FIREBASE MODIFIER *****
    }

    // MARK: - Data Arrays (Keep your existing data)

    // Restaurant Grading Items - Updated with new content including Not Yet Graded
    // Removed the "What percentage of NYC restaurants receive A grades?" item
    let gradingItems = [
        InfoItem(question: "What do the letter grades mean?",
                answer: "\"A restaurant's score depends on how well it follows City and State food safety requirements. Inspectors check for food handling, food temperature, personal hygiene, facility and equipment maintenance and vermin control. Each violation earns a certain number of points. At the end of the inspection, the inspector totals the points, and this number is the restaurant's inspection score; the lower the score, the better.\" (NYC Health)\n\n• Grade A: 0-13 points\n• Grade B: 14-27 points\n• Grade C: 28+ points",
                hasExternalLink: true,
                linkURL: "https://www.nyc.gov/assets/doh/downloads/pdf/rii/restaurant-grading-faq.pdf",
                linkText: "More information can be found here"),
        InfoItem(question: "What does 'Grade Pending' mean?",
                answer: "Restaurants have the right to a re-inspection approximately one month after receiving a B or C grade on an initial inspection. During this period, they may post \"Grade Pending\" until their grade is finalized after re-inspection."),
        InfoItem(question: "What does 'Not Yet Graded' mean?",
                answer: "According to NYC Health, \"Not Yet Graded\" applies to new restaurants or those that have reopened after being closed, but have not yet received their first graded inspection. A restaurant with a \"Not Yet Graded\" status has passed its initial permit inspection but has not yet undergone the full graded inspection process."),
        InfoItem(question: "How often are restaurants inspected?",
                answer: "Restaurants with A grades are inspected roughly once a year, while those with B grades are inspected more frequently (about every 6 months), and C grade establishments receive even more frequent inspections.",
                hasExternalLink: true,
                linkURL: "https://www.nyc.gov/assets/doh/downloads/pdf/rii/inspection-cycle-overview.pdf",
                linkText: "More information can be found here")
    ]

    // Inspection & Common Issues - Updated with new content
    let inspectionItems = [
        InfoItem(question: "What do health inspectors look for?",
                answer: "Health inspectors evaluate restaurants based on several key areas of food safety:\n\n• Temperature control for hot and cold foods\n• Food worker hygiene practices\n• Protection of food from contamination\n• Facility cleanliness and maintenance\n• Proper storage and labeling\n• Evidence of pest control measures\n\nThese factors help ensure that food is prepared and served safely."),
        InfoItem(question: "How are violations categorized?",
                answer: "\"The points for a particular violation depend on the health risk it poses to the public. Violations fall into three categories:\n\n- A **public health hazard**, such as failing to keep food at the right temperature, triggers a minimum of 7 points. If the violation can't be corrected before the inspection ends, the Health Department may close the restaurant until it's fixed.\n\n- A **critical violation**, for example, serving raw food such as a salad without properly washing it first, carries a minimum of 5 points.\n\n- A **general violation**, such as not properly sanitizing cooking utensils, receives at least 2 points. Inspectors assign additional points to reflect the extent of the violation.\n\nA violation's condition level can range from 1 (least extensive) to 5 (most extensive). For example, the presence of one contaminated food item is a condition level 1 violation, generating 7 points. Four or more contaminated food items is a condition level 4 violation, resulting in 10 points.\" (NYC Health)"),
        InfoItem(question: "When does a restaurant get shut down by the health department?",
                answer: "The NYC Health Department will close a restaurant if it finds conditions that pose an imminent hazard to public health, such as severe pest infestation, sewage problems, or lack of hot water.")
    ]

    // Perspective Items - Updated with your content
    let perspectiveItems = [
        InfoItem(question: "How do restaurants typically respond to violations?",
                answer: "Most restaurant owners and managers take food safety very seriously and work quickly to address any violations identified during inspections. The grading system is designed to encourage continuous improvement.\n\nRestaurants often request re-inspections after addressing issues to improve their grades. This process helps maintain high food safety standards across the city's diverse dining scene."),
        InfoItem(question: "How can I make informed dining decisions?",
                answer: "To make balanced decisions about where to eat:\n\n• Consider the grade alongside other factors, such as reviews\n• Look at the inspection history, not just the current grade\n• Pay attention to whether violations are recurring or one-time issues\n• Remember that the inspection system is designed to help restaurants improve")
    ]
} // End of FoodSafetyFAQView struct

// MARK: - Data Model

struct InfoItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    var hasExternalLink: Bool = false
    var linkURL: String = ""
    var linkText: String = ""
}
