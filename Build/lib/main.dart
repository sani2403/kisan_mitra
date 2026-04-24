// lib/main.dart — KisanMitra v3 with Firebase + Gemini AI
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart'; // THIS IS THE CRITICAL ONE
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/schemes_screen.dart';
import 'screens/organic_screen.dart';
import 'screens/iot_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/gemini_service.dart';
import 'screens/ai_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Firebase
  // SETUP STEPS:
  // 1. Create project at https://console.firebase.google.com
  // 2. Add Android app, download google-services.json → android/app/
  // 3. Run: dart pub global activate flutterfire_cli && flutterfire configure
  // 4. Uncomment the options line below
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint('Firebase not configured yet: $e');
    debugPrint('Follow setup steps in main.dart to enable Firebase');
  }

  // Pre-warm Gemini
  GeminiService().initialize();

  final prefs = await SharedPreferences.getInstance();
  final hasProfile = (prefs.getString('farmer_name') ?? '').isNotEmpty;
  runApp(KisanMitraApp(showOnboarding: !hasProfile));
}

class KisanMitraApp extends StatelessWidget {
  final bool showOnboarding;
  const KisanMitraApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'KisanMitra',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        primary: const Color(0xFF2E7D32),
        secondary: const Color(0xFF66BB6A),
        surface: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF2F5F2),
      splashColor: const Color(0xFF2E7D32).withOpacity(0.10),
      highlightColor: const Color(0xFF2E7D32).withOpacity(0.05),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0, shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
    initialRoute: '/',
    routes: {
      '/': (_) => const SplashScreen(),
      '/home': (_) => const MainShell(),

      '/weather': (_) => const WeatherScreen(),
      '/market': (_) => const MarketScreen(),
      '/schemes': (_) => const SchemesScreen(),
      '/organic': (_) => const OrganicScreen(),
      '/iot': (_) => const IoTScreen(),
      '/ai': (_) => const ChatbotScreen(),

      '/profile': (_) => const ProfileScreen(isOnboarding: false),
      '/notifications': (_) => const NotificationsScreen(),
    },
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _idx = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  static const _screens = [
    HomeScreen(), WeatherScreen(), MarketScreen(), SchemesScreen(),
    OrganicScreen(), IoTScreen(), ChatbotScreen(),
  ];
  static const _items = [
    _NavItem(Icons.home_rounded,           Icons.home_outlined,           'Home'),
    _NavItem(Icons.cloud_rounded,          Icons.cloud_outlined,          'Weather'),
    _NavItem(Icons.bar_chart_rounded,      Icons.bar_chart_outlined,      'Market'),
    _NavItem(Icons.account_balance_rounded,Icons.account_balance_outlined,'Schemes'),
    _NavItem(Icons.eco_rounded,            Icons.eco_outlined,            'Organic'),
    _NavItem(Icons.sensors_rounded,        Icons.sensors_outlined,        'IoT'),
    _NavItem(Icons.smart_toy_rounded,      Icons.smart_toy_outlined,      'AI Chat'),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FadeTransition(
      opacity: _fade,
      child: IndexedStack(index: _idx, children: _screens),
    ),
    bottomNavigationBar: _BottomBar(currentIndex: _idx, items: _items,
      onTap: (i) {
        if (i == _idx) return;
        HapticFeedback.selectionClick();
        _fadeCtrl.reset();
        setState(() => _idx = i);
        _fadeCtrl.forward();
      }),
  );
}

class _NavItem {
  final IconData activeIcon, inactiveIcon;
  final String label;
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 28, offset: const Offset(0, -6))
    ]),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 62,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            final sel = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 74,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF2E7D32).withOpacity(0.13) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(sel ? item.activeIcon : item.inactiveIcon,
                        color: sel ? const Color(0xFF2E7D32) : const Color(0xFFB8B8B8), size: 22),
                  ),
                  const SizedBox(height: 1),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? const Color(0xFF2E7D32) : const Color(0xFFB8B8B8),
                    ),
                    child: Text(item.label, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ),
  );
}
