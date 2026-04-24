// ─────────────────────────────────────────────────────────────────────────────
// lib/core/app_constants.dart
//
// Central configuration for KisanMitra.
// All API keys, Firebase paths, and thresholds in one place.
// ─────────────────────────────────────────────────────────────────────────────

class AppConstants {

  // ── Gemini AI ─────────────────────────────────────────────────────────────
  // Get your free key at: https://aistudio.google.com/app/apikey
  static const String geminiApiKey = 'AIzaSyBkLDkITsWFVShyjk3Xo-2THdyTSJCkgpc';
  static const String geminiModel   = 'gemini-2.5-flash';   // Fast + free tier

  // ── Firebase Realtime Database paths ─────────────────────────────────────
  // These match exactly what the ESP32 sends
  static const String sensorBasePath    = 'sensors';           // /sensors/
  static const String farmPath          = 'farm_001';          // /sensors/farm_001/
  static const String sensorDataPath    = '$sensorBasePath/$farmPath/data';
  static const String sensorLatestPath  = '$sensorBasePath/$farmPath/latest';

  // ── Firestore collection names ────────────────────────────────────────────
  static const String chatHistoryCollection = 'chat_history';
  static const String userProfileCollection = 'users';
  static const String advisoryCollection    = 'ai_advisories';

  // ── IoT Sensor Thresholds ─────────────────────────────────────────────────
  // Triggers for automatic alerts and AI advisory
  static const double soilMoistureLow      = 30.0;  // % — below this → irrigate
  static const double soilMoistureHigh     = 80.0;  // % — above this → overwatered
  static const double temperatureHigh      = 38.0;  // °C — heat stress
  static const double temperatureLow       = 10.0;  // °C — frost risk
  static const double humidityHigh         = 85.0;  // % — fungal disease risk
  static const double humidityLow          = 30.0;  // % — drought stress

  // ── Auto-refresh ──────────────────────────────────────────────────────────
  static const Duration sensorRefreshInterval = Duration(seconds: 30);

  // ── Supported Languages ───────────────────────────────────────────────────
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
  };

  // ── Supported Crops ──────────────────────────────────────────────────────
  static const List<String> supportedCrops = [
    'Wheat',    'Rice',    'Maize',   'Soybean',
    'Cotton',   'Tomato',  'Onion',   'Potato',
    'Sugarcane','Chilli',  'Banana',  'Mustard',
  ];

  // ── Design ────────────────────────────────────────────────────────────────
  static const primaryGreen  = 0xFF2E7D32;
  static const lightGreen    = 0xFF66BB6A;
  static const darkGreen     = 0xFF1B5E20;
  static const bgColor       = 0xFFF2F5F2;
}
