import 'package:flutter/material.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  String _filter = 'Name';
  String _search = '';
  final _ctrl = TextEditingController();
  late AnimationController _animCtrl;

  final _filters = ['Name', 'Price', 'Change'];

  final List<Map<String, dynamic>> _all = [
    {'crop': 'Wheat',     'emoji': '🌾', 'location': 'Delhi Mandi',     'price': 2340,  'change': 2.3,  'bookmarked': false},
    {'crop': 'Rice',      'emoji': '🌾', 'location': 'Mumbai APMC',     'price': 3120,  'change': -1.1, 'bookmarked': true},
    {'crop': 'Maize',     'emoji': '🌽', 'location': 'Pune Mandi',      'price': 1890,  'change': 4.7,  'bookmarked': false},
    {'crop': 'Soybean',   'emoji': '🫘', 'location': 'Indore Mandi',    'price': 5230,  'change': 1.2,  'bookmarked': true},
    {'crop': 'Cotton',    'emoji': '🌸', 'location': 'Nagpur Mandi',    'price': 6780,  'change': -0.8, 'bookmarked': false},
    {'crop': 'Sugarcane', 'emoji': '🎋', 'location': 'Kolhapur Mandi',  'price': 3450,  'change': 0.5,  'bookmarked': false},
    {'crop': 'Tomato',    'emoji': '🍅', 'location': 'Nashik Mandi',    'price': 1560,  'change': -5.2, 'bookmarked': false},
    {'crop': 'Onion',     'emoji': '🧅', 'location': 'Lasalgaon',       'price': 2100,  'change': 8.3,  'bookmarked': true},
    {'crop': 'Potato',    'emoji': '🥔', 'location': 'Agra Mandi',      'price': 1200,  'change': -2.1, 'bookmarked': false},
    {'crop': 'Chilli',    'emoji': '🌶️', 'location': 'Guntur Mandi',    'price': 9800,  'change': 3.4,  'bookmarked': false},
    {'crop': 'Turmeric',  'emoji': '🌿', 'location': 'Erode Mandi',     'price': 8200,  'change': 1.8,  'bookmarked': false},
    {'crop': 'Garlic',    'emoji': '🧄', 'location': 'Neemuch Mandi',   'price': 7600,  'change': -3.5, 'bookmarked': false},
  ];

  List<Map<String, dynamic>> get _filtered {
    var list = _all.where((c) =>
        _search.isEmpty ||
        (c['crop'] as String).toLowerCase().contains(_search.toLowerCase()) ||
        (c['location'] as String).toLowerCase().contains(_search.toLowerCase())).toList();
    if (_filter == 'Price') list.sort((a, b) => (b['price'] as int) - (a['price'] as int));
    else if (_filter == 'Change') list.sort((a, b) => (b['change'] as double).compareTo(a['change'] as double));
    else list.sort((a, b) => (a['crop'] as String).compareTo(b['crop'] as String));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animCtrl.forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final crops = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildSearch(),
                _buildFilters(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text('${crops.length} crops found',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ),
                ...crops.asMap().entries.map((e) {
                  return TweenAnimationBuilder<double>(
                    key: ValueKey('${e.value['crop']}_${e.key}'),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 200 + e.key * 40),
                    curve: Curves.easeOut,
                    builder: (ctx, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
                    child: _CropCard(crop: e.value, onBookmark: () => setState(() => e.value['bookmarked'] = !e.value['bookmarked'])),
                  );
                }).toList(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Market Prices 📊', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 3),
        Text('Live mandi prices across India', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ]),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2E7D32))),
          const SizedBox(width: 6),
          const Text('Live', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      ),
    ]),
  );

  Widget _buildSearch() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: _ctrl,
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search crop or market...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
          suffixIcon: _search.isNotEmpty ? IconButton(
              icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
              onPressed: () { _ctrl.clear(); setState(() => _search = ''); }) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ),
  );

  Widget _buildFilters() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(children: [
      Text('Sort: ', style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      ..._filters.map((f) {
        final sel = _filter == f;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () { _animCtrl.reset(); setState(() => _filter = f); _animCtrl.forward(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? const Color(0xFF2E7D32) : Colors.grey.shade300),
                boxShadow: sel ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
              ),
              child: Text(f, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.grey[600])),
            ),
          ),
        );
      }).toList(),
    ]),
  );
}

class _CropCard extends StatelessWidget {
  final Map<String, dynamic> crop;
  final VoidCallback onBookmark;
  const _CropCard({required this.crop, required this.onBookmark});

  @override
  Widget build(BuildContext context) {
    final pos = (crop['change'] as double) >= 0;
    final c = pos ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.07), borderRadius: BorderRadius.circular(13)),
                child: Center(child: Text(crop['emoji'] as String, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(crop['crop'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.location_on_rounded, size: 11, color: Colors.grey[400]),
                  const SizedBox(width: 2),
                  Text(crop['location'] as String, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${crop['price']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${pos ? '↑' : '↓'} ${(crop['change'] as double).abs()}%',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c)),
                ),
                const SizedBox(height: 2),
                Text('/quintal', style: TextStyle(fontSize: 9.5, color: Colors.grey[400])),
              ]),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onBookmark,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Icon(
                    (crop['bookmarked'] as bool) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    key: ValueKey(crop['bookmarked']),
                    color: (crop['bookmarked'] as bool) ? const Color(0xFF2E7D32) : Colors.grey[400],
                    size: 22,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
