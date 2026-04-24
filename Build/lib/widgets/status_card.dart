import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final Animation<double> pulse;
  final String status;   // "normal" | "warning" | "critical"
  final String message;

  const StatusCard({
    super.key,
    required this.pulse,
    this.status  = 'normal',
    this.message = 'All systems normal',
  });

  @override
  Widget build(BuildContext context) {
    final isOk = status == 'normal';
    final gradColors = isOk
        ? const [Color(0xFF1B5E20), Color(0xFF2E7D32)]
        : status == 'warning'
            ? const [Color(0xFF7F4F00), Color(0xFFE65100)]
            : const [Color(0xFF7F0000), Color(0xFFC62828)];

    final dotColor = isOk ? const Color(0xFF69F0AE) : const Color(0xFFFFEB3B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: gradColors.last.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ScaleTransition(scale: pulse, child: Container(width: 10, height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor))),
            const SizedBox(width: 8),
            Text(isOk ? 'All systems normal' : (status == 'warning' ? 'Attention needed' : 'Critical alert'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
          child: Text(isOk ? '🌾' : (status == 'warning' ? '⚠️' : '🚨'), style: const TextStyle(fontSize: 28)),
        ),
      ]),
    );
  }
}
