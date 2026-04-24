// ─────────────────────────────────────────────────────────────────────────────
// services/api_service.dart
//
// Central API service for all network calls.
//
// HOW IT WORKS:
//   - All HTTP requests go through this single file (single responsibility).
//   - Returns typed model objects, not raw Maps, so screens stay clean.
//   - Throws ApiException on any error → screens show user-friendly messages.
//
// CONFIGURATION:
//   Change _baseUrl to point to your Flask server.
//   • Local development:  http://10.0.2.2:5000   (Android emulator)
//   • iPhone simulator:   http://localhost:5000
//   • Real device on WiFi: http://192.168.X.X:5000
//   • Production server:  https://your-domain.com
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/weather_model.dart';
import '../models/market_model.dart';
import '../models/sensor_model.dart';

// ── Custom exception class ───────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int?   statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (HTTP $statusCode)';
}

// ─────────────────────────────────────────────────────────────────────────────
// ApiService — all static methods, no instantiation needed
// ─────────────────────────────────────────────────────────────────────────────
class ApiService {

  // ── Base URL: change this to your Flask server address ──────────────────────
  // For Android emulator  → http://10.0.2.2:5000
  // For iOS simulator     → http://localhost:5000
  // For real device (WiFi)→ http://192.168.1.X:5000  (check your PC's IP)
  // For deployed server   → https://api.yourdomain.com
  static const String _baseUrl = 'http://10.0.2.2:5000/api';

  // Standard timeout for all requests
  static const Duration _timeout = Duration(seconds: 15);

  // ── Generic GET helper ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? params}) async {
    try {
      // Build URI with optional query parameters
      final uri = Uri.parse('$_baseUrl$path')
          .replace(queryParameters: params);

      final response = await http.get(uri).timeout(_timeout);

      // Parse JSON body
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return body;
      } else {
        // Server returned an error code
        final msg = body['error'] as String? ??
                    'Server error (${response.statusCode})';
        throw ApiException(msg, statusCode: response.statusCode);
      }

    } on SocketException {
      // No internet or server not reachable
      throw const ApiException(
          'Cannot connect to server. Check your internet connection.');
    } on HttpException {
      throw const ApiException('Network error. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response from server.');
    } on ApiException {
      rethrow;   // Already an ApiException, re-throw as-is
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // WEATHER METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Fetch current weather for a city.
  /// [city] – e.g. "Raipur", "Bhopal" (defaults to "Raipur" on server)
  ///
  /// Usage:
  ///   final weather = await ApiService.getCurrentWeather(city: 'Raipur');
  ///   print(weather.temperature);  // 32
  static Future<WeatherData> getCurrentWeather({String city = 'Raipur'}) async {
    final json = await _get('/weather', params: {'city': city});

    // If API key is missing, server may return a "fallback" key
    final data = json.containsKey('fallback')
        ? json['fallback'] as Map<String, dynamic>
        : json;

    return WeatherData.fromJson(data);
  }

  /// Fetch 7-day weather forecast for a city.
  ///
  /// Usage:
  ///   final result = await ApiService.getForecast(city: 'Raipur');
  ///   for (final day in result) { print(day.desc); }
  static Future<List<ForecastDay>> getForecast({String city = 'Raipur'}) async {
    final json = await _get('/forecast', params: {'city': city});

    // Server returns { city: "...", forecast: [...] }
    final data = json.containsKey('fallback')
        ? json['fallback'] as Map<String, dynamic>
        : json;

    final forecastList = data['forecast'] as List<dynamic>? ?? [];
    return forecastList
        .map((d) => ForecastDay.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MARKET / MANDI METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Fetch mandi prices for a specific city.
  ///
  /// Usage:
  ///   final city = await ApiService.getMandiByCity('Raipur');
  ///   for (final crop in city.crops) { print('${crop.crop}: ₹${crop.price}'); }
  static Future<MandiCity> getMandiByCity(String city) async {
    final json = await _get('/mandi', params: {'city': city});
    return MandiCity.fromJson(json);
  }

  /// Fetch mandi prices for ALL 5 cities.
  ///
  /// Usage:
  ///   final markets = await ApiService.getAllMandi();
  ///   markets.forEach((m) => print(m.city));
  static Future<List<MandiCity>> getAllMandi() async {
    final json = await _get('/mandi');
    final markets = json['markets'] as List<dynamic>? ?? [];
    return markets
        .map((m) => MandiCity.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Fetch top price movers (biggest changes today).
  ///
  /// Usage:
  ///   final movers = await ApiService.getTopMovers();
  static Future<List<MandiCrop>> getTopMovers() async {
    final json = await _get('/mandi/top-movers');
    final list = json['top_movers'] as List<dynamic>? ?? [];
    return list
        .map((c) => MandiCrop.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // IoT SENSOR METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Fetch latest sensor readings from your IoT devices.
  ///
  /// Usage:
  ///   final sensors = await ApiService.getSensorData();
  ///   print(sensors.temperature.value);   // 28.5
  ///   print(sensors.soilMoisture.status); // "good"
  static Future<SensorData> getSensorData() async {
    final json = await _get('/sensors');
    return SensorData.fromJson(json);
  }

  /// Fetch 24-hour sensor history for trend charts.
  ///
  /// Usage:
  ///   final history = await ApiService.getSensorHistory();
  ///   print(history['temperature']); // [24, 23, 22, ...]
  static Future<Map<String, dynamic>> getSensorHistory() async {
    return _get('/sensors/history');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SCHEMES METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Fetch all government schemes, optionally filtered by category.
  ///
  /// Usage:
  ///   final schemes = await ApiService.getSchemes();
  ///   final creditSchemes = await ApiService.getSchemes(category: 'Credit');
  static Future<List<Map<String, dynamic>>> getSchemes({String? category}) async {
    final params = category != null ? {'category': category} : null;
    final json = await _get('/schemes', params: params);
    final list = json['schemes'] as List<dynamic>? ?? [];
    return list.map((s) => s as Map<String, dynamic>).toList();
  }
}
