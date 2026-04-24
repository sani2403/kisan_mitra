// models/sensor_model.dart — IoT Sensor models

class SensorReading {
  final double value;
  final String unit;
  final String status;   // "normal"|"good"|"moderate"|"low"|"high"|"critical"|"ideal"

  const SensorReading({
    required this.value,
    required this.unit,
    required this.status,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      value:  (json['value'] as num?)?.toDouble() ?? 0.0,
      unit:   json['unit']   as String? ?? '',
      status: json['status'] as String? ?? 'normal',
    );
  }

  String get displayValue {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class SensorControls {
  final bool irrigationOn;
  final bool autoMode;

  const SensorControls({required this.irrigationOn, required this.autoMode});

  factory SensorControls.fromJson(Map<String, dynamic> json) {
    return SensorControls(
      irrigationOn: json['irrigation_on'] as bool? ?? false,
      autoMode:     json['auto_mode']     as bool? ?? true,
    );
  }
}

class SensorData {
  final String         timestamp;
  final String         farmStatus;     // "normal"|"warning"|"critical"
  final String         statusMessage;
  final SensorReading  temperature;
  final SensorReading  soilMoisture;
  final SensorReading  humidity;
  final SensorReading  light;
  final SensorReading  soilPh;
  final SensorReading  waterLevel;
  final SensorControls controls;

  const SensorData({
    required this.timestamp,
    required this.farmStatus,
    required this.statusMessage,
    required this.temperature,
    required this.soilMoisture,
    required this.humidity,
    required this.light,
    required this.soilPh,
    required this.waterLevel,
    required this.controls,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final s = json['sensors'] as Map<String, dynamic>? ?? {};
    return SensorData(
      timestamp:     json['timestamp']      as String? ?? '',
      farmStatus:    json['farm_status']    as String? ?? 'normal',
      statusMessage: json['status_message'] as String? ?? 'All systems normal',
      temperature:   SensorReading.fromJson(s['temperature']   as Map<String, dynamic>? ?? {}),
      soilMoisture:  SensorReading.fromJson(s['soil_moisture'] as Map<String, dynamic>? ?? {}),
      humidity:      SensorReading.fromJson(s['humidity']      as Map<String, dynamic>? ?? {}),
      light:         SensorReading.fromJson(s['light']         as Map<String, dynamic>? ?? {}),
      soilPh:        SensorReading.fromJson(s['soil_ph']       as Map<String, dynamic>? ?? {}),
      waterLevel:    SensorReading.fromJson(s['water_level']   as Map<String, dynamic>? ?? {}),
      controls:      SensorControls.fromJson(json['controls']  as Map<String, dynamic>? ?? {}),
    );
  }
}
