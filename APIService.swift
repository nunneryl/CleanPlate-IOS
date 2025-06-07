import Foundation
import os

// The APIError enum provides detailed, user-friendly descriptions for different kinds of network problems.
enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case serverError(Int)
    case decodingError(Error)
    case noData
    case unknown
    
    var description: String {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .networkError(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .serverError(let code):
            return "The server responded with an error (Code: \(code))."
        case .decodingError(let error):
            // Provides more specific details if the data from the server doesn't match the app's model.
            return "Failed to process server data: \(error.localizedDescription)"
        case .noData:
            return "No data was received from the server."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

// APIService is a singleton class responsible for all network communication.
class APIService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "APIService")
    static let shared = APIService()
    
    private init() {}
    
    // MARK: - Configuration
    
    // This is the base URL for your production backend API.
    private let baseURL = "https://cleanplate-production.up.railway.app"

    // MARK: - API Methods
    
    // ##### THIS FUNCTION IS UPDATED FOR PAGINATION #####
    /// Fetches a specific page of restaurant search results from the API.
    /// - Parameters:
    ///   - query: The user's search term.
    ///   - page: The page number to fetch.
    ///   - perPage: The number of results to fetch per page.
    /// - Returns: An array of `Restaurant` objects.
    func searchRestaurants(query: String, page: Int, perPage: Int) async throws -> [Restaurant] {
        // Ensure the query can be safely included in a URL.
        guard let normalizedQuery = query
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("Failed to URL-encode the search query: \(query, privacy: .public)")
            throw APIError.invalidURL
        }
        
        // Construct the full URL, now with the required 'page' and 'per_page' parameters.
        let urlString = "\(baseURL)/search?name=\(normalizedQuery)&page=\(page)&per_page=\(perPage)"
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL constructed for search: \(urlString, privacy: .public)")
            throw APIError.invalidURL
        }
        
        logger.info("Requesting URL: \(url.absoluteString, privacy: .public)")
        
        do {
            return try await performRequest(url: url)
        } catch {
            // Log the specific error before passing it up.
            logger.error("Search request failed for URL \(url.absoluteString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
    
    // This function for fetching recent restaurants remains unchanged.
    func getRecentRestaurants() async throws -> [Restaurant] {
        guard let url = URL(string: "\(baseURL)/recent") else {
            logger.error("Invalid URL constructed for recent restaurants")
            throw APIError.invalidURL
        }
        
        do {
            return try await performRequest(url: url)
        } catch {
            logger.error("Recent restaurants fetch failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
    
    // MARK: - Private Helper Method
    
    // This generic helper function performs the actual network request and decoding. It remains unchanged.
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20 // Set a 20-second timeout for the request.
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response received from \(url.absoluteString, privacy: .public)")
            throw APIError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error("Server error with status code: \(httpResponse.statusCode, privacy: .public) from \(url.absoluteString, privacy: .public)")
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            // This is where the raw data from the server is converted into your Swift `Restaurant` objects.
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("JSON decoding error from \(url.absoluteString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            // For easier debugging, log the raw data string that failed to decode.
            if let rawString = String(data: data, encoding: .utf8) {
                logger.error("Raw data on decoding error: \(rawString.prefix(500), privacy: .public)")
            }
            throw APIError.decodingError(error)
        }
    }
}
