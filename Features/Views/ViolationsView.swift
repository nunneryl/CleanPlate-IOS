import SwiftUI

struct ViolationsView: View {
    let violations: [Violation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(violations) { violation in
                ViolationRow(violation: violation)
                
                if violation.id != violations.last?.id {
                    Divider()
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

struct ViolationRow: View {
    let violation: Violation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Code: \(violation.violation_code ?? "N/A")")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
                .padding(.leading, 4)
            
            Text(violation.violation_description ?? "No description available")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Preview provider
struct ViolationsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleViolations = [
            Violation(violation_code: "06D", violation_description: "Food contact surface not properly washed, rinsed and sanitized after each use."),
            Violation(violation_code: "10F", violation_description: "Non-food contact surface or equipment made of unacceptable material."),
            Violation(violation_code: "08A", violation_description: "Establishment is not free of harborage or conditions conducive to rodents, insects or other pests.")
        ]
        
        ViolationsView(violations: sampleViolations)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
