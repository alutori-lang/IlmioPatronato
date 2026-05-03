import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Bridges other features (Scanner DOC, simulators, compilatore) with the
/// Documento Wallet (strumenti/documento_wallet_screen.dart). Writes to the
/// same SharedPreferences key used by the wallet UI so the entry appears
/// automatically in the Portafoglio list the next time it's opened.
class WalletBridge {
  WalletBridge._();
  static const _kStorageKey = 'documento_wallet_items';

  /// Tipi riconosciuti dal wallet (devono matchare i _DocumentoTipo.key in
  /// documento_wallet_screen.dart).
  static const _types = {
    'passaporto': [
      'passaporto', 'passport',
    ],
    'permesso_soggiorno': [
      'permesso di soggiorno', 'permesso soggiorno', 'soggiorno',
    ],
    'cie': [
      'carta identità', 'carta d\'identità', 'carta d identita',
      'carta identita', 'cie', 'identità', 'identita',
    ],
    'codice_fiscale': [
      'codice fiscale', 'cf',
    ],
    'tessera_sanitaria': [
      'tessera sanitaria', 'ts',
    ],
    'patente': [
      'patente', 'patente di guida',
    ],
  };

  /// Returns the tipoKey (e.g. 'passaporto') detected from [name], or null
  /// if no important-document match.
  static String? detectTipo(String name) {
    final lower = name.toLowerCase().trim();
    for (final entry in _types.entries) {
      for (final alias in entry.value) {
        if (lower.contains(alias)) return entry.key;
      }
    }
    return null;
  }

  /// If [name] matches one of the important document types AND no wallet
  /// entry of that type exists yet, creates one. Returns true if saved.
  /// Second scans of the same type are ignored (user already has a CIE
  /// in the wallet → don't overwrite whatever dates they set manually).
  static Future<bool> autoSaveIfImportant({
    required String name,
    String? note,
  }) async {
    final tipoKey = detectTipo(name);
    if (tipoKey == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStorageKey);
    List<dynamic> items = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        items = jsonDecode(raw) as List;
      } catch (_) {
        items = [];
      }
    }

    final alreadyExists = items.any((e) {
      if (e is Map<String, dynamic>) return e['tipoKey'] == tipoKey;
      if (e is Map) return (e as Map)['tipoKey'] == tipoKey;
      return false;
    });
    if (alreadyExists) return false;

    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final entry = <String, dynamic>{
      'id': id,
      'tipoKey': tipoKey,
      'nome': name,
      'numero': '',
      'dataRilascio': null,
      'dataScadenza': null,
      'note': note ?? 'Aggiunto automaticamente dallo Scanner',
    };

    items.add(entry);
    await prefs.setString(_kStorageKey, jsonEncode(items));
    return true;
  }

  /// Human-readable label for a tipoKey (mirrors documento_wallet_screen.dart).
  static const _typeLabels = {
    'passaporto': 'Passaporto',
    'permesso_soggiorno': 'Permesso di Soggiorno',
    'cie': "Carta d'Identità",
    'codice_fiscale': 'Codice Fiscale',
    'tessera_sanitaria': 'Tessera Sanitaria',
    'patente': 'Patente di Guida',
  };

  static String labelFor(String tipoKey) =>
      _typeLabels[tipoKey] ?? tipoKey;

  /// Reads all wallet items and computes a summary used by the Profilo
  /// card and the Home alert banner.
  static Future<WalletSummary> getSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStorageKey);
    if (raw == null || raw.isEmpty) return const WalletSummary.empty();

    List<dynamic> items;
    try {
      items = jsonDecode(raw) as List;
    } catch (_) {
      return const WalletSummary.empty();
    }

    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);

    int count = 0;
    String? nextLabel;
    int? nextDays;

    for (final raw in items) {
      if (raw is! Map) continue;
      count++;

      final scadStr = raw['dataScadenza'] as String?;
      if (scadStr == null) continue;
      final scad = DateTime.tryParse(scadStr);
      if (scad == null) continue;

      final scadDay = DateTime(scad.year, scad.month, scad.day);
      final days = scadDay.difference(t0).inDays;

      // Track the most-urgent upcoming or recently-expired
      if (nextDays == null || days < nextDays) {
        nextDays = days;
        nextLabel = labelFor((raw['tipoKey'] as String?) ?? '');
      }
    }

    return WalletSummary(
      count: count,
      nextLabel: nextLabel,
      nextDays: nextDays,
    );
  }
}

/// Snapshot of the wallet shown in the Profilo card / Home alert.
class WalletSummary {
  final int count;
  final String? nextLabel;
  final int? nextDays;

  const WalletSummary({
    required this.count,
    required this.nextLabel,
    required this.nextDays,
  });

  const WalletSummary.empty()
      : count = 0,
        nextLabel = null,
        nextDays = null;

  bool get isEmpty => count == 0;
  bool get hasUrgent => nextDays != null && nextDays! <= 60;
}
