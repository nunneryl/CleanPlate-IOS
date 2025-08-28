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
    let update_type: String?
    let activity_date: String?

    var id: String { camis ?? UUID().uuidString }

    // In file: Models.swift

    var relativeGradeDate: String {
        // Use the new activity_date for finalized grades for correct timing, but always use the "Graded" prefix.
        let dateStringToUse = (update_type == "finalized") ? self.activity_date : self.grade_date
        let prefix = "Graded"
        
        guard let dateStr = dateStringToUse, let date = DateHelper.parseDate(dateStr) else {
            return "Not Yet Graded"
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "\(prefix) today" }
        if calendar.isDateInYesterday(date) { return "\(prefix) yesterday" }
        
        let components = calendar.dateComponents([.day], from: date, to: Date())
        if let day = components.day, day < 30 {
            return "\(prefix) \(day + 1) days ago"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(prefix) on \(formatter.string(from: date))"
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

struct RecentActionsResponse: Codable {
    let recently_closed: [Restaurant]
    let recently_reopened: [Restaurant]
}

// Represents a single recent search item returned from the API.
struct RecentSearch: Codable, Identifiable, Equatable {
    let id: Int
    let search_term_display: String
    let created_at: String
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
        for dateFormat in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ", "MM/dd/yyyy", "yyyy-MM-dd", "E, dd MMM yyyy HH:mm:ss z"] {
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
    
    var mostRecentInspectionGrade: String? {
        return inspections?
            .sorted {
                guard let date1 = $0.inspection_date, let date2 = $1.inspection_date else { return false }
                return date1 > date2
            }
            .first?
            .grade
    }
    
    var displayGradeImageName: String {
        let sortedInspections = inspections?.sorted(by: {
            guard let date1 = DateHelper.parseDate($0.inspection_date),
                  let date2 = DateHelper.parseDate($1.inspection_date) else { return false }
            return date1 > date2
        }) ?? []
        
        guard let latestInspection = sortedInspections.first else {
            return "Not_Graded"
        }
        
        if let action = latestInspection.action?.lowercased(), action.contains("closed by dohmh") {
            return "closed_down"
        }
        
        if let grade = latestInspection.grade {
            switch grade {
            case "A": return "Grade_A"
            case "B": return "Grade_B"
            case "C": return "Grade_C"
            case "Z", "P": return "Grade_Pending"
            case "N": return "Not_Graded"
            default: return "Grade_Pending"
            }
        } else {
            return "Grade_Pending"
        }
    }
}
