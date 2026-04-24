import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/agevolazioni/agevolazioni_data.dart' as ag;
import 'notification_service.dart';

// ---------------------------------------------------------------------------
// BonusRepository — fonte unica, aggiornabile da remoto.
//
// 1) All'avvio prova a scaricare il JSON master da GitHub raw
// 2) Cache locale in SharedPreferences (chiave `bonus_cache_json`)
// 3) Fallback all'asset embedded `assets/bonuses_2026.json`
// 4) Ultimo fallback alla lista hardcodata in agevolazioni_data.dart
// 5) Filtra automaticamente i bonus scaduti (validoFino < now)
// ---------------------------------------------------------------------------

class BonusRepository {
  BonusRepository._();
  static final BonusRepository instance = BonusRepository._();

  static const _remoteUrl =
      'https://raw.githubusercontent.com/alutori-lang/IlmioPatronato-bonuses/main/bonuses_2026.json';
  static const _assetPath = 'assets/bonuses_2026.json';
  static const _prefsKey = 'bonus_cache_json';
  static const _prefsTs = 'bonus_cache_ts';
  static const _staleAfter = Duration(hours: 24);

  List<ag.Agevolazione> _memory = const [];
  DateTime? _lastLoaded;
  String _source = 'seed';

  List<ag.Agevolazione> get all =>
      _memory.where((a) => !a.isScaduto).toList(growable: false);

  String get source => _source;
  DateTime? get lastLoaded => _lastLoaded;

  /// Carica i bonus. Strategia:
  /// 1. cache locale se fresca (< 24h)
  /// 2. fetch remoto (timeout 8s)
  /// 3. cache locale (anche se stantia)
  /// 4. asset embedded
  /// 5. seed hardcodato (mai null)
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_prefsKey);
      final cachedTs = prefs.getInt(_prefsTs);
      final isFresh = cachedTs != null &&
          DateTime.now().millisecondsSinceEpoch - cachedTs < _staleAfter.inMilliseconds;

      if (cachedJson != null && isFresh) {
        final parsed = _parse(cachedJson);
        if (parsed.isNotEmpty) {
          _memory = parsed;
          _source = 'cache-fresh';
          _applyToGlobalList();
          debugPrint('[BonusRepository] loaded ${parsed.length} from fresh cache');
          // Refresh in background (with notification check)
          unawaited(_refreshFromRemote(prefs).then(_notifyIfNewBonuses));
          return;
        }
      }

      // Prova remoto
      final remote = await _refreshFromRemote(prefs);
      if (remote != null && remote.isNotEmpty) {
        _memory = remote;
        _source = 'remote';
        _applyToGlobalList();
        await _notifyIfNewBonuses(remote);
        return;
      }

      // Cache stantia
      if (cachedJson != null) {
        final parsed = _parse(cachedJson);
        if (parsed.isNotEmpty) {
          _memory = parsed;
          _source = 'cache-stale';
          _applyToGlobalList();
          debugPrint('[BonusRepository] loaded ${parsed.length} from stale cache');
          return;
        }
      }

      // Asset embedded
      final asset = await _loadAsset();
      if (asset.isNotEmpty) {
        _memory = asset;
        _source = 'asset';
        _applyToGlobalList();
        debugPrint('[BonusRepository] loaded ${asset.length} from asset');
        return;
      }
    } catch (e, st) {
      debugPrint('[BonusRepository] load error: $e\n$st');
    }

    // Ultimo fallback — lista hardcodata già in memoria
    _memory = ag.allAgevolazioni;
    _source = 'seed';
    debugPrint('[BonusRepository] fell back to seed list (${_memory.length})');
  }

  Future<List<ag.Agevolazione>?> _refreshFromRemote(SharedPreferences prefs) async {
    try {
      final response = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final parsed = _parse(response.body);
        if (parsed.isNotEmpty) {
          await prefs.setString(_prefsKey, response.body);
          await prefs.setInt(_prefsTs, DateTime.now().millisecondsSinceEpoch);
          _lastLoaded = DateTime.now();
          debugPrint('[BonusRepository] fetched ${parsed.length} from remote');
          return parsed;
        }
      }
      debugPrint('[BonusRepository] remote status=${response.statusCode}');
    } on SocketException {
      debugPrint('[BonusRepository] remote unreachable (offline)');
    } on TimeoutException {
      debugPrint('[BonusRepository] remote timeout');
    } catch (e) {
      debugPrint('[BonusRepository] remote error: $e');
    }
    return null;
  }

  Future<List<ag.Agevolazione>> _loadAsset() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      return _parse(raw);
    } catch (e) {
      debugPrint('[BonusRepository] asset load error: $e');
      return const [];
    }
  }

  List<ag.Agevolazione> _parse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      final list = decoded is Map<String, dynamic> ? decoded['bonuses'] as List? : decoded as List?;
      if (list == null) return const [];
      return list
          .whereType<Map>()
          .map((m) => ag.Agevolazione.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('[BonusRepository] parse error: $e');
      return const [];
    }
  }

  void _applyToGlobalList() {
    if (_memory.isEmpty) return;
    ag.allAgevolazioni = _memory.where((a) => !a.isScaduto).toList(growable: false);
  }

  Future<void> _notifyIfNewBonuses(List<ag.Agevolazione>? list) async {
    if (list == null || list.isEmpty) return;
    await NotificationService.instance.checkForNewBonuses(
      list.where((a) => !a.isScaduto).toList(),
    );
  }
}
