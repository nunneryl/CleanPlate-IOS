import SwiftUI

struct UpdatesView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("App Updates")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Group {
                        Text("Past Updates:")
                            .font(.headline)
                        Text("""
                        • Initial release with search and detail views
                        • Added accessibility enhancements and performance improvements
                        """)
                    }
                    
                    Group {
                        Text("Future Updates:")
                            .font(.headline)
                        Text("""
                        • Integration of a map view for restaurant locations
                        • Enhanced user analytics and logging
                        • Favorites feature to bookmark restaurants
                        """)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Updates")
        }
    }
}

struct UpdatesView_Previews: PreviewProvider {
    static var previews: some View {
        UpdatesView()
    }
}
