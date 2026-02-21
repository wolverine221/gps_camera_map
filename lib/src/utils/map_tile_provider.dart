import '../models/gps_camera_config.dart';

/// Utility class to build tile URLs for different map providers.
class MapTileUrlBuilder {
  /// Returns the tile URL template for the configured [MapProvider].
  ///
  /// - **MapTiler**: Uses the MapTiler Streets style.
  /// - **Google Maps**: Uses Google's standard road map tiles.
  static String getTileUrl(GpsCameraConfig config) {
    switch (config.mapProvider) {
      case MapProvider.mapTiler:
        return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${config.mapTilerApiKey}';
      case MapProvider.googleMaps:
        final key = config.googleMapsApiKey ?? '';
        if (key.isNotEmpty) {
          return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=$key';
        }
        // Fallback without key (may have limited usage)
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    }
  }

  /// Returns a user-agent package name appropriate for the provider.
  static String getUserAgent(GpsCameraConfig config) {
    switch (config.mapProvider) {
      case MapProvider.mapTiler:
        return 'com.gps_camera_snap.maptiler';
      case MapProvider.googleMaps:
        return 'com.gps_camera_snap.googlemaps';
    }
  }
}
