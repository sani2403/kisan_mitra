import 'package:flutter/material.dart';
import '../widgets/scheme_card.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});
  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  String _cat = 'All';
  String _search = '';
  final _ctrl = TextEditingController();

  final _cats = [
    {'label': 'All',            'emoji': '◉'},
    {'label': 'Income Support', 'emoji': '💰'},
    {'label': 'Crop Insurance', 'emoji': '🛡️'},
    {'label': 'Credit',         'emoji': '💳'},
    {'label': 'Irrigation',     'emoji': '💧'},
  ];

  final List<Map<String, dynamic>> _schemes = [
    {'name': 'PM-KISAN',  'full': 'Pradhan Mantri Kisan Samman Nidhi', 'cat': 'Income Support', 'desc': 'Direct income support of ₹6,000 per year to all farmer families across India.', 'emoji': '💰', 'color': Color(0xFF1565C0), 'bg': Color(0xFFE3F0FD), 'benefit': '₹6,000/year',  'bookmark': true},
    {'name': 'PMFBY',     'full': 'Pradhan Mantri Fasal Bima Yojana',  'cat': 'Crop Insurance', 'desc': 'Comprehensive crop insurance coverage against natural calamities, pests and diseases.', 'emoji': '🛡️', 'color': Color(0xFF2E7D32), 'bg': Color(0xFFE8F5E9), 'benefit': 'Full Coverage', 'bookmark': false},
    {'name': 'KCC',       'full': 'Kisan Credit Card Scheme',           'cat': 'Credit',         'desc': 'Short-term credit for crop cultivation, post-harvest expenses and allied activities.', 'emoji': '💳', 'color': Color(0xFF6A1B9A), 'bg': Color(0xFFF3E5F5), 'benefit': 'Up to ₹3L',   'bookmark': false},
    {'name': 'PMKSY',     'full': 'PM Krishi Sinchayee Yojana',         'cat': 'Irrigation',     'desc': 'Har Khet Ko Pani – expanding irrigation coverage to all farms across India.', 'emoji': '💧', 'color': Color(0xFF00838F), 'bg': Color(0xFFE0F7FA), 'benefit': '90% Subsidy',  'bookmark': true},
    {'name': 'PKVY',      'full': 'Paramparagat Krishi Vikas Yojana',   'cat': 'Income Support', 'desc': 'Support for organic farming clusters and certification of organic produce.', 'emoji': '🌿', 'color': Color(0xFF558B2F), 'bg': Color(0xFFF1F8E9), 'benefit': '₹50K/ha',      'bookmark': false},
    {'name': 'RKVY',      'full': 'Rashtriya Krishi Vikas Yojana',      'cat': 'Income Support', 'desc': 'Holistic development of agriculture sector through need-based flexible planning.', 'emoji': '🏗️', 'color': Color(0xFFE65100), 'bg': Color(0xFFFFF3E0), 'benefit': 'Flexible Grants','bookmark': false},
    {'name': 'ATMA',      'full': 'Agricultural Technology Management', 'cat': 'Credit',         'desc': 'Technology dissemination through farmer field schools and training programs.', 'emoji': '📚', 'color': Color(0xFFAD1457), 'bg': Color(0xFFFCE4EC), 'benefit': 'Free Training', 'bookmark': false},
    {'name': 'NHM',       'full': 'National Horticulture Mission',       'cat': 'Income Support', 'desc': 'Holistic development of horticulture sector to enhance farmer income and exports.', 'emoji': '🌸', 'color': Color(0xFF00695C), 'bg': Color(0xFFE0F2F1), 'benefit': '50% Subsidy',  'bookmark': false},
  ];

  List<Map<String, dynamic>> get _filtered => _schemes.where((s) {
    final cm = _cat == 'All' || s['cat'] == _cat;
    final sm = _search.isEmpty ||
        (s['name'] as String).toLowerCase().contains(_search.toLowerCase()) ||
        (s['full'] as String).toLowerCase().contains(_search.toLowerCase());
    return cm && sm;
  }).toList();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
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
                _buildCats(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text('${list.length} schemes available', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ),
                ...list.asMap().entries.map((e) {
                  final s = e.value;
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(s['name']),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 220 + e.key * 50),
                    curve: Curves.easeOut,
                    builder: (ctx, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child)),
                    child: SchemeCard(
                      scheme: s,
                      onBookmark: () => setState(() => s['bookmark'] = !(s['bookmark'] as bool)),
                    ),
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
        const Text('Gov. Schemes 🏛️', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 3),
        Text('Agricultural support programs', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ]),
      Material(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.filter_list_rounded, color: Color(0xFF2E7D32), size: 22)),
        ),
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
          hintText: 'Search schemes...',
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

  Widget _buildCats() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _cats[i];
          final sel = _cat == cat['label'];
          return GestureDetector(
            onTap: () => setState(() => _cat = cat['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? const Color(0xFF2E7D32) : Colors.grey.shade300),
                boxShadow: sel ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))] : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(cat['emoji'] as String, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text(cat['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.grey[600])),
              ]),
            ),
          );
        },
      ),
    ),
  );
}
