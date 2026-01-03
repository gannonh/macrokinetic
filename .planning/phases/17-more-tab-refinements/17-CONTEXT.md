# Phase 17: More Tab Refinements - Context

**Gathered:** 2026-01-01
**Status:** Ready for planning

<vision>
## How This Should Work

The More tab gets reorganized with cleaner groupings and new settings screens. The current structure is messy — this phase makes it intuitive.

**Structure:**
- Remove the User Card from the top
- **Overflow menu** at top for items not in main tabs: Goals & Strategy, Food Library, GLP-1 Medications
- **Feature Settings** group: Dashboard (inactive), Food Log (inactive), Metrics, Units, Calorie Expenditure, Shortcuts & Tabs (inactive)
- **Account Settings** group: Profile (rename from Account), Subscription, Security & Privacy, Notifications
- **Support** group: FAQ (inactive), Help & Support (inactive), General

**New screens:**
- Security & Privacy: Face ID toggle, Health toggle, iCloud sync status
- Notifications: Weigh-in reminders (daily/weekly), Food logging reminders (per meal + end of day), Medication dose reminders
- Calorie Expenditure: Mock screen with burned calories toggle, predictive activity adjustment toggle, rollover calories toggle
- Subscription: Mock screen showing plan details, restore purchases, manage subscription link

Inactive items show in gray as placeholders for future features.

</vision>

<essential>
## What Must Be Nailed

- **More tab navigation** restructured with the new groupings
- **Security & Privacy** screen with working Face ID and Health toggles
- **Notifications** screen with working notification scheduling (weigh-in, food logging, medication reminders)
- **Mock screens** clearly marked as coming soon (Calorie Expenditure, Subscription)

</essential>

<boundaries>
## What's Out of Scope

- Inactive feature screens (Dashboard settings, Food Log settings, Shortcuts & Tabs, FAQ, Help & Support) — just gray placeholders
- Real Calorie Expenditure functionality (burned calories, activity adjustment, rollover) — mock only
- Real Subscription/StoreKit integration — mock only showing what it will look like
- Goal editing from Settings — already handled in prior phases

</boundaries>

<specifics>
## Specific Ideas

- Inactive items should be gray text to indicate they're not yet available
- Mock screens should have small gray text saying "Coming soon" or similar
- Notifications screen should actually wire up to NotificationService
- "Profile" replaces current "Account" naming
- Some items intentionally appear in multiple places for discoverability (per user note)
- @docs/active-context.md contains the full specification for each screen's content.

</specifics>

<notes>
## Additional Context

Original Phase 17 was "Goal Settings Integration" but that was largely completed in prior phases (15.2, 16). This phase has evolved into More tab refinements that were deferred.

Reference: @docs/active-context.md contains the full specification for each screen's content.

</notes>

---

*Phase: 17-more-tab-refinements*
*Context gathered: 2026-01-01*
