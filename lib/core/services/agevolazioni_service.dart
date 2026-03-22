import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_service.dart';

// ---------------------------------------------------------------------------
// Servizio Agevolazioni Reali — con cache 6 ore
// ---------------------------------------------------------------------------
class AgevolazioniService {
  static final AgevolazioniService _instance = AgevolazioniService._();
  factory AgevolazioniService() => _instance;
  AgevolazioniService._();

  static const _cacheKey = 'agevolazioni_cache';
  static const _cacheTimeKey = 'agevolazioni_cache_time';
  static const _cacheDuration = Duration(hours: 6);

  List<Agevolazione> _cached = [];
  bool _loading = false;

  bool get isLoading => _loading;
  List<Agevolazione> get cached => _cached;

  /// Carica agevolazioni: prima da cache, poi da AI se scaduta
  Future<List<Agevolazione>> getAgevolazioni({bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh && _cached.isNotEmpty) return _cached;

    final prefs = await SharedPreferences.getInstance();
    final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (!forceRefresh && now - cacheTime < _cacheDuration.inMilliseconds) {
      final cacheStr = prefs.getString(_cacheKey);
      if (cacheStr != null && cacheStr.isNotEmpty) {
        try {
          final list = jsonDecode(cacheStr) as List;
          _cached = list.map((e) => Agevolazione.fromJson(e)).toList();
          return _cached;
        } catch (_) {}
      }
    }

    // Fetch from Gemini AI
    return await _fetchFromAi(prefs);
  }

  Future<List<Agevolazione>> _fetchFromAi(SharedPreferences prefs) async {
    _loading = true;

    final now = DateTime.now();
    // Find Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final friday = monday.add(const Duration(days: 4));
    final mondayStr = '${monday.day.toString().padLeft(2, '0')}/${monday.month.toString().padLeft(2, '0')}/${monday.year}';
    final fridayStr = '${friday.day.toString().padLeft(2, '0')}/${friday.month.toString().padLeft(2, '0')}/${friday.year}';

    final res = await GeminiService().chat(
      messages: [
        {
          'role': 'user',
          'content': 'Sei un esperto di agevolazioni e bonus italiani. '
              'Elenca le ULTIME agevolazioni, bonus e incentivi italiani pubblicati o attivi questa settimana '
              '(dal $mondayStr al $fridayStr). '
              'Includi SOLO agevolazioni REALI, VERIFICABILI e ATTUALI:\n'
              '- Bonus e incentivi statali (Bonus bollette, Bonus mamme, ADI, SFL, ecc.)\n'
              '- Agevolazioni fiscali\n'
              '- Contributi INPS\n'
              '- Bonus per famiglie, lavoratori, immigrati, disabili, giovani, casa\n'
              '- Nuove misure del governo o scadenze importanti di questa settimana\n\n'
              'Per ogni agevolazione indica la data ESATTA di pubblicazione o scadenza.\n\n'
              'Restituisci SOLO un array JSON valido, NESSUN markdown, NESSUN testo prima o dopo:\n'
              '[{"titolo":"nome agevolazione","descrizione":"max 2 righe di spiegazione",'
              '"importo":"€ importo se applicabile, altrimenti stringa vuota",'
              '"data":"dd/mm/yyyy","fonte":"nome sito o ente",'
              '"categoria":"famiglia|lavoro|disabilità|giovani|casa|fiscale|immigrazione|salute"}]',
        }
      ],
    );

    _loading = false;

    if (res.isSuccess) {
      try {
        final start = res.text.indexOf('[');
        final end = res.text.lastIndexOf(']');
        if (start != -1 && end > start) {
          final list = jsonDecode(res.text.substring(start, end + 1)) as List;
          _cached = list.map((e) => Agevolazione.fromJson(e as Map<String, dynamic>)).toList();

          // Save to cache
          await prefs.setString(_cacheKey, jsonEncode(list));
          await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);

          return _cached;
        }
      } catch (_) {}
    }

    return _cached;
  }
}

// ---------------------------------------------------------------------------
// Modello Agevolazione
// ---------------------------------------------------------------------------
class Agevolazione {
  final String titolo;
  final String descrizione;
  final String importo;
  final String data;
  final String fonte;
  final String categoria;

  Agevolazione({
    required this.titolo,
    required this.descrizione,
    this.importo = '',
    required this.data,
    this.fonte = '',
    this.categoria = '',
  });

  factory Agevolazione.fromJson(Map<String, dynamic> json) {
    return Agevolazione(
      titolo: json['titolo'] ?? '',
      descrizione: json['descrizione'] ?? '',
      importo: json['importo'] ?? '',
      data: json['data'] ?? '',
      fonte: json['fonte'] ?? '',
      categoria: json['categoria'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'titolo': titolo,
    'descrizione': descrizione,
    'importo': importo,
    'data': data,
    'fonte': fonte,
    'categoria': categoria,
  };

  /// Ritorna stringa tempo relativo (es. "2 ore fa", "Lunedì")
  String get tempoRelativo {
    try {
      final parts = data.split('/');
      if (parts.length != 3) return data;
      final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inHours < 1) return '${diff.inMinutes} min fa';
      if (diff.inHours < 24) return '${diff.inHours} ore fa';
      if (diff.inDays == 0) return 'Oggi';
      if (diff.inDays == 1) return 'Ieri';

      const giorni = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
      if (diff.inDays < 7) return giorni[date.weekday - 1];

      return data;
    } catch (_) {
      return data;
    }
  }

  /// Icona per categoria
  String get categoriaIcon {
    switch (categoria.toLowerCase()) {
      case 'famiglia': return '👨‍👩‍👧‍👦';
      case 'lavoro': return '💼';
      case 'disabilità': return '♿';
      case 'giovani': return '🎓';
      case 'casa': return '🏠';
      case 'fiscale': return '💰';
      case 'immigrazione': return '🌍';
      case 'salute': return '🏥';
      default: return '📋';
    }
  }
}
