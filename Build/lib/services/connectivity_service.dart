// ─────────────────────────────────────────────────────────────────────────────
// services/connectivity_service.dart
//
// Simple connectivity checker.
// Tries a lightweight GET to the backend health endpoint.
// Returns true if server is reachable, false otherwise.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ConnectivityService {
  /// Ping the backend to check if it's reachable.
  /// Returns true = server is up, false = offline or server down.
  static Future<bool> isServerReachable() async {
    try {
      final uri = Uri.parse(ApiConfig.baseUrl.replaceAll('/api', ''));
      final response = await http.get(uri)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Check basic internet connectivity by pinging Google DNS
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns a user-friendly error message based on connectivity state
  static Future<String> getDiagnosticMessage() async {
    final internet = await hasInternet();
    if (!internet) return 'No internet connection. Check your WiFi or mobile data.';

    final server = await isServerReachable();
    if (!server) {
      return 'Server is not reachable.\n'
          '• Make sure Flask is running: python app.py\n'
          '• Check the server URL in api_config.dart';
    }
    return 'Connected';
  }
}
