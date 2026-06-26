# UrbanPulse — Flutter App

**Intelligent Urban Reporting System** — Full prototype with real data logic.

---

## ✅ Features Implemented

### 📍 GPS Location Capture
- Tap the blue location button in Create Report to auto-detect your position
- Uses `geolocator` for GPS coordinates
- Reverse geocodes to a human-readable address via `geocoding`
- Coordinates are saved with every report and shown on the detail screen
- Animated pulsing dot appears on the mock map once location is captured

### 📷 Image & Video Upload
- Camera: take a photo or record a video directly
- Gallery: pick an existing photo or video
- Real file path is saved to the report and displayed as a thumbnail everywhere:
  - Report card carousel on Home
  - Report list tile in My Reports & All Reports
  - Full-size preview in Report Detail
- Tap the preview to change or remove media

### 📋 Report Submission
- Validates category and location before submitting
- Creates a `Report` object with UUID, GPS, media path, timestamp, and status
- Persisted immediately to `SharedPreferences` (survives app restart)
- 2-second simulated AI verification delay with a loading spinner
- Success dialog with "View Report" shortcut

### 🗂 Report State (Provider + SharedPreferences)
- `ReportProvider` is the single source of truth for all reports
- All screens read from and write to it via `Consumer` / `context.read()`
- Data loads from `SharedPreferences` on app start; seeds with sample data on first launch
- Add, delete, comment, and advance-status operations are all persisted

### 👁 See All Button (Fixed)
- Navigates to the new `AllReportsScreen`
- Search bar: filter reports by title, location, or description
 - Filter chips: filter by status (Received / Verified / In Progress / Resolved)
- Swipe-to-delete on My Reports screen

### 📊 Report Detail (Live)
- Status timeline updates in real time as status changes
- Actual photo/video displayed (not a placeholder) if media was attached
- "Advance Status" button (🔄 in AppBar) lets you demo the pipeline
- Delete report from the overflow menu (⋮)
- Comments are persisted and shown newest-first

### 👤 Profile (Live Data)
- Total Reports, Resolved, and Points are computed from live provider data
- Resolution Rate progress bar
- Edit Profile sheet to change name and email
- Report Statistics bottom sheet with breakdown
- Help & Support dialog

---

## 🚀 Quick Start

```bash
# 1. Unzip and enter the folder
cd urbanpulse

# 2. Get packages
flutter pub get

# 3. Run on a device or emulator
flutter run
```

### Import into Android Studio
1. **File → Open** → select the `urbanpulse/` folder
2. Wait for Gradle sync
3. Connect a device / start an emulator
4. Press **▶ Run**

> **Tip:** Run on a real device for GPS and camera to work properly.  
> On an emulator, you can set a mock location in the Extended Controls panel.

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `provider ^6.1.2` | State management |
| `image_picker ^1.1.2` | Camera + gallery photo/video |
| `geolocator ^13.0.2` | GPS coordinates |
| `geocoding ^3.0.0` | Reverse geocoding (coords → address) |
| `shared_preferences ^2.3.2` | Persist reports across sessions |
| `uuid ^4.4.2` | Unique report IDs |
| `permission_handler ^11.3.1` | Runtime permission requests |

---

## 📂 Project Structure

```
lib/
├── main.dart                        # App entry, Provider setup, routes, BottomNav
├── models/
│   └── report.dart                  # Report + ReportUpdate models, JSON serialization, seed data
├── providers/
│   └── report_provider.dart         # ChangeNotifier, CRUD, SharedPreferences persistence
├── services/
│   ├── location_service.dart        # GPS + reverse geocoding
│   └── media_service.dart           # image_picker wrapper
├── screens/
│   ├── splash_screen.dart           # Animated logo, waits for provider.load()
│   ├── home_screen.dart             # Dashboard, live stats, carousel, FAB
│   ├── all_reports_screen.dart      # Search + status filter + full list  ← NEW
│   ├── create_report_screen.dart    # Real camera/gallery, real GPS, submits to provider
│   ├── report_detail_screen.dart    # Live timeline, real media, comments, delete
│   ├── my_reports_screen.dart       # Tabbed list, swipe-to-delete
│   └── profile_screen.dart         # Live stats, editable name/email, help dialog
└── widgets/
    ├── mock_map_widget.dart         # Custom-painted map with animated GPS dot
    ├── report_card.dart             # Carousel card with real media thumbnail
    └── status_badge.dart            # Shared colored status badge

android/
├── app/
│   ├── build.gradle                 # compileSdk 35, minSdk 21
│   └── src/main/
│       ├── AndroidManifest.xml      # Camera, location, storage permissions + FileProvider
│       ├── res/xml/file_paths.xml   # FileProvider paths for image_picker
│       ├── res/values/styles.xml    # Launch + Normal theme
│       └── kotlin/.../MainActivity.kt
ios/
└── Runner/Info.plist                # NSCamera, NSLocation, NSPhotoLibrary usage strings
```

---

## 🎨 Design Tokens

| Token | Value |
|---|---|
| Primary Blue | `#1565C0` |
| Success Green | `#43A047` |
| Warning Orange | `#FB8C00` |
| Error Red | `#E53935` |
| Background | `#F5F7FA` |
| Card White | `#FFFFFF` |
| Text Primary | `#1A1A2E` |

---

## 🗺 Map Note

The map is a custom `CustomPainter` widget — **no API key required**.  
To upgrade to real maps, replace `MockMapWidget` with:
- `google_maps_flutter` (requires Google Maps API key)
- `flutter_map` + OpenStreetMap (free, no key needed)
