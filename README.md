# ☀️ AquaSol Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-v3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://android.com)
[![Release](https://img.shields.io/badge/Download-Latest%20APK-FF5722?logo=github&logoColor=white)](https://github.com/Ganeshchaithanya/AquaSol/releases/latest/download/app-release.apk)

**AquaSol** is a smart irrigation management app powered by AI and real-time sensor data. Designed for modern farmers, it connects to a network of ESP32 field nodes monitoring soil humidity, temperature, rainfall, and water flow — delivering live telemetry straight to your phone. The built-in ML engine automatically predicts optimal irrigation schedules using LSTM forecasting and XGBoost models trained on your farm's own history. Control solenoid valves manually or let the system decide, with built-in safety overrides for dry-run protection and automatic rain vetoes. AquaSol keeps your crops healthy, your water usage efficient, and your farm running smart — from anywhere.

---

## 🚀 Official APK Download
You can download and install the latest stable production build of the Android application here:
👉 **[Download AquaSol Latest Release APK](https://github.com/Ganeshchaithanya/AquaSol/releases/latest/download/app-release.apk)**

*Includes the native aspect-ratio dynamic startup video and custom high-resolution AquaSol branding launcher icons.*

---

## 🛠️ Features
*   **Dynamic Telemetry Analytics:** High-fidelity real-time chart visualizations of ground humidity, ambient temperature, battery levels, and water flow rates.
*   **AI/ML Irrigation Planner:** Interface showing predictions, forecasts, and schedules calculated by the LSTM forecasting models and XGBoost duration classifiers.
*   **Cyber-Physical Controls:** Direct manual activation of solenoid valves with safety dry-run check overrides and rain veto triggers.
*   **Branded Experience:** Premium aspect-ratio launching videos and professional custom application icons.

---

## 💻 Developer Quick Start

### 1. Prerequisites
Ensure you have the Flutter SDK installed on your development machine.
*   **Flutter SDK:** `>=3.22.0`
*   **Dart SDK:** `>=3.4.0`

### 2. Clone and Setup
```bash
# Get all dependent package modules
flutter pub get
```

### 3. Configure API Connection
Create a `.env` file in the root folder of the mobile app to set your endpoint:
```env
API_BASE_URL="https://aquasol-software.onrender.com/api/v1"
```

### 4. Run the Application
Connect your physical device or emulator and execute:
```bash
# Debug Mode
flutter run

# Compile Production Release APK
flutter build apk --release
```
*The compiled artifact will be generated at `build/app/outputs/flutter-apk/app-release.apk`.*

