import 'package:flutter/material.dart';

class ModuleCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const ModuleCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
