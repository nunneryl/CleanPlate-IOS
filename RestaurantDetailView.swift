// In file: RestaurantDetailView.swift

import SwiftUI
import os
import FirebaseAnalytics

struct RestaurantDetailView: View {
    @StateObject private var viewModel: RestaurantDetailViewModel
    @State private var isShowingShareSheet = false
    @State private var isMapVisible = false
    @State private var isShowingReportSheet = false
    
    init(restaurant: Restaurant) {
        _viewModel = StateObject(wrappedValue: RestaurantDetailViewModel(restaurant: restaurant))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                mapSection
                inspectionList
                reportIssueSection // <<< The new section
                faqLink
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationTitle("Restaurant Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticsManager.shared.impact(style: .light)
                    self.isShowingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(items: [viewModel.shareableText])
        }
        .sheet(isPresented: $isShowingReportSheet) {
            ReportIssueView { issueType, comments in
                viewModel.submitReport(issueType: issueType, comments: comments)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    private var headerSection: some View {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text(viewModel.formattedAddress)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    if let cuisine = viewModel.cuisine {
                        Text(cuisine)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(viewModel.headerStatus.imageName)
                    .resizable().scaledToFit().frame(width: 72, height: 72)
            }
            .padding(.horizontal)
        }

    @ViewBuilder
        private var mapSection: some View {
            if let lat = viewModel.restaurant.latitude, let lon = viewModel.restaurant.longitude {
                VStack(spacing: 12) {
                    Button(action: {
                        HapticsManager.shared.impact(style: .light)
                        withAnimation(.easeInOut) { isMapVisible.toggle() }
                    }) {
                        HStack {
                            Text(isMapVisible ? "Hide Map" : "Show Map")
                            Image(systemName: isMapVisible ? "chevron.up" : "chevron.down")
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .buttonStyle(.bordered).tint(.blue)

                    if isMapVisible {
                        VStack(spacing: 0) {
                            StaticMapView(latitude: lat, longitude: lon, restaurantName: viewModel.name)
                            
                            // MOVED GOOGLE BUTTON HERE
                            if viewModel.restaurant.google_place_id != nil {
                                Button(action: {
                                    viewModel.handleGoogleLink()
                                }) {
                                    HStack(spacing: 12) {
                                        Image("logo_google")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 24, height: 24)
                                        
                                        Text("View on Google Maps")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.forward.app.fill")
                                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                                    }
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                    }
                }
            }
        }
    
    private var inspectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inspections")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .padding(.horizontal)

            if !viewModel.inspections.isEmpty {
                ForEach(viewModel.inspections) { inspection in
                    NavigationLink(destination: InspectionDetailView(inspection: inspection)) {
                         inspectionRow(for: inspection)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            } else {
                 Text("No inspection history found.").font(.system(size: 14)).foregroundColor(.secondary).padding()
            }
        }
    }
    
    private func inspectionRow(for inspection: Inspection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(inspection.formattedDate)
                .font(.system(size: 16, weight: .semibold))

            if let action = inspection.action?.lowercased() {
                if action.contains("closed by dohmh") {
                    HStack(alignment: .top) {
                        Text("Status:").font(.system(size: 14, weight: .semibold))
                        Text(inspection.action ?? "")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.red)
                    }
                } else if action.contains("re-opened by dohmh") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("Status:").font(.system(size: 14, weight: .semibold))
                            Text(inspection.action ?? "")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.green)
                        }
                        if let grade = inspection.grade, !grade.isEmpty {
                            displayGrade(for: grade)
                        }
                    }
                } else {
                    displayGrade(for: inspection.grade)
                }
            } else {
                displayGrade(for: inspection.grade)
            }

            Text("Critical Flag: \(inspection.critical_flag ?? "N/A")")
                .font(.system(size: 14))
            
            if let violations = inspection.violations, !violations.isEmpty {
                 DisclosureGroup("Violations (\(violations.count))") { ViolationsView(violations: violations).padding(.top, 8) }
                     .font(.system(size: 14, weight: .bold)).foregroundColor(.blue)
            } else {
                 Text("No violations listed for this inspection.")
                     .font(.system(size: 14, weight: .regular)).foregroundColor(.secondary)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6)).cornerRadius(8)
    }

    private func displayGrade(for grade: String?) -> some View {
        HStack {
            Text("Grade:")
                .font(.system(size: 14))
            if let grade = grade, !grade.isEmpty, grade != "N/A" {
                Text(viewModel.formattedGrade(grade))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(viewModel.gradeColor(for: grade))
            } else {
                Text("No Grade Assigned")
                    .font(.system(size: 14, weight: .regular)).foregroundColor(.gray)
            }
        }
    }

    private var reportIssueSection: some View {
            VStack(alignment: .leading) {
                Divider()
                    .padding(.bottom, 8)
                
                Button(action: {
                    self.isShowingReportSheet = true
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.bubble.fill")
                        Text("Report an Issue")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.systemGray3))
                    }
                }
                .foregroundColor(.primary)
                
                Text("See an issue with this restaurant's data, like a wrong address or a permanent closure? Let us know.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding(.horizontal)
        }
    
    private var faqLink: some View {
        Link("NYC Health Dept Info", destination: URL(string: "https://a816-health.nyc.gov/ABCEatsRestaurants/#!/faq")!)
            .font(.system(size: 16, weight: .semibold)).foregroundColor(.blue).padding(.top, 10)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
