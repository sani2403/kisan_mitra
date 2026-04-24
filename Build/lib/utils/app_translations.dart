import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTranslations extends ChangeNotifier {
  String _lang = 'English';

  String get lang => _lang;

  final Map<String, Map<String, String>> _translations = {
    'English': {
      'weather': 'Weather',
      'market': 'Market',
      'schemes': 'Schemes',
      'organic': 'Organic',
      'iot': 'IoT',
      'ai_chat': 'AI Chat',
      'quick_access': 'Quick Access',
      'tap_weather': 'Tap to check weather',
      'market_prices': 'Market Prices',
      'view_all': 'View All',
      'ask_ai': 'Ask AI Assistant',
    },

    'हिंदी': {
      'weather': 'मौसम',
      'market': 'मंडी',
      'schemes': 'योजनाएं',
      'organic': 'जैविक',
      'iot': 'आईओटी',
      'ai_chat': 'AI चैट',
      'quick_access': 'त्वरित सेवाएं',
      'tap_weather': 'मौसम देखने के लिए टैप करें',
      'market_prices': 'मंडी भाव',
      'view_all': 'सभी देखें',
      'ask_ai': 'AI से पूछें',
      'home': 'होम',
    },

    'छत्तीसगढ़ी': {
      'home': 'घर',
      'weather': 'मौसम',
      'market': 'मंडी',
      'schemes': 'योजना',
      'organic': 'जैविक',
      'iot': 'आईओटी',
      'ai_chat': 'एआई गोठ',
      'quick_access': 'जल्दी सेवा',
      'tap_weather': 'मौसम देखे बर टच करव',
      'market_prices': 'मंडी दाम',
      'view_all': 'सब देखव',
      'ask_ai': 'AI ले पूछव',
    }
  };

  String t(String key) {
    return _translations[_lang]?[key] ?? key;
  }

  Future<void> setLang(String lang) async {
    _lang = lang;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
  }

  Future<void> loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('lang') ?? 'English';
    notifyListeners();
  }
}