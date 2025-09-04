//
//  ReviewManager.swift
//  CleanPlate
//
//  This file manages the logic for asking the user for an App Store rating
//  in a non-intrusive way, as recommended by Apple.
//

import Foundation
import StoreKit
import SwiftUI

class ReviewManager {
    
    // Create a shared instance so we can access it easily from anywhere.
    static let shared = ReviewManager()
    private init() {}

    // We'll use UserDefaults to keep track of how many times the user has
    // performed a key action.
    private let userDefaultsKey = "restaurantDetailViewCount"

    /// Increments a counter and requests an App Store review when appropriate.
    ///
    /// This method should be called when the user completes a meaningful action,
    /// such as successfully viewing a restaurant's detail page.
    func requestReviewIfAppropriate() {
        
        // 1. Get the current count from device storage.
        let currentCount = UserDefaults.standard.integer(forKey: userDefaultsKey)
        
        // 2. Increment the count.
        let newCount = currentCount + 1
        
        // 3. Save the new count back to device storage.
        UserDefaults.standard.set(newCount, forKey: userDefaultsKey)
        
        // 4. Define the thresholds for when to ask for a review.
        // We'll ask after the 3rd, 10th, and 30th restaurant they've viewed.
        // Apple will only show the prompt a maximum of 3 times per year.
        let reviewThresholds: [Int] = [3, 10, 30]
        
        // 5. Check if the new count matches one of our thresholds.
        guard reviewThresholds.contains(newCount) else {
            // If it's not a threshold count, we do nothing.
            return
        }

        // 6. Find the active window scene to present the review request.
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        // 7. Request the review. iOS will decide if it's the right time to show the pop-up.
        SKStoreReviewController.requestReview(in: scene)
    }
}
