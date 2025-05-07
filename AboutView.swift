import SwiftUI
import FirebaseAnalytics // <-- ADDED IMPORT

struct AboutView: View {
    var body: some View {
        // Root NavigationView for this tab's content
        NavigationView { // <-- Modifier will be added to this NavigationView
            List {
                // App Description Section
                Section { // Removed redundant header
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("CleanPlate is designed to provide quick and reliable health inspection information for restaurants throughout New York City. Whether you're choosing a safe dining option or simply curious about a restaurant's track record, this app delivers up-to-date data at your fingertips.")
                            .padding(.vertical, 4) // Add padding around text
                            .fixedSize(horizontal: false, vertical: true) // Allow wrapping

                        Text("We promote transparency and celebrate NYC's diverse dining scene. While health ratings are an important factor in choosing where to eat, we encourage users to consider the full picture, including a restaurant's cuisine, ambiance, reviews and role in the community.")
                            .padding(.vertical, 4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8) // Padding for the VStack within the section
                }

                // Data Source Section
                Section(header: Text("Data Source")) {
                    Text("The information displayed in this app is sourced directly from the NYC Open Data API, which publishes daily updates from the NYC Department of Health. This ensures that you always have access to the most current inspection results.")
                     .padding(.vertical, 4) // Add padding
                     .fixedSize(horizontal: false, vertical: true)
                }

                // Using CleanPlate Section
                Section(header: Text("Using CleanPlate")) {
                    DisclosureGroup("How do I search for a restaurant?") {
                        Text("Use the search bar on the Home page to type in the restaurant name and view its details.")
                            .padding(.vertical, 8) // Padding inside disclosure
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // .padding(.vertical, 4) // Padding for the row itself

                    DisclosureGroup("What should I do if I suspect a food safety issue?") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("If you experience symptoms of foodborne illness after eating at a restaurant, or if you observe concerning food handling practices:")
                                .fixedSize(horizontal: false, vertical: true)

                            Text("1. Contact 311 to report your concerns to the NYC Department of Health")
                                .fixedSize(horizontal: false, vertical: true)
                            Text("2. Seek medical attention if you are experiencing symptoms")
                                .fixedSize(horizontal: false, vertical: true)
                            Text("3. Note what you ate, when, and where")
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 8) // Padding inside disclosure
                    }
                   // .padding(.vertical, 4)
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

                // Feedback Section (Updated Email)
                Section(header: Text("Feedback & Support")) {
                    // Consider making this a tappable mailto link
                    Text("We value your input! If you have any questions, suggestions, or concerns about the app, please reach out to us at cleanplateapp@aol.com. Your feedback helps us improve the experience for everyone.")
                     .padding(.vertical, 4) // Add padding
                     .fixedSize(horizontal: false, vertical: true)

                    // OR make it a link directly:
                    // Link("Email us at cleanplateapp@aol.com", destination: URL(string: "mailto:cleanplateapp@aol.com")!)
                    //    .padding(.vertical, 4)
                }

                // Legal Section (Link Added/Updated)
                Section(header: Text("Legal")) {
                     Link("Privacy Policy", destination: URL(string: "https://cleanplate.support/privacy.html")!) // <-- Use your live URL
                        .padding(.vertical, 4)
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("About")
        } // End of NavigationView
        .navigationViewStyle(.stack) // <--- MODIFIER ADDED HERE
        .onAppear { // <-- ***** ADDED FIREBASE .onAppear MODIFIER HERE *****
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [AnalyticsParameterScreenName: "About",
                                          AnalyticsParameterScreenClass: "\(AboutView.self)"])
            print("Analytics: Logged screen_view event for About")
        } // <-- ***** END FIREBASE MODIFIER *****
    }
} // End of AboutView struct
