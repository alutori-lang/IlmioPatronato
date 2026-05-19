import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Stable per-install identifier used to throttle/track AI proxy requests.
/// Persists across app launches via SharedPreferences. Regenerated only on
/// reinstall or manual data clear.
class DeviceIdService {
  static const _prefsKey = 'device_id_v1';
  static String? _cached;

  static Future<String> getId() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_prefsKey);
    if (id == null || id.length < 8) {
      id = _generate();
      await prefs.setString(_prefsKey, id);
    }
    _cached = id;
    return id;
  }

  static String _generate() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
