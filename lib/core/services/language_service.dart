import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages with display names and native scripts.
class AppLanguage {
  final String code;
  final String name;       // Native name
  final String nameEn;     // English name
  final String flag;       // Emoji flag

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.flag,
  });
}

const supportedLanguages = [
  AppLanguage(code: 'it', name: 'Italiano', nameEn: 'Italian', flag: '🇮🇹'),
  AppLanguage(code: 'en', name: 'English', nameEn: 'English', flag: '🇬🇧'),
  AppLanguage(code: 'ar', name: 'العربية', nameEn: 'Arabic', flag: '🇸🇦'),
  AppLanguage(code: 'sq', name: 'Shqip', nameEn: 'Albanian', flag: '🇦🇱'),
  AppLanguage(code: 'ro', name: 'Română', nameEn: 'Romanian', flag: '🇷🇴'),
  AppLanguage(code: 'zh', name: '中文', nameEn: 'Chinese', flag: '🇨🇳'),
  AppLanguage(code: 'bn', name: 'বাংলা', nameEn: 'Bengali', flag: '🇧🇩'),
  AppLanguage(code: 'ur', name: 'اردو', nameEn: 'Urdu', flag: '🇵🇰'),
  AppLanguage(code: 'uk', name: 'Українська', nameEn: 'Ukrainian', flag: '🇺🇦'),
  AppLanguage(code: 'fr', name: 'Français', nameEn: 'French', flag: '🇫🇷'),
  AppLanguage(code: 'hi', name: 'हिन्दी', nameEn: 'Hindi', flag: '🇮🇳'),
  AppLanguage(code: 'pa', name: 'ਪੰਜਾਬੀ', nameEn: 'Punjabi', flag: '🇮🇳'),
  AppLanguage(code: 'es', name: 'Español', nameEn: 'Spanish', flag: '🇪🇸'),
  AppLanguage(code: 'ru', name: 'Русский', nameEn: 'Russian', flag: '🇷🇺'),
];

class LanguageService extends ChangeNotifier {
  static const _key = 'app_language';
  String _currentCode = 'it';

  String get currentCode => _currentCode;

  AppLanguage get current =>
      supportedLanguages.firstWhere((l) => l.code == _currentCode);

  LanguageService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCode = prefs.getString(_key) ?? 'it';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_currentCode == code) return;
    _currentCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
