import 'package:flutter/material.dart';

class SchemeCard extends StatelessWidget {
  final Map<String, dynamic> scheme;
  final VoidCallback onBookmark;
  const SchemeCard({super.key, required this.scheme, required this.onBookmark});

  @override
  Widget build(BuildContext context) {
    final color = scheme['color'] as Color;
    final bg    = scheme['bg'] as Color;
    final bookmarked = scheme['bookmark'] as bool;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(scheme['emoji'] as String, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(scheme['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 2),
                    Text(scheme['full'] as String,
                        style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onBookmark,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Icon(
                        bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        key: ValueKey(bookmarked),
                        color: bookmarked ? const Color(0xFF2E7D32) : Colors.grey[400],
                        size: 22,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(scheme['cat'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(scheme['benefit'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(scheme['desc'] as String,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.5),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Material(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Center(child: Text('Learn More', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
                      ),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: Material(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Center(child: Text('Apply Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
                      ),
                    ),
                  )),
                ]),
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}
