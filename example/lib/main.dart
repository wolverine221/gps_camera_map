import 'dart:io';

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
      title: 'GPS Camera Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'GPS Camera Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _capturedPath;

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GpsCamera(
          config: GpsCameraConfig(
            mapTilerApiKey:Constants.mapTilerApiKey,
            showMap: true,
            showAddress: true,
            showCoordinates: true,
            showDate: true,
            showTime: true,
          ),
          onImageCaptured: (path) {
            // Camera saves and returns path.
            // We pop back to this screen and show result.
            // But GpsCamera is a screen that pushes capture screen.
            // onImageCaptured is called from there.
            // We should pop the GpsCamera screen (and CaptureScreen)
            // OR GpsCamera handles the flow.

            // In my implementation:
            // GpsCamera -> CaptureScreen -> (pop with result) -> GpsCamera (onImageCaptured callback)

            // So inside GpsCamera, when we get result, we call onImageCaptured in `_captureImage`.
            // But we didn't pop `GpsCamera` itself.

            // So we need to pop GpsCamera here?
            Navigator.of(context).pop();
            setState(() {
              _capturedPath = path;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_capturedPath != null) ...[
              const Text(
                'Captured Image:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Image.file(File(_capturedPath!)),
              ),
              const SizedBox(height: 10),
              Text(
                _capturedPath!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else
              const Text('No image captured yet.'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        tooltip: 'Open Camera',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class Constants {
  static String mapTilerApiKey ='YJTqwOH2ibLl66ACB7lA';
}
