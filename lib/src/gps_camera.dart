import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'models/gps_camera_config.dart';
import 'services/gps_service.dart';
import 'widgets/camera_overlay_widget.dart';
import 'gps_capture_screen.dart';

class GpsCamera extends StatefulWidget {
  final GpsCameraConfig config;
  final Function(String path) onImageCaptured;

  const GpsCamera({
    super.key,
    required this.config,
    required this.onImageCaptured,
  });

  @override
  State<GpsCamera> createState() => _GpsCameraState();
}

class _GpsCameraState extends State<GpsCamera> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final GpsService _gpsService = GpsService();
  Position? _currentPosition;
  Placemark? _currentPlacemark;
  bool _isCapturing = false;
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeLocation();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initializeLocation() async {
    // Check permissions directly via GpsService or rely on the stream to handle it
    _startLocationStream();
  }

  void _startLocationStream() {
    // Get initial location
    _gpsService.getCurrentLocation().then((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _updateAddress(position);
      }
    });

    // Listen for updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _updateAddress(position);
      }
    });
  }

  Future<void> _updateAddress(Position position) async {
    final placemark = await _gpsService.getAddress(position);
    if (mounted) {
      setState(() {
        _currentPlacemark = placemark;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for GPS location...')),
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile imageFile = await _controller!.takePicture();

      if (mounted) {
        // Navigate to capture screen to process the image
        final resultPath = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GpsCaptureScreen(
              imagePath: imageFile.path,
              position: _currentPosition!,
              placemark: _currentPlacemark,
              config: widget.config,
            ),
          ),
        );

        // If a path was returned, pass it to the callback
        if (resultPath != null && resultPath is String) {
          widget.onImageCaptured(resultPath);
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _initializeControllerFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final double aspectRatio = widget.config.aspectRatio;

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview with Aspect Ratio
                Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: ClipRect(
                      child: Transform.scale(
                        scale: _controller!.value.aspectRatio / aspectRatio,
                        child: Center(child: CameraPreview(_controller!)),
                      ),
                    ),
                  ),
                ),

                // Live Overlay
                if (_currentPosition != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: CameraOverlayWidget(
                                position: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                placemark: _currentPlacemark,
                                dateTime: DateTime.now(),
                                config: widget.config,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_currentPosition == null)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                // Capture Loading Indicator
                if (_isCapturing)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),

                // Capture Button
                if (!_isCapturing)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
                            color: Colors.transparent,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
