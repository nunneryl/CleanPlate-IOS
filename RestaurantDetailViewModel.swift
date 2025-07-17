// In file: RestaurantDetailViewModel.swift

import SwiftUI
import os
import FirebaseAnalytics

@MainActor
class RestaurantDetailViewModel: ObservableObject {
    let restaurant: Restaurant
    let name: String
    let formattedAddress: String
    let cuisine: String?
    let shareableText: String
    let addressURL: URL?
    let inspections: [Inspection]
    let headerStatus: (imageName: String, text: String)
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "RestaurantDetailViewModel")

    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        self.name = restaurant.dba ?? "Restaurant Name"
        self.formattedAddress = Self.formatAddress(for: restaurant)
        let status = Self.calculateCurrentDisplayStatus(for: restaurant)
        self.cuisine = restaurant.cuisine_description == "N/A" ? nil : restaurant.cuisine_description
        self.headerStatus = (imageName: Self.gradeImageName(for: status), text: status)
        self.shareableText = Self.buildShareableText(name: self.name, status: status)
        self.addressURL = Self.buildAddressURL(from: self.formattedAddress)
        self.inspections = restaurant.inspections?.sorted {
            guard let date1 = $0.inspection_date, let date2 = $1.inspection_date else { return false }
            return date1 > date2
        } ?? []
    }
    
    func submitReport(issueType: ReportIssueView.IssueType, comments: String) {
        guard let camis = self.restaurant.camis else {
            // This logger is from the class scope, it should be available
            logger.error("Cannot submit report, restaurant CAMIS is missing.")
            return
        }
        
        logger.info("Submitting issue report...")
        
        Task {
            do {
                try await APIService.shared.submitReport(
                    camis: camis,
                    issueType: issueType.rawValue,
                    comments: comments
                )
                logger.info("Report submission successful.")
                
                // Log the successful submission to Firebase
                Analytics.logEvent("submit_issue_report", parameters: [
                    "issue_type": issueType.rawValue,
                    "has_comments": !comments.isEmpty,
                    AnalyticsParameterItemID: camis // Using standard Firebase parameter
                ])
                
            } catch {
                logger.error("Report submission failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    
    func onAppear() {
        // ReviewManager.shared.requestReviewIfAppropriate()
        logger.info("RestaurantDetailView appeared for \(self.name)")
        Analytics.logEvent(AnalyticsEventViewItem, parameters: [
            AnalyticsParameterItemID: self.restaurant.camis ?? "unknown",
            AnalyticsParameterItemName: self.name,
            AnalyticsParameterItemCategory: self.restaurant.cuisine_description ?? "N/A",
            "restaurant_boro": self.restaurant.boro ?? "N/A"
        ])
    }
    
    func formattedGrade(_ gradeCode: String?) -> String {
        guard let grade = gradeCode, !grade.isEmpty else { return "Not Graded" }
        switch grade {
        case "A", "B", "C": return "Grade \(grade)"
        case "Z": return "Grade Pending"
        case "P": return "Grade Pending (Re-opening)"
        case "N": return "Not Yet Graded"
        default: return "N/A"
        }
    }

    func gradeColor(for grade: String) -> Color {
        switch grade {
        case "A": return .blue
        case "B": return .green
        case "C": return .orange
        case "Z", "P", "N": return .gray
        default: return .gray
        }
    }

    private static func formatAddress(for restaurant: Restaurant) -> String {
        [restaurant.building, restaurant.street, restaurant.boro, restaurant.zipcode]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
    
    private static func calculateCurrentDisplayStatus(for restaurant: Restaurant) -> String {
        let sortedInspections = restaurant.inspections?.sorted(by: {
            guard let date1 = $0.inspection_date, let date2 = $1.inspection_date else { return false }
            return date1 > date2
        }) ?? []
        guard let latestInspection = sortedInspections.first else { return "Not_Graded" }
        if let action = latestInspection.action?.lowercased(), action.contains("closed by dohmh") { return "Closed" }
        if let grade = latestInspection.grade, ["Z", "P"].contains(grade) { return "Grade_Pending" }
        if let graded = sortedInspections.first(where: { ["A", "B", "C"].contains($0.grade ?? "") }) { return graded.grade ?? "Grade_Pending" }
        if sortedInspections.contains(where: { $0.grade == "N" }) == true { return "Not_Graded" }
        return "Grade_Pending"
    }

    private static func gradeImageName(for status: String) -> String {
        switch status {
        case "A": return "Grade_A"
        case "B": return "Grade_B"
        case "C": return "Grade_C"
        case "Grade_Pending": return "Grade_Pending"
        case "Closed": return "closed_down"
        default: return "Not_Graded"
        }
    }
    
    private static func buildShareableText(name: String, status: String) -> String {
        let appStoreLink = "Download CleanPlate to search for any restaurant in NYC: https://apps.apple.com/us/app/cleanplate-nyc/id6745222863"
        let statusText: String
        switch status {
        case "A", "B", "C": statusText = "a New York City Department of Health Restaurant Inspection Grade \(status)"
        case "Grade_Pending": statusText = "a Grade Pending status"
        case "Closed": statusText = "a Closed by DOHMH status"
        default: statusText = "a 'Not Graded' status"
        }
        return "Here's the latest NYC health grade for \(name) via the CleanPlate app:\n\nIt currently has \(statusText).\n\nNew to CleanPlate? \(appStoreLink)"
    }
    
    private static func buildAddressURL(from address: String) -> URL? {
        guard let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "http://maps.apple.com/?q=\(encodedAddress)")
    }
}
