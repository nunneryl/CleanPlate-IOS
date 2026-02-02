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
            grade: "A",
            grade_date: "2025-08-26",
            foursquare_fsq_id: nil,
            google_place_id: "ChIJExample1",
            inspections: [
                Inspection(inspection_date: "2025-08-26T00:00:00", critical_flag: "Not Critical", grade: "A", grade_date: "2025-08-26", score: 8, inspection_type: "Cycle Inspection / Initial Inspection", action: nil, violations: [])
            ],
            update_type: nil,
            activity_date: nil,
            finalized_date: nil,
            google_rating: 4.7,
            google_review_count: 1243,
            website: "https://pizzaplaceexample.com",
            hours: OpeningHours(
                openNow: true,
                periods: [
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 0, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 0, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 1, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 1, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 2, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 2, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 3, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 3, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 4, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 4, hour: 23, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 5, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 5, hour: 23, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 6, hour: 12, minute: 0), close: OpeningHours.Period.TimePoint(day: 6, hour: 21, minute: 0))
                ],
                weekdayDescriptions: nil
            ),
            price_level: "PRICE_LEVEL_MODERATE"
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
            cuisine_description: "Cafe/Coffee/Tea",
            grade: "A",
            grade_date: "2025-08-25",
            foursquare_fsq_id: nil,
            google_place_id: "ChIJExample2",
            inspections: [
                Inspection(inspection_date: "2025-08-25T00:00:00", critical_flag: "Not Critical", grade: "A", grade_date: "2025-08-25", score: 5, inspection_type: "Cycle Inspection / Initial Inspection", action: nil, violations: []),
                Inspection(inspection_date: "2024-04-15T00:00:00", critical_flag: "Critical", grade: "B", grade_date: "2024-04-15", score: 18, inspection_type: "Cycle Inspection / Re-inspection", action: nil, violations: [
                    Violation(violation_code: "04L", violation_description: "Evidence of mice or live mice present in facility's food and/or non-food areas."),
                    Violation(violation_code: "02B", violation_description: "Hot food item not held at or above 140º F.")
                ])
            ],
            update_type: nil,
            activity_date: nil,
            finalized_date: nil,
            google_rating: 4.5,
            google_review_count: 876,
            website: "https://neighborhoodcafe.com",
            hours: OpeningHours(
                openNow: true,
                periods: [
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 0, hour: 7, minute: 0), close: OpeningHours.Period.TimePoint(day: 0, hour: 18, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 1, hour: 6, minute: 30), close: OpeningHours.Period.TimePoint(day: 1, hour: 19, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 2, hour: 6, minute: 30), close: OpeningHours.Period.TimePoint(day: 2, hour: 19, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 3, hour: 6, minute: 30), close: OpeningHours.Period.TimePoint(day: 3, hour: 19, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 4, hour: 6, minute: 30), close: OpeningHours.Period.TimePoint(day: 4, hour: 19, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 5, hour: 6, minute: 30), close: OpeningHours.Period.TimePoint(day: 5, hour: 20, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 6, hour: 7, minute: 0), close: OpeningHours.Period.TimePoint(day: 6, hour: 18, minute: 0))
                ],
                weekdayDescriptions: nil
            ),
            price_level: "PRICE_LEVEL_INEXPENSIVE"
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
            cuisine_description: "Mexican",
            grade: "B",
            grade_date: "2025-08-24",
            foursquare_fsq_id: nil,
            google_place_id: "ChIJExample3",
            inspections: [
                Inspection(inspection_date: "2025-08-24T00:00:00", critical_flag: "Not Critical", grade: "B", grade_date: "2025-08-24", score: 19, inspection_type: "Cycle Inspection / Initial Inspection", action: nil, violations: [])
            ],
            update_type: nil,
            activity_date: nil,
            finalized_date: nil,
            google_rating: 4.3,
            google_review_count: 542,
            website: nil,
            hours: OpeningHours(
                openNow: true,
                periods: [
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 0, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 0, hour: 21, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 1, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 1, hour: 21, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 2, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 2, hour: 21, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 3, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 3, hour: 21, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 4, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 4, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 5, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 5, hour: 23, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 6, hour: 11, minute: 0), close: OpeningHours.Period.TimePoint(day: 6, hour: 21, minute: 0))
                ],
                weekdayDescriptions: nil
            ),
            price_level: "PRICE_LEVEL_INEXPENSIVE"
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
            cuisine_description: "American",
            grade: "C",
            grade_date: "2025-08-23",
            foursquare_fsq_id: nil,
            google_place_id: "ChIJExample4",
            inspections: [
                Inspection(inspection_date: "2025-08-23T00:00:00", critical_flag: "Critical", grade: "C", grade_date: "2025-08-23", score: 34, inspection_type: "Cycle Inspection / Initial Inspection", action: nil, violations: [
                    Violation(violation_code: "08A", violation_description: "Facility not vermin proof."),
                    Violation(violation_code: "06C", violation_description: "Food not protected from potential source of contamination."),
                    Violation(violation_code: "02G", violation_description: "Cold food item held above 41° F.")
                ])
            ],
            update_type: nil,
            activity_date: nil,
            finalized_date: nil,
            google_rating: 3.8,
            google_review_count: 312,
            website: "https://downtowndiner.com",
            hours: OpeningHours(
                openNow: false,
                periods: [
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 1, hour: 6, minute: 0), close: OpeningHours.Period.TimePoint(day: 1, hour: 15, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 2, hour: 6, minute: 0), close: OpeningHours.Period.TimePoint(day: 2, hour: 15, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 3, hour: 6, minute: 0), close: OpeningHours.Period.TimePoint(day: 3, hour: 15, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 4, hour: 6, minute: 0), close: OpeningHours.Period.TimePoint(day: 4, hour: 15, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 5, hour: 6, minute: 0), close: OpeningHours.Period.TimePoint(day: 5, hour: 15, minute: 0))
                ],
                weekdayDescriptions: nil
            ),
            price_level: "PRICE_LEVEL_INEXPENSIVE"
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
            grade: "A",
            grade_date: "2025-08-21",
            foursquare_fsq_id: nil,
            google_place_id: "ChIJExample5",
            inspections: [
                Inspection(inspection_date: "2025-08-21T00:00:00", critical_flag: "Not Critical", grade: "A", grade_date: "2025-08-21", score: 10, inspection_type: "Cycle Inspection / Initial Inspection", action: nil, violations: [])
            ],
            update_type: nil,
            activity_date: nil,
            finalized_date: nil,
            google_rating: 4.6,
            google_review_count: 2187,
            website: "https://uptowngrill.com",
            hours: OpeningHours(
                openNow: true,
                periods: [
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 0, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 0, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 1, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 1, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 2, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 2, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 3, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 3, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 4, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 4, hour: 23, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 5, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 5, hour: 23, minute: 30)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 6, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 6, hour: 22, minute: 0))
                ],
                weekdayDescriptions: nil
            ),
            price_level: "PRICE_LEVEL_EXPENSIVE"
        ),
        // 6. Test Kitchen
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
            cuisine_description: "Asian Fusion",
            grade: nil,
            grade_date: nil,
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [],
            update_type: nil,
            activity_date: nil,
            finalized_date: nil,
            google_rating: nil,
            google_review_count: nil,
            website: nil,
            hours: nil,
            price_level: nil
        ),
        // 7. City Bistro (No Grade Yet)
        Restaurant(
            camis: "44444444",
            dba: "City Bistro",
            boro: "Manhattan",
            building: "101",
            street: "Any St",
            zipcode: "10023",
            phone: "2125554444",
            latitude: 40.7789,
            longitude: -73.9815,
            cuisine_description: "French",
            grade: "N",
            grade_date: nil,
            foursquare_fsq_id: nil,
            google_place_id: "ChIJExample7",
            inspections: [
                Inspection(inspection_date: "2025-08-15T00:00:00", critical_flag: "Not Applicable", grade: "N", grade_date: nil, score: nil, inspection_type: "Pre-permit (Operational) / Initial Inspection", action: nil, violations: [])
            ],
            update_type: nil,
            activity_date: nil,
            finalized_date: nil,
            google_rating: 4.4,
            google_review_count: 89,
            website: "https://citybistro.com",
            hours: OpeningHours(
                openNow: true,
                periods: [
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 2, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 2, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 3, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 3, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 4, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 4, hour: 22, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 5, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 5, hour: 23, minute: 0)),
                    OpeningHours.Period(open: OpeningHours.Period.TimePoint(day: 6, hour: 17, minute: 0), close: OpeningHours.Period.TimePoint(day: 6, hour: 23, minute: 0))
                ],
                weekdayDescriptions: nil
            ),
            price_level: "PRICE_LEVEL_EXPENSIVE"
        ),
        // 8. The Greasy Spoon - Closed
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
            cuisine_description: "American",
            grade: "C",
            grade_date: "2025-08-20",
            foursquare_fsq_id: nil,
            google_place_id: "ChIJExample8",
            inspections: [
                Inspection(inspection_date: "2025-08-25T00:00:00", critical_flag: "Critical", grade: "C", grade_date: "2025-08-20", score: 45, inspection_type: "Cycle Inspection / Initial Inspection", action: "Establishment Closed by DOHMH. Violations of public health law constitute an imminent health hazard.", violations: [
                     Violation(violation_code: "04L", violation_description: "Evidence of mice or live mice present in facility's food and/or non-food areas.")
                ])
            ],
            update_type: nil,
            activity_date: nil,
            finalized_date: nil,
            google_rating: 2.9,
            google_review_count: 156,
            website: nil,
            hours: nil,
            price_level: "PRICE_LEVEL_INEXPENSIVE"
        ),
        // 9. Sanitation Optional Sushi - Closed
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
            cuisine_description: "Japanese",
            grade: nil,
            grade_date: "2025-08-19",
            foursquare_fsq_id: nil,
            google_place_id: "ChIJExample9",
            inspections: [
                Inspection(inspection_date: "2025-08-24T00:00:00", critical_flag: "Critical", grade: nil, grade_date: nil, score: 52, inspection_type: "Cycle Inspection / Initial Inspection", action: "Establishment Closed by DOHMH.", violations: [
                    Violation(violation_code: "02G", violation_description: "Cold food item held above 41° F.")
                ])
            ],
            update_type: nil,
            activity_date: nil,
            finalized_date: nil,
            google_rating: 3.2,
            google_review_count: 87,
            website: nil,
            hours: nil,
            price_level: "PRICE_LEVEL_MODERATE"
        ),
        // 10. Forgotten Deli - Closed
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
            cuisine_description: "Delicatessen",
            grade: "C",
            grade_date: "2025-08-18",
            foursquare_fsq_id: nil,
            google_place_id: nil,
            inspections: [
                Inspection(inspection_date: "2025-08-23T00:00:00", critical_flag: "Critical", grade: "C", grade_date: "2025-08-18", score: 38, inspection_type: "Cycle Inspection / Re-inspection", action: "Establishment Closed by DOHMH due to imminent health hazard.", violations: [])
            ],
            update_type: nil,
            activity_date: nil,
            finalized_date: nil,
            google_rating: nil,
            google_review_count: nil,
            website: nil,
            hours: nil,
            price_level: nil
        )
    ]
}
#endif
