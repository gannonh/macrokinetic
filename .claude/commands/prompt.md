Lets take a step back and think about the UI. Looking at the full epic for analytics, what are the key components of the feature? We've done ConcentrationTimelineChart #56 and did a rough integration of it on the analytics page. We are now doing AdherenceInsightsView #57 of which there are several UI compoenents:

- AdherenceInsightsView SwiftUI component created
- Adherence percentage display with color-coded status
- Current and best streak counters
- Missed dose pattern visualization
- Weekly/monthly adherence trend charts
- Personalized improvement recommendations\

So, Concentration Timeline is really one interactive chart component. Adherence Insights is more of a dashboard with multiple subcomponents.

What are your thoughts? There are several ways we could go:

- Have all components on the Analytics View
- Have a tabbed segmented control interface within the Analytics View to switch between various analytics subviews
- Have a scrollable vertical stack of components on the Analytics View
- Have a main Analytics View with navigation links to separate detailed views for each component
- Something else?