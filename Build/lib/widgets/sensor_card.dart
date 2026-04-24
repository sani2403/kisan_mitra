import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final Map<String, dynamic> sensor;
  const SensorCard({super.key, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final statusColor = sensor['statusColor'] as Color;
    final bgColor     = sensor['bgColor'] as Color;
    final progress    = sensor['progress'] as double;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(sensor['emoji'] as String, style: const TextStyle(fontSize: 20))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(sensor['status'] as String,
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(sensor['name'] as String,
            style: TextStyle(fontSize: 11.5, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(sensor['value'] as String,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          const SizedBox(width: 3),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(sensor['unit'] as String,
                style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: statusColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 5,
          ),
        ),
      ]),
    );
  }
}
