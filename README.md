# Background Location Tracker

A Flutter app that records periodic location points in the background, stores them in local SQLite, and displays recent history plus route visualization.

## High-Level Architecture

The app uses a layered structure with clear responsibilities:

- `lib/ui/`
  - Screens and user interactions.
  - `home_screen.dart` shows service state, recent records, and permission guidance.
  - `maps_screen.dart` visualizes recorded points on Google Maps.

- `lib/services/`
  - Service orchestration and platform setup.
  - `location_service.dart` configures and controls `flutter_background_service`.

- `lib/background/`
  - Background execution entrypoint.
  - `location_background_service.dart` runs periodic fetch logic and writes location records.

- `lib/data/`
  - Persistence layer.
  - `location_db.dart` manages SQLite schema/migrations.
  - `location_repository.dart` handles DB writes/reads and UI polling stream.

- `lib/models/`
  - Domain models.
  - `location_point.dart` defines stored location data (`lat/lng`, `accuracy`, timestamp, error).

- `lib/providers/`
  - Riverpod providers connecting data layer to UI.

Data flow summary:
1. User starts tracking from UI.
2. Background service periodically fetches location.
3. Service writes records to SQLite through repository.
4. UI watches recent records stream and updates automatically.

## Key Packages Used (and Why)

- `flutter_background_service`
  - Runs periodic background Dart logic for tracking.
- `geolocator`
  - Location permission checks and location fetching.
- `sqflite`
  - Local persistence of background records.
- `flutter_riverpod` + `riverpod_annotation`
  - State management and reactive UI updates.
- `google_maps_flutter`
  - Map view and route visualization.
- `flutter_local_notifications`
  - Android notification channel for foreground/background service behavior.
- `android_intent_plus`
  - Opens Android battery optimization settings when needed.
- `url_launcher`
  - Opens external maps from location list rows.

## Background Execution Stability Strategy

To improve reliability across Android/iOS background conditions:

- Foreground/background service architecture via `flutter_background_service`.
- Background fetch loop with adaptive location strategy:
  - tries `high -> medium -> low` accuracy,
  - uses timeout per attempt,
  - falls back to last known position.
- Explicit permission and location-service checks before fetch.
- Error-tolerant persistence:
  - if fetch fails, writes an error record to keep observability.
- Timer lifecycle safety:
  - timer is canceled explicitly when service stops.
- Repository split behavior:
  - background uses write-only repository mode (`enablePolling: false`),
  - UI uses polling stream for near-real-time updates.

Important iOS note:
- iOS can suspend/stop background execution after force-kill from app switcher. This is platform behavior.

## Setup: API Keys (Do Not Commit Real Keys)

This project requires Google Maps API keys for Android and iOS.

### Android

1. Add your key to `android/local.properties`:

```properties
MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY
```

2. The key is injected into AndroidManifest via Gradle placeholder (`${MAPS_API_KEY}`).

### iOS

1. Create `ios/Config/Secrets.xcconfig` with:

```xcconfig
GOOGLE_MAPS_API_KEY = YOUR_IOS_MAPS_API_KEY
```

2. `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig` include this file.
3. `Info.plist` reads `$(GOOGLE_MAPS_API_KEY)` and `AppDelegate.swift` initializes Google Maps.

Security reminder:
- Keep key files out of source control (`.gitignore`), and never commit real keys.

## Required Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`
- `RECEIVE_BOOT_COMPLETED`
- `POST_NOTIFICATIONS` (Android 13+)
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (for OEM battery constraints)

### iOS (`ios/Runner/Info.plist`)

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- `UIBackgroundModes` includes `location`

## Run Instructions

1. Install dependencies:

```bash
flutter pub get
```

2. Configure Maps API keys (Android + iOS) as described above.

3. Run on device/emulator:

```bash
flutter run
```

Recommended testing notes:
- Use a physical device for realistic background location behavior.
- Grant location permission as required by platform flow.
- On Android OEM devices, disable battery optimization for best reliability.
