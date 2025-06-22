// MARK: - FULLY UPDATED AND CORRECTED FILE: Models.swift

import Foundation

// MARK: - Restaurant Model
struct Restaurant: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    // This is the main change. We now correctly handle that `camis` is a number (Int).
    // The `id` is then safely converted to a String to satisfy the `Identifiable` protocol.
    var id: String {
        if let camis = camis {
            return String(camis)
        }
        return UUID().uuidString
    }
    
    // We are changing camis from String? to Int? to match the backend JSON.
    let camis: Int?
    
    let dba: String?
    let boro: String?
    let building: String?
    let street: String?
    let zipcode: String?
    let phone: String?
    let latitude: Double?
    let longitude: Double?
    let cuisine_description: String?
    let inspections: [Inspection]?
    
    // MARK: - Methods
    
    func fullAddress() -> String {
        [building, street, boro, zipcode]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
    
    func formattedPhone() -> String {
        guard let phone = phone, phone.count >= 10 else { return "N/A" }
        
        let cleaned = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let index = cleaned.index(cleaned.startIndex, offsetBy: min(3, cleaned.count))
        let areaCode = cleaned[..<index]
        
        if cleaned.count >= 6 {
            let prefixEnd = cleaned.index(index, offsetBy: 3)
            let prefix = cleaned[index..<prefixEnd]
            
            let remainingStart = cleaned.index(prefixEnd, offsetBy: 0)
            let remaining = cleaned[remainingStart...]
            
            return "(\(areaCode)) \(prefix)-\(remaining)"
        } else if cleaned.count > 3 {
            let remaining = cleaned[index...]
            return "(\(areaCode)) \(remaining)"
        }
        
        return phone
    }
}

// MARK: - Inspection Model
struct Inspection: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    var id: String {
        if let date = inspection_date {
            return "\(date)-\(UUID().uuidString)"
        }
        return UUID().uuidString
    }
    
    let inspection_date: String?
    let critical_flag: String?
    let grade: String?
    let inspection_type: String?
    let violations: [Violation]?
    
    // MARK: - Computed Properties
    
    var formattedDate: String {
        DateHelper.formatDate(inspection_date)
    }
    
    var hasCriticalViolations: Bool {
        critical_flag?.lowercased() == "critical"
    }
}

// MARK: - Violation Model
struct Violation: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    var id: String {
        if let code = violation_code {
            return "\(code)-\(UUID().uuidString)"
        }
        return UUID().uuidString
    }
    
    let violation_code: String?
    let violation_description: String?
    
    // MARK: - Equatable
    
    static func == (lhs: Violation, rhs: Violation) -> Bool {
        lhs.violation_code == rhs.violation_code &&
        lhs.violation_description == rhs.violation_description
    }
}

// MARK: - Date Helper
struct DateHelper {
    static func formatDate(_ dateStr: String?) -> String {
        guard let dateStr = dateStr, let date = parseDate(dateStr) else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    static func parseDate(_ dateStr: String?) -> Date? {
        guard let dateStr = dateStr else { return nil }
        
        let formatter = DateFormatter()
        
        // Try different date formats
        for dateFormat in ["E, dd MMM yyyy HH:mm:ss z", "yyyy-MM-dd", "yyyy-MM-dd'T'HH:mm:ss"] {
            formatter.dateFormat = dateFormat
            if let date = formatter.date(from: dateStr) {
                return date
            }
        }
        
        return nil
    }
}
