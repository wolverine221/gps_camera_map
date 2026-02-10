# GPS Camera

A Flutter package to capture images with an overlay of GPS location, Address, Date/Time, and a Map snippet.

Supported Platforms: **Android** & **iOS**

> **IMPORTANT:** Please test this package on a **real device**. Emulators often have issues with camera simulation and GPS location, which may lead to unexpected behavior or errors.

## Features

- Capture high-resolution images.
- Automatically fetch GPS location and Address.
- Overlay a map snippet (OpenStreetMap) on the image.
- Customizable overlay options (show/hide specific details).
- Returns the file path of the final processed image.

## Installation

Add `gps_camera` to your `pubspec.yaml`:

```yaml
dependencies:
  gps_camera:
    path: ./gps_camera # If local
    # or git url
```

## Setup

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS

Add the following keys to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take pictures with GPS data.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location access to tag your photos.</string>
```

## Usage

```dart
import 'package:gps_camera/gps_camera.dart';

// ...

Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => GpsCamera(
      config: const GpsCameraConfig(
        showMap: true,
        showAddress: true,
        showCoordinates: true,
        showDate: true,
        showTime: true,
        mapTilerApiKey: "YOUR_API_KEY_HERE", // Get a free key from https://www.maptiler.com/
      ),
      onImageCaptured: (path) {
        print("Image captured at: $path");
        // Display or use the image
      },
    ),
  ),
);
```

## Configuration

`GpsCameraConfig` allows you to toggle:
- `showMap`: Show/Hide the mini-map.
- `showAddress`: Show/Hide the reversed geocoded address.
- `showDate` / `showTime`: Show/Hide timestamp.
- `showCoordinates`: Show/Hide Lat/Long.
- `mapTilerApiKey`: Your MapTiler API key. **Hint:** You can get a free API key from [MapTiler](https://www.maptiler.com/).

## Dependencies

- `camera`
- `geolocator`
- `geocoding`
- `flutter_map` (for the map overlay)
