// ─────────────────────────────────────────────────────────────────────────────
// screens/iot_screen.dart  (API-integrated version)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/sensor_model.dart';
import '../widgets/sensor_card.dart';
import '../widgets/status_card.dart';

class IoTScreen extends StatefulWidget {
  const IoTScreen({super.key});
  @override
  State<IoTScreen> createState() => _IoTScreenState();
}

class _IoTScreenState extends State<IoTScreen> with TickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────────────────────
  bool        _loading = true;
  String?     _error;
  SensorData? _sensorData;
  bool        _irrigationOn = false;
  bool        _autoMode     = true;
  Timer?      _refreshTimer;   // auto-refresh every 30 seconds

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fetchData();
    // Auto-refresh sensor data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchData());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    // Don't show full-screen loader on auto-refresh, only on manual/first load
    if (_sensorData == null) setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getSensorData();
      if (!mounted) return;
      setState(() {
        _sensorData   = data;
        _irrigationOn = data.controls.irrigationOn;
        _autoMode     = data.controls.autoMode;
        _loading      = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Could not load sensor data.'; _loading = false; });
    }
  }

  // Build sensor list from SensorData model
  List<Map<String, dynamic>> _buildSensorList() {
    if (_sensorData == null) return [];
    final s = _sensorData!;
    return [
      _sensorEntry('🌡️', 'Temperature',  s.temperature,  const Color(0xFF2E7D32), const Color(0xFFE8F5E9), 45.0),
      _sensorEntry('💧', 'Soil Moisture', s.soilMoisture, const Color(0xFF1565C0), const Color(0xFFE3F0FD), 100.0),
      _sensorEntry('🌫️', 'Humidity',     s.humidity,     const Color(0xFFF57F17), const Color(0xFFFFF8E1), 100.0),
      _sensorEntry('☀️', 'Light',         s.light,        const Color(0xFFE65100), const Color(0xFFFFF3E0), 1200.0),
      _sensorEntry('🌱', 'Soil pH',       s.soilPh,       const Color(0xFF2E7D32), const Color(0xFFF1F8E9), 14.0),
      _sensorEntry('🚰', 'Water Level',   s.waterLevel,   const Color(0xFFC62828), const Color(0xFFFFEBEE), 100.0),
    ];
  }

  Map<String, dynamic> _sensorEntry(
    String emoji, String name, SensorReading reading,
    Color statusColor, Color bgColor, double maxVal,
  ) {
    return {
      'name':        name,
      'emoji':       emoji,
      'value':       reading.displayValue,
      'unit':        reading.unit,
      'status':      _statusLabel(reading.status),
      'statusColor': _statusColor(reading.status),
      'bgColor':     bgColor,
      'progress':    (reading.value / maxVal).clamp(0.0, 1.0),
    };
  }

  String _statusLabel(String s) => const {
    'normal': 'Normal', 'good': 'Good', 'moderate': 'Moderate',
    'low': 'Low', 'high': 'High', 'critical': 'Critical', 'ideal': 'Ideal',
  }[s] ?? s.toUpperCase();

  Color _statusColor(String s) => const {
    'normal':   Color(0xFF2E7D32),
    'good':     Color(0xFF2E7D32),
    'ideal':    Color(0xFF2E7D32),
    'moderate': Color(0xFFF57F17),
    'low':      Color(0xFFC62828),
    'high':     Color(0xFFE65100),
    'critical': Color(0xFFC62828),
  }[s] ?? const Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ])),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 3),
        SizedBox(height: 16),
        Text('Reading sensors...', style: TextStyle(color: Colors.grey, fontSize: 14)),
      ]),
    );

    if (_error != null) return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );

    final sensors = _buildSensorList();
    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildStatusBanner()),
          SliverToBoxAdapter(child: _buildLiveSensorsHeader()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 280 + i * 65),
                  curve: Curves.easeOutBack,
                  builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
                  child: SensorCard(sensor: sensors[i]),
                ),
                childCount: sensors.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildTrends()),
          SliverToBoxAdapter(child: _buildControls()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Smart Farm 📡', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 3),
        Text(_sensorData != null ? 'Last sync: just now' : 'Live farm monitoring',
            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ]),
      Material(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _fetchData,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(padding: EdgeInsets.all(10),
              child: Icon(Icons.refresh_rounded, color: Color(0xFF2E7D32), size: 22)),
        ),
      ),
    ]),
  );

  Widget _buildStatusBanner() {
    final isOk = _sensorData?.farmStatus == 'normal';
    final msg  = _sensorData?.statusMessage ?? 'Connecting...';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: StatusCard(pulse: _pulse, status: _sensorData?.farmStatus ?? 'normal', message: msg),
    );
  }

  Widget _buildLiveSensorsHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('Live Sensors', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(scale: _pulse, child: Container(width: 7, height: 7,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2E7D32)))),
          const SizedBox(width: 5),
          const Text('Live', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    ]),
  );

  Widget _buildTrends() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Trends', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        Text('Last 24 hours', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ]),
      const SizedBox(height: 14),
      Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _dot(const Color(0xFF2E7D32)), const SizedBox(width: 5),
              Text('Temperature', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(width: 14),
              _dot(const Color(0xFF1565C0)), const SizedBox(width: 5),
              Text('Soil Moisture', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ]),
            const SizedBox(height: 10),
            Expanded(child: CustomPaint(painter: _ChartPainter(), child: Container())),
          ]),
        ),
      ),
    ]),
  );

  Widget _dot(Color c) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: c));

  Widget _buildControls() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Controls', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          _controlRow('💧', 'Irrigation', 'Controls water pump', _irrigationOn, const Color(0xFF1565C0),
              (v) => setState(() => _irrigationOn = v)),
          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
          _controlRow('🤖', 'Auto Mode', 'AI-driven farm control', _autoMode, const Color(0xFF2E7D32),
              (v) => setState(() => _autoMode = v)),
        ]),
      ),
    ]),
  );

  Widget _controlRow(String emoji, String title, String sub, bool value, Color activeColor, ValueChanged<bool> onChanged) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: value ? activeColor.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A1A))),
          Text(sub, style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
        ])),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: activeColor),
      ]),
    );
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tempData  = [26.0,27.5,28.0,29.0,27.0,28.5,28.0,26.5,27.0,28.0,27.5,28.0];
    final moistData = [60.0,62.0,65.0,63.0,67.0,65.0,64.0,66.0,65.0,63.0,65.0,65.0];

    void drawLine(List<double> data, Color color, double min, double max) {
      final paint = Paint()..color = color..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final x = i / (data.length - 1) * size.width;
        final y = size.height - ((data[i] - min) / (max - min)) * size.height;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      final fillPath = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
      canvas.drawPath(fillPath, Paint()..color = color.withOpacity(0.07)..style = PaintingStyle.fill);
      canvas.drawPath(path, paint);
    }

    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.12)..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = i / 3 * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    drawLine(tempData,  const Color(0xFF2E7D32), 24, 31);
    drawLine(moistData, const Color(0xFF1565C0), 55, 72);
  }
  @override
  bool shouldRepaint(_) => false;
}
