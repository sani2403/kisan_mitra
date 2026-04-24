// ─────────────────────────────────────────────────────────────────────────────
// models/weather_model.dart
//
// Data models for Weather and Forecast API responses.
// These classes convert raw JSON (from Flask API) into typed Dart objects.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── Current Weather ───────────────────────────────────────────────────────────
class WeatherData {
  final String city;
  final String country;
  final int    temperature;
  final int    feelsLike;
  final int    tempMin;
  final int    tempMax;
  final int    humidity;
  final int    windSpeed;
  final String condition;
  final int    conditionId;
  final String emoji;
  final Color  color;
  final int    rainChance;
  final double visibility;
  final String sunrise;
  final String sunset;
  final bool   isDay;

  const WeatherData({
    required this.city,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.conditionId,
    required this.emoji,
    required this.color,
    required this.rainChance,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    required this.isDay,
  });

  /// Parse from the JSON returned by GET /api/weather
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      city:        json['city']         as String? ?? 'Unknown',
      country:     json['country']      as String? ?? 'IN',
      temperature: (json['temperature'] as num?)?.toInt() ?? 0,
      feelsLike:   (json['feels_like']  as num?)?.toInt() ?? 0,
      tempMin:     (json['temp_min']    as num?)?.toInt() ?? 0,
      tempMax:     (json['temp_max']    as num?)?.toInt() ?? 0,
      humidity:    (json['humidity']    as num?)?.toInt() ?? 0,
      windSpeed: (json['wind_speed'] as num?)?.round() ?? 0,
      condition:   json['condition']    as String? ?? 'Unknown',
      conditionId: (json['condition_id']as num?)?.toInt() ?? 800,
      emoji:       json['emoji']        as String? ?? '⛅',
      // Parse hex color string like "#1565C0" → Color
      color:       _hexToColor(json['color'] as String? ?? '#1565C0'),
      rainChance:  (json['rain_chance'] as num?)?.toInt() ?? 0,
      visibility:  (json['visibility']  as num?)?.toDouble() ?? 10.0,
      sunrise:     json['sunrise']      as String? ?? '--:--',
      sunset:      json['sunset']       as String? ?? '--:--',
      isDay:       json['is_day']       as bool?   ?? true,
    );
  }

  static Color _hexToColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF1565C0);
    }
  }
}

// ── Single Forecast Day ───────────────────────────────────────────────────────
class ForecastDay {
  final String day;
  final String date;
  final String emoji;
  final int    high;
  final int    low;
  final String desc;
  final int    rain;
  final int    wind;
  final int    humid;
  final Color  color;

  const ForecastDay({
    required this.day,
    required this.date,
    required this.emoji,
    required this.high,
    required this.low,
    required this.desc,
    required this.rain,
    required this.wind,
    required this.humid,
    required this.color,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      day:   json['day']   as String? ?? '',
      date:  json['date']  as String? ?? '',
      emoji: json['emoji'] as String? ?? '⛅',
      high:  (json['high'] as num?)?.toInt() ?? 0,
      low:   (json['low']  as num?)?.toInt() ?? 0,
      desc:  json['desc']  as String? ?? '',
      rain:  (json['rain'] as num?)?.toInt() ?? 0,
      wind:  (json['wind'] as num?)?.toInt() ?? 0,
      humid: (json['humid']as num?)?.toInt() ?? 0,
      color: WeatherData._hexToColor(json['color'] as String? ?? '#1565C0'),
    );
  }
}
