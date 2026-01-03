# Phase 12: Goal Data Model - Context

**Gathered:** 2025-12-27
**Status:** Ready for planning

<vision>
## How This Should Work

Users set personalized weight and macro goals through a three-tier program system:

1. **Coached** - App designs calorie/macro program based on goal and preferences
2. **Collaborative** - User sets macro targets, app adjusts calorie budget based on progress
3. **Manual** - User sets everything manually

The system supports diet preferences (Balanced, Low-fat, Low-carb, Keto), calorie floors for safety, weekly calorie distribution (even or shifted to specific days), and protein intake levels (Low to Extra High).

The standout feature: **Adaptive TDEE** — calorie targets adjust based on actual weight changes, not generic formulas. This should feel like invisible magic to the user. Targets just work. They don't need to understand the mechanics.

Goals drive everything. Weight goal + pace + preferences → daily calorie/macro targets. Progress rings show intake vs targets with color coding (green/yellow/red). Weekly check-ins allow adjustments.

</vision>

<essential>
## What Must Be Nailed

- **Flexible goal types** - Data model supports all three program styles (Coached/Collaborative/Manual) from day one
- **TDEE tracking foundation** - Structure that enables adaptive calculations in Phase 14
- **CloudKit-ready** - Goals sync across devices immediately, following existing SwiftData patterns

</essential>

<boundaries>
## What's Out of Scope

- No UI — wizard, progress rings, settings are later phases (13, 15, 17)
- No TDEE algorithm logic — calculation engine is Phase 14
- No check-in flows — weekly check-ins are Phase 16

This phase is purely SwiftData models. Foundation only.

</boundaries>

<specifics>
## Specific Ideas

- Follow existing codebase patterns (User/Dose/Food modeling style)
- Design optimal model structure taking all requirements into consideration
- Reference: docs/active-context.md contains full program configuration options

</specifics>

<notes>
## Additional Context

From docs/active-context.md — program configuration includes:
- Program style (Coached/Collaborative/Manual)
- Diet preference (Balanced/Low-fat/Low-carb/Keto)
- Calorie floor (Standard/Low with safety warning)
- Weekly distribution (Even/Shifted)
- Protein intake level (Low/Moderate/High/Extra High)

Goal wizard should complete in under 2 minutes. Progress updates real-time. Colors reflect target status.

</notes>

---

*Phase: 12-goal-data-model*
*Context gathered: 2025-12-27*
