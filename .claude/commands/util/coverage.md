---
description: Update coverage config with new files and run coverage report
argument-hint: none (auto-detects new files)
---

# Coverage Configuration Update & Validation

Update `coverage-config.json` with any new Swift files, run coverage report, and verify accuracy.

Activate **ULTRATHINK**

## Process

### Step 1: Detect New Files in This Branch/PR
- [ ] Get files added in current branch: `git diff --name-only --diff-filter=A origin/main..HEAD`
- [ ] Or check staged/modified files: `git status --porcelain`
- [ ] Filter for new Swift files in `JabTracker/` directory
- [ ] Read each new file to understand its purpose and classification

### Step 2: Categorize Files
Apply **CRITICAL CLASSIFICATION RULES**:

**🧠 Pure Business Logic (90% threshold):**
- Models with computed properties (User.swift, Medication.swift)
- Calculators and algorithms (ReconstitutionCalculator.swift, PharmacokineticsEngine.swift)
- Core business entities (Dose.swift, MedicationProfile.swift)

**🏗️ Infrastructure (62% threshold):**
- Data managers (DataController.swift, MedicationManager.swift)
- Service layers with framework dependencies
- CRUD operations and data persistence logic

**🔗 Framework Integration (42% threshold):**
- Authentication managers (AuthenticationManager.swift, BiometricAuthManager.swift)
- System integrations (HealthKit, CloudKit, StoreKit)
- Platform-specific implementations (SubscriptionManager.swift)

**📊 View Models (85% threshold):**
- Classes with `@ObservableObject`
- Contains `@Published` properties
- Business logic for UI state management (OnboardingViewModel.swift)

**🔧 Utilities (75% threshold):**
- Helper functions and extensions (ProfileValidation.swift, Array+Unique.swift)
- Static utility classes
- Configuration objects (SubscriptionProducts.swift)

**❌ EXCLUDED (No coverage requirements):**
- SwiftUI Views (contains `View` protocol)
- ViewModifiers and UI components
- SwiftUI presentation logic

### Step 3: Update Configuration
- [ ] Read current `coverage-config.json`
- [ ] Add new files to appropriate tiers
- [ ] Remove any misclassified files
- [ ] Verify all new files are properly categorized

### Step 4: Run Coverage Report
- [ ] Execute: `./scripts/check-coverage.sh --use-existing` (if coverage exists)
- [ ] OR execute: `./scripts/check-coverage.sh` (run tests + coverage)
- [ ] Review output for accuracy

### Step 5: Validate & Fix
- [ ] Check each tier appears in report
- [ ] Verify file categorization matches classification rules
- [ ] Fix any "Not found in coverage report" issues
- [ ] Ensure SwiftUI views are NOT in coverage tiers
- [ ] Confirm thresholds are appropriate for each file type

## Double-Check Questions

Before completing, verify:
- Are SwiftUI Views excluded from all tiers?
- Do pure calculators/models have 90% threshold?
- Are data managers in infrastructure tier (62%)?
- Are authentication/system integrations in framework tier (42%)?
- Are utility functions properly categorized (75%)?

## Success Criteria

✅ All new Swift files categorized
✅ No SwiftUI Views in coverage tiers
✅ Coverage report runs without "Not found" errors
✅ File categorization matches business logic
✅ All tiers appear in coverage output

## Common Fixes

**"Not found in coverage report":**
- File might not be executed in unit tests
- Check if file exists at expected path
- Verify file is included in Xcode project (run `xcodegen generate`)

**Wrong categorization:**
- SwiftUI Views → Remove from all tiers (excluded)
- Business logic → Pure Business Logic tier (90%)
- Data/service classes → Infrastructure tier (62%)
- Authentication/system → Framework Integration tier (42%)