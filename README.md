# GPS Camera

A Flutter package to capture images with GPS coordinates, address, date, and time overlays.

## Features

- Capture images with a camera preview.
- Overlay GPS coordinates, address, date, and time on the captured image.
- Display a map with the captured location.
- Customizable overlay elements.
- **Tile Caching** — Map tiles are cached to disk to reduce API hits (great for repeated use in the same area).
- **Google Maps Support** — Use Google Maps tiles as an alternative to MapTiler.
- **Graceful API Fallback** — If the map API fails or hits rate limits, the overlay shows lat/lng text instead.

## Getting Started

1. **Get a MapTiler API Key:**
   - Go to [MapTiler](https://www.maptiler.com/) and create a free account.
   - Get your API key from the MapTiler dashboard.

2. **Set the API Key in your project:**
   - When you run your Flutter app, you need to provide the MapTiler API key as a Dart environment variable. Use the following command:

     ```bash
     flutter run --dart-define=MAPTILER_API_KEY=YOUR_API_KEY
     ```

     Replace `YOUR_API_KEY` with your actual MapTiler API key.

   > **Note:** If the API key is missing or invalid, the map will gracefully fall back to showing latitude/longitude coordinates instead.

3. **Add the package to your `pubspec.yaml`:**

   ```yaml
   dependencies:
     gps_camera_snap: ^0.0.4
   ```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:gps_camera_snap/gps_camera_snap.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GPS Camera Example')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GpsCamera(
                    config: const GpsCameraConfig(
                      mapTilerApiKey: String.fromEnvironment('MAPTILER_API_KEY'),
                      showMap: true,
                      showAddress: true,
                      showCoordinates: true,
                      showDate: true,
                      showTime: true,
                      cacheTiles: true, // Cache tiles to reduce API hits (default: true)
                    ),
                    onImageCaptured: (path) {
                      print('Image captured at: $path');
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
            child: const Text('Open Camera'),
          ),
        ),
      ),
    );
  }
}
```

## Using Google Maps Instead of MapTiler

You can switch to Google Maps tiles by setting `mapProvider`:

```dart
GpsCameraConfig(
  mapTilerApiKey: '', // Can be empty when using Google Maps
  mapProvider: MapProvider.googleMaps,
  googleMapsApiKey: 'YOUR_GOOGLE_MAPS_API_KEY',
)
```

Run with:
```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY --dart-define=USE_GOOGLE_MAPS=true
```

## Tile Caching

Map tiles are **cached to disk by default** (`cacheTiles: true`). This significantly reduces API hits when you're working repeatedly in the same area (e.g., field work in the same city/region).

- Cached tiles are served from disk on subsequent loads — no network request needed.
- Cache is managed automatically with a 1GB limit.
- To disable caching, set `cacheTiles: false`.

## Configuration Options

| Option | Type | Default | Description |
|---|---|---|---|
| `mapTilerApiKey` | `String` | *required* | MapTiler API key |
| `mapProvider` | `MapProvider` | `mapTiler` | Tile provider (`mapTiler` or `googleMaps`) |
| `googleMapsApiKey` | `String?` | `null` | Google Maps API key (required for Google Maps) |
| `showMap` | `bool` | `true` | Show map in overlay |
| `showAddress` | `bool` | `true` | Show address text |
| `showCoordinates` | `bool` | `true` | Show lat/lng coordinates |
| `showDate` | `bool` | `true` | Show date |
| `showTime` | `bool` | `true` | Show time |
| `cacheTiles` | `bool` | `true` | Cache map tiles to disk |
| `aspectMode` | `CameraAspectMode` | `portrait` | Camera aspect ratio |
