import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('uz', '');

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'uz';
    _locale = Locale(languageCode, '');
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode == _locale.languageCode) return;

    _locale = Locale(languageCode, '');
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }
}