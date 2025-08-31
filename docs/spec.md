# JabTracker Product Requirements Specification

> **Implementation Status**: For detailed progress tracking and current development status, see [`docs/implementation-plan.md`](./implementation-plan.md)

## 1. Executive Summary

### 1.1 Product Overview

JabTracker is a native iOS application for tracking injectable GLP-1 medication doses (Ozempic, Wegovy, Mounjaro) and monitoring drug concentration levels using pharmacokinetic modeling.

### 1.2 Technology Stack

- **Framework**: SwiftUI
- **Platform**: iOS 17.0+
- **Backend**: CloudKit (Sync, Storage, User Management)
- **Data Persistence**: SwiftData + CloudKit Sync (with graceful local-only fallback)
- **Charts**: Swift Charts
- **Notifications**: User Notifications Framework
- **Health Integration**: HealthKit
- **Testing**: Swift Testing (unit tests) + XCUITest (UI tests)
- **Build Tools**: xcbeautify for enhanced output formatting

### 1.3 Key Features

- Medication dose tracking and logging
- Real-time drug concentration calculations
- Visual analytics and trends
- Dose reminders and notifications
- Multiple medication support
- Export data for healthcare providers
- Educational content about GLP-1 medications
- **✅ iCloud sync status monitoring** - Real-time feedback on data synchronization
- **✅ Offline-first functionality** - Full app functionality without internet connection

## 2. Functional Requirements

### 2.1 User Authentication & Onboarding ✅

#### 2.1.1 Account Management ✅

- **✅ Sign In Methods**:
  - ✅ Sign in with Apple (sole authentication method)
  - ✅ Face ID/Touch ID for app access security
- **✅ Profile Information**:
  - ✅ Name
  - ✅ Email
  - ✅ Date of birth
  - ✅ Weight (with unit conversion between kg/lbs)
  - ✅ Preferred units (kg/lbs)
  - ✅ Time zone

#### 2.1.2 Onboarding Flow

- Welcome screens with app benefits
- Medication selection wizard
- Initial dose entry
- Notification permissions request
- HealthKit permissions
- Optional: Import existing dose history

### 2.2 Medication Management

#### 2.2.1 Supported Medications

```swift
enum Medication: CaseIterable, Codable {
    case semaglutide
    case tirzepatide
    case liraglutide
    case dulaglutide
    
    var brands: [String] {
        switch self {
        case .semaglutide: return ["Ozempic", "Wegovy", "Rybelsus (oral)"]
        case .tirzepatide: return ["Mounjaro", "Zepbound"]
        case .liraglutide: return ["Victoza", "Saxenda"]
        case .dulaglutide: return ["Trulicity"]
        }
    }
    
    var halfLifeDays: Double {
        switch self {
        case .semaglutide: return 7.0
        case .tirzepatide: return 5.0
        case .liraglutide: return 0.54
        case .dulaglutide: return 4.7
        }
    }
    
    var availableDoses: [Double] {
        switch self {
        case .semaglutide: return [0.25, 0.5, 1.0, 1.7, 2.0, 2.4]
        case .tirzepatide: return [2.5, 5.0, 7.5, 10.0, 12.5, 15.0]
        case .liraglutide: return [0.6, 1.2, 1.8, 2.4, 3.0]
        case .dulaglutide: return [0.75, 1.5, 3.0, 4.5]
        }
    }
    
    var frequency: DoseFrequency {
        switch self {
        case .liraglutide: return .daily
        default: return .weekly
        }
    }
}
```

#### 2.2.2 Medication Profile Features

- Add multiple medications
- Set current medication and dose
- Track dose escalation schedule
- Store prescription information
- Set refill reminders

### 2.3 Dose Tracking

#### 2.3.1 Dose Entry

- **Quick Add**: One-tap for scheduled doses
- **Manual Entry**:
  - Date and time picker
  - Dose amount selector
  - Injection site tracking
  - Optional notes field
  - Photo attachment via PhotosUI
- **Missed Dose Handling**:
  - Mark as skipped
  - Reschedule options
  - Smart recommendations

#### 2.3.2 Dose History

- List view with filtering
- Calendar view with dose indicators
- Edit past entries
- Swipe actions (edit/delete)
- Search functionality

### 2.4 Concentration Monitoring

#### 2.4.1 Pharmacokinetic Calculations

```swift
class PharmacokineticsEngine: ObservableObject {
    func calculateConcentration(doses: [Dose], medication: Medication, at date: Date) -> Double {
        let decayRate = pow(0.5, 1.0 / medication.halfLifeDays)
        
        return doses.reduce(0.0) { total, dose in
            let daysSince = date.timeIntervalSince(dose.timestamp) / (24 * 60 * 60)
            guard daysSince >= 0 else { return total }
            let remaining = dose.amount * pow(decayRate, daysSince)
            return total + remaining
        }
    }
    
    func calculateSteadyState(dose: Double, medication: Medication) -> Double {
        let decayRate = pow(0.5, 1.0 / medication.halfLifeDays)
        let frequencyDays = medication.frequency == .daily ? 1.0 : 7.0
        return dose / (1 - pow(decayRate, frequencyDays))
    }
}
```

#### 2.4.2 Display Metrics

- Current concentration level
- Peak concentration (post-dose)
- Trough concentration (pre-dose)
- Time to next dose
- Percentage of steady-state achieved
- Therapeutic range indicators

### 2.5 Analytics & Visualizations

#### 2.5.1 Charts and Graphs

- **Concentration Timeline** (Swift Charts):
  - Interactive line chart
  - Dose markers
  - Gesture-based zoom/pan
  - Future projections
- **Dose Consistency**:
  - Adherence percentage
  - Streak tracking
  - Missed dose patterns
- **Summary Views**:
  - Average levels
  - Dose frequency
  - Site rotation tracking

#### 2.5.2 Insights Dashboard

- Adherence score
- Steady-state progress
- Dose optimization suggestions
- Comparison to typical patterns

### 2.6 Reminders & Notifications

#### 2.6.1 Notification Types

- **Dose Reminders**:
  - Customizable time
  - Snooze options
  - Location-based reminders
- **Refill Alerts**:
  - Based on remaining doses
  - Lead time customization
- **Milestone Notifications**:
  - Steady-state achieved
  - Streak achievements
  - Weekly summaries

#### 2.6.2 Notification Settings

- Enable/disable by type
- Focus mode integration
- Sound and haptic options
- Custom notification content

### 2.7 Data Management

#### 2.7.1 Export Features

- **PDF Reports** (PDFKit):
  - Dose history
  - Concentration graphs
  - Summary statistics
  - Healthcare provider format
- **Data Formats**:
  - CSV export
  - JSON backup
  - HealthKit integration
  - CDA document export

#### 2.7.2 Backup & Sync

- **CloudKit automatic sync** with real-time status monitoring
- **iCloud backup** with graceful fallback to local-only storage
- **Sync status display** with user-friendly messaging and actionable guidance
- **Offline-first architecture** ensures full functionality without internet
- **Multi-device sync** (iPad, Apple Watch)
- **Data recovery options** and conflict resolution

**Sync Status Monitoring Requirements:**
- Real-time iCloud account status detection
- Network connectivity monitoring
- User guidance for resolving sync issues (sign in to iCloud, network problems)
- Visual indicators in Settings tab with appropriate icons and colors

### 2.8 Educational Content

#### 2.8.1 Medication Information

- How GLP-1 medications work
- Proper injection technique
- Side effect management
- Storage guidelines
- Travel tips

#### 2.8.2 In-App Guidance

- TipKit integration
- Interactive tutorials
- FAQ section
- Links to official resources

## 3. Non-Functional Requirements

### 3.1 Performance

- App launch time < 2 seconds
- Calculation updates < 50ms
- ProMotion support (120Hz)
- Offline functionality
- Background task scheduling

### 3.2 Security & Privacy

- **✅ Data Encryption**:
  - ✅ SwiftData encryption enabled
  - ✅ Keychain for sensitive credential storage
  - ✅ Face ID/Touch ID protection with BiometricAuthManager
- **Privacy Compliance**:
  - App Tracking Transparency
  - Privacy nutrition labels
  - On-device processing preference

**✅ Implemented Security Components:**
- `AuthenticationManager` - Secure Sign in with Apple integration
- `BiometricAuthManager` - Comprehensive biometric authentication with fallback
- Keychain Services integration for credential persistence
- Secure authentication state management

### 3.3 Accessibility

- VoiceOver support
- Dynamic Type
- Increased Contrast
- Reduce Motion support
- Voice Control compatibility

### 3.4 Localization

- **Initial Languages**:
  - English
  - Spanish
  - French
  - German
- **Localized Content**:
  - Formatters for dates/numbers
  - Localized medication names
  - Educational content

## 4. User Interface Design

### 4.1 Design System

#### 4.1.1 Color Scheme

```swift
extension Color {
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let theme = Theme(
        primary: Color(hex: "667eea"),
        primaryLight: Color(hex: "8b9ff4"),
        primaryDark: Color(hex: "4c5fbf"),
        success: .green,
        warning: .orange,
        danger: .red,
        info: .blue
    )
}
```

#### 4.1.2 Typography

```swift
extension Font {
    static let largeTitle = Font.system(.largeTitle, design: .rounded)
    static let headline = Font.system(.headline, design: .default).bold()
    static let body = Font.system(.body, design: .default)
    static let caption = Font.system(.caption, design: .default)
}
```

### 4.2 Screen Layouts

#### 4.2.1 Navigation Structure

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            
            AddDoseView()
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
            
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
            
            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.line.uptrend.xyaxis") }
            
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
```

## 5. Technical Architecture

### 5.1 Data Models

#### 5.1.1 SwiftData Models ✅

```swift
// ✅ User Model (Implemented with Code Quality Improvements)
@Model
final class User {
    var id: UUID = UUID()
    var email: String = ""  // Required with default - prevents runtime nil issues
    var name: String? = nil  // Optional - Apple might not provide
    var dateOfBirth: Date? = nil  // Optional user input
    var weight: Double = 70.0  // Required with sensible default for medical calculations
    var weightUnit: String = "kg"  // Required with default
    var timezone: String = TimeZone.current.identifier  // Required with system default
    var createdAt: Date = Date()  // Audit trail
    var updatedAt: Date = Date()  // Audit trail
    var appleUserId: String? = nil  // For Sign in with Apple linking
    
    @Relationship(deleteRule: .cascade, inverse: \Dose.user)
    var doses: [Dose] = []
    
    @Relationship(deleteRule: .cascade, inverse: \MedicationProfile.user) 
    var medicationProfiles: [MedicationProfile] = []
    
    init(email: String = "", name: String? = nil, weight: Double = 70.0, weightUnit: String = "kg") {
        self.email = email
        self.name = name
        self.weight = weight
        self.weightUnit = weightUnit
        self.timezone = TimeZone.current.identifier
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// Dose Model (Improved with Code Quality Updates)
@Model
final class Dose {
    var id: UUID = UUID()
    var amount: Double = 0.0  // Required with default - medical dosing data
    var timestamp: Date = Date()  // Required with default - when dose was taken
    var site: String? = nil  // Optional - injection site tracking
    var notes: String? = nil  // Optional - user notes
    var imageData: Data? = nil  // Optional - photo attachment
    var skipped: Bool = false  // Default false - dose completion status
    var createdAt: Date = Date()  // Audit trail
    
    @Relationship(inverse: \User.doses) 
    var user: User? = nil  // Parent user relationship
    
    @Relationship(inverse: \MedicationProfile.doses)
    var medicationProfile: MedicationProfile? = nil  // Associated medication
    
    init(amount: Double = 0.0, timestamp: Date = Date()) {
        self.amount = amount
        self.timestamp = timestamp
        self.createdAt = Date()
    }
}

// Medication Profile Model (Improved with Code Quality Updates)
@Model
final class MedicationProfile {
    var id: UUID = UUID()
    var genericName: String = ""  // Required with default - medication type
    var brandName: String = ""  // Required with default - specific brand
    var currentDose: Double = 0.0  // Required with default - current dosing amount
    var startDate: Date = Date()  // Required with default - when medication started
    var refillDate: Date? = nil  // Optional - next refill date
    var createdAt: Date = Date()  // Audit trail
    
    @Relationship(inverse: \User.medicationProfiles) 
    var user: User? = nil  // Parent user relationship
    
    @Relationship(deleteRule: .cascade, inverse: \Dose.medicationProfile) 
    var doses: [Dose] = []  // Associated doses
    
    init(genericName: String = "", brandName: String = "", currentDose: Double = 0.0) {
        self.genericName = genericName
        self.brandName = brandName
        self.currentDose = currentDose
        self.startDate = Date()
        self.createdAt = Date()
    }
}
```

**✅ CloudKit Sync Capability:**
All models configured with CloudKit sync support through DataController with graceful local-only fallback when iCloud is unavailable.

### 5.1.2 Authentication Architecture ✅

**Implemented Components:**

```swift
// AuthenticationManager - Complete Sign in with Apple Integration
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authenticationError: AuthenticationError?
    
    func signInWithApple() async throws
    func signOut() async throws
    func checkAuthenticationStatus() async
    // Keychain credential management
    // User creation and linking
}

// BiometricAuthManager - Face ID/Touch ID Security
class BiometricAuthManager: ObservableObject {
    func evaluateBiometricAuthentication() async -> BiometricAuthResult
    func checkBiometricAvailability() -> BiometricAuthAvailability
    // Comprehensive error handling and fallback
}

// Authentication Views
struct AuthenticationView: View {
    // Clean Sign in with Apple UI
    // Loading states and error handling
}

struct UserProfileView: View {
    // Comprehensive profile management
    // Weight conversion, form validation
    // Real-time data persistence
}

struct SplashView: View {
    // Authentication loading state
}
```

**Security Features:**
- Secure Keychain credential storage
- Biometric authentication with device passcode fallback  
- Authentication state persistence across app launches
- Comprehensive error handling and user guidance
- Privacy-compliant Apple ID information handling

### 5.2 CloudKit Schema

```swift
struct CKRecordType {
    static let dose = "Dose"
    static let medication = "Medication"
    static let userPreferences = "UserPreferences"
}

struct CKField {
    struct Dose {
        static let amount = "amount"
        static let timestamp = "timestamp"
        static let medication = "medication"
        static let site = "site"
        static let notes = "notes"
    }
}
```

## 6. Development Phases

### Phase 1: Foundation & Infrastructure (4-6 weeks)

**Core Infrastructure:**
- SwiftData setup with User/Dose/MedicationProfile models
- CloudKit sync with graceful local-only fallback
- iCloud sync status monitoring with real-time user feedback
- Design system foundation with DesignTokens and reusable components
- Comprehensive testing infrastructure (Swift Testing + XCUITest)
- Build tooling with automated checks and quality gates

### Phase 2: Core User Features (6-8 weeks)

**✅ Authentication & Security (COMPLETED):**
- ✅ Sign in with Apple integration
- ✅ Face ID/Touch ID for app access security
- ✅ Secure data storage and encryption

**✅ User Onboarding Flow (COMPLETED in PR #20):**
- ✅ Welcome screens with app benefits (3 screens with pharmacokinetics explanation)
- ✅ Medication selection wizard (all 4 GLP-1 medications with medical accuracy)
- ✅ Initial dose entry setup (with injection site selection and scheduling)
- ✅ Notification permissions request (with clear value proposition)
- ✅ HealthKit permissions integration (weight and health data)
- ✅ Subscription placeholder screen (2-week trial, $4.99/month pricing)
- ✅ Comprehensive testing (203 unit tests + complete UI test coverage)

**Medication Management:**
- Single medication support (starting with Semaglutide)
- Medication profile creation and management
- Dose scheduling and tracking

**Dose Tracking:**
- Quick dose entry with one-tap functionality
- Manual dose entry with detailed logging
- Dose history with calendar view
- Missed dose handling and rescheduling

### Phase 3: Advanced Analytics & Integration (6-8 weeks)

**Pharmacokinetics & Analytics:**
- Real-time drug concentration calculations
- Concentration timeline visualization with Swift Charts
- Adherence tracking and insights
- Peak/trough level monitoring

**Data & Health Integration:**
- Multiple medication support with enum-based definitions
- HealthKit integration for weight and health data
- PDF export for healthcare provider reports
- Advanced analytics dashboard

### Phase 4: Platform Extensions (6-8 weeks)

**Multi-Platform Support:**
- Apple Watch companion app for quick dose logging
- iOS Widget extensions for at-a-glance information
- iPad optimizations with enhanced layouts

**Advanced Features:**
- Siri Shortcuts integration
- App Clips for quick dose entry
- SharePlay for provider consultations
- Push notifications with rich content

## 7. Testing Requirements

### 7.1 Testing Types

- **✅ Unit Testing**: Swift Testing framework for modern, clean test syntax
- **✅ UI Testing**: XCUITest for user flows and end-to-end testing
- **✅ Model Testing**: SwiftData model and persistence testing
- **✅ Design System Testing**: Component accessibility and functionality testing
- **Performance Testing**: Instruments profiling for optimization
- **Accessibility Testing**: Accessibility Inspector for compliance
- **Beta Testing**: TestFlight for user acceptance testing

**✅ Testing Infrastructure Requirements (COMPLETED):**
- ✅ File-based test organization for better maintainability
- ✅ Enhanced test output formatting with xcbeautify
- ✅ Automated test runs via scripts (unit, UI, all)
- ✅ Comprehensive pre-merge testing pipeline

**✅ Authentication Testing Coverage (COMPLETED):**
- `AuthenticationTests` - Comprehensive unit test coverage for authentication flows
- `AuthenticationUITests` - Complete E2E testing for Sign in with Apple
- Biometric authentication testing with device and simulator scenarios
- Keychain integration security testing
- Authentication state management testing
- Error handling and recovery flow testing

### 7.2 Test Coverage Goals

- **✅ SwiftData operations**: Comprehensive coverage for all model operations
- **✅ Design system components**: Full component testing with accessibility  
- **✅ Model relationships**: Complete relationship testing (User-Dose, etc.)
- **✅ Authentication flows**: 100% coverage achieved for security-critical code
- **Pharmacokinetic calculations**: 100% coverage target for medical accuracy
- **Critical user flows**: 90% coverage for core functionality
- **View models**: 85% coverage for business logic

**✅ Current Coverage Status:**
- Authentication components: 100% test coverage
- User SwiftData model: 100% test coverage  
- Design system components: 100% test coverage
- Authentication UI flows: Complete E2E coverage

## 8. Success Metrics

### 8.1 User Engagement

- Daily Active Users
- Dose logging compliance rate
- Session duration
- Feature adoption rates

### 8.2 Clinical Value

- Medication adherence improvement
- Steady-state achievement rate
- Healthcare provider report usage
- User-reported outcomes

### 8.3 Technical Performance

- Crash-free rate > 99.5%
- App Store rating > 4.5
- Launch time < 2 seconds
- Memory usage < 100MB

## 9. Compliance & Regulatory

### 9.1 Medical Device Classification

- FDA classification determination
- CE marking for EU
- Health Canada requirements

### 9.2 Data Privacy

- HIPAA compliance
- App Tracking Transparency
- Privacy nutrition labels
- Data retention policies

### 9.3 Clinical Validation

- Pharmacokinetic model validation
- Clinical advisory board
- User safety monitoring
- Adverse event reporting

## 10. Monetization Strategy

### 10.1 Revenue Models

- **Freemium**:
  - Basic: Single medication, 30-day history
  - Premium: Unlimited medications, full history, exports
- **In-App Purchase Tiers**:
  - Monthly: $4.99
  - Annual: $39.99
  - Lifetime: $99.99

### 10.2 Premium Features

- Unlimited medication tracking
- Advanced analytics
- PDF reports
- iCloud sync
- Apple Watch app
- Priority support