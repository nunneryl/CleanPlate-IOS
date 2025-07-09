// MARK: - UPDATED FILE: Models.swift

import Foundation

struct Restaurant: Identifiable, Codable, Equatable {
    let camis: String?
    let dba: String?
    let boro: String?
    let building: String?
    let street: String?
    let zipcode: String?
    let phone: String?
    let latitude: Double?
    let longitude: Double?
    let cuisine_description: String?
    let grade_date: String?
    let inspections: [Inspection]?

    var id: String { camis ?? UUID().uuidString }
    
    // --- NEW COMPUTED PROPERTY ADDED HERE ---
    var relativeGradeDate: String {
        guard let dateStr = self.grade_date, let date = DateHelper.parseDate(dateStr) else {
            return ""
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Graded today"
        } else if calendar.isDateInYesterday(date) {
            return "Graded yesterday"
        } else {
            let components = calendar.dateComponents([.day], from: date, to: Date())
            if let day = components.day {
                return "Graded \(day + 1) days ago"
            }
        }
        return ""
    }
    
    // The rest of your helper functions remain unchanged
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

// --- The rest of the file (Inspection, Violation, DateHelper) remains unchanged ---

struct Inspection: Identifiable, Codable, Equatable {
    var id: String { inspection_date ?? UUID().uuidString }
    let inspection_date: String?
    let critical_flag: String?
    let grade: String?
    let inspection_type: String?
    let action: String?
    let violations: [Violation]?
    
    var formattedDate: String {
        DateHelper.formatDate(inspection_date)
    }
    
    var hasCriticalViolations: Bool {
        critical_flag?.lowercased() == "critical"
    }
}

struct Violation: Identifiable, Codable, Equatable {
    var id: String { violation_code ?? UUID().uuidString }
    let violation_code: String?
    let violation_description: String?
}

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
        // Expanded to handle grade_date format which might be 'yyyy-MM-dd'
        for dateFormat in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd", "E, dd MMM yyyy HH:mm:ss z"] {
            formatter.dateFormat = dateFormat
            if let date = formatter.date(from: dateStr) {
                return date
            }
        }
        return nil
    }
}
