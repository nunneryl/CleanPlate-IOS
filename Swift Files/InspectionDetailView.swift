import SwiftUI
import os

struct InspectionDetailView: View {
    let inspection: Inspection
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "InspectionDetailView")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                violationsSection
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Inspection Details")
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .onAppear {
            logger.info("InspectionDetailView appeared for inspection date: \(inspection.inspection_date ?? "N/A", privacy: .public)")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inspection Date: \(DateHelper.formatDate(inspection.inspection_date))")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Grade: \(inspection.grade ?? "Not Graded")")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Type: \(inspection.inspection_type ?? "N/A")")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Critical Flag: \(inspection.critical_flag ?? "N/A")")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var violationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Violations")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .padding(.vertical, 8)
            
            if let violations = inspection.violations, !violations.isEmpty {
                ForEach(violations) { violation in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Code: \(violation.violation_code ?? "N/A")")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text(violation.violation_description ?? "No description available")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    Divider()
                        .background(Color.secondary)
                }
            } else {
                Text("No violations listed.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
