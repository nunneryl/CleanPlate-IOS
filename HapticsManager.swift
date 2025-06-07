//
//  HapticsManager.swift
//  CleanPlate
//
//  This file defines a simple, reusable manager for triggering haptic feedback (vibrations).
//  Using a shared manager like this ensures consistent haptic feedback across the app
//  and keeps the code for it in one organized place.
//

import SwiftUI

/// A manager class to provide haptic feedback.
class HapticsManager {
    
    /// A shared singleton instance of the manager.
    /// This allows you to call `HapticsManager.shared.impact()` from anywhere in the app
    /// without needing to create a new instance each time.
    static let shared = HapticsManager()
    
    /// A private initializer to ensure that the `shared` instance is the only one used.
    private init() {}

    /// Triggers a haptic feedback impact of a specific style.
    /// - Parameter style: The intensity of the haptic feedback. Common styles are `.light`, `.medium`, and `.heavy`.
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // Create a generator for the specified feedback style.
        let generator = UIImpactFeedbackGenerator(style: style)
        
        // Trigger the haptic feedback.
        generator.impactOccurred()
    }
}
