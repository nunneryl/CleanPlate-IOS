
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
            return "The request URL was invalid."
        case .networkError(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .serverError(let code):
            return "The server responded with an error (Code: \(code))."
        case .decodingError(let error):
            return "Failed to process server data: \(error.localizedDescription)"
        case .noData:
            return "No data was received from the server."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

class APIService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "APIService")
    static let shared = APIService()
    
    private init() {}
    
    // Remember to change it back to the production URL before merging to main.
    private let baseURL = "https://cleanplate-production.up.railway.app"
    
    /// The primary public method for searching restaurants with optional filters.
    func searchRestaurants(query: String, page: Int, perPage: Int, grade: String?, boro: String?, cuisine: String?, sort: String?) async throws -> [Restaurant] {
        var queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        
        if let grade = grade, !grade.isEmpty {
            queryItems.append(URLQueryItem(name: "grade", value: grade))
        }
        if let boro = boro, !boro.isEmpty {
            queryItems.append(URLQueryItem(name: "boro", value: boro))
        }
        if let cuisine = cuisine, !cuisine.isEmpty {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        if let sort = sort, !sort.isEmpty {
            queryItems.append(URLQueryItem(name: "sort", value: sort))
        }
        
        return try await buildAndPerformRequest(path: "/search", queryItems: queryItems)
    }
    
    /// The public method for fetching recently graded restaurants.
    func fetchRecentlyGraded(limit: Int) async throws -> [Restaurant] {
        let queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        return try await buildAndPerformRequest(path: "/lists/recently-graded", queryItems: queryItems)
    }
    
    func fetchRestaurantDetails(camis: String) async throws -> Restaurant {
        // Using self.baseURL for consistency
        guard let url = URL(string: "\(self.baseURL)/restaurant/\(camis)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        guard httpResponse.statusCode == 200 else {
            // Corrected to throw a valid server error
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let restaurant = try JSONDecoder().decode(Restaurant.self, from: data)
            return restaurant
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func submitReport(camis: String, issueType: String, comments: String) async throws {
        // 1. Define the URL for our new backend endpoint
        guard let url = URL(string: baseURL + "/report-issue") else {
            throw APIError.invalidURL
        }
        
        // 2. Prepare the data to be sent as JSON
        struct ReportPayload: Codable {
            let camis: String
            let issue_type: String
            let comments: String
        }
        let payload = ReportPayload(camis: camis, issue_type: issueType, comments: comments)
        let httpBody = try JSONEncoder().encode(payload)
        
        // 3. Create the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        // 4. Perform the network request
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        // If we get a 200 OK status, the submission was successful
        logger.info("Successfully submitted issue report for CAMIS: \(camis, privacy: .public)")
    }

    // MARK: - Private Helper Functions

    /// A generic, reusable function to build a URL and perform a network request.
    private func buildAndPerformRequest<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            logger.error("Invalid URL constructed for path \(path, privacy: .public) with items: \(queryItems.debugDescription, privacy: .public)")
            throw APIError.invalidURL
        }
        
        logger.info("Requesting URL: \(url.absoluteString, privacy: .public)")
        return try await performRequest(url: url)
    }

    /// Performs the actual data task and JSON decoding.
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            // Assuming your Restaurant model has a date decoding strategy set, if not add it here:
            // decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("JSON decoding error from \(url.absoluteString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            if let rawString = String(data: data, encoding: .utf8) {
                logger.error("Raw data on decoding error: \(rawString.prefix(500), privacy: .public)")
            }
            throw APIError.decodingError(error)
        }
    }
}
