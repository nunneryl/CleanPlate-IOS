// In file: PreviewMockData.swift

import Foundation

#if DEBUG
// This struct holds our sample data for previews and screenshots.
struct PreviewMockData {

    // A list of mock restaurants for creating screenshots.
    static let mockRestaurants: [Restaurant] = [
        // 1. Pizza Place Example - Graded Today
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
            grade_date: "2025-08-26",
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [
                Inspection(inspection_date: "2025-08-26T00:00:00", critical_flag: "Not Critical", grade: "A", inspection_type: "Cycle Inspection / Initial Inspection", action: nil, violations: [])
            ],
            // --- ADDED MISSING PARAMETERS ---
            update_type: nil,
            activity_date: nil
        ),
        // 2. Neighborhood Cafe - Graded Yesterday
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
            grade_date: "2025-08-25",
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [
                Inspection(inspection_date: "2025-08-25T00:00:00", critical_flag: "Not Critical", grade: "A", inspection_type: "Cycle Inspection / Initial Inspection", action: nil, violations: []),
                Inspection(inspection_date: "2024-04-15T00:00:00", critical_flag: "Critical", grade: "B", inspection_type: "Cycle Inspection / Re-inspection", action: nil, violations: [
                    Violation(violation_code: "04L", violation_description: "Evidence of mice or live mice present in facility's food and/or non-food areas."),
                    Violation(violation_code: "02B", violation_description: "Hot food item not held at or above 140º F.")
                ])
            ],
            update_type: nil,
            activity_date: nil
        ),
        // 3. Side Street Tacos - Graded 2 days ago
        Restaurant(
            camis: "66666666",
            dba: "Side Street Tacos",
            boro: "Queens",
            building: "333",
            street: "Taco Row",
            zipcode: "11102",
            phone: "2125556666",
            latitude: 40.7650,
            longitude: -73.9230,
            cuisine_description: "Tacos",
            grade_date: "2025-08-24",
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [
                Inspection(inspection_date: "2025-08-24T00:00:00", critical_flag: "Not Critical", grade: "B", inspection_type: "Cycle Inspection / Initial Inspection", action: nil, violations: [])
            ],
            update_type: nil,
            activity_date: nil
        ),
        // 4. Downtown Diner - Graded 3 days ago
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
            grade_date: "2025-08-23",
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [
                Inspection(inspection_date: "2025-08-23T00:00:00", critical_flag: "Critical", grade: "C", inspection_type: "Cycle Inspection / Initial Inspection", action: nil, violations: [
                    Violation(violation_code: "08A", violation_description: "Facility not vermin proof."),
                    Violation(violation_code: "06C", violation_description: "Food not protected from potential source of contamination."),
                    Violation(violation_code: "02G", violation_description: "Cold food item held above 41° F.")
                ])
            ],
            update_type: nil,
            activity_date: nil
        ),
        // 5. Uptown Grill - Graded 5 days ago
        Restaurant(
            camis: "77777777",
            dba: "Uptown Grill",
            boro: "Manhattan",
            building: "999",
            street: "Upper Ave",
            zipcode: "10028",
            phone: "2125557777",
            latitude: 40.7750,
            longitude: -73.9550,
            cuisine_description: "Steakhouse",
            grade_date: "2025-08-21",
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [
                Inspection(inspection_date: "2025-08-21T00:00:00", critical_flag: "Not Critical", grade: "A", inspection_type: "Cycle Inspection / Initial Inspection", action: nil, violations: [])
            ],
            update_type: nil,
            activity_date: nil
        ),
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
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [],
            update_type: nil,
            activity_date: nil
        ),
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
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [
                Inspection(inspection_date: "2025-08-15T00:00:00", critical_flag: "Not Applicable", grade: "N", inspection_type: "Pre-permit (Operational) / Initial Inspection", action: nil, violations: [])
            ],
            update_type: nil,
            activity_date: nil
        ),
        Restaurant(
            camis: "88888888",
            dba: "The Greasy Spoon",
            boro: "Brooklyn",
            building: "777",
            street: "Clogged Artery Ave",
            zipcode: "11221",
            phone: "2125558888",
            latitude: 40.6900,
            longitude: -73.9400,
            cuisine_description: "Diner",
            grade_date: "2025-08-20",
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [
                Inspection(inspection_date: "2025-08-25T00:00:00", critical_flag: "Critical", grade: "C", inspection_type: "Cycle Inspection / Initial Inspection", action: "Establishment Closed by DOHMH. Violations of public health law constitute an imminent health hazard.", violations: [
                     Violation(violation_code: "04L", violation_description: "Evidence of mice or live mice present in facility's food and/or non-food areas.")
                ])
            ],
            update_type: nil,
            activity_date: nil
        ),
        Restaurant(
            camis: "99999999",
            dba: "Sanitation Optional Sushi",
            boro: "Manhattan",
            building: "404",
            street: "Health Inspector's Folly",
            zipcode: "10003",
            phone: "2125559999",
            latitude: 40.7300,
            longitude: -73.9900,
            cuisine_description: "Sushi",
            grade_date: "2025-08-19",
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [
                Inspection(inspection_date: "2025-08-24T00:00:00", critical_flag: "Critical", grade: nil, inspection_type: "Cycle Inspection / Initial Inspection", action: "Establishment Closed by DOHMH.", violations: [
                    Violation(violation_code: "02G", violation_description: "Cold food item held above 41° F.")
                ])
            ],
            update_type: nil,
            activity_date: nil
        ),
        Restaurant(
            camis: "10101010",
            dba: "Forgotten Deli",
            boro: "Staten Island",
            building: "500",
            street: "Secluded Street",
            zipcode: "10301",
            phone: "2125551010",
            latitude: 40.6400,
            longitude: -74.0700,
            cuisine_description: "Deli",
            grade_date: "2025-08-18",
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [
                Inspection(inspection_date: "2025-08-23T00:00:00", critical_flag: "Critical", grade: "C", inspection_type: "Cycle Inspection / Re-inspection", action: "Establishment Closed by DOHMH due to imminent health hazard.", violations: [])
            ],
            update_type: nil,
            activity_date: nil
        )
    ]
}
#endif
