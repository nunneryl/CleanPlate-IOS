// MARK: - UPDATED FILE: AboutView.swift

import SwiftUI
import FirebaseAnalytics

struct AboutView: View {
    
    /// This computed property automatically reads the app's version and build number
    /// from the project's settings. You will never need to update this manually.
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        NavigationView {
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

                // Technical Information Section
                Section(header: Text("Technical Information")) {
                    DisclosureGroup("Is offline support available?") {
                        Text("Currently, an internet connection is required to fetch the latest data.")
                            .padding(.vertical, 8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    DisclosureGroup("How recently is the data updated?") {
                        Text("CleanPlate pulls data directly from the NYC Open Data API, which is updated daily with the latest inspection results from the NYC Department of Health.")
                            .padding(.vertical, 8)
                            .fixedSize(horizontal: false, vertical: true)
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
                        // Add an icon for visual context
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(.secondary)
                        
                        Link("Privacy Policy", destination: URL(string: "https://cleanplate.support/privacy.html")!)
                        
                        Spacer()
                        
                        // A chevron can better indicate that this is a link
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.systemGray3))
                    }
                }
                .foregroundColor(.primary) // Apply this to make the Link text black/white
                
                // This section will display the app version at the bottom of the list.
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
            .navigationTitle("About")
        }
        .navigationViewStyle(.stack)
        .onAppear {
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "About",
                                          AnalyticsParameterScreenClass: "\(AboutView.self)"])
        }
    }
}
