import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/guide_documenti/guide_documenti_data.dart';
import 'gemini_service.dart';

class GuidaContenuto {
  final String cosEce;
  final List<String> requisiti;
  final List<String> documenti;
  final String dove;
  final List<String> procedura;
  final String costi;
  final String tempi;
  final List<String> avvertenze;
  final List<GuidaFaq> faq;

  const GuidaContenuto({
    required this.cosEce,
    required this.requisiti,
    required this.documenti,
    required this.dove,
    required this.procedura,
    required this.costi,
    required this.tempi,
    required this.avvertenze,
    required this.faq,
  });

  Map<String, dynamic> toJson() => {
        'cosEce': cosEce,
        'requisiti': requisiti,
        'documenti': documenti,
        'dove': dove,
        'procedura': procedura,
        'costi': costi,
        'tempi': tempi,
        'avvertenze': avvertenze,
        'faq': faq.map((f) => f.toJson()).toList(),
      };

  factory GuidaContenuto.fromJson(Map<String, dynamic> j) => GuidaContenuto(
        cosEce: j['cosEce'] as String? ?? '',
        requisiti: _strList(j['requisiti']),
        documenti: _strList(j['documenti']),
        dove: j['dove'] as String? ?? '',
        procedura: _strList(j['procedura']),
        costi: j['costi'] as String? ?? '',
        tempi: j['tempi'] as String? ?? '',
        avvertenze: _strList(j['avvertenze']),
        faq: ((j['faq'] as List?) ?? [])
            .map((e) => GuidaFaq.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GuidaFaq {
  final String domanda;
  final String risposta;
  const GuidaFaq({required this.domanda, required this.risposta});
  Map<String, dynamic> toJson() => {'domanda': domanda, 'risposta': risposta};
  factory GuidaFaq.fromJson(Map<String, dynamic> j) => GuidaFaq(
        domanda: j['domanda'] as String? ?? '',
        risposta: j['risposta'] as String? ?? '',
      );
}

List<String> _strList(dynamic v) {
  if (v == null) return const [];
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String) return [v];
  return const [];
}

class GuideAiService {
  GuideAiService._();
  static final GuideAiService _instance = GuideAiService._();
  factory GuideAiService() => _instance;

  final _gemini = GeminiService();
  static const _prefsPrefix = 'guida_cache_';

  static String _key(String schedaId, String langCode) =>
      '$_prefsPrefix${schedaId}_$langCode';

  static const _langNames = {
    'it': 'Italian',
    'en': 'English',
    'ar': 'Arabic',
    'sq': 'Albanian',
    'ro': 'Romanian',
    'zh': 'Chinese (Simplified)',
    'bn': 'Bengali',
    'ur': 'Urdu',
    'uk': 'Ukrainian',
    'fr': 'French',
    'hi': 'Hindi',
    'pa': 'Punjabi',
    'es': 'Spanish',
    'ru': 'Russian',
  };

  /// Returns cached content for (schedaId, lang) if present, else null.
  Future<GuidaContenuto?> cached(String schedaId, String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(schedaId, langCode));
    if (raw == null || raw.isEmpty) return null;
    try {
      return GuidaContenuto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Generates and caches the content for (schedaId, lang). Throws on failure.
  Future<GuidaContenuto> generate(GuidaScheda scheda, String langCode) async {
    final lang = _langNames[langCode] ?? 'Italian';

    final systemPrompt =
        'You are an expert immigration counsellor ("operatore di patronato") for foreigners in Italy. '
        'You answer clearly, practically and kindly, in simple language. '
        'You always respond in $lang. Output is strict JSON, no markdown, no prose.';

    final prompt = '''
Scrivi una scheda informativa per immigrati in Italia sul documento/procedura: "${scheda.titolo}".
Ente erogatore: ${scheda.ente}. Link ufficiale: ${scheda.linkUfficiale}.

Rispondi ESCLUSIVAMENTE con un oggetto JSON valido nella lingua $lang, con questo schema:

{
  "cosEce": "Spiegazione chiara di cos'è, 2-4 frasi",
  "requisiti": ["requisito 1", "requisito 2", ...],
  "documenti": ["documento 1", "documento 2", ...],
  "dove": "Dove fare la domanda in modo concreto (uffici, portali)",
  "procedura": ["Passo 1 breve", "Passo 2 breve", ...],
  "costi": "Costi con importi precisi (marche bollo, tasse) o 'Gratuito'",
  "tempi": "Tempi tipici di risposta/rilascio",
  "avvertenze": ["avvertenza 1", "avvertenza 2", ...],
  "faq": [
    {"domanda": "Domanda comune", "risposta": "Risposta breve e pratica"},
    {"domanda": "...", "risposta": "..."},
    {"domanda": "...", "risposta": "..."}
  ]
}

Regole:
- Tutti i valori testuali nella lingua $lang.
- Se non sei sicuro di un dato (es. costo esatto), scrivi "Variabile" o "Verificare sul sito ufficiale".
- Includi almeno 3 requisiti, 3 documenti, 4 passi di procedura, 2 avvertenze, 3 FAQ.
- Non inventare: se un dato non è disponibile di default, indicarlo.
''';

    final res = await _gemini.chat(
      messages: [
        {'role': 'user', 'content': prompt},
      ],
      systemPrompt: systemPrompt,
      maxTokens: 4096,
      timeoutSeconds: 40,
    );

    if (!res.isSuccess || res.text.trim().isEmpty) {
      throw Exception(res.errorMessage ?? 'Errore AI');
    }

    final map = _extractJson(res.text);
    if (map == null) {
      throw Exception('Risposta AI non in formato valido');
    }

    final contenuto = GuidaContenuto.fromJson(map);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(scheda.id, langCode), jsonEncode(contenuto.toJson()));
    return contenuto;
  }

  /// Convenience: returns cached if available, else generates.
  Future<GuidaContenuto> load(GuidaScheda scheda, String langCode) async {
    final c = await cached(scheda.id, langCode);
    if (c != null) return c;
    return generate(scheda, langCode);
  }

  Future<void> clearCache(String schedaId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('$_prefsPrefix${schedaId}_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  Map<String, dynamic>? _extractJson(String text) {
    var t = text.trim();
    t = t.replaceAll(RegExp(r'```json', caseSensitive: false), '');
    t = t.replaceAll('```', '').trim();
    final start = t.indexOf('{');
    final end = t.lastIndexOf('}');
    if (start == -1 || end <= start) return null;
    try {
      return jsonDecode(t.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
