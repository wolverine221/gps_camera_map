# GPS Camera

A Flutter package to capture images with GPS coordinates, address, date, and time overlays.

## Features

- Capture images with a camera preview.
- Overlay GPS coordinates, address, date, and time on the captured image.
- Display a map with the captured location.
- Customizable overlay elements.

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

3. **Add the package to your `pubspec.yaml`:**

   ```yaml
   dependencies:
     gps_camera: ^0.0.1 # Replace with the latest version
   ```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:gps_camera/gps_camera.dart';

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
                    ),
                    onImageCaptured: (path) {
                      // Handle the captured image path
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
