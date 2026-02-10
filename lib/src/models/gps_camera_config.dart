enum CameraAspectMode { square, portrait, fullscreen }

class GpsCameraConfig {
  /// The API key for MapTiler. Get a free key at https://www.maptiler.com/
  final String mapTilerApiKey;
  final bool showMap;
  final bool showAddress;
  final bool showDate;
  final bool showTime;
  final bool showCoordinates;
  final CameraAspectMode aspectMode;

  const GpsCameraConfig({
    required this.mapTilerApiKey,
    this.showMap = true,
    this.showAddress = true,
    this.showDate = true,
    this.showTime = true,
    this.showCoordinates = true,
    this.aspectMode = CameraAspectMode.portrait,
  });

  double get aspectRatio {
    switch (aspectMode) {
      case CameraAspectMode.square:
        return 1.0;
      case CameraAspectMode.portrait:
        return 3 / 4; // 3:4 aspect ratio (standard portrait)
      case CameraAspectMode.fullscreen:
        return 9 / 16; // 9:16 aspect ratio (standard fullscreen portrait)
    }
  }
}
