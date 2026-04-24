import 'package:flutter/material.dart';

class OrganicTipCard extends StatelessWidget {
  final Map<String, dynamic> tip;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleBookmark;

  const OrganicTipCard({
    super.key,
    required this.tip,
    required this.onToggleExpand,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final expanded = tip['expanded'] as bool;
    final bookmarked = tip['bookmarked'] as bool;
    final color = tip['iconColor'] as Color;
    final bgColor = tip['color'] as Color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onToggleExpand,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(tip['emoji'] as String, style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tip['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(tip['category'] as String,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
                    ),
                  ])),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onToggleBookmark,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          key: ValueKey(bookmarked),
                          color: bookmarked ? const Color(0xFF2E7D32) : Colors.grey[400],
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400], size: 24),
                  ),
                ]),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: expanded
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(height: 1, color: Colors.grey.shade100),
                          const SizedBox(height: 12),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.info_outline_rounded, color: color, size: 14),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(
                              tip['description'] as String,
                              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.55),
                            )),
                          ]),
                        ]),
                      )
                    : const SizedBox.shrink(),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
