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
    let finalized_date: String?

    var id: String { camis ?? UUID().uuidString }

    var relativeGradeDate: String {
            // Prioritize the finalized_date for "Updated from Pending" events.
            // Fall back to the inspection's date for all other cases.
            let dateStringToUse = self.finalized_date ?? self.displayInspection?.inspection_date
            
            guard let dateStr = dateStringToUse, let date = DateHelper.parseDate(dateStr) else {
                return "Not Yet Graded"
            }

            // Use a friendly prefix. For finalized dates, it reads better.
            let prefix = self.finalized_date != nil ? "Updated" : "Graded"
            let calendar = Calendar.current
            
            if calendar.isDateInToday(date) { return "\(prefix) today" }
            if calendar.isDateInYesterday(date) { return "\(prefix) yesterday" }
            
            let components = calendar.dateComponents([.day], from: date, to: Date())
            if let day = components.day, day >= 0 && day < 7 {
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
    let recently_graded: [Restaurant]
    let recently_closed: [Restaurant]
    let recently_reopened: [Restaurant]
}

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
    
    /// The sorted list of inspections, from most recent to oldest.
    private var sortedInspections: [Inspection] {
        inspections?.sorted(by: {
            guard let date1 = DateHelper.parseDate($0.inspection_date),
                  let date2 = DateHelper.parseDate($1.inspection_date) else { return false }
            return date1 > date2
        }) ?? []
    }
    
    /// The single most recent inspection record.
    var mostRecentInspection: Inspection? {
        return sortedInspections.first
    }
    
    /// The single inspection that should be displayed to the user, applying the fallback logic.
    var displayInspection: Inspection? {
        guard let latest = mostRecentInspection else { return nil }
        
        // If the latest inspection's grade is blank (nil or empty)...
        if latest.grade == nil || latest.grade?.isEmpty == true {
            // ...then search for the next most recent inspection that HAS a grade.
            return sortedInspections.first { insp in
                let g = insp.grade
                return g != nil && g?.isEmpty == false
            }
        }
        
        // Otherwise, just use the latest inspection.
        return latest
    }
        
    /// The grade from the inspection that should be displayed.
    var displayGrade: String? {
        displayInspection?.grade
    }

    /// The date from the inspection that should be displayed.
    var displayInspectionDate: String? {
        displayInspection?.inspection_date
    }

    var relativeActionDate: String {
            guard let inspection = mostRecentInspection,
                  let actionText = inspection.action?.lowercased(),
                  let dateStr = inspection.inspection_date,
                  let date = DateHelper.parseDate(dateStr) else {
                return "Status date not available"
            }

            let prefix: String
            if actionText.contains("closed") {
                prefix = "Closed"
            } else if actionText.contains("re-opened") {
                prefix = "Re-opened"
            } else {
                // Fallback for any unexpected action text
                return "Status updated \(DateHelper.formatDate(dateStr))"
            }
            
            let calendar = Calendar.current
            if calendar.isDateInToday(date) { return "\(prefix) today" }
            if calendar.isDateInYesterday(date) { return "\(prefix) yesterday" }
            
            let components = calendar.dateComponents([.day], from: date, to: Date())
            if let day = components.day, day >= 0 && day < 30 {
                if day == 0 { return "\(prefix) today" }
                return "\(prefix) \(day + 1) days ago"
            }
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(prefix) on \(formatter.string(from: date))"
        }
    
    var displayGradeImageName: String {
        if let latestAction = mostRecentInspection?.action?.lowercased(), latestAction.contains("closed by dohmh") {
            return "closed_down"
        }
        
        guard let inspectionToDisplay = displayInspection else {
            return "Not_Graded"
        }
        
        if let grade = inspectionToDisplay.grade {
            switch grade {
            case "A": return "Grade_A"
            case "B": return "Grade_B"
            case "C": return "Grade_C"
            case "Z", "P": return "Grade_Pending"
            case "N": return "Not_Graded"
            default: return "Grade_Pending"
            }
        } else {
            return "Not_Graded"
        }
    }
}
