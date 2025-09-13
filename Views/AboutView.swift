// In file: AboutView.swift

import SwiftUI
import FirebaseAnalytics

// MARK: - Main Container View
struct AboutView: View {
    
    // State to manage the selected tab
    private enum SelectedTab: String, CaseIterable {
        case about = "About"
        case faq = "FAQ"
    }
    @State private var selectedTab: SelectedTab = .about

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Picker for the segmented control tabs
                Picker("Select a section", selection: $selectedTab) {
                    ForEach(SelectedTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Switch between the About content and the FAQ content
                switch selectedTab {
                case .about:
                    AboutContentView()
                        .transition(.opacity.animation(.easeIn))
                case .faq:
                    FoodSafetyFAQView()
                        .transition(.opacity.animation(.easeIn))
                }
                
                Spacer()
            }
            .navigationTitle(selectedTab.rawValue) // Title changes with the tab
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground)) // Ensure background color consistency
        }
        .navigationViewStyle(.stack)
        .onAppear {
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "About/FAQ Container",
                                          AnalyticsParameterScreenClass: "\(AboutView.self)"])
        }
    }
}

// MARK: - "About" Content View
struct AboutContentView: View {
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            // App Description Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("CleanPlate is designed to provide quick and reliable health inspection information for restaurants throughout New York City. Whether you're choosing a safe dining option or simply curious about a restaurant's track record, this app delivers up-to-date data at your fingertips.")
                        .padding(.vertical, 4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("We promote transparency and celebrate NYC's diverse dining scene. While health ratings are an important factor in choosing where to eat, we encourage users to consider the full picture, including a restaurant's cuisine, ambiance, reviews and role in the community.")
                        .padding(.vertical, 4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }

            // Data Source Section
            Section(header: Text("Data Source")) {
                Text("The information displayed in this app is sourced directly from the NYC Open Data API, which publishes daily updates from the NYC Department of Health. This ensures that you always have access to the most current inspection results.")
                 .padding(.vertical, 4)
                 .fixedSize(horizontal: false, vertical: true)
            }

            // Using CleanPlate Section
            Section(header: Text("Using CleanPlate")) {
                DisclosureGroup("How do I search for a restaurant?") {
                    Text("Use the search bar on the Home page to type in the restaurant name and view its details.")
                        .padding(.vertical, 8)
                        .fixedSize(horizontal: false, vertical: true)
                }

                DisclosureGroup("What should I do if I suspect a food safety issue?") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("If you experience symptoms of foodborne illness after eating at a restaurant, or if you observe concerning food handling practices:")
                            .fixedSize(horizontal: false, vertical: true)

                        Text("1. Contact 311 to report your concerns to the NYC Department of Health")
                        Text("2. Seek medical attention if you are experiencing symptoms")
                        Text("3. Note what you ate, when, and where")
                    }
                    .padding(.vertical, 8)
                }
            }

            // Feedback Section
            Section(header: Text("Feedback & Support")) {
                Link("Email us at cleanplateapp@aol.com", destination: URL(string: "mailto:cleanplateapp@aol.com")!)
                   .padding(.vertical, 4)
            }

            // Legal Section
            Section(header: Text("Legal")) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.secondary)
                    
                    Link("Privacy Policy, Terms and Conditions, Etc.", destination: URL(string: "https://cleanplate.support")!)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.systemGray3))
                }
            }
            .foregroundColor(.primary)
            
            Section {
                HStack {
                    Text("App Version")
                        .font(.body)
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}


// MARK: - "FAQ" Content View
struct FoodSafetyFAQView: View {
    var body: some View {
        List {
            Section(header: Text("Understanding NYC Restaurant Grades")) {
                ForEach(gradingItems) { item in
                    DisclosureGroup(item.question) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.answer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if item.hasExternalLink {
                                Link(item.linkText, destination: URL(string: item.linkURL)!)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section(header: Text("Inspections & Common Issues")) {
                ForEach(inspectionItems) { item in
                    DisclosureGroup(item.question) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.answer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                         .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .onAppear {
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "Food Safety FAQ",
                                          AnalyticsParameterScreenClass: "\(FoodSafetyFAQView.self)"])
        }
    }

    // MARK: - FAQ Data
    let gradingItems = [
        InfoItem(question: "What do the letter grades mean?", answer: "\"A restaurant's score depends on how well it follows City and State food safety requirements... (NYC Health)\n\n• Grade A: 0-13 points\n• Grade B: 14-27 points\n• Grade C: 28+ points", hasExternalLink: true, linkURL: "https://www.nyc.gov/assets/doh/downloads/pdf/rii/restaurant-grading-faq.pdf", linkText: "More information can be found here"),
        InfoItem(question: "What does 'Grade Pending' mean?", answer: "Restaurants have the right to a re-inspection approximately one month after receiving a B or C grade on an initial inspection. During this period, they may post \"Grade Pending\" until their grade is finalized after re-inspection."),
        InfoItem(question: "What does 'Not Yet Graded' mean?", answer: "According to NYC Health, \"Not Yet Graded\" applies to new restaurants or those that have reopened after being closed, but have not yet received their first graded inspection."),
        InfoItem(question: "How often are restaurants inspected?", answer: "Restaurants with A grades are inspected roughly once a year, while those with B grades are inspected more frequently (about every 6 months), and C grade establishments receive even more frequent inspections.", hasExternalLink: true, linkURL: "https://www.nyc.gov/assets/doh/downloads/pdf/rii/inspection-cycle-overview.pdf", linkText: "More information can be found here")
    ]
    let inspectionItems = [
        InfoItem(question: "What do health inspectors look for?", answer: "Health inspectors evaluate restaurants based on several key areas of food safety:\n\n• Temperature control for hot and cold foods\n• Food worker hygiene practices\n• Protection of food from contamination..."),
        InfoItem(question: "How are violations categorized?", answer: "\"The points for a particular violation depend on the health risk it poses to the public. Violations fall into three categories:\n\n- A public health hazard...\n\n- A critical violation...\n\n- A general violation...\" (NYC Health)"),
        InfoItem(question: "When does a restaurant get shut down by the health department?", answer: "The NYC Health Department will close a restaurant if it finds conditions that pose an imminent hazard to public health, such as severe pest infestation, sewage problems, or lack of hot water.")
    ]
}

// MARK: - FAQ Data Model
struct InfoItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    var hasExternalLink: Bool = false
    var linkURL: String = ""
    var linkText: String = ""
}
