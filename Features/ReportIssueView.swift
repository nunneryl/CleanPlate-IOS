// In file: ReportIssueView.swift

import SwiftUI

struct ReportIssueView: View {
    @Environment(\.dismiss) var dismiss
    
    let onSubmit: (IssueType, String) -> Void
    
    @State private var issueType: IssueType = .wrongAddress
    @State private var comments: String = ""
    
    enum IssueType: String, CaseIterable, Identifiable {
        case permanentlyClosed = "Permanently Closed"
        case wrongAddress = "Wrong Address / Map Pin"
        case wrongName = "Wrong Restaurant Name"
        case other = "Other"
        var id: Self { self }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("What's the issue?")) {
                    Picker("Issue Type", selection: $issueType) {
                        ForEach(IssueType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section(header: Text("Optional Comments")) {
                    TextEditor(text: $comments)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Report an Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if #available(iOS 16.0, *) {
                        Button("Submit") {
                            onSubmit(issueType, comments)
                            dismiss()
                        }
                        .bold()
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
        }
    }
}
