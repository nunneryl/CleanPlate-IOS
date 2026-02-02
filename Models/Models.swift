// In file: Models.swift

import Foundation
import SwiftUI

struct Restaurant: Identifiable, Equatable {
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
    let grade: String?  // Top-level grade for list views
    let grade_date: String?
    let foursquare_fsq_id: String?
    let google_place_id: String?
    let inspections: [Inspection]?
    let update_type: String?
    let activity_date: String?
    let finalized_date: String?

    // Google enrichment data
    let google_rating: Double?
    let google_review_count: Int?
    let website: String?
    let hours: OpeningHours?
    let price_level: String?

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


// MARK: - Restaurant Codable Conformance
extension Restaurant: Codable {
    enum CodingKeys: String, CodingKey {
        case camis, dba, boro, building, street, zipcode, phone
        case latitude, longitude, cuisine_description
        case grade, grade_date
        case foursquare_fsq_id, google_place_id
        case inspections, update_type, activity_date, finalized_date
        case google_rating, google_review_count, website, hours, price_level
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        camis = try container.decodeIfPresent(String.self, forKey: .camis)
        dba = try container.decodeIfPresent(String.self, forKey: .dba)
        boro = try container.decodeIfPresent(String.self, forKey: .boro)
        building = try container.decodeIfPresent(String.self, forKey: .building)
        street = try container.decodeIfPresent(String.self, forKey: .street)
        zipcode = try container.decodeIfPresent(String.self, forKey: .zipcode)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        cuisine_description = try container.decodeIfPresent(String.self, forKey: .cuisine_description)
        grade = try container.decodeIfPresent(String.self, forKey: .grade)
        grade_date = try container.decodeIfPresent(String.self, forKey: .grade_date)
        foursquare_fsq_id = try container.decodeIfPresent(String.self, forKey: .foursquare_fsq_id)
        google_place_id = try container.decodeIfPresent(String.self, forKey: .google_place_id)
        inspections = try container.decodeIfPresent([Inspection].self, forKey: .inspections)
        update_type = try container.decodeIfPresent(String.self, forKey: .update_type)
        activity_date = try container.decodeIfPresent(String.self, forKey: .activity_date)
        finalized_date = try container.decodeIfPresent(String.self, forKey: .finalized_date)
        
        // Handle google_rating which might come as Double or String from the backend
        if let rating = try? container.decodeIfPresent(Double.self, forKey: .google_rating) {
            google_rating = rating
        } else if let ratingString = try? container.decodeIfPresent(String.self, forKey: .google_rating),
                  let rating = Double(ratingString) {
            google_rating = rating
        } else {
            google_rating = nil
        }
        
        google_review_count = try container.decodeIfPresent(Int.self, forKey: .google_review_count)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        hours = try container.decodeIfPresent(OpeningHours.self, forKey: .hours)
        price_level = try container.decodeIfPresent(String.self, forKey: .price_level)
    }
}

struct Inspection: Identifiable, Codable, Equatable {
    var id: String { inspection_date ?? UUID().uuidString }
    let inspection_date: String?
    let critical_flag: String?
    let grade: String?
    let grade_date: String?
    let score: Int?
    let inspection_type: String?
    let action: String?
    let violations: [Violation]?
    
    var formattedDate: String { DateHelper.formatDate(inspection_date) }
    var hasCriticalViolations: Bool { critical_flag?.lowercased() == "critical" }
    
    /// Formatted score display
    var displayScore: String? {
        guard let score = score else { return nil }
        return "\(score) points"
    }
    
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

// MARK: - Google Hours Data
struct OpeningHours: Equatable {
    let openNow: Bool?
    let periods: [Period]?
    let weekdayDescriptions: [String]?

    struct Period: Codable, Equatable {
        let open: TimePoint?
        let close: TimePoint?

        struct TimePoint: Codable, Equatable {
            let day: Int?
            let hour: Int?
            let minute: Int?
        }
    }
}

// Custom Codable for OpeningHours to handle various Google API response formats
extension OpeningHours: Codable {
    enum CodingKeys: String, CodingKey {
        case openNow
        case periods
        case weekdayDescriptions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        openNow = try container.decodeIfPresent(Bool.self, forKey: .openNow)
        periods = try container.decodeIfPresent([Period].self, forKey: .periods)
        weekdayDescriptions = try container.decodeIfPresent([String].self, forKey: .weekdayDescriptions)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(openNow, forKey: .openNow)
        try container.encodeIfPresent(periods, forKey: .periods)
        try container.encodeIfPresent(weekdayDescriptions, forKey: .weekdayDescriptions)
    }
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
    /// Falls back to top-level grade for list views (Grade Updates).
    var displayGrade: String? {
        displayInspection?.grade ?? self.grade
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
    
    /// Returns "Grade updated X days ago" text ONLY for B/C restaurants from the recently graded list.
    /// A grades don't need this since they're assigned same day as inspection.
    var gradeUpdatedLabel: String? {
        // Only show for restaurants from the recently graded list (update_type is set)
        guard update_type != nil else { return nil }

        // Only show for B or C grades (A grades are assigned immediately)
        guard let currentGrade = displayGrade, currentGrade == "B" || currentGrade == "C" else { return nil }

        // Use grade_date for the label
        guard let dateStr = grade_date, let date = DateHelper.parseDate(dateStr) else { return nil }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Grade updated today" }
        if calendar.isDateInYesterday(date) { return "Grade updated yesterday" }

        let components = calendar.dateComponents([.day], from: date, to: Date())
        if let day = components.day, day >= 0 {
            if day == 0 { return "Grade updated today" }
            return "Grade updated \(day + 1) days ago"
        }

        return nil
    }

    var displayGradeImageName: String {
        if let latestAction = mostRecentInspection?.action?.lowercased(), latestAction.contains("closed by dohmh") {
            return "closed_down"
        }

        // Try inspection grade first, fall back to top-level grade for list views
        let gradeToUse = displayInspection?.grade ?? self.grade

        guard let grade = gradeToUse, !grade.isEmpty else {
            return "Not_Graded"
        }

        switch grade {
        case "A": return "Grade_A"
        case "B": return "Grade_B"
        case "C": return "Grade_C"
        case "Z", "P": return "Grade_Pending"
        case "N": return "Not_Graded"
        default: return "Grade_Pending"
        }
    }

    // MARK: - Google Data Helpers

    /// Formats the price level as dollar signs (e.g., "$$")
    var displayPriceLevel: String? {
        guard let level = price_level else { return nil }
        switch level {
        case "PRICE_LEVEL_FREE": return "Free"
        case "PRICE_LEVEL_INEXPENSIVE": return "$"
        case "PRICE_LEVEL_MODERATE": return "$$"
        case "PRICE_LEVEL_EXPENSIVE": return "$$$"
        case "PRICE_LEVEL_VERY_EXPENSIVE": return "$$$$"
        default: return nil
        }
    }

    /// Formatted rating string with star (e.g., "4.3 ★")
    var displayRating: String? {
        guard let rating = google_rating else { return nil }
        return String(format: "%.1f", rating)
    }

    /// Formatted review count (e.g., "(847 reviews)")
    var displayReviewCount: String? {
        guard let count = google_review_count, count > 0 else { return nil }
        if count == 1 {
            return "(1 review)"
        }
        return "(\(count) reviews)"
    }

    /// Whether the restaurant is currently open
    var isOpenNow: Bool? {
        return hours?.openNow
    }

    /// Status text for open/closed
    var openStatusText: String? {
        guard let isOpen = hours?.openNow else { return nil }
        return isOpen ? "Open now" : "Closed"
    }
    
    /// Returns the closing time for today (e.g., "9 PM")
    var closingTimeText: String? {
        guard let periods = hours?.periods, !periods.isEmpty else { return nil }
        
        // Get current day of week (1 = Sunday, 2 = Monday, ... 7 = Saturday)
        // Google uses 0 = Sunday, 1 = Monday, ... 6 = Saturday
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let googleWeekday = weekday - 1  // Convert to Google's format
        
        // Find today's period
        guard let todayPeriod = periods.first(where: { $0.open?.day == googleWeekday }),
              let closeTime = todayPeriod.close,
              let hour = closeTime.hour else {
            return nil
        }
        
        // Format the hour (e.g., 21 -> "9 PM")
        let hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let ampm = hour >= 12 ? "PM" : "AM"
        
        if let minute = closeTime.minute, minute > 0 {
            return "\(hour12):\(String(format: "%02d", minute)) \(ampm)"
        } else {
            return "\(hour12) \(ampm)"
        }
    }
}
