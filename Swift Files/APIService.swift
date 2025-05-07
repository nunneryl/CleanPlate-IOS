import Foundation
import os

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
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

class APIService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "APIService")
    static let shared = APIService()
    
    private init() {}
    
    // MARK: - Configuration
    
    #if DEBUG
    private let baseURL = "http://192.168.1.69:5000"  // Development
    #else
    private let baseURL = "https://api.cleanplate.app"  // Production (change to your actual domain)
    #endif
    
    // MARK: - API Methods
    
    func searchRestaurants(query: String) async throws -> [Restaurant] {
        guard let normalizedQuery = query
            .replacingOccurrences(of: "'", with: "'")
            .replacingOccurrences(of: "'", with: "'")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw APIError.invalidURL
        }
        
        guard let url = URL(string: "\(baseURL)/search?name=\(normalizedQuery)") else {
            logger.error("Invalid URL constructed for search")
            throw APIError.invalidURL
        }
        
        do {
            return try await performRequest(url: url)
        } catch {
            logger.error("Search failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
    
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
    
    // MARK: - Private Methods
    
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response received")
            throw APIError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error("Server error with status code: \(httpResponse.statusCode, privacy: .public)")
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.error("JSON decoding error: \(error.localizedDescription, privacy: .public)")
            throw APIError.decodingError(error)
        }
    }
}
