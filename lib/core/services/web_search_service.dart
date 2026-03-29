import 'package:http/http.dart' as http;

/// Servizio di ricerca web via DuckDuckGo (gratis, illimitato).
/// Cerca informazioni aggiornate su bonus, agevolazioni, leggi italiane.
class WebSearchService {
  static final WebSearchService _instance = WebSearchService._();
  factory WebSearchService() => _instance;
  WebSearchService._();

  /// Cerca su DuckDuckGo e ritorna i risultati come testo leggibile dall'AI.
  Future<String> search(String query) async {
    try {
      // DuckDuckGo HTML search (no API key needed)
      final uri = Uri.parse(
        'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}',
      );

      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return '';

      return _parseResults(response.body);
    } catch (_) {
      return '';
    }
  }

  /// Decide se la domanda dell'utente richiede ricerca web.
  bool needsWebSearch(String userMessage) {
    final lower = userMessage.toLowerCase();
    final keywords = [
      'bonus', 'agevolazione', 'agevolazioni', 'contributo', 'contributi',
      'incentivo', 'incentivi', 'scadenza', 'scadenze', 'bando', 'bandi',
      'decreto', 'legge', 'normativa', 'novità', 'nuovo', 'nuova', 'nuovi',
      'oggi', 'attuale', 'attualmente', 'corrente', '2024', '2025', '2026',
      'isee', 'inps', 'agenzia entrate', 'superbonus', 'ecobonus',
      'assegno unico', 'reddito', 'cittadinanza', 'permesso di soggiorno',
      'carta identità', 'spid', 'quanto', 'importo', 'requisiti',
      'come richiedere', 'come fare', 'domanda', 'modulo',
      'ultimo', 'ultima', 'ultimi', 'ultime', 'recente', 'recenti',
      'notizia', 'notizie', 'aggiornamento', 'aggiornamenti',
      'congedo', 'maternità', 'paternità', 'naspi', 'disoccupazione',
      'pensione', 'invalidità', 'handicap', '104',
    ];
    return keywords.any((k) => lower.contains(k));
  }

  /// Estrae titoli e snippet dai risultati HTML di DuckDuckGo.
  String _parseResults(String html) {
    final results = <String>[];
    // Estrai i risultati dai <a class="result__a"> e <a class="result__snippet">
    final titleRegex = RegExp(
      r'class="result__a"[^>]*>(.*?)</a>',
      dotAll: true,
    );
    final snippetRegex = RegExp(
      r'class="result__snippet"[^>]*>(.*?)</(?:a|td|div)',
      dotAll: true,
    );

    final titles = titleRegex.allMatches(html).toList();
    final snippets = snippetRegex.allMatches(html).toList();

    final count = titles.length < 5 ? titles.length : 5;
    for (var i = 0; i < count; i++) {
      final title = _stripHtml(titles[i].group(1) ?? '');
      final snippet = i < snippets.length
          ? _stripHtml(snippets[i].group(1) ?? '')
          : '';
      if (title.isNotEmpty) {
        results.add('$title: $snippet');
      }
    }

    if (results.isEmpty) return '';
    return results.join('\n\n');
  }

  /// Rimuove tag HTML da una stringa.
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
