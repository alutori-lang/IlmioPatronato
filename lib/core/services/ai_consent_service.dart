import 'package:shared_preferences/shared_preferences.dart';

class AiConsentService {
  static const _prefsKey = 'ai_consent_v1';

  static Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> setConsented(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_prefsKey, true);
    } else {
      await prefs.remove(_prefsKey);
    }
  }

  static Future<void> revoke() => setConsented(false);
}
