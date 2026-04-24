import 'package:flutter/material.dart';
import '../widgets/module_card.dart';
import '../widgets/price_card.dart';
import 'weather_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _selectedLang = 'English';
  String _farmerName = 'Farmer';
  late AnimationController _headerCtrl;
  late AnimationController _cardsCtrl;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardsFade;
  Map<String, Map<String, String>> translations = {
    'English': {
      'greeting_morning': 'Good Morning',
      'greeting_afternoon': 'Good Afternoon',
      'greeting_evening': 'Good Evening',
      'quick_access': 'Quick Access',
      'tap_weather': 'Tap to check weather',
      'market_prices': 'Market Prices',
      'view_all': 'View All',
      'ask_ai': 'Ask AI Assistant',
    'weather_desc': 'Get live forecast for your field',
    'market_live': 'Live mandi prices · Updated now',
    'ai_desc': 'Instant farming advice in your language',
      'weather': 'Weather',
      'market': 'Market',
      'schemes': 'Schemes',
      'organic': 'Organic',
      'iot': 'IoT',
      'ai_chat': 'AI Chat',
    },

    'हिंदी': {
      'greeting_morning': 'सुप्रभात',
      'greeting_afternoon': 'नमस्कार',
      'greeting_evening': 'शुभ संध्या',
      'quick_access': 'त्वरित सेवाएं',
      'tap_weather': 'मौसम देखने के लिए टैप करें',
      'market_prices': 'मंडी भाव',
      'view_all': 'सभी देखें',
      'ask_ai': 'AI से पूछें',
      'weather_desc': 'अपने खेत के लिए लाइव मौसम देखें',
      'market_live': 'लाइव मंडी भाव · अभी अपडेट',
      'ai_desc': 'अपनी भाषा में खेती की सलाह पाएं',
      'weather': 'मौसम',
      'market': 'मंडी',
      'schemes': 'योजनाएं',
      'organic': 'जैविक',
      'iot': 'आईओटी',
      'ai_chat': 'AI चैट',

    },

    'छत्तीसगढ़ी': {
      'greeting_morning': 'राम राम',
      'greeting_afternoon': 'नमस्कार',
      'greeting_evening': 'जोहाड़',
      'quick_access': 'जल्दी सेवा',
      'tap_weather': 'मौसम देखे बर टच करव',
      'market_prices': 'मंडी दाम',
      'view_all': 'सब देखव',
      'ask_ai': 'AI ले पूछव',
      'weather_desc': 'अपन खेत बर मौसम देखव',
      'market_live': 'लाइव मंडी दाम · अभी अपडेट',
      'ai_desc': 'अपन भाखा म खेती के सलाह पावव',
      'weather': 'मौसम',
      'market': 'मंडी',
      'schemes': 'योजना',
      'organic': 'जैविक',
      'iot': 'आईओटी',
      'ai_chat': 'एआई गोठ',
    }
  };
  // ✅ STEP 2: ADD HELPER FUNCTION JUST BELOW IT
  String t(String key) {
    return translations[_selectedLang]?[key] ?? key;
  }

  final _languages = ['English', 'हिंदी', 'छत्तीसगढ़ी'];

  final _modules = [
    {'emoji': '⛅', 'label': 'weather', 'color': Color(0xFF1565C0), 'bg': Color(0xFFE3F0FD)},
    {'emoji': '📈', 'label': 'market',  'color': Color(0xFF2E7D32), 'bg': Color(0xFFE8F5E9)},
    {'emoji': '🏛️', 'label': 'schemes', 'color': Color(0xFF6A1B9A), 'bg': Color(0xFFF3E5F5)},
    {'emoji': '🌿', 'label': 'organic', 'color': Color(0xFF558B2F), 'bg': Color(0xFFF1F8E9)},
    {'emoji': '📡', 'label': 'iot',     'color': Color(0xFFE65100), 'bg': Color(0xFFFFF3E0)},
    {'emoji': '🤖', 'label': 'ai_chat', 'color': Color(0xFF00838F), 'bg': Color(0xFFE0F7FA)},
  ];

  final _prices = [
    {'crop': 'Wheat',   'emoji': '🌾', 'price': '2,340', 'change': '+2.3', 'pos': true,  'mkt': 'Delhi'},
    {'crop': 'Rice',    'emoji': '🌾', 'price': '3,120', 'change': '−1.1', 'pos': false, 'mkt': 'Mumbai'},
    {'crop': 'Maize',   'emoji': '🌽', 'price': '1,890', 'change': '+4.7', 'pos': true,  'mkt': 'Pune'},
    {'crop': 'Soybean', 'emoji': '🫘', 'price': '5,230', 'change': '+1.2', 'pos': true,  'mkt': 'Indore'},
    {'crop': 'Cotton',  'emoji': '🌸', 'price': '6,780', 'change': '−0.8', 'pos': false, 'mkt': 'Nagpur'},
  ];


  Future<void> _saveLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
  }
  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedLang = prefs.getString('lang') ?? 'English';
      });
    }
  }
  @override
  void initState() {
    super.initState();
    _loadName();
    _loadLang();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _cardsCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _cardsFade  = CurvedAnimation(parent: _cardsCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () => _cardsCtrl.forward());
  }

  Future<void> _loadName() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _farmerName = p.getString('farmer_name') ?? 'Farmer');
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SlideTransition(position: _headerSlide, child: _buildHeader())),
            SliverToBoxAdapter(child: FadeTransition(opacity: _cardsFade, child: Column(children: [
              _buildWeatherCard(),
              _buildModules(),
              _buildMarketSection(),
              _buildAIBanner(),
              const SizedBox(height: 20),
            ]))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? t('greeting_morning')
        : hour < 17
        ? t('greeting_afternoon')
        : t('greeting_evening');
    final greetEmoji = hour < 12 ? '🌅' : hour < 17 ? '☀️' : '🌙';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(greeting, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Text(greetEmoji, style: const TextStyle(fontSize: 13)),
            ]),
            const SizedBox(height: 3),
            Text('$_farmerName 👨‍🌾',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          ]),
          Row(children: [
            _iconBtn(Icons.notifications_outlined, () {
              Navigator.of(context).pushNamed('/notifications');
            }),
            const SizedBox(width: 8),
            _iconBtn(Icons.person_outline_rounded, () {
              Navigator.of(context).pushNamed('/profile');
            }),
          ]),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _languages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final lang = _languages[i];
              final sel = _selectedLang == lang;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedLang = lang);
                  _saveLang(lang);   // 👈 ADD THIS LINE
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF2E7D32) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? const Color(0xFF2E7D32) : Colors.grey.shade300),
                    boxShadow: sel ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))] : [],
                  ),
                  child: Text(lang,
                      style: TextStyle(
                          fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? Colors.white : Colors.grey[600])),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Material(
    color: const Color(0xFFF5F5F5),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 20, color: const Color(0xFF2E7D32))),
    ),
  );

  Widget _buildWeatherCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WeatherScreen()),
              );
            },
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Stack(children: [
              Positioned(right: -18, top: -18, child: _circle(110, 0.06)),
              Positioned(right: 28, bottom: -28, child: _circle(90, 0.06)),
              Positioned(left: -10, bottom: -10, child: _circle(70, 0.04)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Container(
                    width: 66, height: 66,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(18)),
                    child: const Center(child: Text('⛅', style: TextStyle(fontSize: 32))),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t('tap_weather'),
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(t('weather_desc'),
                        style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12.5)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.location_on_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Detect Location', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white60, size: 28),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)));

  Widget _buildModules() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(t('quick_access'), null),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0),
          itemCount: _modules.length,
          itemBuilder: (ctx, i) {
            final m = _modules[i];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + i * 60),
              curve: Curves.easeOutBack,
              builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
              child: ModuleCard(
                emoji: m['emoji'] as String,
                label: t(m['label'] as String),
                color: m['color'] as Color,
                bgColor: m['bg'] as Color,
    onTap: () {
    switch (m['label']) {
    case 'weather':
    Navigator.pushNamed(context, '/weather');
    break;

    case 'market':
    Navigator.pushNamed(context, '/market');
    break;

    case 'schemes':
    Navigator.pushNamed(context, '/schemes');
    break;

    case 'organic':
    Navigator.pushNamed(context, '/organic');
    break;

    case 'iot':
    Navigator.pushNamed(context, '/iot');
    break;

    case 'ai_chat':
    Navigator.pushNamed(context, '/ai');
    break;
    }
    }
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildMarketSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: _sectionHeader(
          t('market_prices'),
          t('view_all'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2E7D32))),
          const SizedBox(width: 6),
          Text(t('market_live'),
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      ),
      SizedBox(
        height: 138,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: _prices.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (ctx, i) {
            final p = _prices[i];
            return PriceCard(
              crop: p['crop'] as String,
              emoji: p['emoji'] as String,
              price: p['price'] as String,
              change: p['change'] as String,
              isPositive: p['pos'] as bool,
              market: p['mkt'] as String,
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildAIBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/ai');
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1F10), Color(0xFF1B3320)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text(t('ask_ai'),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(t('ai_desc'),
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11.5)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(12)),
                child: const Text('Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String? action) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      if (action != null)
        TextButton(
          onPressed: () {
            if (action == t('view_all')) {
              Navigator.pushNamed(context, '/market');
            }
          },
          style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 4)),
          child: Text(action, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
        ),
    ],
  );
}
