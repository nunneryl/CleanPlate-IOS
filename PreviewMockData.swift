// In PreviewMockData.swift

import Foundation

#if DEBUG
// This struct holds our sample data for previews and screenshots.
struct PreviewMockData {

    // A list of mock restaurants for creating screenshots.
    static let mockRestaurants: [Restaurant] = [
        // 1. Neighborhood Cafe
        Restaurant(
            camis: "11111111",
            dba: "Neighborhood Cafe",
            boro: "Manhattan",
            building: "123",
            street: "Fictional Ave",
            zipcode: "10011",
            phone: "2125551111",
            latitude: 40.7400,
            longitude: -74.0000,
            cuisine_description: "Cafe/Variety",
            grade_date: nil,
            inspections: [
                Inspection(inspection_date: "2025-05-20T00:00:00", critical_flag: "Not Critical", grade: "A", inspection_type: "Cycle Inspection / Initial Inspection", violations: []),
                Inspection(inspection_date: "2024-04-15T00:00:00", critical_flag: "Critical", grade: "B", inspection_type: "Cycle Inspection / Re-inspection", violations: [
                    Violation(violation_code: "04L", violation_description: "Evidence of mice or live mice present in facility's food and/or non-food areas."),
                    Violation(violation_code: "02B", violation_description: "Hot food item not held at or above 140º F.")
                ])
            ]
        ),
        // 2. Downtown Diner
        Restaurant(
            camis: "22222222",
            dba: "Downtown Diner",
            boro: "Brooklyn",
            building: "456",
            street: "Sample St",
            zipcode: "11201",
            phone: "2125552222",
            latitude: 40.7027,
            longitude: -73.9906,
            cuisine_description: "American Diner",
            grade_date: nil,
            inspections: [
                Inspection(inspection_date: "2025-06-10T00:00:00", critical_flag: "Critical", grade: "C", inspection_type: "Cycle Inspection / Initial Inspection", violations: [
                    Violation(violation_code: "08A", violation_description: "Facility not vermin proof."),
                    Violation(violation_code: "06C", violation_description: "Food not protected from potential source of contamination."),
                    Violation(violation_code: "02G", violation_description: "Cold food item held above 41° F.")
                ])
            ]
        ),
        // 3. Test Kitchen
        Restaurant(
            camis: "33333333",
            dba: "Test Kitchen",
            boro: "Queens",
            building: "789",
            street: "Example Blvd",
            zipcode: "11101",
            phone: "2125553333",
            latitude: 40.7447,
            longitude: -73.9485,
            cuisine_description: "Fusion",
            grade_date: nil,
            inspections: []
        ),
        // 4. City Bistro (No Grade Yet)
        Restaurant(
            camis: "44444444",
            dba: "City Bistro (No Grade Yet)",
            boro: "Manhattan",
            building: "101",
            street: "Any St",
            zipcode: "10023",
            phone: "2125554444",
            latitude: 40.7789,
            longitude: -73.9815,
            cuisine_description: "New American",
            grade_date: nil,
            inspections: [
                Inspection(inspection_date: "2025-06-25T00:00:00", critical_flag: "Not Applicable", grade: "N", inspection_type: "Pre-permit (Operational) / Initial Inspection", violations: [])
            ]
        ),
        // 5. Pizza Place Example
        Restaurant(
            camis: "55555555",
            dba: "Pizza Place Example",
            boro: "Bronx",
            building: "212",
            street: "Pizza Pl",
            zipcode: "10458",
            phone: "2125555555",
            latitude: 40.8560,
            longitude: -73.8837,
            cuisine_description: "Pizza",
            grade_date: nil,
            inspections: [
                Inspection(inspection_date: "2025-03-01T00:00:00", critical_flag: "Not Critical", grade: "A", inspection_type: "Cycle Inspection / Initial Inspection", violations: [])
            ]
        )
    ]
}
#endif
