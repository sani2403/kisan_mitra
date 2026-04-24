import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  int _selectedDay = 0;
  String _cityName = "Detecting location...";
  late AnimationController _entryCtrl;
  late AnimationController _iconCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late Animation<double> _iconRotate;

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _cityName = "Raipur");
        await fetchWeather("Raipur");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _cityName = "Raipur");
        await fetchWeather("Raipur");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      String city = placemarks.isNotEmpty
          ? (placemarks.first.locality ??
          placemarks.first.subAdministrativeArea ??
          "Raipur")
          : "Raipur";

      setState(() => _cityName = city);

      await fetchWeather(Uri.encodeComponent(city));

    } catch (e) {
      print("Location error: $e");

      // 🔥 NEVER STAY STUCK
      setState(() => _cityName = "Raipur");
      await fetchWeather("Raipur");
    }
  }
  Future<void> fetchWeather(String city) async {
    final url = Uri.parse(
        "http://localhost:5000/api/weather?city=$city&ts=${DateTime.now().millisecondsSinceEpoch}"
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _cityName = data['city'];

        _selectedDay = 0;

        _forecast = List.from(_forecast);

        _forecast[0] = {
          ..._forecast[0],
          'high': int.tryParse(data['temperature'].toString()) ?? 0,
          'desc': data['condition'] ?? 'Unknown',
          'wind': int.tryParse(data['wind_speed'].toString()) ?? 0,
          'humid': int.tryParse(data['humidity'].toString()) ?? 0,
        };
      });
    }
  }
  List<Map<String, dynamic>> _forecast = [
    {'day': 'Today',  'date': 'Apr 6',  'emoji': '⛅', 'high': 32, 'low': 22, 'desc': 'Partly Cloudy',   'rain': 20, 'wind': 14, 'humid': 62, 'uv': 7,  'color': Color(0xFF1565C0)},
    {'day': 'Tue',    'date': 'Apr 7',  'emoji': '🌧️', 'high': 28, 'low': 20, 'desc': 'Light Rain',       'rain': 80, 'wind': 22, 'humid': 85, 'uv': 2,  'color': Color(0xFF0277BD)},
    {'day': 'Wed',    'date': 'Apr 8',  'emoji': '⛈️', 'high': 26, 'low': 19, 'desc': 'Thunderstorm',    'rain': 95, 'wind': 35, 'humid': 90, 'uv': 1,  'color': Color(0xFF4527A0)},
    {'day': 'Thu',    'date': 'Apr 9',  'emoji': '🌤️', 'high': 30, 'low': 21, 'desc': 'Mostly Sunny',    'rain': 10, 'wind': 12, 'humid': 55, 'uv': 8,  'color': Color(0xFF2E7D32)},
    {'day': 'Fri',    'date': 'Apr 10', 'emoji': '☀️', 'high': 35, 'low': 24, 'desc': 'Clear & Sunny',   'rain': 5,  'wind': 10, 'humid': 45, 'uv': 10, 'color': Color(0xFFE65100)},
    {'day': 'Sat',    'date': 'Apr 11', 'emoji': '🌦️', 'high': 29, 'low': 21, 'desc': 'Scattered Showers','rain': 55, 'wind': 18, 'humid': 78, 'uv': 4,  'color': Color(0xFF00695C)},
    {'day': 'Sun',    'date': 'Apr 12', 'emoji': '⛅', 'high': 31, 'low': 22, 'desc': 'Partly Cloudy',   'rain': 25, 'wind': 15, 'humid': 60, 'uv': 6,  'color': Color(0xFF1565C0)},
  ];

  final _farmAdvisory = [
    {'icon': '💧', 'title': 'Irrigation Advisory',    'desc': 'Light rain expected Tuesday. Reduce irrigation by 40% for wheat fields.',      'type': 'info'},
    {'icon': '⚠️', 'title': 'Pest Alert',             'desc': 'High humidity forecast may increase aphid risk. Inspect crops by Wednesday.',   'type': 'warning'},
    {'icon': '✅', 'title': 'Harvest Window',          'desc': 'Thursday–Friday ideal for harvesting with clear skies and low humidity.',       'type': 'success'},
    {'icon': '🌱', 'title': 'Sowing Recommendation',  'desc': 'Post-rain soil moisture will be optimal for sowing on Saturday.',               'type': 'info'},
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _iconCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _iconRotate = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
    _iconCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  void _selectDay(int i) {
    _iconCtrl.reset();
    setState(() => _selectedDay = i);
    _iconCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final today = _forecast[_selectedDay];
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildMainCard(today)),
                SliverToBoxAdapter(child: _buildStatsRow(today)),
                SliverToBoxAdapter(child: _buildForecastStrip()),
                SliverToBoxAdapter(child: _buildHourlySection()),
                SliverToBoxAdapter(child: _buildFarmAdvisory()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Weather ⛅', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 3),
        Row(children: [
          const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF2E7D32)),
          const SizedBox(width: 3),
          Text(_cityName, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ]),
      ]),
      Material(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
            onTap: () async {
              await _getLocation();
            },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.my_location_rounded, color: Color(0xFF2E7D32), size: 22),
          ),
        ),
      ),
    ]),
  );

  Widget _buildMainCard(Map<String, dynamic> d) {
    final color = d['color'] as Color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 28, offset: const Offset(0, 12))],
        ),
        child: Stack(children: [
          Positioned(right: -30, top: -30, child: _wCircle(160, 0.06)),
          Positioned(left: -20, bottom: -20, child: _wCircle(120, 0.05)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['day'] as String,
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(d['desc'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ]),
                RotationTransition(
                  turns: _iconRotate,
                  child: Text(d['emoji'] as String, style: const TextStyle(fontSize: 56)),
                ),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${d['high']}',
                    style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, height: 1)),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('°C',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 28, fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.end, children: [
                  const SizedBox(height: 30),
                  _tempRow('H', '${d['high']}°'),
                  const SizedBox(height: 4),
                  _tempRow('L', '${d['low']}°'),
                ]),
              ]),
              const SizedBox(height: 4),
              Text('Feels like ${(d['high'] as int) + 2}°C · ${d['date']}',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tempRow(String label, String val) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$label ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
    Text(val, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
  ]);

  Widget _buildStatsRow(Map<String, dynamic> d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: [
        _statCard('🌧️', 'Rain', '${d['rain']}%'),
        const SizedBox(width: 10),
        _statCard('💨', 'Wind', '${d['wind']} km/h'),
        const SizedBox(width: 10),
        _statCard('💧', 'Humidity', '${d['humid']}%'),
        const SizedBox(width: 10),
        _statCard('☀️', 'UV Index', '${d['uv']}'),
      ]),
    );
  }

  Widget _statCard(String emoji, String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9.5, color: Colors.grey[500]), textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _buildForecastStrip() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: const Text('7-Day Forecast',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      ),
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: _forecast.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (ctx, i) {
            final f = _forecast[i];
            final sel = _selectedDay == i;
            final color = f['color'] as Color;
            return GestureDetector(
              onTap: () => _selectDay(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? color : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: sel ? color.withOpacity(0.35) : Colors.black.withOpacity(0.05),
                      blurRadius: sel ? 14 : 8,
                      offset: const Offset(0, 4))],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(f['day'] as String,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: sel ? Colors.white.withOpacity(0.8) : Colors.grey[500])),
                  const SizedBox(height: 6),
                  Text(f['emoji'] as String, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text('${f['high']}°',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildHourlySection() {
    final hours = [
      {'time': '6 AM', 'emoji': '🌅', 'temp': 23},
      {'time': '9 AM', 'emoji': '⛅', 'temp': 27},
      {'time': '12 PM','emoji': '☀️', 'temp': 32},
      {'time': '3 PM', 'emoji': '🌤️', 'temp': 31},
      {'time': '6 PM', 'emoji': '🌥️', 'temp': 28},
      {'time': '9 PM', 'emoji': '🌙', 'temp': 24},
      {'time': '12 AM','emoji': '🌙', 'temp': 22},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Text('Hourly Forecast',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: hours.map((h) => Column(children: [
            Text(h['time'] as String, style: TextStyle(fontSize: 9.5, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(h['emoji'] as String, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text('${h['temp']}°', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          ])).toList(),
        ),
      ),
    ]);
  }

  Widget _buildFarmAdvisory() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 22, 16, 12),
        child: Text('Farm Advisory 🌱',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      ),
      ..._farmAdvisory.asMap().entries.map((e) {
        final a = e.value;
        final configs = {
          'info':    {'bg': const Color(0xFFE3F0FD), 'color': const Color(0xFF1565C0)},
          'warning': {'bg': const Color(0xFFFFF8E1), 'color': const Color(0xFFF57F17)},
          'success': {'bg': const Color(0xFFE8F5E9), 'color': const Color(0xFF2E7D32)},
        };
        final cfg = configs[a['type']]!;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 220 + e.key * 60),
          curve: Curves.easeOut,
          builder: (ctx, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                border: Border(left: BorderSide(color: cfg['color'] as Color, width: 3)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: cfg['bg'] as Color, borderRadius: BorderRadius.circular(11)),
                  child: Center(child: Text(a['icon'] as String, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  Text(a['desc'] as String,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.45)),
                ])),
              ]),
            ),
          ),
        );
      }).toList(),
    ]);
  }

  Widget _wCircle(double s, double o) => Container(
      width: s, height: s,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(o)));
}
