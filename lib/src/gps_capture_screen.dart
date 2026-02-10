import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import 'models/gps_camera_config.dart';
import 'widgets/camera_overlay_widget.dart';

class GpsCaptureScreen extends StatefulWidget {
  final String imagePath;
  final Position position;
  final Placemark? placemark;
  final GpsCameraConfig config;
  const GpsCaptureScreen({
    super.key,
    required this.imagePath,
    required this.position,
    this.placemark,
    required this.config,
  });

  @override
  State<GpsCaptureScreen> createState() => _GpsCaptureScreenState();
}

class _GpsCaptureScreenState extends State<GpsCaptureScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    // Wait for the map to load tiles and the widget to render
    Future.delayed(const Duration(seconds: 2), _captureAndSave);
  }

  Future<void> _captureAndSave() async {
    try {
      // Small delay to ensure frame is painted
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Boundary not found");
      }

      // Capture image
      ui.Image image = await boundary.toImage(
        pixelRatio: 2.0,
      ); // Higher resolution
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Save to file
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'gps_camera_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        if (mounted) {
          Navigator.of(context).pop(file.path);
        }
      }
    } catch (e) {
      debugPrint("Error capturing overlay: $e");
      if (mounted) {
        Navigator.of(context).pop(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: AspectRatio(
              aspectRatio: widget.config.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(widget.imagePath), fit: BoxFit.cover),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: CameraOverlayWidget(
                      position: LatLng(
                        widget.position.latitude,
                        widget.position.longitude,
                      ),
                      placemark: widget.placemark,
                      dateTime: DateTime.now(),
                      config: widget.config,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Processing Image...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
