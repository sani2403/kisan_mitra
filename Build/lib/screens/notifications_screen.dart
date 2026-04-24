import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {'emoji': '🌧️', 'title': 'Rain Alert',        'desc': 'Heavy rain expected in your area tonight. Cover stored crops.', 'time': '5 min ago',  'type': 'warning', 'read': false},
    {'emoji': '📈', 'title': 'Price Surge',        'desc': 'Onion prices up 8.3% today in Lasalgaon mandi. Good selling opportunity.', 'time': '1 hr ago',   'type': 'success', 'read': false},
    {'emoji': '🏛️', 'title': 'PM-KISAN Update',   'desc': 'New installment of ₹2,000 released. Check your bank account.', 'time': '3 hrs ago',  'type': 'info',    'read': false},
    {'emoji': '⚠️', 'title': 'Pest Alert',         'desc': 'Locust activity reported 50km from your area. Stay alert.', 'time': '6 hrs ago',  'type': 'warning', 'read': true},
    {'emoji': '💧', 'title': 'Irrigation Reminder','desc': 'Scheduled irrigation due for Wheat field tomorrow at 6 AM.', 'time': '1 day ago',  'type': 'info',    'read': true},
    {'emoji': '🌱', 'title': 'Sowing Window',      'desc': 'Optimal sowing window for Rabi crops starts in 3 days.', 'time': '1 day ago',  'type': 'success', 'read': true},
    {'emoji': '📡', 'title': 'Sensor Update',      'desc': 'Soil moisture sensor reading critically low at 28%. Irrigate soon.', 'time': '2 days ago', 'type': 'warning', 'read': true},
    {'emoji': '💰', 'title': 'Market Report',      'desc': 'Weekly market summary is ready. Cotton prices stable this week.', 'time': '3 days ago', 'type': 'info',    'read': true},
  ];

  String _filter = 'All';
  final _filters = ['All', 'Unread', 'Alerts', 'Market', 'Schemes'];

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'Unread') return _notifications.where((n) => !(n['read'] as bool)).toList();
    if (_filter == 'Alerts') return _notifications.where((n) => n['type'] == 'warning').toList();
    if (_filter == 'Market') return _notifications.where((n) => (n['title'] as String).toLowerCase().contains('market') || (n['title'] as String).toLowerCase().contains('price')).toList();
    if (_filter == 'Schemes') return _notifications.where((n) => (n['title'] as String).toLowerCase().contains('kisan') || (n['title'] as String).toLowerCase().contains('scheme')).toList();
    return _notifications;
  }

  final _typeConfig = {
    'warning': {'color': Color(0xFFF57F17), 'bg': Color(0xFFFFF8E1)},
    'success': {'color': Color(0xFF2E7D32), 'bg': Color(0xFFE8F5E9)},
    'info':    {'color': Color(0xFF1565C0), 'bg': Color(0xFFE3F0FD)},
  };

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final unreadCount = _notifications.where((n) => !(n['read'] as bool)).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(unreadCount),
          _buildFilters(),
          Expanded(
            child: list.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final n = list[i];
                      final cfg = _typeConfig[n['type']]!;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 200 + i * 50),
                        curve: Curves.easeOut,
                        builder: (ctx, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child)),
                        child: _NotificationCard(
                          notification: n,
                          config: cfg,
                          onTap: () => setState(() => n['read'] = true),
                          onDismiss: () => setState(() => _notifications.remove(n)),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(int unread) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          if (unread > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(10)),
              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ],
        ]),
        const SizedBox(height: 3),
        Text('Stay updated on your farm', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ]),
      if (unread > 0)
        TextButton(
          onPressed: () => setState(() { for (final n in _notifications) n['read'] = true; }),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E7D32), padding: EdgeInsets.zero),
          child: const Text('Mark all read', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
    ]),
  );

  Widget _buildFilters() => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 2),
    child: SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final f = _filters[i];
          final sel = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? const Color(0xFF2E7D32) : Colors.grey.shade300),
                boxShadow: sel ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
              ),
              child: Text(f, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.grey[600])),
            ),
          );
        },
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🔔', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 16),
      const Text('No notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
      const SizedBox(height: 8),
      Text('You\'re all caught up!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
    ]),
  );
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final Map<String, Color> config;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.config,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !(notification['read'] as bool);
    return Dismissible(
      key: Key('${notification['title']}_${notification['time']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread ? Colors.white : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: unread ? config['color']!.withOpacity(0.2) : Colors.transparent),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(unread ? 0.07 : 0.04),
                blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: config['bg'], borderRadius: BorderRadius.circular(13)),
              child: Center(child: Text(notification['emoji'] as String, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(notification['title'] as String,
                    style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600, fontSize: 14, color: const Color(0xFF1A1A1A))),
                if (unread)
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: config['color'])),
              ]),
              const SizedBox(height: 4),
              Text(notification['desc'] as String,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.45), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(notification['time'] as String,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500)),
            ])),
          ]),
        ),
      ),
    );
  }
}
