import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _bgCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _bgScale;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _bgScale = Tween<double>(begin: 1.1, end: 1.0)
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOutCubic));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    _bgCtrl.forward();
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350),
        () => _textCtrl.forward());
    Future.delayed(const Duration(milliseconds: 2400), _navigate);
  }

  Future<void> _navigate() async {
    final p = await SharedPreferences.getInstance();
    final hasProfile = (p.getString('farmer_name') ?? '').isNotEmpty;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(hasProfile ? '/home' : '/profile');
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, __) => Transform.scale(
          scale: _bgScale.value,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Background decorative circles
                  Positioned(top: -60, right: -60,
                      child: _circle(220, 0.06)),
                  Positioned(bottom: 80, left: -80,
                      child: _circle(260, 0.05)),
                  Positioned(top: 100, left: -40,
                      child: _circle(120, 0.04)),
                  Positioned(bottom: -40, right: 60,
                      child: _circle(160, 0.04)),
                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5),
                              ),
                              child: const Center(
                                child: Text('🌾',
                                    style: TextStyle(fontSize: 54)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Text
                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textFade,
                            child: Column(children: [
                              const Text(
                                'KisanMitra',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'किसान का डिजिटल साथी',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Farmer's Digital Companion",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 13,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom loading
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: Colors.white.withOpacity(0.6),
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Loading your farm data...',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity)),
  );
}
