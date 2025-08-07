// In file: Models.swift

import Foundation
import SwiftUI

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
    let foursquare_fsq_id: String?
    let google_place_id: String?
    let inspections: [Inspection]?

    var id: String { camis ?? UUID().uuidString }

    var relativeGradeDate: String {
        guard let dateStr = self.grade_date, let date = DateHelper.parseDate(dateStr) else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Graded today" }
        if calendar.isDateInYesterday(date) { return "Graded yesterday" }
        let components = calendar.dateComponents([.day], from: date, to: Date())
        if let day = components.day { return "Graded \(day + 1) days ago" }
        return ""
    }
    
    func fullAddress() -> String {
        [building, street, boro, zipcode].compactMap { $0 }.joined(separator: ", ")
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

    var formattedStreet: String {
        guard let street = street else { return "" }
        var formatted = street
        if formatted.lowercased().contains("avenue") {
            formatted = formatted.replacingOccurrences(of: "AVENUE", with: "Ave", options: .caseInsensitive)
        }
        if formatted.lowercased().contains("street") {
            formatted = formatted.replacingOccurrences(of: "STREET", with: "St", options: .caseInsensitive)
        }
        return formatted
    }
    
    var formattedBoro: String {
        return boro?.capitalized ?? ""
    }
}

struct Inspection: Identifiable, Codable, Equatable {
    var id: String { inspection_date ?? UUID().uuidString }
    let inspection_date: String?
    let critical_flag: String?
    let grade: String?
    let inspection_type: String?
    let action: String?
    let violations: [Violation]?
    
    var formattedDate: String { DateHelper.formatDate(inspection_date) }
    var hasCriticalViolations: Bool { critical_flag?.lowercased() == "critical" }
    

    var displayGradeText: String {
        guard let grade = self.grade, !grade.isEmpty else {
            return "Not Graded"
        }
        switch grade {
            case "A", "B", "C": return "Grade \(grade)"
            case "Z": return "Grade Pending"
            case "P": return "Grade Pending (Re-opening)"
            case "N": return "Not Yet Graded"
            default: return "N/A"
        }
    }
    
    var displayGradeColor: Color {
        guard let grade = self.grade else { return .gray }
        switch grade {
            case "A": return .blue
            case "B": return .green
            case "C": return .orange
            case "Z", "P", "N": return .gray
            default: return .gray
        }
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
        // CORRECTED: Added the "MM/dd/yyyy" format to the list of formats to try.
        for dateFormat in ["yyyy-MM-dd'T'HH:mm:ss", "MM/dd/yyyy", "yyyy-MM-dd", "E, dd MMM yyyy HH:mm:ss z"] {
            formatter.dateFormat = dateFormat
            if let date = formatter.date(from: dateStr) {
                return date
            }
        }
        return nil
    }
}

extension Restaurant {
    var latestFinalGrade: String? {
        return inspections?
            .sorted {
                guard let date1 = $0.inspection_date, let date2 = $1.inspection_date else { return false }
                return date1 > date2
            }
            .first { ["A", "B", "C"].contains($0.grade ?? "") }?
            .grade
    }
}
