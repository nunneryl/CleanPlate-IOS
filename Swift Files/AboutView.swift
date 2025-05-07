import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About NYC Food Ratings")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("""
                    The NYC Food Ratings app is designed to provide quick and reliable health inspection information for restaurants throughout New York City. Whether you're choosing a safe dining option or simply curious about a restaurant's track record, this app delivers up-to-date data at your fingertips.
                    """)
                    
                    Text("Data Source")
                        .font(.headline)
                    Text("""
                    The information displayed in this app is sourced directly from the NYC Open Data API, which publishes daily updates from the NYC Department of Health. This ensures that you always have access to the most current inspection results.
                    """)
                    
                    Text("Our Mission")
                        .font(.headline)
                    Text("""
                    We believe that transparency in health inspections empowers consumers to make informed dining choices. Our goal is to contribute to a healthier community by providing clear and accessible restaurant inspection data.
                    """)
                    
                    Text("Feedback & Support")
                        .font(.headline)
                    Text("""
                    We value your input! If you have any questions, suggestions, or concerns about the app, please reach out to us at support@yourdomain.com. Your feedback helps us improve the experience for everyone.
                    """)
                    
                    Link("Visit NYC Department of Health", destination: URL(string: "https://www1.nyc.gov/site/doh/index.page")!)
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
