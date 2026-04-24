// ─────────────────────────────────────────────────────────────────────────────
// widgets/api_widgets.dart
//
// Reusable widgets for loading, error, and empty states.
// Used across all API-integrated screens.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── Loading spinner with label ────────────────────────────────────────────────
class ApiLoader extends StatelessWidget {
  final String message;
  const ApiLoader({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(
        width: 36, height: 36,
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32), strokeWidth: 3),
      ),
      const SizedBox(height: 14),
      Text(message,
          style: TextStyle(fontSize: 14, color: Colors.grey[500])),
    ]),
  );
}

// ── Error state with retry button ─────────────────────────────────────────────
class ApiError extends StatelessWidget {
  final String  emoji;
  final String  title;
  final String  message;
  final VoidCallback onRetry;

  const ApiError({
    super.key,
    this.emoji   = '😕',
    this.title   = 'Something went wrong',
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        Text(message,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Try Again',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),
        // Show the raw error in debug mode
        Text('Details: $message',
            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class ApiEmpty extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const ApiEmpty({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A))),
      const SizedBox(height: 8),
      Text(subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          textAlign: TextAlign.center),
    ]),
  );
}

// ── Pull-to-refresh hint banner ───────────────────────────────────────────────
class RefreshHint extends StatelessWidget {
  const RefreshHint({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.arrow_downward_rounded, size: 12, color: Colors.grey[400]),
      const SizedBox(width: 5),
      Text('Pull down to refresh',
          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
    ]),
  );
}

// ── Last updated chip ─────────────────────────────────────────────────────────
class LastUpdatedChip extends StatelessWidget {
  final String time;
  const LastUpdatedChip({super.key, required this.time});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF2E7D32).withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFF2E7D32))),
      const SizedBox(width: 5),
      Text(time,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600)),
    ]),
  );
}
