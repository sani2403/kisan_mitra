import 'package:flutter/material.dart';

class PriceCard extends StatelessWidget {
  final String crop, emoji, price, change, market;
  final bool isPositive;

  const PriceCard({super.key, required this.crop, required this.emoji, required this.price, required this.change, required this.isPositive, required this.market});

  @override
  Widget build(BuildContext context) {
    final posColor = const Color(0xFF2E7D32);
    final negColor = const Color(0xFFD32F2F);
    final c = isPositive ? posColor : negColor;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 128,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
                child: Text(change, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: c)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(crop, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 2),
            Text(market, style: TextStyle(fontSize: 10, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text('₹$price', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c)),
            Text('/quintal', style: TextStyle(fontSize: 9, color: Colors.grey[400])),
          ]),
        ),
      ),
    );
  }
}
