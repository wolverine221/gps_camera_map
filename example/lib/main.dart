import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gps_camera_snap/gps_camera_snap.dart';

// Get your free API key from https://www.maptiler.com/
const String mapTilerApiKey = String.fromEnvironment('MAPTILER_API_KEY');

void main() {
  if (mapTilerApiKey.isEmpty) {
    // ignore: avoid_print
    print(
      '************************************************************************************************',
    );
    // ignore: avoid_print
    print('You need to provide a MapTiler API key to run this example.');
    // ignore: avoid_print
    print('Run the following command to set the API key:');
    // ignore: avoid_print
    print('flutter run --dart-define=MAPTILER_API_KEY=YOUR_API_KEY');
    // ignore: avoid_print
    print(
      '************************************************************************************************',
    );
    return;
  }
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
          config: const GpsCameraConfig(
            mapTilerApiKey: mapTilerApiKey,
            showMap: true,
            showAddress: true,
            showCoordinates: true,
            showDate: true,
            showTime: true,
          ),
          onImageCaptured: (path) {
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
