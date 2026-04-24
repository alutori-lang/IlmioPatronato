import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Profilo Utente — salva/legge da SharedPreferences
// ---------------------------------------------------------------------------
class ProfiloUtente {
  // ── Dati da ISEE ──
  double isee;
  int eta;
  int numeriFigli;
  List<int> etaFigli;
  String statoFamiliare; // 'single', 'sposato', 'convivente', 'separato', 'vedovo'
  bool disabilita;

  // ── Dati da domande rapide ──
  String sesso; // 'M', 'F', ''
  String cittadinanza; // 'italiana', 'ue', 'extraue', ''
  int anniInItalia; // 0 se italiana/UE
  String situazioneLavoro; // 'dipendente', 'cococo', 'partita_iva', 'disoccupato', 'pensionato', 'studente', ''
  String fasciaReddito; // '<8k', '8-15k', '15-28k', '28-50k', '>50k', ''
  bool inAffitto;
  bool merito100; // true solo se 18-19enni con diploma 100/100

  // ── Campi legacy (retrocompatibilità) ──
  String nazionalita;
  String tipoPermesso;
  String scadenzaPermesso;
  bool lavora;
  String tipoContratto;
  String citta;
  String provincia;

  ProfiloUtente({
    this.isee = 0,
    this.eta = 0,
    this.numeriFigli = 0,
    this.etaFigli = const [],
    this.statoFamiliare = 'single',
    this.disabilita = false,
    this.sesso = '',
    this.cittadinanza = '',
    this.anniInItalia = 0,
    this.situazioneLavoro = '',
    this.fasciaReddito = '',
    this.inAffitto = false,
    this.merito100 = false,
    this.nazionalita = '',
    this.tipoPermesso = '',
    this.scadenzaPermesso = '',
    this.lavora = false,
    this.tipoContratto = '',
    this.citta = '',
    this.provincia = '',
  });

  bool get isComplete => sesso.isNotEmpty && cittadinanza.isNotEmpty && situazioneLavoro.isNotEmpty;

  // ── Helper derivati (per DirittiService) ──
  bool get isItaliano => cittadinanza == 'italiana';
  bool get isUE => cittadinanza == 'ue' || cittadinanza == 'italiana';
  bool get isExtraUE => cittadinanza == 'extraue';
  bool get haFigliMinori => numeriFigli > 0 && etaFigli.any((e) => e < 18);
  bool get haComponentiFragili => haFigliMinori || eta >= 60 || disabilita;

  // Fascia reddito → limite superiore approssimato per check
  double get redditoLimiteSuperiore {
    switch (fasciaReddito) {
      case '<8k': return 8000;
      case '8-15k': return 15000;
      case '15-28k': return 28000;
      case '28-50k': return 50000;
      case '>50k': return 100000;
      default: return 0;
    }
  }

  Map<String, dynamic> toJson() => {
    'isee': isee,
    'eta': eta,
    'numeriFigli': numeriFigli,
    'etaFigli': etaFigli,
    'statoFamiliare': statoFamiliare,
    'disabilita': disabilita,
    'sesso': sesso,
    'cittadinanza': cittadinanza,
    'anniInItalia': anniInItalia,
    'situazioneLavoro': situazioneLavoro,
    'fasciaReddito': fasciaReddito,
    'inAffitto': inAffitto,
    'merito100': merito100,
    'nazionalita': nazionalita,
    'tipoPermesso': tipoPermesso,
    'scadenzaPermesso': scadenzaPermesso,
    'lavora': lavora,
    'tipoContratto': tipoContratto,
    'citta': citta,
    'provincia': provincia,
  };

  factory ProfiloUtente.fromJson(Map<String, dynamic> json) => ProfiloUtente(
    isee: (json['isee'] ?? 0).toDouble(),
    eta: json['eta'] ?? 0,
    numeriFigli: json['numeriFigli'] ?? 0,
    etaFigli: (json['etaFigli'] as List?)?.cast<int>() ?? [],
    statoFamiliare: json['statoFamiliare'] ?? 'single',
    disabilita: json['disabilita'] ?? false,
    sesso: json['sesso'] ?? '',
    cittadinanza: json['cittadinanza'] ?? '',
    anniInItalia: json['anniInItalia'] ?? 0,
    situazioneLavoro: json['situazioneLavoro'] ?? '',
    fasciaReddito: json['fasciaReddito'] ?? '',
    inAffitto: json['inAffitto'] ?? false,
    merito100: json['merito100'] ?? false,
    nazionalita: json['nazionalita'] ?? '',
    tipoPermesso: json['tipoPermesso'] ?? '',
    scadenzaPermesso: json['scadenzaPermesso'] ?? '',
    lavora: json['lavora'] ?? false,
    tipoContratto: json['tipoContratto'] ?? '',
    citta: json['citta'] ?? '',
    provincia: json['provincia'] ?? '',
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
