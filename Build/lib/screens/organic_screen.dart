import 'package:flutter/material.dart';
import '../widgets/organic_tip_card.dart';
import '../widgets/category_chip.dart';

class OrganicScreen extends StatefulWidget {
  const OrganicScreen({super.key});
  @override
  State<OrganicScreen> createState() => _OrganicScreenState();
}

class _OrganicScreenState extends State<OrganicScreen> with SingleTickerProviderStateMixin {
  String _selectedCat = 'Pest Control';
  String _search = '';
  final _searchCtrl = TextEditingController();
  late AnimationController _listCtrl;

  final _categories = [
    {'label': 'All',               'emoji': '🌾'},
    {'label': 'Pest Control',      'emoji': '🐛'},
    {'label': 'Soil Enrichment',   'emoji': '🪱'},
    {'label': 'Natural Fertilizer','emoji': '🌱'},
  ];

  final List<Map<String, dynamic>> _allTips = [
    {
      'title': 'Neem Oil Spray',
      'category': 'Pest Control',
      'emoji': '🌿',
      'color': Color(0xFFE8F5E9),
      'iconColor': Color(0xFF2E7D32),
      'description': 'Mix 2 tbsp of neem oil with 1 tsp of liquid soap in 1 liter of water. Spray on affected plants every 7 days. Best applied in early morning or late evening.',
      'bookmarked': false,
      'expanded': false,
    },
    {
      'title': 'Garlic Spray',
      'category': 'Pest Control',
      'emoji': '🧄',
      'color': Color(0xFFFFF8E1),
      'iconColor': Color(0xFFFF8F00),
      'description': 'Blend 4 garlic cloves with 1 cup water, strain, dilute 1:10 with water. Effective against aphids and caterpillars. Spray every 3–4 days.',
      'bookmarked': true,
      'expanded': false,
    },
    {
      'title': 'Chili & Ginger Spray',
      'category': 'Pest Control',
      'emoji': '🌶️',
      'color': Color(0xFFFFEBEE),
      'iconColor': Color(0xFFD32F2F),
      'description': 'Boil 100g chili and 50g ginger in 1 liter water for 30 mins. Strain and dilute 1:5 before spraying. Repels insects and mites effectively.',
      'bookmarked': false,
      'expanded': false,
    },
    {
      'title': 'Vermicompost',
      'category': 'Soil Enrichment',
      'emoji': '🪱',
      'color': Color(0xFFF3E5F5),
      'iconColor': Color(0xFF7B1FA2),
      'description': 'Add vermicompost at 2–5 tonnes per hectare before sowing. Improves water retention, aeration, and microbial activity. Mix with top soil before planting.',
      'bookmarked': false,
      'expanded': false,
    },
    {
      'title': 'Green Manuring',
      'category': 'Soil Enrichment',
      'emoji': '🌾',
      'color': Color(0xFFE8F5E9),
      'iconColor': Color(0xFF388E3C),
      'description': 'Grow Dhaincha or Sunhemp for 45 days, then plow them into the soil. Adds 60–90 kg N/ha and improves organic matter significantly.',
      'bookmarked': false,
      'expanded': false,
    },
    {
      'title': 'Cow Dung Slurry',
      'category': 'Natural Fertilizer',
      'emoji': '🐄',
      'color': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFE65100),
      'description': 'Mix 10 kg fresh cow dung in 100 liters water. Let ferment for 3–4 days, stir daily. Dilute 1:10 before application. Rich in nitrogen and microbes.',
      'bookmarked': true,
      'expanded': false,
    },
    {
      'title': 'Banana Peel Fertilizer',
      'category': 'Natural Fertilizer',
      'emoji': '🍌',
      'color': Color(0xFFFFF9C4),
      'iconColor': Color(0xFFF9A825),
      'description': 'Soak banana peels in water for 48 hours. Use the liquid to water plants. Rich in potassium, phosphorus, and calcium. Ideal for fruiting crops.',
      'bookmarked': false,
      'expanded': false,
    },
    {
      'title': 'Ash Spray',
      'category': 'Pest Control',
      'emoji': '🔥',
      'color': Color(0xFFECEFF1),
      'iconColor': Color(0xFF546E7A),
      'description': 'Dissolve 1 cup of wood ash in 5 liters of water. Strain and spray on leaves. Controls soft-bodied pests like aphids and spider mites naturally.',
      'bookmarked': false,
      'expanded': false,
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    return _allTips.where((t) {
      final catMatch = _selectedCat == 'All' || t['category'] == _selectedCat;
      final searchMatch = _search.isEmpty ||
          (t['title'] as String).toLowerCase().contains(_search.toLowerCase()) ||
          (t['description'] as String).toLowerCase().contains(_search.toLowerCase());
      return catMatch && searchMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _listCtrl.forward();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _changeCategory(String cat) {
    _listCtrl.reset();
    setState(() => _selectedCat = cat);
    _listCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final tips = _filtered;
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
                _buildCategoryChips(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text('${tips.length} tips found',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ),
                ...tips.asMap().entries.map((e) {
                  final idx = e.key;
                  final tip = e.value;
                  return TweenAnimationBuilder<double>(
                    key: ValueKey('${tip['title']}_$idx'),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 250 + idx * 50),
                    curve: Curves.easeOut,
                    builder: (ctx, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
                    ),
                    child: OrganicTipCard(
                      tip: tip,
                      onToggleExpand: () => setState(() => tip['expanded'] = !(tip['expanded'] as bool)),
                      onToggleBookmark: () => setState(() => tip['bookmarked'] = !(tip['bookmarked'] as bool)),
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

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Organic Farming 🌿',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 3),
          Text('Natural remedies & tips',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ]),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: const Text('🌱', style: TextStyle(fontSize: 20)),
        ),
      ]),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Search tips...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
            suffixIcon: _search.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                    onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final cat = _categories[i];
            return CategoryChip(
              label: cat['label'] as String,
              emoji: cat['emoji'] as String,
              isSelected: _selectedCat == cat['label'],
              onTap: () => _changeCategory(cat['label'] as String),
            );
          },
        ),
      ),
    );
  }
}
