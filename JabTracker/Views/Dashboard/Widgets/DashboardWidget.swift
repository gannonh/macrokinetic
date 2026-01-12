//
//  DashboardWidget.swift
//  JabTracker
//
//  Protocol defining the contract for all dashboard widgets.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftUI

/// Protocol defining the contract for all dashboard widgets.
///
/// Widgets conforming to this protocol can be rendered in the dashboard
/// using standard containers like `WidgetCard`, `HeroWidgetContainer`,
/// or `StandardWidgetGroup`.
///
/// Example usage:
/// ```swift
/// struct CaloriesWidget: DashboardWidget {
///     let id = "calories"
///     let title = "Daily Calories"
///
///     var content: some View {
///         Text("2,100 / 2,400")
///     }
/// }
/// ```
protocol DashboardWidget: Identifiable {
    associatedtype Content: View

    /// Unique identifier for the widget
    var id: String { get }

    /// Display title shown in widget header (if applicable)
    var title: String { get }

    /// The widget's main content view
    @ViewBuilder var content: Content { get }
}
