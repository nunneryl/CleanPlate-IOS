// In file: FilterSortView.swift

import SwiftUI
import FirebaseAnalytics

struct FilterSortView: View {
    @Binding var sortSelection: SortOption
    @Binding var boroSelection: BoroOption
    @Binding var gradeSelection: GradeOption
    @Binding var cuisineSelection: CuisineOption
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("SORT BY")) {
                    Picker("Sort Option", selection: $sortSelection) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section(header: Text("FILTER BY")) {
                    Picker("Borough", selection: $boroSelection) {
                        ForEach(BoroOption.allCases) { boro in
                            Text(boro.rawValue).tag(boro)
                        }
                    }
                    
                    Picker("Grade", selection: $gradeSelection) {
                        ForEach(GradeOption.allCases) { grade in
                            // <<< UPDATED to use the new displayName property >>>
                            Text(grade.displayName).tag(grade)
                        }
                    }
                    
                    Picker("Cuisine", selection: $cuisineSelection) {
                        ForEach(CuisineOption.allCases) { cuisine in
                            Text(cuisine.rawValue).tag(cuisine)
                        }
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        HapticsManager.shared.impact(style: .light)
                        
                        sortSelection = .relevance
                        boroSelection = .any
                        gradeSelection = .any
                        cuisineSelection = .any
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if #available(iOS 16.0, *) {
                        Button("Apply") {
                            HapticsManager.shared.impact(style: .medium)
                            Analytics.logEvent("apply_filters_sort", parameters: [
                                "boro_selected": boroSelection == .any ? "none" : boroSelection.rawValue,
                                "grade_selected": gradeSelection == .any ? "none" : gradeSelection.rawValue,
                                "cuisine_selected": cuisineSelection == .any ? "none" : cuisineSelection.rawValue,
                                "sort_by": sortSelection.rawValue
                            ])
                            
                            // Then dismiss
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
