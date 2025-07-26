import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // Default to English

  Locale get locale => _locale;

  // Check if current locale is RTL
  bool get isRTL => _locale.languageCode == 'ar';

  // Get RTL text direction while keeping layout LTR
  TextDirection get textDirection =>
      isRTL ? TextDirection.rtl : TextDirection.ltr;

  // Always return LTR for layout direction
  TextDirection get layoutDirection => TextDirection.ltr;

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language');
    if (savedLanguage != null) {
      _locale = Locale(savedLanguage);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);

    notifyListeners();
  }
}
