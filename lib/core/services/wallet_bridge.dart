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
}
