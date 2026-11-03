# Changelog 📋

All notable changes to the **Nesty** - Little Things, Taken Care Of project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.13.2] - 2026-11-03

### Fixed
- **Identifier Resolution & Fake Email Elimination (`AuthController._resolveEmail`)**:
  - Eliminated legacy fake `@users.nesty.app` domain fallback for unresolved usernames.
  - Aligned with Wall o' Pay standard: non-existent usernames now fail immediately with `invalid-credential` / `user-not-found` without causing misleading password-reset confirmations or extra failed Firebase Auth roundtrips.
- **Strict Email Lowercase Normalization**:
  - Enforced strict lowercase email normalization across `signUp`, `updateUsername`, and `SyncService` cloud push to guarantee exact case matches with Firebase Auth token claims in `firestore.rules`.
- **Rate Limit Error Localization (`AuthScreen`)**:
  - Added localized handling for Firebase Auth `too-many-requests` error code with clear instructions in both English and Indonesian.

---

## [0.13.1] - 2026-11-03

### Fixed
- **Account Re-Registration & Username Reclamation (`AuthController.signUp`)**:
  - Fixed an issue where deleting an account and attempting to re-register with the same email and username caused a false `username-taken` conflict followed by auth user rollback.
  - Added preliminary username availability pre-checks prior to creating Firebase Auth accounts, preventing orphaned auth records.
  - Allowed users to seamlessly reclaim and update their previously owned username reservation when registering with the identical verified email address.
- **Thorough Cloud Data Deletion (`AuthController.deleteAccount`)**:
  - Re-architected account deletion to systematically discover and purge all username reservations mapped to the user's `uid`, email, and cached displayName in Firestore prior to Firebase Auth user deletion.
  - Replaced generic error suppression with explicit re-authentication credential checks and error reporting.
  - Added deletion cleanup for subcollections under `users/{uid}/meta/profile`.
- **Delete Account Modal Validation & Feedback (`ProfileScreen`)**:
  - Added inline password validation in the deletion confirmation modal, preventing empty submissions from triggering unhandled `requires-recent-login` errors.
  - Added clear localized feedback for incorrect password and session re-login requirements.
- **Hardened Cloud Firestore Security Rules (`firestore.rules`)**:
  - Updated `/usernames/{name}` update and delete rules to allow users with matching token email (`request.auth.token.email`) to reclaim or delete username mappings across re-registration lifecycles.
  - Added strict payload domain schema validation (`isValidUsernameDoc`).

---

## [0.13.0] - 2026-11-03

### Added
- **Store Compliance & Privacy Policy (`docs/privacy.html`)**:
  - Published comprehensive Privacy Policy and User Data Deletion documentation compliant with Google Play Data Safety and Apple App Store Review Guidelines.
  - Added in-app Privacy Policy access under Settings > About & Support with direct browser opening.
  - Documented dual deletion workflows: instant 1-tap deletion in-app and verified email request channel.
- **In-App Change Password (`AuthController.changePassword`, `ProfilePage`)**:
  - Added secure in-app password change modal with current password re-authentication, validation, and localized error feedback.
- **Unified Signature Cozy Theme (`AppTheme.signature`)**:
  - Unified the visual identity into a single signature theme (Warm Cream `#FFF7EC`, Soft Surfaces `#FFFCF7`, and Deep Espresso `#62504A` typography with Cozy Peach `#F2A07F` accents).
  - Perfectly balanced for both bright daylight readability (crisp contrast) and dim room comfort (warm paper-like sepia tone without harsh blue light), removing unnecessary theme toggle complexity.
- **Actionable Notification Buttons ("Mark Done")**:
  - Added actionable response buttons directly on Android routine reminder notifications, allowing users to mark tasks as done with zero friction.
- **Gentle Sunday Evening Digest (`ReminderController`)**:
  - Introduced a calming weekly digest scheduled every Sunday evening to review the upcoming week's routines and essentials in peace.
  - Added toggle preference under Smart Reminders.
- **Android Battery Saver Guide**:
  - Added guidance dialog in Smart Reminders helping users on aggressive OEM devices (Xiaomi, Oppo, Vivo, Samsung) configure battery saver exclusions to guarantee prompt alarms.

---

## [0.12.0] - 2026-11-03

### Added
- **Onboarding Setup Wizard & Modular Visibility (`ModuleController`)**:
  - Introduced a streamlined final setup step in onboarding: *"What would you like Nesty to monitor?"*, allowing users to customize which modules (Electricity Token, Water Gallon, Laundry, Kost Supplies, Rent & Bills) appear on their home dashboard.
  - Added module customization preferences in Settings (`ProfileScreen`) so users can re-enable or hide modules at any time.
  - Enabled one-tap opt-in for Smart Reminders directly in the onboarding setup wizard.
- **Home Getting Started Checklist**:
  - Added an interactive progress checklist on the Home dashboard for new users (e.g. record first electricity meter reading, log current water gallon, review supplies, activate smart reminders).
- **Cold-Start Instant Token Forecast (`TokenController`)**:
  - Implemented instant electricity token predictions based on typical refill spend and duration (`setColdStartEstimate`), eliminating the initial waiting friction before two consecutive meter readings are recorded.
  - Added an in-app "Quick Estimate" prompt dialog on `TokenScreen`.
- **Gesture Affordance Hints & Visual Cues**:
  - Added dismissible gesture tip banners in `SuppliesScreen` (*"Tip: Tap an item to change stock status. Swipe left to delete"*).
  - Added subtle dropdown arrows on `StatusPill` indicating interactive status switching.
  - Added swipe-to-delete indicator cues across `RoutineScreen`, `BillsScreen`, `GallonScreen`, `LaundryScreen`, and `TokenScreen`.
- **Guest-First Cloud Backup Prompt**:
  - Transitioned the app from a blocking upfront login screen to a friction-free guest-first launch. Users can start managing their room immediately without registration.
  - Added a warm cloud backup reminder banner on Home once data is recorded, encouraging account creation to safeguard data without being intrusive.
- **Dedicated Forgot Password Dialog (`AuthScreen`)**:
  - Replaced the input-dependent password reset action with a clear pop-up dialog allowing users to enter their registered email or username directly.

### Changed
- **Device Language Auto-Detection (`LocaleController`)**:
  - Automatically detects the user's device system locale on fresh installs (`PlatformDispatcher.instance.locale`), defaulting to Indonesian (`'id'`) on Indonesian devices rather than forcing English.
- **Universal Starter Supplies Catalog (`defaultSupplies`)**:
  - Streamlined the default supplies catalog from 19 broad items to 10 truly universal kost essentials, pre-setting Laundry Detergent to *Running Low* so new users immediately understand how the Stock and Shopping List workflow connects.

---

## [0.11.2] - 2026-11-03

### Fixed
- **Dynamic Application Versioning (`PackageInfo`, `UpdateCheckerService`)**:
  - Integrated `package_info_plus` to dynamically resolve the installed version and build number directly from the native package manifest at runtime.
  - Replaced legacy hardcoded version strings (`v0.10.0` in `UpdateCheckerService` and `v0.7.2 (Build 8)` in `ProfileScreen`), eliminating false-positive update notifications and ensuring the Settings screen always displays the authentic, up-to-date version.

---

## [0.11.1] - 2026-11-03

### Added
- **Automated Flutter Widget Test Suite (`test/widget_test.dart`)**:
  - Expanded test suite from 23 to 26 automated tests by introducing UI widget tests.
  - Verifies screen rendering and user interactions on `HomeScreen`, `RoutineScreen` (completion & undo SnackBars), and `BillsScreen` (split bill badges & payment settlement).

### Fixed
- **Collision-Resistant Cryptographic UUIDs (`uuid`)**:
  - Replaced microsecond-based timestamps across `BillsController`, `LaundryController`, `RoutinesController`, `SuppliesController`, and `PhotoService` with UUID v4 (`const Uuid().v4()`), preventing potential ID collisions during cloud sync and bulk data operations.

---

## [0.11.0] - 2026-11-03

### Added
- **Redesigned Cozy Web Landing Page (`docs/`)**:
  - Rebuilt the entire landing page based on the warm, storybook-inspired Nunito & Nunito Sans design specification.
  - Integrated interactive CSS mobile phone stage featuring live utility status cards and tap-to-complete daily tasks.
  - Unified Signature Theme: Warm cozy cream canvas harmoniously mixed with rich espresso typography, phone framing, and cozy peach accents, presenting a single cohesive brand identity.
  - Highlighted full independent living feature suite: Electricity Token prediction, Gallon countdown, Laundry tracking, Daily Supplies, Recurring Bills, and Weekly/Monthly Living Expenses.
  - Added dedicated persona cards ("Who is it for?"): Boarders (Anak Kos), Students, Young Workers, and Independent Souls.
  - Direct APK download card linked to GitHub Releases with dynamic version detection via GitHub API.
- **Brand-New 3D House Mascot & Cross-Platform Launcher Icons**:
  - Updated all project icon assets across Android (adaptive & standard mipmaps), iOS, Web (PWA icons & favicon), and Windows desktop with the official 3D glossy winking house mascot.
  - Synchronized in-app `BrandMark` and `MascotBadge` widgets.
  - Regenerated native splash screens via `flutter_native_splash`.

---

## [0.10.1] - 2026-11-03

### Fixed
- **Firestore Security Rules Hardening (`firestore.rules`)**:
  - Restricted `/usernames/{name}` writes so users can only create entries mapping to their own authenticated UID (`request.resource.data.uid == request.auth.uid`), and only edit or delete entries they own (`resource.data.uid == request.auth.uid`), eliminating potential username hijacking.
- **Atomic Username Reservation Transactions (`AuthController`)**:
  - Implemented Firestore Transactions (`runTransaction`) during `signUp()` and `updateUsername()` for atomic check-and-set operations, eliminating race conditions when multiple users sign up or change handles simultaneously.
  - Added clean rollback handling for auth user creation if username reservation fails.
- **Enhanced Error Diagnostics & Silent Catch Elimination**:
  - Replaced silent `catch (_) {}` blocks across `AuthController`, `TokenController`, `BillsController`, `GallonController`, `LaundryController`, and `PhotoService` with contextual `debugPrint` statements for improved debugging and maintainability.

### Changed
- **Design Token Harmonization (`AppColors`)**:
  - Added standardized module accent tokens (`water`, `waterDeep`, `lavender`, `lavenderDeep`) in `AppColors`.
  - Replaced all remaining hardcoded hex colors across `HomeScreen`, `GallonScreen`, `LaundryScreen`, `RemindersScreen`, and `OnboardingScreen` with centralized design tokens.

---

## [0.10.0] - 2026-11-03

### Added
- **Weekly Living Expense View & Period Mode Toggle (`ExpensePeriodMode`, `MonthlyExpenseSheet`)**:
  - Added segmented mode switcher allowing users to toggle between **Monthly** and **Weekly** expense views.
  - Weekly view calculates living expenses in exact 7-day windows (bills due in that week, token purchases, and laundry costs).
  - Clean previous/next week navigation arrows and dynamic week date range preview.
- **Live Real-Time Firestore Synchronization (`SyncService`)**:
  - Integrated active Firestore snapshot stream listener (`_doc(uid).snapshots()`) for genuine live two-way sync across multiple devices.
  - Changes made on one device are immediately delivered and reflected in real-time on all active paired devices without manual refresh.
  - Implemented local cache echo suppression (`snap.metadata.hasPendingWrites`) to prevent redundant write loops.

---

## [0.9.0] - 2026-11-03

### Added
- **Monthly Living Expense Overview & CSV Export (`MonthlyExpenseCalculator`, `MonthlyExpenseSheet`)**:
  - Automatically aggregates living expenses per month: Recurring Bills (accounting for split bill portion), Electricity Token purchases, and Laundry orders.
  - Interactive monthly expense bottom sheet with month switcher, grand total card, and category breakdown badges.
  - One-tap CSV export (`toCsv()`) and clean summary text copy (`toSummaryText()`) to clipboard for personal budgeting or roommate expense sharing.
  - Quick-glance monthly expense banner and analytics action button on `BillsScreen`.
- **Optional Laundry Cost Tracking (`LaundryOrder`, `DropOffDialog`, `LaundryScreen`)**:
  - Added optional cost (Rp) input when dropping off laundry, enabling accurate monthly laundry cost tracking.
- **Routine Completion History & Streak Insights (`RoutineTask`, `RoutinesController`, `RoutineScreen`)**:
  - Automatically records timestamped completion history (capped at 10 to keep storage minimal) and shows total completed count on each routine card.
- **Shared Nest Code Preparation (`ProfileController`, `ProfilePage`)**:
  - Added unique Nest Code (House ID) in user profile with one-tap clipboard copy, laying the groundwork for shared roommate and family data synchronization.
- **Tactile Haptic Feedback Micro-interactions**:
  - Added subtle, satisfying haptic feedback (`HapticFeedback.lightImpact()`) when completing routines, replacing water gallons, and paying bills.
- **Expanded Automated Unit Test Suite (`test/`)**:
  - Unit tests expanded to 22 tests, including `test/expense_test.dart` and `test/routines_test.dart`.

---

## [0.8.0] - 2026-11-03

### Added
- **Split Bill Calculation & Roommate Sharing (`BillsController`, `AddBillDialog`, `BillsScreen`)**:
  - Added `splitWays` selector (1 to 10 persons) with dynamic live share calculation preview in `AddBillDialog`.
  - Added cozy green split badge (`Split N (Rp X/person)`) to bill cards on `BillsScreen` when a bill is shared with roommates.
  - Fully backward compatible `Bill` serialization with `splitWays` defaulting to 1 for legacy records.
- **Automated Unit Test Suite (`test/`)**:
  - Comprehensive unit test suite covering 18 automated tests across core domain logic:
    - `test/token_test.dart`: kWh estimation, daily rate learning, days-left countdown, and serialization.
    - `test/gallon_test.dart`: Gallon consumption learning, default days, intervals, and sorting.
    - `test/bills_test.dart`: Due date calculation, overdue detection, mark paid cycle advancement, and split bill math.
    - `test/sync_test.dart`: Full 6-module snapshot and profile JSON serialization.
    - `test/profile_test.dart`: Disk avatar caching, memory cleanup, and migration from legacy SharedPreferences.

### Changed
- **Optimized Profile Photo Storage (`PhotoService`, `ProfileController`)**:
  - User avatars are now persisted as local `.jpg` files in the app's documents directory (`/avatars/<uid>.jpg`) instead of large Base64 strings in `SharedPreferences`.
  - Seamless automatic migration from legacy Base64 SharedPreferences on startup.
  - Significantly reduces app memory footprint and Android XML storage churn while maintaining complete cloud synchronization compatibility.

---

## [0.7.2] - 2026-10-31

### Fixed
- **Release Signing Configuration & Keystore Integration**:
  - Integrated persistent release signing key (`release-keystore.jks`) and `key.properties` into the repository (matching the `wall_o_pay` release configuration).
  - Ensures all release APKs produced by GitHub Actions share the identical cryptographic certificate signature, preventing the Android "App not installed as package conflicts with an existing package" signature conflict during in-place APK updates.

---

## [0.7.1] - 2026-10-31

### Fixed
- **Multi-Device Account & Profile Synchronization**:
  - Unified `ProfileController` with `SyncService` so that user nicknames and custom avatar photos are stored directly in cloud backups and synced across all devices.
  - Resolved Firestore document overwrite issue in `SyncService._push()` by applying `SetOptions(merge: true)`, preserving account fields (`username`, `email`, `nickname`, `photo`).
  - Updated `firestore.rules` to recursively match subcollection document operations (`match /users/{uid}/{document=**}`).
  - Upgraded Auth state listener to `FirebaseAuth.instance.userChanges()` to capture immediate profile and display name updates.

### Added
- **Username Customization in Profile**:
  - Added in-app username update dialog in `ProfilePage` (`@username`), enabling users to change their username with real-time uniqueness validation and Firestore mapping updates.

---

## [0.7.0] - 2026-10-31

### Added
- **In-App GitHub Release Update Checker (`UpdateCheckerService`)**:
  - Automatically checks GitHub Releases API (`https://api.github.com/repos/hyenavia/nesty/releases/latest`) on launch and on-demand.
  - Compares local SemVer against remote release version.
  - Interactive "Update Available!" dialog displaying full release notes formatted cleanly.
  - Direct one-tap "Update Now" download targeting `Nesty.apk` via external browser intent (`url_launcher`).
- **Dynamic Update Status & Indicators (`ProfileScreen`)**:
  - Added "Check for Updates" tile with dynamic subtitle (`Nesty v0.7.0 • Latest Release` or `v0.7.0 ➔ v0.7.x (Update Available!)`).
  - Eye-catching vibrant orange/peach `NEW` badge when an update is available.
  - Manual check trigger with toast status feedback (`Checking for updates...` and `You are using the latest version`).
- **Feedback & Bug Reporting (`send_feedback`)**:
  - Dedicated "Send Feedback" option in Settings linking to the repository issue tracker.
- **Cross-Platform URL Launching (`url_launcher`)**:
  - Added `url_launcher` dependency with Android `<queries>` declarations for secure HTTPS URL dispatching.

---

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

