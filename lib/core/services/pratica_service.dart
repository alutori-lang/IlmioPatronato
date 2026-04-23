import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/pratica.dart';

class PraticaService extends ChangeNotifier {
  static const _prefsKey = 'pratiche_v1';

  List<Pratica> _pratiche = [];
  bool _loaded = false;

  List<Pratica> get pratiche {
    final sorted = [..._pratiche];
    sorted.sort((a, b) {
      final s = a.stato.sortOrder.compareTo(b.stato.sortOrder);
      if (s != 0) return s;
      return b.dataCreazione.compareTo(a.dataCreazione);
    });
    return List.unmodifiable(sorted);
  }

  bool get isLoaded => _loaded;

  int countByStato(PraticaStato s) => _pratiche.where((p) => p.stato == s).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _pratiche = Pratica.decodeList(raw);
      } catch (_) {
        _pratiche = [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, Pratica.encodeList(_pratiche));
  }

  Future<Pratica> create(Pratica p) async {
    _pratiche.add(p);
    await _persist();
    notifyListeners();
    return p;
  }

  Future<void> update(Pratica updated) async {
    final idx = _pratiche.indexWhere((p) => p.id == updated.id);
    if (idx < 0) return;
    _pratiche[idx] = updated;
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _pratiche.removeWhere((p) => p.id == id);
    await _persist();
    notifyListeners();
  }

  Pratica? byId(String id) {
    try {
      return _pratiche.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
