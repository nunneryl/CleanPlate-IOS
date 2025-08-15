// In file: KeychainHelper.swift

import Foundation

struct KeychainHelper {
    // Service and account names for the User ID
    private static let userIDService = "com.CleanPlateNYC.userID"
    private static let userAccount = "currentUser"

    // Service and account names for the Identity Token
    private static let tokenService = "com.CleanPlateNYC.token"
    private static let tokenAccount = "currentUserToken"

    // MARK: - User ID Management
    
    static func save(userID: String) throws {
        try saveData(data: Data(userID.utf8), service: userIDService, account: userAccount)
    }

    static func getUserID() -> String? {
        guard let data = readData(service: userIDService, account: userAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteUserID() throws {
        try deleteData(service: userIDService, account: userAccount)
    }
    
    // MARK: - Identity Token Management

    static func save(token: String) throws {
        try saveData(data: Data(token.utf8), service: tokenService, account: tokenAccount)
    }

    static func getToken() -> String? {
        guard let data = readData(service: tokenService, account: tokenAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteToken() throws {
        try deleteData(service: tokenService, account: tokenAccount)
    }

    // MARK: - Private Generic Helpers

    private static func saveData(data: Data, service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete any existing item to ensure we are replacing it
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    private static func readData(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }

    private static func deleteData(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}
