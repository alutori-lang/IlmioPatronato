import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Profilo Utente — salva/legge da SharedPreferences
// ---------------------------------------------------------------------------
class ProfiloUtente {
  String nazionalita;
  String tipoPermesso; // 'cittadino_ue', 'lungo_soggiornante', 'lavoro', 'famiglia', 'asilo', 'altro', 'cittadino_italiano'
  String scadenzaPermesso; // 'gg/mm/aaaa'
  int anniInItalia;
  String statoFamiliare; // 'single', 'sposato', 'convivente', 'separato', 'vedovo'
  int numeriFigli;
  List<int> etaFigli;
  bool lavora;
  String tipoContratto; // 'indeterminato', 'determinato', 'apprendista', 'autonomo', 'stagionale', 'disoccupato'
  double isee;
  String citta;
  String provincia;
  bool disabilita;
  int eta;

  ProfiloUtente({
    this.nazionalita = '',
    this.tipoPermesso = '',
    this.scadenzaPermesso = '',
    this.anniInItalia = 0,
    this.statoFamiliare = '',
    this.numeriFigli = 0,
    this.etaFigli = const [],
    this.lavora = false,
    this.tipoContratto = '',
    this.isee = 0,
    this.citta = '',
    this.provincia = '',
    this.disabilita = false,
    this.eta = 0,
  });

  bool get isComplete =>
      nazionalita.isNotEmpty &&
      eta > 0 &&
      statoFamiliare.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'nazionalita': nazionalita,
    'tipoPermesso': tipoPermesso,
    'scadenzaPermesso': scadenzaPermesso,
    'anniInItalia': anniInItalia,
    'statoFamiliare': statoFamiliare,
    'numeriFigli': numeriFigli,
    'etaFigli': etaFigli,
    'lavora': lavora,
    'tipoContratto': tipoContratto,
    'isee': isee,
    'citta': citta,
    'provincia': provincia,
    'disabilita': disabilita,
    'eta': eta,
  };

  factory ProfiloUtente.fromJson(Map<String, dynamic> json) => ProfiloUtente(
    nazionalita: json['nazionalita'] ?? '',
    tipoPermesso: json['tipoPermesso'] ?? '',
    scadenzaPermesso: json['scadenzaPermesso'] ?? '',
    anniInItalia: json['anniInItalia'] ?? 0,
    statoFamiliare: json['statoFamiliare'] ?? '',
    numeriFigli: json['numeriFigli'] ?? 0,
    etaFigli: (json['etaFigli'] as List?)?.cast<int>() ?? [],
    lavora: json['lavora'] ?? false,
    tipoContratto: json['tipoContratto'] ?? '',
    isee: (json['isee'] ?? 0).toDouble(),
    citta: json['citta'] ?? '',
    provincia: json['provincia'] ?? '',
    disabilita: json['disabilita'] ?? false,
    eta: json['eta'] ?? 0,
  );
}

class ProfiloUtenteService extends ChangeNotifier {
  static const _key = 'profilo_utente';
  ProfiloUtente? _profilo;

  ProfiloUtente? get profilo => _profilo;
  bool get hasProfile => _profilo != null && _profilo!.isComplete;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        _profilo = ProfiloUtente.fromJson(jsonDecode(data));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> save(ProfiloUtente profilo) async {
    _profilo = profilo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profilo.toJson()));
    notifyListeners();
  }

  Future<void> clear() async {
    _profilo = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }
}
