// MARK: - UPDATED FILE: APIService.swift

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
    
    // --- IMPORTANT FOR TESTING ---
    // Change this to your Railway preview URL to test your feature branch.
    // Remember to change it back to the production URL before merging to main.
    private let baseURL = "https://cleanplate-production.up.railway.app"

    func searchRestaurants(query: String, page: Int, perPage: Int, grade: String?, boro: String?, cuisine: String?, sort: String?) async throws -> [Restaurant] {
        
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        components.path = "/search"
        
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        
        if let grade = grade, !grade.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "grade", value: grade))
        }
        if let boro = boro, !boro.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "boro", value: boro))
        }
        if let cuisine = cuisine, !cuisine.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        if let sort = sort, !sort.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "sort", value: sort))
        }
        
        guard let url = components.url else {
            logger.error("Invalid URL constructed from components: \(components.debugDescription, privacy: .public)")
            throw APIError.invalidURL
        }
        
        logger.info("Requesting URL: \(url.absoluteString, privacy: .public)")
        
        return try await performRequest(url: url)
    }
    
    // --- NEW FUNCTION ADDED HERE ---
    func fetchRecentlyGraded(limit: Int) async throws -> [Restaurant] {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        components.path = "/lists/recently-graded"
        
        // Only add the 'limit' query item
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            logger.error("Invalid URL for recently-graded endpoint.")
            throw APIError.invalidURL
        }
        logger.info("Requesting recently graded restaurants from: \(url.absoluteString, privacy: .public)")
        return try await performRequest(url: url)
    }

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
