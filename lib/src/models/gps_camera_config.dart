enum CameraAspectMode { square, portrait, fullscreen }

/// Map tile provider to use for the overlay map.
enum MapProvider {
  /// Use MapTiler tiles (default). Requires [GpsCameraConfig.mapTilerApiKey].
  mapTiler,

  /// Use Google Maps tiles. Requires [GpsCameraConfig.googleMapsApiKey].
  googleMaps,
}

class GpsCameraConfig {
  /// The API key for MapTiler. Get a free key at https://www.maptiler.com/
  final String mapTilerApiKey;

  /// The map tile provider to use. Defaults to [MapProvider.mapTiler].
  final MapProvider mapProvider;

  /// The API key for Google Maps. Required when [mapProvider] is [MapProvider.googleMaps].
  /// Get a key at https://console.cloud.google.com/
  final String? googleMapsApiKey;

  final bool showMap;
  final bool showAddress;
  final bool showDate;
  final bool showTime;
  final bool showCoordinates;
  final CameraAspectMode aspectMode;

  /// Whether to cache map tiles to disk. Defaults to `true`.
  /// Reduces API hits significantly when working in the same area repeatedly.
  final bool cacheTiles;

  const GpsCameraConfig({
    required this.mapTilerApiKey,
    this.mapProvider = MapProvider.mapTiler,
    this.googleMapsApiKey,
    this.showMap = true,
    this.showAddress = true,
    this.showDate = true,
    this.showTime = true,
    this.showCoordinates = true,
    this.aspectMode = CameraAspectMode.portrait,
    this.cacheTiles = true,
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

  /// Returns the active API key based on the selected [mapProvider].
  String get activeApiKey {
    switch (mapProvider) {
      case MapProvider.mapTiler:
        return mapTilerApiKey;
      case MapProvider.googleMaps:
        return googleMapsApiKey ?? '';
    }
  }
}
