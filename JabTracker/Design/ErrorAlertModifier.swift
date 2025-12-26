//
//  ErrorAlertModifier.swift
//  JabTracker
//
//  Reusable error alert modifier for consistent error presentation across views.
//

import SwiftUI

/// A view modifier that presents a standard error alert
struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String?

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "An error occurred")
            }
    }
}

extension View {
    /// Presents a standard error alert when the binding is true
    /// - Parameters:
    ///   - isPresented: Binding to control alert presentation
    ///   - message: Optional error message to display
    func errorAlert(isPresented: Binding<Bool>, message: String?) -> some View {
        modifier(ErrorAlertModifier(isPresented: isPresented, message: message))
    }
}
