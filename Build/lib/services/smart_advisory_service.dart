// ─────────────────────────────────────────────────────────────────────────────
// lib/services/smart_advisory_service.dart
//
// The BRAIN of KisanMitra.
//
// This service:
//   1. Listens to Firebase for new sensor data
//   2. Automatically checks thresholds
//   3. Triggers Gemini for advisory when conditions warrant it
//   4. Generates instant rule-based alerts (no API call needed for simple cases)
//   5. Saves advisories to Firestore for history
//
// TWO ADVISORY MODES:
//   A) Rule-based (instant, offline): Simple threshold checks
//      "Soil moisture < 30% → Show 'Irrigate Now' alert"
//   B) AI-powered (Gemini): Complex, context-aware advice
//      "Given wheat crop + low moisture + high temp → nuanced advice"
// ─────────────────────────────────────────────────────────────────────────────

import '../core/app_constants.dart';
import '../models/iot_sensor_model.dart';
import 'gemini_service.dart';
import 'firebase_service.dart';

// ── Alert data class ──────────────────────────────────────────────────────────
class FarmAlert {
  final String     emoji;
  final String     title;
  final String     description;
  final AlertLevel level;
  final DateTime   timestamp;

  const FarmAlert({
    required this.emoji,
    required this.title,
    required this.description,
    required this.level,
    required this.timestamp,
  });
}

enum AlertLevel { info, warning, critical }

// ── Advisory result ───────────────────────────────────────────────────────────
class AdvisoryResult {
  final List<FarmAlert> instantAlerts;  // Rule-based, no API call
  final String?         aiAdvisory;     // Gemini-generated advice
  final bool            hasIssues;

  const AdvisoryResult({
    required this.instantAlerts,
    this.aiAdvisory,
    required this.hasIssues,
  });
}

class SmartAdvisoryService {
  static final SmartAdvisoryService _instance = SmartAdvisoryService._internal();
  factory SmartAdvisoryService() => _instance;
  SmartAdvisoryService._internal();

  final GeminiService  _gemini  = GeminiService();
  final FirebaseService _firebase = FirebaseService();

  // Callback: called when automatic advisory is ready
  void Function(AdvisoryResult)? onAutoAdvisory;

  // ─────────────────────────────────────────────────────────────────────────
  // RULE-BASED INSTANT ALERTS (No API call — works offline)
  // These fire immediately when sensor data is received
  // ─────────────────────────────────────────────────────────────────────────
  List<FarmAlert> generateInstantAlerts({
    required IoTSensorReading sensor,
    required String cropType,
  }) {
    final alerts = <FarmAlert>[];
    final now    = DateTime.now();

    // ── Soil Moisture Alerts ──────────────────────────────────────────────
    if (sensor.soilMoisture < 20) {
      alerts.add(FarmAlert(
        emoji:       '🚨',
        title:       'Critical: Irrigate Immediately!',
        description: 'Soil moisture is ${sensor.soilMoisture.toStringAsFixed(1)}% — '
                     'critically low for $cropType. Irrigate as soon as possible, '
                     'preferably before 8 AM.',
        level:       AlertLevel.critical,
        timestamp:   now,
      ));
    } else if (sensor.soilMoisture < AppConstants.soilMoistureLow) {
      alerts.add(FarmAlert(
        emoji:       '💧',
        title:       'Low Soil Moisture — Plan Irrigation',
        description: 'Soil moisture at ${sensor.soilMoisture.toStringAsFixed(1)}%. '
                     'Schedule irrigation within the next 24 hours.',
        level:       AlertLevel.warning,
        timestamp:   now,
      ));
    } else if (sensor.soilMoisture > AppConstants.soilMoistureHigh) {
      alerts.add(FarmAlert(
        emoji:       '🌊',
        title:       'Soil Overwatered — Stop Irrigation',
        description: 'Soil moisture at ${sensor.soilMoisture.toStringAsFixed(1)}% — '
                     'too high. Stop irrigation. Risk of root rot for $cropType.',
        level:       AlertLevel.warning,
        timestamp:   now,
      ));
    }

    // ── Temperature Alerts ────────────────────────────────────────────────
    if (sensor.temperature > AppConstants.temperatureHigh) {
      alerts.add(FarmAlert(
        emoji:       '🌡️',
        title:       'Heat Stress Alert',
        description: 'Temperature is ${sensor.temperature.toStringAsFixed(1)}°C. '
                     'Irrigate during early morning (5–7 AM) or evening (6–8 PM). '
                     'Avoid midday irrigation — high evaporation loss.',
        level:       AlertLevel.warning,
        timestamp:   now,
      ));
    } else if (sensor.temperature < AppConstants.temperatureLow) {
      alerts.add(FarmAlert(
        emoji:       '❄️',
        title:       'Frost Risk Alert',
        description: 'Temperature is ${sensor.temperature.toStringAsFixed(1)}°C. '
                     'Risk of frost damage to $cropType. '
                     'Cover young plants. Irrigate lightly to protect roots.',
        level:       AlertLevel.critical,
        timestamp:   now,
      ));
    }

    // ── Humidity Alerts ───────────────────────────────────────────────────
    if (sensor.humidity > AppConstants.humidityHigh) {
      alerts.add(FarmAlert(
        emoji:       '🦠',
        title:       'High Humidity — Disease Risk',
        description: 'Humidity at ${sensor.humidity.toStringAsFixed(1)}%. '
                     'High risk of fungal diseases (blight, rust, powdery mildew) '
                     'for $cropType. Inspect plants for symptoms. '
                     'Consider preventive fungicide if persists over 48h.',
        level:       AlertLevel.warning,
        timestamp:   now,
      ));
    } else if (sensor.humidity < AppConstants.humidityLow) {
      alerts.add(FarmAlert(
        emoji:       '🏜️',
        title:       'Low Humidity — Drought Stress',
        description: 'Humidity at ${sensor.humidity.toStringAsFixed(1)}%. '
                     'Plants may experience drought stress. '
                     'Increase irrigation frequency for $cropType.',
        level:       AlertLevel.info,
        timestamp:   now,
      ));
    }

    // ── Combined condition: Hot + Dry ─────────────────────────────────────
    if (sensor.temperature > 35 && sensor.soilMoisture < 35) {
      alerts.add(FarmAlert(
        emoji:       '☀️💧',
        title:       'Hot & Dry — Immediate Action',
        description: 'High temperature (${sensor.temperature.toStringAsFixed(1)}°C) '
                     'combined with low soil moisture (${sensor.soilMoisture.toStringAsFixed(1)}%). '
                     'This is the most stressful condition for $cropType. '
                     'Irrigate immediately in early morning.',
        level:       AlertLevel.critical,
        timestamp:   now,
      ));
    }

    // ── All Clear ─────────────────────────────────────────────────────────
    if (alerts.isEmpty) {
      alerts.add(FarmAlert(
        emoji:       '✅',
        title:       'Conditions Optimal',
        description: 'All sensor readings are within optimal range for $cropType. '
                     'Continue regular monitoring.',
        level:       AlertLevel.info,
        timestamp:   now,
      ));
    }

    return alerts;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FULL AI ADVISORY: Combines rule alerts + Gemini intelligence
  // ─────────────────────────────────────────────────────────────────────────
  Future<AdvisoryResult> generateFullAdvisory({
    required IoTSensorReading sensor,
    required String cropType,
    String language = 'en',
    String? userQuestion,
    String userId = 'default_user',
  }) async {
    // Step 1: Instant rule-based alerts (no API needed)
    final alerts  = generateInstantAlerts(sensor: sensor, cropType: cropType);
    final hasIssues = alerts.any((a) => a.level != AlertLevel.info);

    // Step 2: Call Gemini for comprehensive advice
    String? aiAdvice;
    try {
      if (userQuestion != null && userQuestion.isNotEmpty) {
        // User asked something specific
        aiAdvice = await _gemini.sendMessage(
          userMessage: userQuestion,
          sensorData:  sensor,
          cropType:    cropType,
          language:    language,
        );
      } else if (hasIssues) {
        // Auto-advisory when issues detected
        aiAdvice = await _gemini.generateAutoAdvisory(
          sensorData: sensor,
          cropType:   cropType,
          language:   language,
        );
      }

      // Step 3: Save advisory to Firestore for history
      if (aiAdvice != null) {
        await _firebase.saveAdvisory(
          userId:    userId,
          advisory:  aiAdvice,
          sensorData: sensor,
          cropType:  cropType,
        );
      }
    } catch (e) {
      // Don't fail if AI call fails — instant alerts still work
      aiAdvice = null;
    }

    return AdvisoryResult(
      instantAlerts: alerts,
      aiAdvisory:    aiAdvice,
      hasIssues:     hasIssues,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIREBASE LISTENER: Auto-trigger advisory on data change
  // ─────────────────────────────────────────────────────────────────────────
  void startAutoAdvisoryListener({
    required String cropType,
    required String language,
    required String userId,
    required void Function(AdvisoryResult) onAdvisory,
  }) {
    _firebase.startSensorListener(
      onData: (IoTSensorReading newReading) async {
        // New sensor data arrived from ESP32 → generate advisory
        final result = await generateFullAdvisory(
          sensor:    newReading,
          cropType:  cropType,
          language:  language,
          userId:    userId,
        );
        onAdvisory(result);
      },
    );
  }

  void stopAutoAdvisoryListener() {
    _firebase.stopSensorListener();
  }
}
