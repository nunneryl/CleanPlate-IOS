import SwiftUI

struct FAQView: View {
    // Sample FAQ items for each section
    let generalFAQs = [
        FAQItem(question: "What is the NYC Food Ratings app?",
                answer: "It provides quick and reliable health inspection information for NYC restaurants."),
        FAQItem(question: "Where does the data come from?",
                answer: "Data is pulled from the NYC Open Data API and updated daily.")
    ]
    
    let usageFAQs = [
        FAQItem(question: "How do I search for a restaurant?",
                answer: "Use the search bar on the Home page to type in the restaurant name and view its details."),
        FAQItem(question: "What does the grade mean?",
                answer: "The grade reflects the health inspection score, with 'A' being the highest rating."),
        FAQItem(question: "How often is the data updated?",
                answer: "The data is refreshed daily to ensure you see the latest inspection results.")
    ]
    
    let technicalFAQs = [
        FAQItem(question: "Does the app collect my personal data?",
                answer: "No, the app does not collect or store any personal data."),
        FAQItem(question: "Is offline support available?",
                answer: "Currently, an internet connection is required to fetch the latest data."),
        FAQItem(question: "What platforms are supported?",
                answer: "The app is built for iOS and supports iPhones and iPads running iOS 15 or later."),
        FAQItem(question: "How can I contact support?",
                answer: "For support or feedback, please email us at support@yourdomain.com.")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General")) {
                    ForEach(generalFAQs) { item in
                        DisclosureGroup(item.question) {
                            Text(item.answer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Usage")) {
                    ForEach(usageFAQs) { item in
                        DisclosureGroup(item.question) {
                            Text(item.answer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Technical")) {
                    ForEach(technicalFAQs) { item in
                        DisclosureGroup(item.question) {
                            Text(item.answer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("FAQ")
        }
    }
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQView_Previews: PreviewProvider {
    static var previews: some View {
        FAQView()
    }
}
