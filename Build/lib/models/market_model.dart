// models/market_model.dart — Mandi price models

class MandiCrop {
  final String crop;
  final String emoji;
  final int    price;
  final String unit;
  final String trend;    // "up" | "down" | "stable"
  final double change;   // % change, e.g. +2.3 or -1.5
  final String grade;
  final String city;

  const MandiCrop({
    required this.crop,
    required this.emoji,
    required this.price,
    required this.unit,
    required this.trend,
    required this.change,
    required this.grade,
    this.city = '',
  });

  bool get isPositive => change >= 0;

  /// Formatted price string with commas
  String get formattedPrice {
    final s = price.toString();
    // Insert comma for thousands (simple version for Indian numbering)
    if (s.length > 3) {
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return s;
  }

  String get changeStr => '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%';

  factory MandiCrop.fromJson(Map<String, dynamic> json, {String cityName = ''}) {
    return MandiCrop(
      crop:   json['crop']   as String? ?? '',
      emoji:  json['emoji']  as String? ?? '🌾',
      price:  (json['price'] as num?)?.toInt() ?? 0,
      unit:   json['unit']   as String? ?? '₹/quintal',
      trend:  json['trend']  as String? ?? 'stable',
      change: (json['change']as num?)?.toDouble() ?? 0.0,
      grade:  json['grade']  as String? ?? '',
      city:   (json['city']  as String?) ?? cityName,
    );
  }
}

class MandiCity {
  final String        city;
  final String        state;
  final String        lastUpdated;
  final List<MandiCrop> crops;

  const MandiCity({
    required this.city,
    required this.state,
    required this.lastUpdated,
    required this.crops,
  });

  factory MandiCity.fromJson(Map<String, dynamic> json) {
    final cropList = (json['crops'] as List<dynamic>? ?? [])
        .map((c) => MandiCrop.fromJson(c as Map<String, dynamic>, cityName: json['city'] as String? ?? ''))
        .toList();
    return MandiCity(
      city:        json['city']         as String? ?? '',
      state:       json['state']        as String? ?? '',
      lastUpdated: json['last_updated'] as String? ?? '',
      crops:       cropList,
    );
  }
}
