import SwiftUI

struct FilterSortView: View {
    @Binding var sortSelection: SortOption
    @Binding var boroSelection: BoroOption
    @Binding var gradeSelection: GradeOption
    @Binding var cuisineSelection: CuisineOption // UPDATED to use the CuisineOption enum

    // The 'cuisineOptions' array is no longer needed here.

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
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                    
                    // UPDATED to use the new CuisineOption enum, just like the others.
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
                        sortSelection = .relevance
                        boroSelection = .any
                        gradeSelection = .any
                        cuisineSelection = .any // UPDATED to reset to the .any case
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // This #available check fixes the '.bold()' error for older iOS versions
                    if #available(iOS 16.0, *) {
                        Button("Apply") {
                            dismiss()
                        }
                        .bold()
                    } else {
                        Button("Apply") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
