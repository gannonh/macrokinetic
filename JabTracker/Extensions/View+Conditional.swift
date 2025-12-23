//
//  View+Conditional.swift
//  JabTracker
//
//  Conditional view modifiers.
//

import SwiftUI

extension View {
    /// Conditionally applies a transformation to a view
    /// - Parameters:
    ///   - condition: The condition to evaluate
    ///   - transform: The transformation to apply if condition is true
    /// - Returns: Either the transformed view or the original view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
