# JabTracker Constitution

## Core Principles

### I. Medical Accuracy First (NON-NEGOTIABLE)
- All medication properties MUST match published medical literature
- Pharmacokinetic calculations MUST use validated formulas
- Dose ranges MUST align with FDA-approved values
- Any medical calculation requires comprehensive test coverage (>95%)
- User safety overrides all other considerations

### II. Test-First Development (NON-NEGOTIABLE)
- Outside-In TDD mandatory: Write tests → Verify they fail (RED) → Implement → Pass (GREEN) → Refactor
- Test order: Model tests → Service tests → Integration tests → UI tests
- Real dependencies in tests (actual SwiftData, CloudKit) - no mocks for critical paths
- Medical calculations require boundary condition testing
- FORBIDDEN: Implementation before failing tests, skipping RED phase

### III. Native iOS Architecture
- SwiftUI for all UI components - no UIKit unless absolutely necessary
- SwiftData for persistence with CloudKit sync
- Direct framework usage - no unnecessary abstraction layers
- Computed properties over stored values for medical constants
- @Observable and @State for reactive UI updates

### IV. Offline-First with Graceful Sync
- Full functionality without network connection
- CloudKit sync when available, local-only fallback
- User-visible sync status with actionable guidance
- Data integrity maintained across sync boundaries
- No data loss during offline/online transitions

### V. Component Modularity
- Features as focused services (MedicationManager, ReconstitutionCalculator, etc.)
- Single responsibility per service
- Clear separation: Models → Services → Views
- Services testable in isolation
- No circular dependencies between components

### VI. User Safety & Error Handling
- Medical errors must be impossible through UI constraints
- Input validation at every entry point
- User-friendly error messages (no technical jargon)
- Clear guidance for error resolution
- Dangerous operations require confirmation

### VII. Performance Standards
- Calculation updates < 50ms
- App launch < 2 seconds  
- Memory usage < 100MB baseline
- Smooth 60fps UI (120fps ProMotion support)
- Background tasks properly scheduled

## Medical & Regulatory Constraints

### FDA Compliance Considerations
- App classified as wellness/informational tool
- Clear disclaimers about not replacing medical advice
- Calculation formulas must be transparent
- Audit trail for dose tracking

### Data Privacy (HIPAA-Adjacent)
- Medical data encrypted at rest (SwiftData encryption)
- CloudKit private database only
- Biometric authentication for app access
- No third-party analytics for medical data
- Secure credential storage in Keychain

### Accessibility Requirements
- Full VoiceOver support for all features
- Dynamic Type support (all text scalable)
- High contrast mode compatibility
- Reduced motion alternatives
- Medical values clearly announced

## Development Workflow

### Code Quality Gates
1. **SwiftLint** must pass (no warnings)
2. **Unit test coverage** > 80% overall, >95% for medical calculations
3. **UI tests** for all critical user paths
4. **Performance profiling** before major releases
5. **Accessibility audit** for new UI components

### Git Workflow
- Feature branches from main: `###-feature-name`
- Conventional commits: `feat:`, `fix:`, `test:`, `docs:`
- PR requires: passing tests, lint, coverage check
- Squash merge to main
- Tag releases with semantic versioning

### Documentation Requirements
- Inline documentation for all public APIs
- CLAUDE.md updates for AI context
- Test scenarios in quickstart.md
- Medical calculations must include formula references

## Governance

### Constitution Authority
- Constitution supersedes all other project guidelines
- Violations must be justified in writing (Complexity Tracking)
- Medical safety principles are absolute - no exceptions

### Amendment Process
1. Proposed changes documented in PR
2. Impact analysis on existing code
3. Migration plan if breaking changes
4. Team review and approval
5. Update version and amendment date

### Enforcement
- All PRs checked against constitution
- `/plan` command includes Constitution Check gate
- Complexity deviations tracked and justified
- Regular audits for compliance drift

### Reference Documents
- Primary: `/memory/constitution.md` (this document)
- Project context: `CLAUDE.md`
- User guidelines: `~/.claude/CLAUDE.md`
- Feature tracking: `docs/implementation-plan.md`

**Version**: 1.0.0 | **Ratified**: 2025-09-06 | **Last Amended**: 2025-09-06

---

## Appendix: Quick Reference Checklist

### For Every Feature:
- [ ] Medical accuracy validated?
- [ ] Tests written first and failing?
- [ ] Offline functionality maintained?
- [ ] Error handling user-friendly?
- [ ] Performance targets met?
- [ ] Accessibility verified?
- [ ] Documentation updated?

### For Every PR:
- [ ] Tests pass?
- [ ] Coverage adequate?
- [ ] SwiftLint clean?
- [ ] Constitution compliant?
- [ ] Commits conventional?
- [ ] CLAUDE.md updated?