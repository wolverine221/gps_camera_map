import 'dart:async';
import 'package:http/http.dart' as http;

/// Utility class to validate MapTiler API keys
class MapTilerValidator {
  /// Validates a MapTiler API key by making a test request to the MapTiler API
  ///
  /// Returns `true` if the API key is valid, `false` otherwise
  static Future<bool> validate(String apiKey) async {
    if (apiKey.isEmpty) {
      return false;
    }

    try {
      // Test the API key with a simple tile request
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

  /// Prints a beautiful formatted log message for API key validation status
  static void logValidationResult(bool isValid, String apiKey) {
    // ANSI color codes for terminal
    const String reset = '\x1B[0m';
    const String green = '\x1B[32m';
    const String red = '\x1B[31m';
    const String yellow = '\x1B[33m';
    const String cyan = '\x1B[36m';
    const String bold = '\x1B[1m';

    final String border = '═' * 60;

    // Safely truncate API key for display
    String displayKey = apiKey.isEmpty
        ? '(empty)'
        : apiKey.length > 8
        ? '${apiKey.substring(0, 8)}...'
        : '$apiKey...';

    if (isValid) {
      // Success message
      print('');
      print('$cyan$border$reset');
      print('$bold$green✓ MapTiler API Key Validation$reset');
      print('$cyan$border$reset');
      print('$green  Status:$reset ${bold}SUCCESS$reset ✨');
      print('$green  API Key:$reset $displayKey');
      print(
        '$green  Message:$reset Your MapTiler API key is valid and ready to use!',
      );
      print('$cyan$border$reset');
      print('');
    } else {
      // Failure message
      print('');
      print('$yellow$border$reset');
      print('$bold$red✗ MapTiler API Key Validation$reset');
      print('$yellow$border$reset');
      print('$red  Status:$reset ${bold}FAILED$reset ❌');
      print('$red  API Key:$reset $displayKey');
      print(
        '$red  Message:$reset The provided API key is invalid or unreachable.',
      );
      print(
        '$yellow  Tip:$reset Get a free API key at https://www.maptiler.com/',
      );
      print('$yellow$border$reset');
      print('');
    }
  }
}
