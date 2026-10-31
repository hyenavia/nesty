# Changelog 📋

All notable changes to the **Nesty** - Little Things, Taken Care Of project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2026-10-31

### Added
- **Monthly Recurring Bills Management (`features/bills`)**:
  - Track monthly commitments such as rent, WiFi, water, and phone bills with due days.
  - Interactive status with "Mark paid" settling the current monthly cycle.
  - Automated proactive reminders 2 days prior to each bill's due date.
  - Home dashboard integration with quick-access Bill status card.
- **First-Launch Interactive Onboarding (`features/onboarding`)**:
  - Three-step animated introduction highlighting calm home organization and core features.
  - In-app bilingual switcher (`EN` / `ID`) right from the start.
  - Replayable anytime via "Show intro again" in the Profile tab.
- **Animated In-App Splash Experience (`features/splash`)**:
  - Smooth animated brand wordmark with floating cloud elements and hills landscape.
  - Seamless handover from native splash screen (`flutter_native_splash`) with animated progress indicator.
- **Weekly Schedule Strip (`RoutineWeekStrip`)**:
  - 7-day horizontal calendar bar in the Routine screen showing upcoming tasks due on each day.
- **Supplies Quantity Counter**:
  - Added optional numeric quantity tracking (`quantity`) for household items with one-tap incremental/decremental stepper controls (`+` / `-`).

### Changed
- **Unified Sync & Cloud Storage**:
  - Expanded `SyncService` and `BackupService` to synchronize and export all six domains (Supplies with quantities, Routines, Electricity Tokens, Water Gallons, Laundry Orders, and Monthly Bills).
- **Comprehensive Notification Center**:
  - `ReminderController` now orchestrates reminders across routines, electricity tokens, water gallon refills, laundry collection, and recurring bills.

---

## [0.5.0] - 2026-10-31

### Added
- **Electricity Token Prediction Module (`features/token`)**:
  - Track meter readings (kWh) and purchase history (Rp & kWh).
  - Intelligent burn rate calculation with run-out date prediction.
  - Optional kWh tariff estimation per unit.
  - Proactive reminders 3 days before expected token exhaustion.
- **Drinking Water Gallon Tracker (`features/gallon`)**:
  - One-tap refill logging with learned average consumption calculation.
  - Dynamic progress countdown showing estimated days remaining.
  - Configurable default duration and historical duration analytics.
  - Automatic push notification alert the day before the gallon runs out.
- **Laundry Order Management (`features/laundry`)**:
  - Full lifecycle tracking: *In Basket* -> *At Laundry* -> *Ready for Pickup* -> *Done*.
  - Track laundry shop name, package weight in kg, promised completion date, and receipt photos.
  - Local receipt photo capture via camera or gallery with `PhotoService` and `image_picker`.
  - Notification reminder on promised collection day.
- **Core Utilities & Widgets**:
  - Reusable `numbers_dialog.dart` for inputting numeric metrics.
  - Reusable `screen_header.dart` for uniform section branding.
  - Unified formatting helpers in `format.dart`.

### Changed
- **Home Dashboard Integration**:
  - Replaced upcoming feature placeholders with active, interactive modules for Token, Gallon, and Laundry.
  - Dynamic "Today" alert card highlighting items requiring immediate attention.
- **Unified Sync & Backup Engine**:
  - Expanded `SyncService` and `BackupService` to synchronize and export all five home domains (Supplies, Routines, Electricity Tokens, Water Gallons, and Laundry Orders).
- **Proactive Notification Hub**:
  - `ReminderController` now schedules integrated reminders across cleaning routines, tokens, gallons, and laundry pickups.

---

## [0.4.0] - 2026-10-31

### Added
- **Official Cozy Mascot App Icon**:
  - Replaced application icons across all supported platforms (Android adaptive and legacy mipmaps, Web favicons & PWA icons, Windows desktop, and iOS) with the official 3D clay peach & mint house mascot.
  - Added new reusable `BrandMark` widget in `lib/core/widgets/brand_mark.dart` with configurable size and rounded corners.
  - Added `appInput` unified input decoration helper in `lib/core/widgets/app_input.dart` matching Wall o' Pay design specifications.
  - Added `FirebaseMissingPage` fallback view shown when Firebase configuration is absent, with a one-tap "Continue without account" action.

### Changed
- **Wall o' Pay Aligned Authentication Experience**:
  - Rebuilt `AuthScreen` layout and flow to exactly match Wall o' Pay:
    - Top header row with `BrandMark(size: 52)` and bilingual `SegmentedButton` (`EN` | `ID`).
    - Dynamic welcome titles and descriptive subtitles for Sign In and Sign Up modes.
    - Standardized text inputs for `Username`, `Email`, `Email or username`, and `Password` with visibility toggle.
    - Quick "Forgot password?" inline trigger with real-time feedback notifications.
    - 52px full-width `FilledButton` primary action with animated progress indicator.
    - Seamless toggle between Sign In and Sign Up modes.
    - Prominent "Continue without account" action for offline-first guest onboarding.
  - Upgraded error handling to support standard Firebase Auth error codes and localized error messages.

---

## [0.3.0] - 2026-10-31

### Added
- **Dual Login with Username or Email**:
  - Sign in using either username or verified email address.
  - Automatic email resolution via Firestore `usernames` mapping.
- **Email Password Reset**:
  - Built-in password reset flow with automated reset links sent directly to registered email addresses.
- **Custom Profile Management**:
  - Personalized nickname editing displayed on the Home screen greeting.
  - Profile avatar photo picker from device gallery (`image_picker`) with automatic base64 local cache and cloud backup.
  - Read-only immutable `@username` and email displays.
- **Comprehensive Settings Hub**:
  - Redesigned Settings screen aligned with Wall o' Pay standards: Top Profile Card with chevron, Preferences (Bilingual & Theme), Smart Reminders, Cloud Sync & Storage (Sync Now, Send to Cloud, Fetch from Cloud), Offline File Backup (Import/Export JSON), Account Management with permanent Delete Account option, and In-App Version Changelog viewer.

---

## [0.2.0] - 2026-10-31

### Added
- **Firebase Authentication & Cloud Synchronization**:
  - Optional account login (Email/Password & Anonymous) to backup and synchronize supplies and routines across multiple devices.
  - Offline-first architecture: complete local database persistence with transparent background Firestore sync when connected.
- **Smart Reminders Engine**:
  - Local push notifications with `flutter_local_notifications` and `timezone` schedule integration.
  - Automated reminder checks for electricity tokens, water gallon refills, laundry pick-up, and recurring cleaning routines.
- **Offline Import & Export**:
  - Added JSON backup and restore with `file_picker` for privacy-conscious users without online accounts.
- **Multi-language Support**:
  - Complete bilingual support for Bahasa Indonesia and English across all screens and controllers.

---

## [0.1.0] - 2026-10-25

### Added
- **Initial Core Features**:
  - Daily supplies inventory management (safe, running low, out of stock).
  - Living space cleaning routine tracking with recurring interval schedules.
  - Electricity token & water gallon status cards.
  - Warm, cozy Material 3 UI design inspired by calm independent living.

