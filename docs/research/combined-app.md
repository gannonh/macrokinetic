# Product Plan: GLP-1 + Macro Tracking iOS App

The combined **JabTracker + MacroSnap** app addresses a clear market gap: no existing solution offers MyFitnessPal-quality food logging with comprehensive GLP-1 medication management. With **15+ million active GLP-1 users** in the US (up 587% since 2019) and widespread subscription fatigue (62% of consumers report it), a premium one-time purchase app positioned as "pay once, own forever" can capture significant market share from $72-100+/year subscription competitors.

---

## Competitive landscape reveals two disconnected markets

The calorie tracking and GLP-1 management markets operate almost entirely in silos. Major nutrition apps like MyFitnessPal (14+ million foods, $80/year) and MacroFactor ($72/year) offer excellent food databases but zero GLP-1-specific features. Meanwhile, dedicated GLP-1 trackers like Shotsy and Glapp provide medication logging and injection site rotation but suffer from limited food databases where users report "food entries are challenging—cannot edit names, barcode doesn't always work."

**Calorie/macro tracking leaders at a glance:**

| App | Annual Price | Key Strength | Critical Weakness |
|-----|-------------|--------------|-------------------|
| MyFitnessPal | $79.99 | 14M+ food database, brand recognition | Barcode scanner paywalled, user backlash over pricing |
| MacroFactor | $71.99 | Adaptive algorithm, verified database | No free tier, mobile-only |
| Cronometer | $54.99 | 84 micronutrients tracked, best free tier | Information overload, no adaptive coaching |
| Carbon Diet Coach | $79.99 | Science-backed by Dr. Layne Norton | No free trial, requires strict compliance |
| Lose It! | $39.99 | Lifetime option ($149-189), affordable | Smaller database, limited micronutrients |
| FatSecret | $38.99 | Powers 50,000+ apps via API, strong free tier | Dated interface, basic features |

**GLP-1 tracking landscape:** Telehealth platforms (Calibrate at $199/month, Noom Med at $149-297/month, WeightWatchers Clinic at $74-99/month) offer clinical oversight but basic tracking apps. Standalone trackers like **Shotsy** ($39.99/year), **Glapp** (free), and **MeAgain** (subscription) provide medication-level visualization and injection site rotation that telehealth platforms lack, but their nutrition tracking is rudimentary.

**The critical gap:** MyFitnessPal added GLP-1 content in May 2024 (high-protein recipes, hydration tracking, GLP-1 nutrition plans), but lacks injection scheduling, side-effect correlation, or medication-level estimation. GLP-1 apps have these features but poor food databases. No solution combines both effectively.

---

## Core feature requirements for market differentiation

The MVP must nail the integration that users explicitly request: "Why can't I have MyFitnessPal's food database with Shotsy's medication tracking?" Research confirms 34% of GLP-1 users want nutrition content related to their medication, and users who track food alongside GLP-1s report higher weight-loss success rates.

### MVP features (Phase 1 - Launch)

**GLP-1 Medication Management:**
- Dose tracking and injection logging with medication selection (Ozempic, Wegovy, Mounjaro, Zepbound, Saxenda)
- **Medication-level visualization** showing drug concentration curve over the weekly cycle—the feature users love most in Shotsy and Glapp
- Injection site rotation with body-map tracking and automatic rotation reminders
- Titration schedule management with dose escalation protocols matching manufacturer guidelines
- Side effect monitoring with severity tracking (nausea, constipation, fatigue, diarrhea)
- Shot reminders with customizable timing

**Nutrition/Macro Tracking:**
- Comprehensive food database with barcode scanning (minimum 2M+ verified foods)
- Macro and calorie tracking with customizable goals (grams, not just percentages)
- **Protein-first interface** highlighting protein targets prominently—GLP-1 users need 1.2-1.6g/kg daily to preserve muscle mass
- Hydration tracking with personalized targets (critical for managing GLP-1 side effects)
- Recipe creation and saving with URL import capability
- Apple Health integration for seamless data sync

**GLP-1-Specific Intelligence:**
- Symptom-food correlation engine linking logged side effects to recent meals (63% of users linked nausea to high-fat foods)
- Nausea-friendly food suggestions when symptoms are logged
- "Bodyphase" indicators predicting when appetite suppression peaks and when hunger may return based on medication timing

### Phase 2 features (3-6 months post-launch)

- **Adaptive calorie recommendations** adjusting targets based on medication cycle phase
- Medication inventory tracking with refill reminders
- AI photo food logging (supplementing barcode scanning)
- Multi-metric progress charts overlaying weight, nutrition, symptoms, and injection timing
- Educational content library about GLP-1 medications
- Provider report export for medical appointments
- Meal planning with GLP-1-optimized templates (smaller portions, protein-dense, low-fat options)

### Phase 3 features (6-12 months post-launch)

- Body composition tracking integration (muscle mass preservation monitoring)
- Blood glucose and blood pressure logging (user-requested features)
- Apple Watch companion app
- Community features with privacy controls
- Microdosing simulator for dose optimization experimentation
- Post-GLP-1 transition planning tools

---

## Pricing strategy positions against subscription fatigue

The one-time purchase model directly addresses **62% of consumers reporting subscription fatigue**. Users on Reddit explicitly state willingness to "pay $50-100 one-time for apps I'd normally avoid subscribing to." The break-even psychology is compelling: a $39.99 one-time purchase breaks even against MyFitnessPal ($80/year) at just 6 months.

### Recommended pricing structure

| Tier | Price | Includes |
|------|-------|----------|
| **Standard** | $29.99 | Full app, unlimited use, 1 year of feature updates |
| **Pro** | $39.99 | Standard + lifetime updates + advanced analytics |
| **Family** | $59.99 | Pro features + Family Sharing (5 users) |

**Primary recommended price: $39.99 (Pro tier)**

This price falls at the psychological sweet spot below $40, represents ~6 months of competitor subscriptions (clear value), and leaves room for the Family tier at $59.99 to capture couples and households. Gentler Streak (Apple Watch App of the Year 2022) proved that Family Sharing lifetime options at 1.5x individual price convert well because users perceive "buying for us, not me."

### Revenue sustainability beyond launch

One-time purchase apps face the "windfall at launch, then trickle" challenge. Mitigation strategies based on successful indie apps:

- **Tip jar integration** through in-app tipping or Buy Me a Coffee—provides supplemental income from passionate users
- **Premium add-ons** ($4.99-9.99) for specialized meal plan packs, workout programs, or enhanced food databases
- **Paid major updates** (App 2.0) at 50% discount for existing users after 2-3 years
- **Optional cloud sync subscription** ($2.99/month) for users wanting cross-device data backup—keeps core app one-time while adding recurring revenue option
- **Reserve 20-30%** of Year 1 revenue for development runway

### Marketing positioning

- **Primary message:** "Tired of fitness app subscriptions? Pay once. Done."
- **Comparison hook:** "MacroFactor is $72/year. [App Name] is $39.99. Forever."
- **Value calculator:** Show users their 1, 2, 3-year costs with competitors vs. one-time purchase

---

## Technical considerations for the combined app

Building a truly integrated GLP-1 + nutrition app requires careful architecture to support both domains seamlessly.

**Food database strategy:** Three viable approaches ranked by tradeoff:
1. **License FatSecret API** (powers 50,000+ apps, 2M+ verified foods)—fastest path, ongoing API costs
2. **Integrate Open Food Facts** (open-source, 3M+ products)—lower cost, requires more curation
3. **Build proprietary + USDA NCCDB foundation**—most control, highest development cost, best long-term moat

**Medication timing engine:** The medication-level visualization requires pharmacokinetic modeling based on published half-life data for each GLP-1 (semaglutide ~7 days, tirzepatide ~5 days, liraglutide ~13 hours). This creates the core differentiator that telehealth platforms lack.

**Symptom correlation algorithm:** Machine learning model correlating logged symptoms with:
- Recent food entries (fat content, meal size, specific ingredients)
- Time since injection
- Hydration levels
- Historical patterns for the individual user

**Privacy and data handling:** All GLP-1 medication and symptom data is health-sensitive. Implement:
- Local-first storage with optional iCloud sync
- No third-party analytics on medication data
- HIPAA-adjacent practices even if not technically required for non-covered entity

**Apple Health integration:** Essential for competing with MacroFactor. Read weight, activity, sleep; write nutrition data. Enables users to view comprehensive health picture without duplicate entry.

---

## Market differentiation creates defensible position

The competitive moat builds on three pillars no current competitor addresses simultaneously:

**1. Integration depth:** While MyFitnessPal added GLP-1 "content" in May 2024 (recipes, hydration tips), it remains a general-purpose calorie counter. While Shotsy excels at medication tracking, users complain about food logging. This app is purpose-built for the **15+ million GLP-1 users** who need both, with features designed around their specific nutritional requirements (protein prioritization, nausea-friendly foods, portion guidance as appetite changes).

**2. Pricing model:** Every major competitor uses subscriptions: MyFitnessPal $80/year, MacroFactor $72/year, Carbon $80+/year, Noom Med $149-297/month. A $39.99 one-time purchase creates instant differentiation and attracts the 62% of consumers actively seeking subscription alternatives.

**3. GLP-1-specific intelligence:** No competitor offers adaptive recommendations based on medication timing, symptom-food correlation analysis, or "bodyphase" predictions. These features address the unmet need users express repeatedly: understanding how their medication affects their eating patterns and optimizing nutrition accordingly.

### Target user profile

Primary: Women 30-64 (highest GLP-1 usage demographic) who:
- Currently use both a calorie app AND a GLP-1 tracker (or want to)
- Are frustrated by subscription costs piling up
- Want to maximize weight loss while preserving muscle
- Need help managing side effects through dietary choices

Secondary: Users considering GLP-1 medications who want to establish tracking habits before starting treatment.

---

## Roadmap summary and success metrics

**Pre-launch (Month -2 to 0):**
- Finalize food database licensing/integration
- Complete medication timing engine for all major GLP-1s
- Build core tracking interfaces
- Establish App Store presence with compelling screenshots emphasizing dual functionality

**Launch (Month 0):**
- Release MVP with core GLP-1 + nutrition features
- Target GLP-1 Reddit communities (r/Ozempic, r/Semaglutide, r/Mounjaro—highly active, always asking for app recommendations)
- Emphasize one-time purchase positioning against subscription competitors

**Post-launch metrics to track:**
- Conversion rate at $39.99 price point
- 7-day retention (target: 40%+)
- Daily active usage (target: 60%+ of purchasers using weekly)
- Feature engagement: medication logging vs. food logging balance
- Family tier uptake as percentage of revenue

**6-month milestone:** 10,000 paid users generating $400,000+ revenue, with clear data on which Phase 2 features users request most.

The combined app addresses a documented market gap with a differentiated pricing model at precisely the moment when GLP-1 adoption is accelerating and subscription fatigue is peaking. By building features neither calorie apps nor GLP-1 trackers currently offer—medication-aware nutrition guidance, symptom-food correlation, and protein-first tracking for muscle preservation—the product creates a defensible position in a rapidly growing market projected to reach **$150-170 billion by 2030**.