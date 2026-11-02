# Nesty 🏠✨
> **Little Things, Taken Care Of.**

[![Release](https://img.shields.io/badge/release-v0.11.1-orange.svg)](https://github.com/hyenavia/nesty/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.47+-blue.svg)](https://flutter.dev)

A calm, modern, and offline-first personal assistant designed for independent living. Nesty keeps track of electricity tokens, water gallon refills, laundry pickups, daily household supplies, and recurring cleaning routines—so everything is sorted before it becomes an emergency.

---

## 🌟 Key Features

* **⚡ Offline-First Architecture**: Powered by instant local storage (SharedPreferences) for zero-latency startup and full offline reliability.
* **☁️ Transparent Cloud Sync**: Optional Firebase Authentication (Email & Username) with real-time Firestore synchronization across all your devices.
* **🔑 Dual Login & Recovery**: Sign in using either your `@username` or verified email, with instant password reset delivery.
* **👤 Custom Profile**: Personalize your nickname, upload custom avatar photos from device gallery, and keep credentials secure.
* **📦 Smart Stock Tracker**: Manage household essentials (Food, Bathroom, First Aid, Cleaning) with status indicators: *Safe*, *Running Low*, and *Out of Stock*.
* **🧹 Recurring Cleaning Routines**: Set custom recurring cadences (daily, weekly, or custom intervals) so household chores never pile up.
* **💧 Utilities Countdown**: Predictive tracking for PLN electricity tokens and drinking water gallons.
* **🔔 Smart Reminders**: Native, timezone-aware push notifications scheduled to your personal daily routine.
* **🌐 Multilingual**: Complete native bilingual support for **Bahasa Indonesia** and **English**.

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (3.47.0 or newer)
* Android SDK & Java 17 / 21

### Running the App
```bash
# Clone the repository
git clone https://github.com/hyenavia/nesty.git
cd nesty

# Install dependencies
flutter pub get

# Run in debug mode
flutter run
```

---

## 📱 Web Landing Page
The web landing page is hosted under `/docs` and accessible via GitHub Pages:
* [Web Landing Page Preview](docs/index.html)

---

## 📜 License
This project is open-source and licensed under the [MIT License](LICENSE).
