// In file: ProfileView.swift

import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme
    
    // <<< NEW: The state variable is moved here, to the top level of the View >>>
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
        // NOTE: The @State variable is no longer declared here.
        
        let favoritedRestaurants = authManager.favorites.values.sorted {
            ($0.dba ?? "") < ($1.dba ?? "")
        }
        
        return List {
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
            
            Section {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
                
                Button("Delete Account", role: .destructive) {
                    isShowingDeleteAlert = true
                }
            }
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

