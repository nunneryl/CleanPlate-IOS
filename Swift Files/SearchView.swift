import SwiftUI
import os

// MARK: - Animated Button Style
struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Enums for Sorting (if needed later)
enum SortOrder: String, CaseIterable, Identifiable {
    case ascending = "Ascending"
    case descending = "Descending"
    var id: String { self.rawValue }
}

enum SortType: String, CaseIterable, Identifiable {
    case none = "None"
    case name = "Name"
    case grade = "Grade"
    case date = "Date"
    var id: String { self.rawValue }
}

struct SearchView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "SearchView")
    
    init() {
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }
    
    // MARK: - States
    @State private var searchTerm: String = ""
    @State private var restaurants: [Restaurant] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                // Footer image (skyline)
                Image("nyc_footer") // Ensure this asset is added to your catalog
                    .resizable()
                    .scaledToFit()
                    .opacity(0.08)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                
                // Main Content
                VStack(spacing: 20) {
                    // Shift header and search bar down
                    VStack(spacing: 20) {
                        headerSection
                        searchBar
                    }
                    .padding(.top, 60)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if isLoading {
                        ProgressView("Loading...")
                            .padding()
                    }
                    
                    if !restaurants.isEmpty {
                        mainSearchResults
                            .refreshable {
                                Task { await performSearch() }
                            }
                    } else {
                        Spacer()
                    }
                }
                .padding(.bottom, 50)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                resetSearch()
                logger.info("SearchView appeared. Search state reset.")
            }
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Subviews & Networking
extension SearchView {
    
    private var headerSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
                .shadow(radius: 2)
            
            Text("CleanPlate")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Your Guide to Safe & Smart Dining")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private var searchBar: some View {
        HStack {
            TextField("Search for a restaurant", text: $searchTerm)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
                .padding(10)
                // Darker background for more contrast
                .background(Color(.systemGray5))
                .cornerRadius(8)
                // More pronounced shadow
                .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 2)
            
            Button {
                Task { await performSearch() }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(AnimatedButtonStyle())
        }
        .padding(.horizontal)
    }
    
    private var mainSearchResults: some View {
        List(restaurants) { restaurant in
            NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                VStack(alignment: .leading) {
                    Text(restaurant.dba ?? "Unknown Restaurant")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary)
                    Text("\(restaurant.street ?? ""), \(restaurant.boro ?? ""), \(restaurant.zipcode ?? "")")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(Color.white)
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
    }
    
    private func performSearch() async {
        guard !searchTerm.isEmpty else { return }
        resetError()
        DispatchQueue.main.async { isLoading = true }
        logger.info("Performing search with term: \(self.searchTerm, privacy: .public)")
        
        let normalized = searchTerm
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "’", with: "'")
        
        guard let encoded = normalized.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://192.168.1.69:5000/search?name=\(encoded)") else {
            logger.error("Invalid URL generated from search term.")
            DispatchQueue.main.async { isLoading = false }
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                DispatchQueue.main.async {
                    errorMessage = "Server error: \(httpResponse.statusCode)"
                    isLoading = false
                }
                logger.error("Server error: \(httpResponse.statusCode, privacy: .public)")
                return
            }
            let decoded = try JSONDecoder().decode([Restaurant].self, from: data)
            DispatchQueue.main.async {
                self.restaurants = decoded
                logger.info("Search successful; found \(self.restaurants.count, privacy: .public) restaurants.")
                isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                errorMessage = "Error: \(error.localizedDescription)"
                isLoading = false
            }
            logger.error("Error during search: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private func resetSearch() {
        searchTerm = ""
        restaurants = []
    }
    
    private func resetError() {
        errorMessage = nil
    }
}
