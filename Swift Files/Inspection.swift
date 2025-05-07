struct RestaurantInspection: Identifiable, Codable {
    var id: String { "\(camis)-\(inspection_date)" }
    let camis: String
    let inspection_date: String
    let critical_flag: String?
    let grade: String?
    let score: String?
    let violation_code: String?
    let violation_description: String?
    let inspection_type: String?
}
