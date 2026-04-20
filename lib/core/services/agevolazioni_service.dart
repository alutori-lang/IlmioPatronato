import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_service.dart';

// ---------------------------------------------------------------------------
// Servizio Agevolazioni — 2 liste separate:
//   - getAgevolazioni()       → lista completa aggiornata ogni 24h
//   - getNovita48h()          → solo novità ultime 48h, refresh ogni 48h
// Entrambe usano Gemini + Google Search grounding (dati reali dal web).
// Rimuove automaticamente agevolazioni scadute.
// ---------------------------------------------------------------------------
class AgevolazioniService {
  static final AgevolazioniService _instance = AgevolazioniService._();
  factory AgevolazioniService() => _instance;
  AgevolazioniService._();

  // Cache lista completa (24h)
  static const _cacheKey = 'agevolazioni_cache';
  static const _cacheTimeKey = 'agevolazioni_cache_time';
  static const _cacheDuration = Duration(hours: 24);

  // Cache novità 48h (refresh ogni 48h)
  static const _novitaKey = 'agevolazioni_novita_48h';
  static const _novitaTimeKey = 'agevolazioni_novita_48h_time';
  static const _novitaDuration = Duration(hours: 48);

  List<Agevolazione> _cached = [];
  List<Agevolazione> _cachedNovita = [];
  bool _loading = false;

  bool get isLoading => _loading;
  List<Agevolazione> get cached => _cached;
  List<Agevolazione> get cachedNovita => _cachedNovita;

  // ─────────────────────────────────────────────────────────────────────────
  // LISTA COMPLETA (aggiornata ogni 24h)
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<Agevolazione>> getAgevolazioni({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Carica dalla cache disco se vuota in memoria
    if (_cached.isEmpty) {
      final cacheStr = prefs.getString(_cacheKey);
      if (cacheStr != null && cacheStr.isNotEmpty) {
        try {
          final list = jsonDecode(cacheStr) as List;
          _cached = list.map((e) => Agevolazione.fromJson(e)).toList();
        } catch (_) {}
      }
    }

    // Rimuovi sempre le scadute
    _cached = _filtraNonScadute(_cached);

    final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isExpired = now - cacheTime >= _cacheDuration.inMilliseconds;

    if (!forceRefresh && !isExpired && _cached.isNotEmpty) {
      return _cached;
    }

    await _fetchCompleta(prefs);
    return _cached;
  }

  Future<void> _fetchCompleta(SharedPreferences prefs) async {
    _loading = true;

    final oggi = DateTime.now();
    final oggiStr = '${oggi.day.toString().padLeft(2, '0')}/${oggi.month.toString().padLeft(2, '0')}/${oggi.year}';

    final res = await GeminiService().chat(
      useGoogleSearch: true,
      maxTokens: 8192,
      timeoutSeconds: 60,
      messages: [
        {
          'role': 'user',
          'content': 'Cerca su Google le agevolazioni, bonus, contributi e incentivi italiani ATTIVI oggi ($oggiStr) o con scadenza futura. '
              'Fonti da consultare: inps.it, agenziaentrate.gov.it, mimit.gov.it, invitalia.it, governo.it, lavoro.gov.it, siti regionali, camere di commercio.\n\n'
              'Includi TUTTE le categorie di beneficiari:\n'
              '- LAVORATORI DIPENDENTI (bonus busta paga, fringe benefit, decontribuzione)\n'
              '- LAVORATORI AUTONOMI e PARTITE IVA (forfettario, flat tax, ISA)\n'
              '- IMPRENDITORI e STARTUP (credito imposta, Nuova Sabatini, Resto al Sud, Smart&Start)\n'
              '- COMMERCIANTI e ARTIGIANI (contributi camerali, digitalizzazione)\n'
              '- AGRICOLTORI e settore primario (PAC, ISMEA, giovani agricoltori)\n'
              '- FAMIGLIE (assegno unico, bonus nido, bonus mamme, bonus nuovi nati)\n'
              '- DISABILI (Legge 104, assegno invalidità, caregiver)\n'
              '- GIOVANI (bonus cultura, garanzia giovani)\n'
              '- CASA (mutuo prima casa, ristrutturazione, bonus affitto)\n'
              '- IMMIGRATI (permesso di soggiorno, contributi integrazione)\n'
              '- PENSIONATI e ANZIANI (bonus bollette, quattordicesima)\n'
              '- STUDENTI (borse di studio, no tax area)\n\n'
              'SOLO misure REALI e VERIFICABILI con data di scadenza nel futuro o "in corso".\n'
              'NON inventare, NON includere bonus scaduti.\n\n'
              'Restituisci SOLO un array JSON valido, NESSUN markdown, NESSUN testo prima o dopo:\n'
              '[{"titolo":"nome agevolazione","descrizione":"max 2 righe",'
              '"importo":"€ importo se applicabile","data":"dd/mm/yyyy data scadenza o fine misura",'
              '"fonte":"nome ente","categoria":"famiglia|lavoro|impresa|commercio|agricoltura|disabilità|giovani|casa|fiscale|immigrazione|salute|pensione|studio"}]',
        }
      ],
    );

    _loading = false;

    if (res.isSuccess) {
      final parsed = _parseJsonArray(res.text);
      if (parsed.isNotEmpty) {
        final nuove = parsed.map((e) => Agevolazione.fromJson(e)).toList();
        _cached = _merge(_cached, nuove);
        _cached = _filtraNonScadute(_cached);

        await prefs.setString(_cacheKey, jsonEncode(_cached.map((a) => a.toJson()).toList()));
        await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOVITÀ ULTIME 48H (refresh ogni 48h, fallback su ultime caricate)
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<Agevolazione>> getNovita48h({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Carica dalla cache disco se vuota in memoria
    if (_cachedNovita.isEmpty) {
      final cacheStr = prefs.getString(_novitaKey);
      if (cacheStr != null && cacheStr.isNotEmpty) {
        try {
          final list = jsonDecode(cacheStr) as List;
          _cachedNovita = list.map((e) => Agevolazione.fromJson(e)).toList();
        } catch (_) {}
      }
    }

    final cacheTime = prefs.getInt(_novitaTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isExpired = now - cacheTime >= _novitaDuration.inMilliseconds;

    if (!forceRefresh && !isExpired && _cachedNovita.isNotEmpty) {
      return _cachedNovita;
    }

    await _fetchNovita48h(prefs);
    return _cachedNovita;
  }

  Future<void> _fetchNovita48h(SharedPreferences prefs) async {
    final oggi = DateTime.now();
    final dueGiorniFa = oggi.subtract(const Duration(hours: 48));
    final oggiStr = '${oggi.day.toString().padLeft(2, '0')}/${oggi.month.toString().padLeft(2, '0')}/${oggi.year}';
    final dueGgStr = '${dueGiorniFa.day.toString().padLeft(2, '0')}/${dueGiorniFa.month.toString().padLeft(2, '0')}/${dueGiorniFa.year}';

    final res = await GeminiService().chat(
      useGoogleSearch: true,
      maxTokens: 4096,
      timeoutSeconds: 45,
      messages: [
        {
          'role': 'user',
          'content': 'Cerca su Google SOLO le agevolazioni, bonus, decreti, circolari e incentivi italiani '
              'PUBBLICATI o ATTIVATI negli ULTIMI 2 GIORNI (dal $dueGgStr al $oggiStr).\n\n'
              'Fonti prioritarie: inps.it (news), agenziaentrate.gov.it (circolari), mimit.gov.it, invitalia.it, gazzettaufficiale.it, governo.it.\n\n'
              'Categorie da coprire TUTTE:\n'
              '- lavoratori dipendenti e autonomi\n'
              '- imprenditori, partite IVA, startup\n'
              '- commercianti, artigiani\n'
              '- agricoltori\n'
              '- famiglie, disabili, giovani, casa, immigrati, pensionati, studenti\n\n'
              'REGOLE FERREE:\n'
              '1. SOLO misure pubblicate/aggiornate negli ULTIMI 2 GIORNI\n'
              '2. Se NON ci sono novità in 48h restituisci array vuoto: []\n'
              '3. NON inventare, NON includere vecchie agevolazioni\n'
              '4. Indica la data ESATTA di pubblicazione\n\n'
              'Restituisci SOLO un array JSON valido, senza markdown:\n'
              '[{"titolo":"...","descrizione":"max 2 righe","importo":"...",'
              '"data":"dd/mm/yyyy data pubblicazione","fonte":"nome ente + url",'
              '"categoria":"famiglia|lavoro|impresa|commercio|agricoltura|disabilità|giovani|casa|fiscale|immigrazione|salute|pensione|studio"}]',
        }
      ],
    );

    if (res.isSuccess) {
      final parsed = _parseJsonArray(res.text);
      final nuove = parsed.map((e) => Agevolazione.fromJson(e)).toList();

      // Accetta solo items con data negli ultimi 48h
      final filtered = nuove.where((a) => _isRecentQueDaysUltimate(a.data, 2)).toList();

      if (filtered.isNotEmpty) {
        // Ci sono nuove novità → sovrascrive
        _cachedNovita = filtered;
        await prefs.setString(_novitaKey, jsonEncode(_cachedNovita.map((a) => a.toJson()).toList()));
      }
      // Se filtered è vuoto → tiene quelle in cache (fallback)
      // Aggiorna comunque il timestamp per non riprovare subito
      await prefs.setInt(_novitaTimeKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _parseJsonArray(String text) {
    try {
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start == -1 || end <= start) return [];
      final parsed = jsonDecode(text.substring(start, end + 1));
      if (parsed is List) {
        return parsed.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return [];
  }

  /// Merge: aggiunge nuove, mantiene quelle esistenti per titolo, rimuove scadute
  List<Agevolazione> _merge(List<Agevolazione> vecchie, List<Agevolazione> nuove) {
    final map = <String, Agevolazione>{};
    for (final a in vecchie) {
      map[a.titolo.toLowerCase().trim()] = a;
    }
    for (final a in nuove) {
      map[a.titolo.toLowerCase().trim()] = a; // sovrascrive con versione aggiornata
    }
    return map.values.toList();
  }

  /// Rimuove agevolazioni con data di scadenza passata (>7 giorni fa)
  List<Agevolazione> _filtraNonScadute(List<Agevolazione> lista) {
    final ora = DateTime.now();
    return lista.where((a) {
      final d = _parseDate(a.data);
      if (d == null) return true; // se non parsa, tieni
      return d.isAfter(ora.subtract(const Duration(days: 7)));
    }).toList();
  }

  bool _isRecentQueDaysUltimate(String data, int days) {
    final d = _parseDate(data);
    if (d == null) return true; // se data assente accetta comunque
    final now = DateTime.now();
    return now.difference(d).inHours.abs() <= days * 24 + 12;
  }

  DateTime? _parseDate(String s) {
    try {
      final parts = s.split('/');
      if (parts.length != 3) return null;
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return null;
    }
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

  String get categoriaIcon {
    switch (categoria.toLowerCase()) {
      case 'famiglia': return '👨‍👩‍👧‍👦';
      case 'lavoro': return '💼';
      case 'impresa': return '🏢';
      case 'commercio': return '🛒';
      case 'agricoltura': return '🌾';
      case 'disabilità': return '♿';
      case 'giovani': return '🎓';
      case 'casa': return '🏠';
      case 'fiscale': return '💰';
      case 'immigrazione': return '🌍';
      case 'salute': return '🏥';
      case 'pensione': return '👴';
      case 'studio': return '📚';
      default: return '📋';
    }
  }
}
