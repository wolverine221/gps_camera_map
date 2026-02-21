import 'dart:async';
import 'package:http/http.dart' as http;

import '../models/gps_camera_config.dart';

/// Utility class to validate map API keys (MapTiler or Google Maps).
class MapTilerValidator {
  /// Validates a MapTiler API key by making a test request to the MapTiler API.
  ///
  /// Returns `true` if the API key is valid, `false` otherwise.
  static Future<bool> validate(String apiKey) async {
    if (apiKey.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse(
        'https://api.maptiler.com/maps/basic/style.json?key=$apiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      // MapTiler returns 200 for valid keys, 401/403 for invalid keys
      return response.statusCode == 200;
    } catch (e) {
      // Network error or timeout
      return false;
    }
  }

  /// Validates a Google Maps API key by making a test tile request.
  ///
  /// Returns `true` if the API key is valid, `false` otherwise.
  static Future<bool> validateGoogleMaps(String apiKey) async {
    if (apiKey.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse(
        'https://mt1.google.com/vt/lyrs=m&x=0&y=0&z=0&key=$apiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Validates the appropriate API key based on the [GpsCameraConfig.mapProvider].
  static Future<bool> validateForConfig(GpsCameraConfig config) async {
    switch (config.mapProvider) {
      case MapProvider.mapTiler:
        return validate(config.mapTilerApiKey);
      case MapProvider.googleMaps:
        return validateGoogleMaps(config.googleMapsApiKey ?? '');
    }
  }

  /// Prints a beautiful formatted log message for API key validation status.
  static void logValidationResult(
    bool isValid,
    String apiKey, {
    MapProvider provider = MapProvider.mapTiler,
  }) {
    // ANSI color codes for terminal
    const String reset = '\x1B[0m';
    const String green = '\x1B[32m';
    const String red = '\x1B[31m';
    const String yellow = '\x1B[33m';
    const String cyan = '\x1B[36m';
    const String bold = '\x1B[1m';

    final String border = '═' * 60;
    final String providerName = provider == MapProvider.mapTiler
        ? 'MapTiler'
        : 'Google Maps';

    // Safely truncate API key for display
    String displayKey = apiKey.isEmpty
        ? '(empty)'
        : apiKey.length > 8
        ? '${apiKey.substring(0, 8)}...'
        : '$apiKey...';

    if (isValid) {
      print('');
      print('$cyan$border$reset');
      print('$bold$green✓ $providerName API Key Validation$reset');
      print('$cyan$border$reset');
      print('$green  Status:$reset ${bold}SUCCESS$reset ✨');
      print('$green  API Key:$reset $displayKey');
      print(
        '$green  Message:$reset Your $providerName API key is valid and ready to use!',
      );
      print('$cyan$border$reset');
      print('');
    } else {
      print('');
      print('$yellow$border$reset');
      print('$bold$red✗ $providerName API Key Validation$reset');
      print('$yellow$border$reset');
      print('$red  Status:$reset ${bold}FAILED$reset ❌');
      print('$red  API Key:$reset $displayKey');
      print(
        '$red  Message:$reset The provided API key is invalid or unreachable.',
      );
      if (provider == MapProvider.mapTiler) {
        print(
          '$yellow  Tip:$reset Get a free API key at https://www.maptiler.com/',
        );
      } else {
        print(
          '$yellow  Tip:$reset Get an API key at https://console.cloud.google.com/',
        );
      }
      print(
        '$yellow  Note:$reset The app will still work — map will show lat/lng coordinates instead.',
      );
      print('$yellow$border$reset');
      print('');
    }
  }
}
