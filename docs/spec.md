# SwiftUI Mobile App Requirements Specification

## 1. Executive Summary

### 1.1 Product Overview

JabTracker is a native iOS application for tracking injectable GLP-1 medication doses (Ozempic, Wegovy, Mounjaro) and monitoring drug concentration levels using pharmacokinetic modeling.

### 1.2 Technology Stack

- **Framework**: SwiftUI
- **Platform**: iOS 16.0+
- **Backend**: CloudKit (Sync, Storage, User Management)
- **Data Persistence**: Core Data + CloudKit Sync
- **Charts**: Swift Charts
- **Notifications**: User Notifications Framework
- **Health Integration**: HealthKit

### 1.3 Key Features

- Medication dose tracking and logging
- Real-time drug concentration calculations
- Visual analytics and trends
- Dose reminders and notifications
- Multiple medication support
- Export data for healthcare providers
- Educational content about GLP-1 medications

## 2. Functional Requirements

### 2.1 User Authentication & Onboarding

#### 2.1.1 Account Management

- **Sign In Methods**:
  - Sign in with Apple (sole authentication method)
  - Face ID/Touch ID for app access security
- **Profile Information**:
  - Name
  - Email
  - Date of birth
  - Weight (optional, for dosing calculations)
  - Preferred units (mg/mL)
  - Time zone

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

- CloudKit automatic sync
- iCloud backup
- Multi-device sync (iPad, Apple Watch)
- Data recovery options

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

- **Data Encryption**:
  - Core Data encryption
  - Keychain for sensitive data
  - Face ID/Touch ID protection
- **Privacy Compliance**:
  - App Tracking Transparency
  - Privacy nutrition labels
  - On-device processing preference

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

#### 5.1.1 Core Data Entities

```swift
// User Entity
@objc(User)
public class User: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var email: String
    @NSManaged public var name: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var weight: Double
    @NSManaged public var weightUnit: String
    @NSManaged public var timezone: String
    @NSManaged public var createdAt: Date
    @NSManaged public var doses: NSSet?
}

// Dose Entity
@objc(Dose)
public class Dose: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var amount: Double
    @NSManaged public var timestamp: Date
    @NSManaged public var site: String?
    @NSManaged public var notes: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var skipped: Bool
    @NSManaged public var medication: Medication?
    @NSManaged public var user: User?
}

// Medication Entity
@objc(MedicationProfile)
public class MedicationProfile: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var genericName: String
    @NSManaged public var brandName: String
    @NSManaged public var currentDose: Double
    @NSManaged public var startDate: Date
    @NSManaged public var refillDate: Date?
    @NSManaged public var doses: NSSet?
}
```

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

### Phase 1: MVP (8-10 weeks)

- Core Data setup
- Basic authentication
- Single medication support
- Dose tracking
- Simple concentration calculations
- Basic reminders

### Phase 2: Enhanced Features (6-8 weeks)

- Multiple medication support
- Swift Charts integration
- PDF export with PDFKit
- CloudKit sync
- HealthKit integration

### Phase 3: Advanced Features (6-8 weeks)

- Apple Watch companion app
- Widget extensions
- Siri Shortcuts
- App Clips for quick dose entry
- SharePlay for provider consultations

## 7. Testing Requirements

### 7.1 Testing Types

- **Unit Testing**: XCTest for logic
- **UI Testing**: XCUITest for user flows
- **Performance Testing**: Instruments profiling
- **Accessibility Testing**: Accessibility Inspector
- **Beta Testing**: TestFlight

### 7.2 Test Coverage Goals

- Pharmacokinetic calculations: 100%
- Critical user flows: 90%
- View models: 85%
- Core Data operations: 95%

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