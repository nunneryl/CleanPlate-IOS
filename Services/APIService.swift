// In file: APIService.swift

import Foundation
import os
import Security

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(Int)
    case decodingError(Error)
    case noData
    case sslPinningFailed
    case unknown
    case validationError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to connect to the server."
        case .networkError:
            return "Network connection failed. Please check your internet connection and try again."
        case .serverError(let code):
            if code >= 500 {
                return "The server is temporarily unavailable. Please try again later."
            } else if code == 401 {
                return "Your session has expired. Please sign in again."
            } else if code == 404 {
                return "The requested information could not be found."
            } else {
                return "An error occurred (Code: \(code)). Please try again."
            }
        case .decodingError:
            return "Unable to process the server response. Please try again."
        case .noData:
            return "No data was received. Please try again."
        case .sslPinningFailed:
            return "SSL certificate validation failed. Please ensure you have a secure connection."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        case .validationError(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your Wi-Fi or cellular connection."
        case .serverError(let code) where code >= 500:
            return "The CleanPlate team has been notified."
        case .serverError(401):
            return "Go to Profile and sign in again."
        case .sslPinningFailed:
            return "Try connecting from a different network."
        default:
            return nil
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

// MARK: - Input Validation

enum ValidationError: LocalizedError {
    case emptyInput
    case inputTooLong(max: Int)
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Please enter a search term."
        case .inputTooLong(let max):
            return "Input is too long (maximum \(max) characters)."
        case .invalidFormat:
            return "Input contains invalid characters."
        }
    }
}

private struct InputValidator {
    static let maxSearchLength = 200
    static let maxCommentsLength = 2000
    static let maxCamisLength = 10

    static func validateSearchTerm(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ValidationError.emptyInput }
        guard trimmed.count <= maxSearchLength else { throw ValidationError.inputTooLong(max: maxSearchLength) }
        return trimmed
    }

    static func validateCamis(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ValidationError.emptyInput }
        guard trimmed.count <= maxCamisLength else { throw ValidationError.inputTooLong(max: maxCamisLength) }
        guard trimmed.allSatisfy({ $0.isNumber }) else { throw ValidationError.invalidFormat }
        return trimmed
    }

    static func validateComments(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= maxCommentsLength else { throw ValidationError.inputTooLong(max: maxCommentsLength) }
        return trimmed
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
        return Config.apiBaseURL
    }

    // MARK: - Public API Methods

    func searchRestaurants(query: String, page: Int, perPage: Int, grade: String?, boro: String?, cuisine: String?, sort: String?) async throws -> [Restaurant] {
        let validatedQuery = try InputValidator.validateSearchTerm(query)
        var queryItems = [
            URLQueryItem(name: "name", value: validatedQuery),
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
        let validatedCamis = try InputValidator.validateCamis(camis)
        return try await buildAndPerformRequest(path: "/restaurant/\(validatedCamis)")
    }

    func submitReport(camis: String, issueType: String, comments: String) async throws {
        let validatedCamis = try InputValidator.validateCamis(camis)
        let validatedComments = try InputValidator.validateComments(comments)
        let body: [String: Any] = ["camis": validatedCamis, "issue_type": issueType, "comments": validatedComments]
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/report-issue", method: "POST", body: body)
    }

    func createUser(identityToken: String) async throws {
        let body: [String: Any] = ["identityToken": identityToken]
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/users", method: "POST", body: body)
    }

    func addFavorite(camis: String, token: String) async throws {
        let validatedCamis = try InputValidator.validateCamis(camis)
        let body: [String: Any] = ["camis": validatedCamis]
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/favorites", method: "POST", body: body, token: token)
    }

    func removeFavorite(camis: String, token: String) async throws {
        let validatedCamis = try InputValidator.validateCamis(camis)
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/favorites/\(validatedCamis)", method: "DELETE", token: token)
    }

    func deleteUser(token: String) async throws {
        let _: EmptyResponse = try await buildAndPerformRequest(path: "/users", method: "DELETE", token: token)
    }

    func fetchFavorites(token: String) async throws -> [Restaurant] {
        return try await buildAndPerformRequest(path: "/favorites", method: "GET", token: token)
    }

    func saveRecentSearch(searchTerm: String, token: String) async throws {
        let validatedTerm = try InputValidator.validateSearchTerm(searchTerm)
        let body: [String: Any] = ["search_term": validatedTerm]
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

    private func performRequestWithRetry<T: Decodable>(request: URLRequest, maxRetries: Int = 3) async throws -> T {
        var lastError: Error = APIError.unknown

        for attempt in 0..<maxRetries {
            do {
                return try await performRequest(request: request)
            } catch let error as APIError {
                lastError = error

                // Only retry on network errors or 5xx server errors
                switch error {
                case .networkError, .sslPinningFailed:
                    if attempt < maxRetries - 1 {
                        let delay = pow(2.0, Double(attempt))
                        logger.info("Retry attempt \(attempt + 1) after \(delay)s delay")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                case .serverError(let code) where code >= 500:
                    if attempt < maxRetries - 1 {
                        let delay = pow(2.0, Double(attempt))
                        logger.info("Retry attempt \(attempt + 1) after \(delay)s delay")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }

                default:
                    throw error // Don't retry client errors (4xx) or other errors
                }
            } catch {
                lastError = error
                throw error
            }
        }

        throw lastError
    }


    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .serverCertificateUntrusted ||
               urlError.code == .secureConnectionFailed ||
               urlError.code == .serverCertificateHasBadDate ||
               urlError.code == .serverCertificateNotYetValid {
                throw APIError.sslPinningFailed
            }
            throw APIError.networkError(urlError)
        } catch {
            throw APIError.networkError(error)
        }

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
