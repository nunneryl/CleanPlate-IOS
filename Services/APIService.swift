// In file: APIService.swift

import Foundation
import os
import Security

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case serverError(Int)
    case decodingError(Error)
    case noData
    case sslPinningFailed
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
        case .sslPinningFailed:
            return "SSL certificate validation failed."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

struct EmptyResponse: Decodable {}

struct AuthTokenProvider {
    static var token: String?
}

// MARK: - SSL Pinning Delegate
class SSLPinningDelegate: NSObject, URLSessionDelegate {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "SSLPinning")

    // Allowed hosts for SSL pinning
    private let pinnedHosts = [
        "cleanplate-production.up.railway.app",
        "cleanplate-cleanplate-pr-21.up.railway.app"
    ]

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Only apply pinning to our API hosts
        guard pinnedHosts.contains(host) || host.contains("railway.app") else {
            // For other hosts (like Apple APIs), use default handling
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Validate the certificate chain
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)

        if isValid {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            logger.info("SSL validation successful for \(host, privacy: .public)")
        } else {
            logger.error("SSL validation failed for \(host, privacy: .public): \(error?.localizedDescription ?? "Unknown error", privacy: .public)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

class APIService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "APIService")
    static var shared = APIService()

    // Custom URLSession with SSL pinning
    private let sslPinningDelegate = SSLPinningDelegate()
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        return URLSession(configuration: configuration, delegate: sslPinningDelegate, delegateQueue: nil)
    }()

    public init() {}
    private var baseURL: String {
        #if PREVIEW
        // For a new preview branch, just paste the new URL here.
        return "https://cleanplate-cleanplate-pr-21.up.railway.app"
        #else
        // Defaults to the production URL for all other builds.
        return "https://cleanplate-production.up.railway.app"
        #endif
    }
    
    // MARK: - Public API Methods
    
    func searchRestaurants(query: String, page: Int, perPage: Int, grade: String?, boro: String?, cuisine: String?, sort: String?) async throws -> [Restaurant] {
        var queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        
        if let grade = grade, !grade.isEmpty { queryItems.append(URLQueryItem(name: "grade", value: grade)) }
        if let boro = boro, !boro.isEmpty { queryItems.append(URLQueryItem(name: "boro", value: boro)) }
        if let cuisine = cuisine, !cuisine.isEmpty { queryItems.append(URLQueryItem(name: "cuisine", value: cuisine)) }
        if let sort = sort, !sort.isEmpty { queryItems.append(URLQueryItem(name: "sort", value: sort)) }
        
        return try await buildAndPerformRequest(path: "/search", queryItems: queryItems)
    }
    
    func fetchRecentActions() async throws -> RecentActionsResponse {
        return try await buildAndPerformRequest(path: "/lists/recent-actions")
    }
    
    func fetchRestaurantDetails(camis: String) async throws -> Restaurant {
        return try await buildAndPerformRequest(path: "/restaurant/\(camis)")
    }
    
    func submitReport(camis: String, issueType: String, comments: String) async throws {
        let body: [String: Any] = ["camis": camis, "issue_type": issueType, "comments": comments]
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/report-issue", method: "POST", body: body)
    }

    func createUser(identityToken: String) async throws {
        let body: [String: Any] = ["identityToken": identityToken]
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/users", method: "POST", body: body)
    }

    func addFavorite(camis: String, token: String) async throws {
        let body: [String: Any] = ["camis": camis]
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/favorites", method: "POST", body: body, token: token)
    }

    func removeFavorite(camis: String, token: String) async throws {
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/favorites/\(camis)", method: "DELETE", token: token)
    }
    
    func deleteUser(token: String) async throws {
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/users", method: "DELETE", token: token)
    }

    func fetchFavorites(token: String) async throws -> [Restaurant] {
        return try await buildAndPerformRequest(path: "/favorites", method: "GET", token: token)
    }
    
    func saveRecentSearch(searchTerm: String, token: String) async throws {
        let body: [String: Any] = ["search_term": searchTerm]
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/recent-searches", method: "POST", body: body, token: token)
    }
    
    func fetchRecentSearches(token: String) async throws -> [RecentSearch] {
        return try await buildAndPerformRequest(path: "/recent-searches", method: "GET", token: token)
    }

    func clearRecentSearches(token: String) async throws {
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/recent-searches", method: "DELETE", token: token)
    }
    
    // MARK: - Private Helper Functions

    private func buildAndPerformRequest<T: Decodable>(path: String, method: String = "GET", queryItems: [URLQueryItem]? = nil, body: [String: Any]? = nil, token: String? = nil) async throws -> T {
        guard var components = URLComponents(string: baseURL) else { throw APIError.invalidURL }
        components.path = path
        if let queryItems = queryItems { components.queryItems = queryItems.isEmpty ? nil : queryItems }
        guard let url = components.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        logger.info("Requesting URL: \(url.absoluteString, privacy: .public)")
        return try await performRequest(request: request)
    }

    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.unknown }
        guard (200...299).contains(httpResponse.statusCode) else { throw APIError.serverError(httpResponse.statusCode) }
        if T.self == EmptyResponse.self { return EmptyResponse() as! T }
        
        do {
            let decoder = JSONDecoder()
            // This date decoding strategy is important for handling the format from PostgreSQL
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("JSON decoding error from \(request.url?.absoluteString ?? "N/A", privacy: .public): \(error.localizedDescription, privacy: .public)")
            if let rawString = String(data: data, encoding: .utf8) { logger.error("Raw data on decoding error: \(rawString.prefix(500), privacy: .public)") }
            throw APIError.decodingError(error)
        }
    }
}
