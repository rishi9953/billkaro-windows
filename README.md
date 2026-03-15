# 📱 BillKaro

**BillKaro** is a Flutter application focused on business automation, printing, geolocation services, and advanced business utility features. Built using **Flutter**, **GetX**, **Google Maps**, **Bluetooth Printing**, and other production-ready tools.

---

## 🚀 Features

✅ State management using **GetX**
✅ **Google Maps** integration
✅ **Geolocation & Geocoding** services
✅ **Bluetooth printing & Thermal printing support**
✅ **Contact access** using flutter_contacts
✅ Local storage using SharedPreferences
✅ Connectivity monitoring
✅ Image picker & Lottie animations
✅ SVG support
✅ Localization support (Intl + Flutter Localization)

---

## 🛠️ Tech Stack & Dependencies

### Core

| Package            | Purpose                             |
| ------------------ | ----------------------------------- |
| get                | State management, navigation        |
| shared_preferences | Local storage                       |
| connectivity_plus  | Network monitoring                  |
| url_launcher       | Open URLs & external apps           |
| intl               | Localization & internationalization |

### Location & Maps

| Package             | Purpose           |
| ------------------- | ----------------- |
| google_maps_flutter | Display maps      |
| geolocator          | GPS positioning   |
| geocoding           | Reverse geocoding |

### Bluetooth & Printing

| Package                   | Purpose                 |
| ------------------------- | ----------------------- |
| flutter_bluetooth_printer | Bluetooth printing      |
| flutter_thermal_printer   | Thermal printer support |
| flutter_blue_plus         | BLE operations          |

### UI & Assets

| Package     | Purpose              |
| ----------- | -------------------- |
| flutter_svg | SVG image support    |
| lottie      | Animated JSON assets |
| gap         | Spacing widgets      |

### Code Generators

| Package            | Purpose                        |
| ------------------ | ------------------------------ |
| build_runner       | Code generation                |
| retrofit_generator | API services (Retrofit)        |
| json_serializable  | JSON model generation          |
| flutter_gen_runner | Asset & localization generator |

---

## 📂 Project Structure

```
lib/
 ┣ modules/
 ┣ widgets/
 ┣ services/
 ┣ controllers/  (GetX)
 ┣ models/
 ┗ main.dart
```

---

## ⚙️ Prerequisites

* Flutter **3.9.0+**
* Android Studio / Xcode
* Bluetooth-enabled device for printer testing

---

## ▶️ Getting Started

### Install packages

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Code Generation Commands

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📁 Assets

* /assets/ — General resources
* /assets/lottie/ — Lottie animations
* /assets/svg/ — Icons & SVG files
* Custom font (**Lexend**) included

---

## 🌐 Localization

Flutter localization enabled with flutter_gen

---

## 📩 Contribution

Feel free to contribute or raise issues to improve this project ✨

---

## 🧾 License

This project is private and not published on pub.dev.
