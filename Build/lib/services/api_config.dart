// ─────────────────────────────────────────────────────────────────────────────
// services/api_config.dart
//
// Single place to manage all API configuration.
// Change _env to switch between development and production.
// ─────────────────────────────────────────────────────────────────────────────

enum AppEnv { development, production }

class ApiConfig {
  // ── Change this ONE line to switch environments ───────────────────────────
  static const AppEnv _env = AppEnv.development;

  // ── URLs for each environment ─────────────────────────────────────────────
  static const Map<AppEnv, String> _urls = {
    // Android emulator uses 10.0.2.2 to reach the host machine's localhost
    AppEnv.development: 'http://10.0.2.2:5000/api',

    // Replace with your deployed server URL before releasing
    AppEnv.production: 'https://api.yourdomain.com/api',
  };

  /// The base URL currently in use
  static String get baseUrl => _urls[_env]!;

  /// True when running in development mode
  static bool get isDev => _env == AppEnv.development;

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration sensorRefresh  = Duration(seconds: 30); // IoT auto-refresh

  // ── Supported mandi cities ────────────────────────────────────────────────
  static const List<String> mandiCities = [
    'All Cities',
    'Raipur',
    'Bhopal',
    'Nagpur',
    'Mumbai',
    'Hyderabad',
  ];

  // ── Supported weather cities ──────────────────────────────────────────────
  static const List<String> weatherCities = [
    'Raipur',
    'Bhopal',
    'Nagpur',
    'Mumbai',
    'Hyderabad',
    'Indore',
    'Delhi',
    'Pune',
  ];
}
