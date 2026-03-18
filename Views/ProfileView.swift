// In file: ProfileView.swift

import SwiftUI
import AuthenticationServices
import UserNotifications

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var pushManager = PushNotificationManager.shared

    @State private var isShowingDeleteAlert = false

    var body: some View {
        NavigationView {
            VStack {
                switch authManager.authState {
                case .signedOut:
                    signedOutView
                case .signedIn(let userID):
                    signedInView(userID: userID)
                }
            }
            .navigationTitle("Profile")
        }
        .navigationViewStyle(.stack)
    }

    private var signedOutView: some View {
        VStack {
            Spacer()

            Text("Create an account to save your favorite restaurants.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            SignInWithAppleButton(.signIn, onRequest: { _ in }, onCompletion: { _ in })
                .onTapGesture { authManager.signIn() }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 55)
                .cornerRadius(10)
                .padding()

            Spacer()
        }
    }

    private func signedInView(userID: String) -> some View {
        let favoritedRestaurants = authManager.favorites.values.sorted {
            ($0.dba ?? "") < ($1.dba ?? "")
        }

        return List {
            // FAVORITES SECTION
            Section(header: Text("My Favorites (\(favoritedRestaurants.count))")) {
                if favoritedRestaurants.isEmpty {
                    Text("You haven't saved any favorites yet. Tap the heart icon on a restaurant's page to add it here.")
                        .foregroundColor(.secondary)
                        .padding(.vertical)
                } else {
                    ForEach(favoritedRestaurants) { restaurant in
                        NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                            HStack {
                                Image(restaurant.displayGradeImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(restaurant.dba ?? "Unknown Restaurant")
                                        .font(.headline)
                                    Text(restaurant.cuisine_description ?? "Cuisine not available")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        guard let index = indexSet.first else { return }
                        let restaurantToDelete = favoritedRestaurants[index]
                        authManager.removeFavorite(restaurantToDelete)
                    }
                }
            }

            // NOTIFICATIONS SECTION
            Section(header: Text("Notifications")) {
                if pushManager.notificationStatus == .authorized {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.green)
                        Text("Push notifications enabled")
                        Spacer()
                        Text("On")
                            .foregroundColor(.secondary)
                    }
                    Text("You'll be notified about grade changes, new violations, and reopenings for your favorite restaurants.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if pushManager.notificationStatus == .denied {
                    HStack {
                        Image(systemName: "bell.slash")
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications disabled")
                            Text("Enable in Settings to get updates on your favorites.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.subheadline)
                    }
                } else {
                    Button {
                        Task {
                            await pushManager.requestPermission()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.accentColor)
                            Text("Enable push notifications")
                        }
                    }
                    Text("Get notified about grade changes, violations, and reopenings for your favorites.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // ACCOUNT ACTIONS SECTION
            Section {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }

                Button("Delete Account", role: .destructive) {
                    isShowingDeleteAlert = true
                }
            }
        }
        .onAppear {
            Task { await pushManager.refreshAuthorizationStatus() }
        }
        .alert("Are you sure?", isPresented: $isShowingDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    await authManager.deleteAccount()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action is permanent. All of your saved favorites will be deleted.")
        }
    }
}
