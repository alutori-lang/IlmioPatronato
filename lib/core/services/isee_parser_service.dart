import 'dart:convert';
import 'dart:io';
import 'gemini_service.dart';

class IseeParsed {
  final double? isee;
  final int? etaRichiedente;
  final int? numeroFigli;
  final List<int> etaFigli;
  final bool disabilitaRichiedente;
  final bool disabilitaFigli;
  final bool disabilitaAltroComponente;
  final String? statoFamiliare;
  final int? anno;
  final String? note;

  const IseeParsed({
    this.isee,
    this.etaRichiedente,
    this.numeroFigli,
    this.etaFigli = const [],
    this.disabilitaRichiedente = false,
    this.disabilitaFigli = false,
    this.disabilitaAltroComponente = false,
    this.statoFamiliare,
    this.anno,
    this.note,
  });

  bool get hasDisabilita =>
      disabilitaRichiedente || disabilitaFigli || disabilitaAltroComponente;

  factory IseeParsed.fromJson(Map<String, dynamic> j) {
    double? _num(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) {
        final cleaned = v.replaceAll('.', '').replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned);
      }
      return null;
    }

    int? _int(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
      return null;
    }

    bool _bool(dynamic v) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true' || v.toLowerCase() == 'si' || v.toLowerCase() == 'sì';
      return false;
    }

    final listFigli = <int>[];
    final rawFigli = j['etaFigli'];
    if (rawFigli is List) {
      for (final e in rawFigli) {
        final age = _int(e);
        if (age != null) listFigli.add(age);
      }
    }

    return IseeParsed(
      isee: _num(j['isee']),
      etaRichiedente: _int(j['etaRichiedente']),
      numeroFigli: _int(j['numeroFigli']) ?? listFigli.length,
      etaFigli: listFigli,
      disabilitaRichiedente: _bool(j['disabilitaRichiedente']),
      disabilitaFigli: _bool(j['disabilitaFigli']),
      disabilitaAltroComponente: _bool(j['disabilitaAltroComponente']),
      statoFamiliare: j['statoFamiliare'] as String?,
      anno: _int(j['anno']),
      note: j['note'] as String?,
    );
  }
}

class IseeParserResult {
  final IseeParsed? data;
  final String? error;
  const IseeParserResult({this.data, this.error});
  bool get ok => data != null && error == null;
}

class IseeParserService {
  IseeParserService._();
  static final IseeParserService _instance = IseeParserService._();
  factory IseeParserService() => _instance;

  final _gemini = GeminiService();

  Future<IseeParserResult> parse(File file) async {
    const systemPrompt =
        'Sei un esperto analista di attestazioni ISEE italiane (DSU - Dichiarazione Sostitutiva Unica). '
        'Estrai SOLO i dati richiesti dall\'immagine/PDF. '
        'Ignora patrimoni, redditi lordi, IBAN. Concentrati su: valore ISEE, composizione del nucleo familiare '
        '(età dei componenti), flag di disabilità/invalidità se presenti nelle annotazioni DSU. '
        'Rispondi SOLO con JSON valido.';

    const prompt = '''
Analizza questa attestazione ISEE italiana e restituisci ESCLUSIVAMENTE un oggetto JSON con questa forma:

{
  "isee": <numero, il valore ISEE ordinario o corrente; usa . come separatore decimale; null se non leggibile>,
  "anno": <anno di validità es. 2026; null se non chiaro>,
  "etaRichiedente": <età del dichiarante in anni, calcolata da data di nascita al 2026; null se non calcolabile>,
  "numeroFigli": <numero componenti del nucleo con data di nascita che li rende minori di 26 anni e che risultano figli; 0 se nessuno>,
  "etaFigli": [<lista delle età in anni dei figli ordinate crescente>],
  "disabilitaRichiedente": <true se il dichiarante è indicato come disabile/invalido nella DSU, altrimenti false>,
  "disabilitaFigli": <true se almeno un figlio è indicato come disabile, altrimenti false>,
  "disabilitaAltroComponente": <true se altri componenti (coniuge, genitore anziano) sono indicati come disabili, altrimenti false>,
  "statoFamiliare": <"single" | "sposato" | "convivente" | "separato" | "vedovo" | null>,
  "note": <stringa breve (<120 char) con osservazioni utili; null se non c'è nulla di rilevante>
}

REGOLE:
- Non inventare: se un campo non è chiaro metti null (o false per i booleani di disabilità).
- Output: SOLO JSON, senza markdown né testo extra.
''';

    final res = await _gemini.analyzeDocument(
      imageFile: file,
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    if (!res.isSuccess) {
      return IseeParserResult(error: res.errorMessage ?? 'Errore lettura ISEE');
    }

    final map = _extractJson(res.text);
    if (map == null) {
      return const IseeParserResult(error: 'Risposta AI non in JSON valido');
    }
    try {
      return IseeParserResult(data: IseeParsed.fromJson(map));
    } catch (e) {
      return IseeParserResult(error: 'Parsing fallito: $e');
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
