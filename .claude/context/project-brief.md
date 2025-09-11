---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-11T20:59:06Z
version: 1.0
author: Claude Code PM System
---

# Project Brief

## What It Does
JabTracker is a sophisticated iOS application that helps patients track injectable GLP-1 medications (like Ozempic and Mounjaro) while providing real-time pharmacokinetic modeling to show drug concentration levels in the body. The app combines medication logging, adherence tracking, and scientific visualization to improve patient outcomes and provider communication.

## Why It Exists

### Medical Problem
- **Poor Adherence**: 30-50% of patients struggle with medication adherence
- **Lack of Visibility**: Patients don't understand how medications work in their body
- **Communication Gaps**: Difficult for patients to communicate patterns to providers
- **Dose Confusion**: Complex titration schedules lead to errors
- **Data Fragmentation**: No centralized system for comprehensive medication tracking

### Market Gap
- Existing medication apps lack pharmacokinetic modeling
- No specialized focus on GLP-1 medications and their unique properties
- Generic tracking apps don't address injection-specific needs
- Limited integration with healthcare provider workflows

## Project Scope

### In Scope
- **Core Tracking**: Dose logging, missed dose management, historical review
- **Pharmacokinetics**: Real-time concentration calculations using half-life modeling
- **Visual Analytics**: Charts showing concentration over time, adherence patterns
- **Provider Integration**: PDF reports, data export, clinical documentation
- **User Experience**: Onboarding, authentication, notifications, settings
- **Data Sync**: CloudKit integration with offline-first functionality

### Out of Scope (Phase 1)
- Direct EMR integration
- Telehealth video consultations
- Automatic injection device integration
- Social features and community aspects
- Multi-language support beyond English
- Android version

## Key Objectives

### Primary Goals
1. **Improve Medication Adherence**: Achieve 15%+ improvement in dose compliance
2. **Enhance Patient Understanding**: Provide clear visualization of drug action
3. **Streamline Provider Communication**: Generate professional clinical reports
4. **Ensure Medical Accuracy**: Maintain 99.9%+ accuracy in pharmacokinetic calculations

### Secondary Goals
1. **User Satisfaction**: Maintain 4.5+ App Store rating
2. **Clinical Adoption**: Achieve provider referrals and integration
3. **Revenue Generation**: 15%+ premium subscription conversion
4. **Platform Excellence**: Demonstrate best practices in iOS health app development

## Success Criteria

### User Metrics
- **Engagement**: 90%+ daily dose logging rate among active users
- **Retention**: 80% 30-day retention, 60% 90-day retention
- **Satisfaction**: 4.5+ App Store rating with positive reviews
- **Clinical Value**: Provider report generation and usage

### Technical Metrics
- **Performance**: App launch < 2 seconds, calculation updates < 50ms
- **Reliability**: 99.5%+ crash-free rate
- **Quality**: Comprehensive test coverage with automated CI/CD
- **Accessibility**: Full VoiceOver and Dynamic Type support

### Business Metrics
- **Revenue**: Sustainable subscription model with premium features
- **Growth**: Organic user acquisition through clinical value
- **Partnerships**: Healthcare provider partnerships and referrals
- **Market Position**: Recognition as leading GLP-1 tracking solution

## Constraints and Considerations

### Regulatory
- **FDA Compliance**: Ensure classification as wellness app, not medical device
- **Privacy**: HIPAA-like privacy standards, comprehensive data protection
- **Medical Accuracy**: Clinical advisory oversight for pharmacokinetic modeling
- **International**: CE marking and Health Canada requirements for expansion

### Technical
- **iOS Only**: Native iOS development with Swift/SwiftUI
- **Offline-First**: Full functionality without internet connection
- **Security**: Sign in with Apple, biometric authentication, encrypted storage
- **Performance**: Memory usage < 100MB, ProMotion 120Hz support

### Business
- **Timeline**: MVP in 6 months, full v1.0 in 12 months
- **Budget**: Bootstrapped development with focus on efficiency
- **Team**: Small team with AI-assisted development using Claude Code
- **Competition**: Differentiation through specialized GLP-1 focus and pharmacokinetics

## Risk Mitigation

### Technical Risks
- **CloudKit Complexity**: Graceful local-only fallback implemented
- **Pharmacokinetic Accuracy**: Clinical advisory board and validation
- **Test Coverage**: TDD approach with comprehensive test suite
- **Performance**: Regular profiling and optimization

### Market Risks
- **Regulatory Changes**: Stay informed on FDA guidance updates
- **Competition**: Focus on specialized value proposition
- **User Adoption**: Strong onboarding and clear value demonstration
- **Provider Adoption**: Professional reports and clinical integration focus

## Development Philosophy
- **Medical-First**: Safety and accuracy paramount in all decisions
- **User-Centered**: Intuitive design with accessibility as core requirement
- **Quality-Driven**: TDD approach with comprehensive testing
- **Native Excellence**: Leverage iOS platform capabilities fully
- **Privacy-Focused**: On-device processing and minimal data collection