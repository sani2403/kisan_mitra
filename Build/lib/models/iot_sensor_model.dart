// ─────────────────────────────────────────────────────────────────────────────
// lib/models/iot_sensor_model.dart
//
// Data model that maps exactly to what the ESP32 sends to Firebase.
//
// Firebase Realtime DB structure:
// {
//   "sensors": {
//     "farm_001": {
//       "latest": {
//         "soil_moisture": 45.2,
//         "temperature": 32.5,
//         "humidity": 68.0,
//         "timestamp": 1712400000000,
//         "device_id": "ESP32_FARM_001"
//       },
//       "data": {
//         "-NxAbCd...": {
//           "soil_moisture": 45.2,
//           "temperature": 32.5,
//           "humidity": 68.0,
//           "timestamp": 1712400000000
//         }
//       }
//     }
//   }
// }
// ─────────────────────────────────────────────────────────────────────────────

import '../core/app_constants.dart';

class IoTSensorReading {
  final double soilMoisture;   // % (0–100)
  final double temperature;    // °C
  final double humidity;       // % (0–100)
  final DateTime timestamp;
  final String deviceId;

  const IoTSensorReading({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    required this.deviceId,
  });

  // ── Parse from Firebase snapshot ─────────────────────────────────────────
  factory IoTSensorReading.fromMap(Map<dynamic, dynamic> map) {
    return IoTSensorReading(
      soilMoisture: _toDouble(map['soil_moisture']),
      temperature:  _toDouble(map['temperature']),
      humidity:     _toDouble(map['humidity']),
      timestamp:    map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt())
          : DateTime.now(),
      deviceId: map['device_id'] as String? ?? 'unknown',
    );
  }

  // ── Convert to Map for Firestore/DB write ─────────────────────────────────
  Map<String, dynamic> toMap() => {
    'soil_moisture': soilMoisture,
    'temperature':   temperature,
    'humidity':      humidity,
    'timestamp':     timestamp.millisecondsSinceEpoch,
    'device_id':     deviceId,
  };

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    return (val as num).toDouble();
  }

  // ── Status helpers ────────────────────────────────────────────────────────
  String get soilMoistureStatus {
    if (soilMoisture < AppConstants.soilMoistureLow) return 'low';
    if (soilMoisture > AppConstants.soilMoistureHigh) return 'high';
    return 'normal';
  }

  String get temperatureStatus {
    if (temperature > AppConstants.temperatureHigh) return 'high';
    if (temperature < AppConstants.temperatureLow) return 'low';
    return 'normal';
  }

  String get humidityStatus {
    if (humidity > AppConstants.humidityHigh) return 'high';
    if (humidity < AppConstants.humidityLow) return 'low';
    return 'normal';
  }

  // ── Overall alert level ───────────────────────────────────────────────────
  // Returns: 'critical' | 'warning' | 'normal'
  String get alertLevel {
    final statuses = [soilMoistureStatus, temperatureStatus, humidityStatus];
    if (statuses.any((s) => s == 'low' &&
        soilMoistureStatus == 'low' && soilMoisture < 20)) return 'critical';
    if (statuses.any((s) => s != 'normal')) return 'warning';
    return 'normal';
  }

  // ── Quick summary for display ─────────────────────────────────────────────
  String get summaryText =>
      'Moisture: ${soilMoisture.toStringAsFixed(1)}% · '
      'Temp: ${temperature.toStringAsFixed(1)}°C · '
      'Humidity: ${humidity.toStringAsFixed(1)}%';

  // ── Build a structured prompt fragment for Gemini ────────────────────────
  String toPromptFragment() =>
      'Soil Moisture: ${soilMoisture.toStringAsFixed(1)}% (${soilMoistureStatus.toUpperCase()}), '
      'Temperature: ${temperature.toStringAsFixed(1)}°C (${temperatureStatus.toUpperCase()}), '
      'Humidity: ${humidity.toStringAsFixed(1)}% (${humidityStatus.toUpperCase()})';
}

// ── Chat message model ─────────────────────────────────────────────────────
enum MessageRole { user, assistant, system }

class ChatMessage {
  final String      id;
  final String      text;
  final MessageRole role;
  final DateTime    timestamp;
  final bool        isVoice;       // was this message sent via voice?
  final IoTSensorReading? sensorSnapshot; // sensor data at time of message

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.isVoice = false,
    this.sensorSnapshot,
  });

  bool get isUser => role == MessageRole.user;
  bool get isBot  => role == MessageRole.assistant;

  Map<String, dynamic> toFirestore() => {
    'text':      text,
    'role':      role.name,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'is_voice':  isVoice,
    'sensor':    sensorSnapshot?.toMap(),
  };
}
