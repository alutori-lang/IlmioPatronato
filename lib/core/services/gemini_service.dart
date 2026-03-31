import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'web_search_service.dart';

// ---------------------------------------------------------------------------
// Servizio Claude AI (Anthropic) — Singleton
// - Modello: claude-haiku-4-5-20251001 (veloce, economico, preciso)
// - Supporta: testo, immagini, PDF nativamente
// ---------------------------------------------------------------------------
class GeminiService {
  static final GeminiService _instance = GeminiService._();
  factory GeminiService() => _instance;
  GeminiService._();

  static const _apiKey = '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';
  static const _model = 'claude-sonnet-4-6';
  static const _modelFast = 'claude-haiku-4-5-20251001';
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';

  // ── Headers Anthropic ──
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey,
    'anthropic-version': '2023-06-01',
    'anthropic-beta': 'pdfs-2024-09-25',
  };

  // ── Verifica connessione API ──
  Future<bool> testConnection() async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'model': _model,
          'max_tokens': 8,
          'messages': [{'role': 'user', 'content': 'OK'}],
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Chat testuale ──
  Future<AiResponse> chat({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
  }) async {
    final claudeMessages = <Map<String, dynamic>>[];
    for (final msg in messages) {
      final role = msg['role'] as String;
      if (role == 'system') continue; // system va separato in Anthropic
      final content = msg['content'];
      String text;
      if (content is String) {
        text = content;
      } else if (content is List) {
        text = content
            .whereType<Map>()
            .where((c) => c['type'] == 'text')
            .map((c) => c['text'] as String)
            .join(' ');
      } else {
        continue;
      }
      claudeMessages.add({'role': role, 'content': text});
    }

    try {
      final body = <String, dynamic>{
        'model': _modelFast,
        'max_tokens': 2048,
        'messages': claudeMessages,
      };
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        body['system'] = systemPrompt;
      }

      final result = await Future.any([
        http.post(Uri.parse(_baseUrl), headers: _headers, body: jsonEncode(body))
            .then((r) => r as Object),
        Future.delayed(const Duration(seconds: 20), () => 'timeout' as Object),
      ]);

      if (result == 'timeout') return AiResponse.error('Timeout.');
      return _parseResponse(result as http.Response);
    } on SocketException {
      return AiResponse.error('Nessuna connessione internet.');
    } catch (e) {
      return AiResponse.error('Errore: $e');
    }
  }

  // ── Chat con ricerca web integrata ──
  Future<AiResponse> chatWithSearch({
    required List<Map<String, dynamic>> messages,
    required String userMessage,
    String? systemPrompt,
  }) async {
    final search = WebSearchService();
    String enrichedPrompt = systemPrompt ?? '';

    if (search.needsWebSearch(userMessage)) {
      final results = await search.search('$userMessage Italia 2026');
      if (results.isNotEmpty) {
        enrichedPrompt += '\n\n--- INFORMAZIONI DA INTERNET ---\n$results\n--- FINE ---\n'
            'Rispondi in modo aggiornato. Oggi è ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}.';
      }
    }

    return chat(messages: messages, systemPrompt: enrichedPrompt);
  }

  // ── Analisi documento (2 chiamate: trascrivi + estrai) ──
  Future<AiResponse> analyzeDocument({
    required File imageFile,
    required String prompt,
    String? systemPrompt,
  }) async {
    final ext = imageFile.path.split('.').last.toLowerCase();

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Data = base64Encode(bytes);
      final mimeType = _getMimeType(imageFile.path);

      // ── CHIAMATA 1: Trascrivi TUTTO il testo dal documento ──
      final transcribeBlocks = <dynamic>[
        {
          'type': ext == 'pdf' ? 'document' : 'image',
          'source': {
            'type': 'base64',
            'media_type': mimeType,
            'data': base64Data,
          },
        },
        {
          'type': 'text',
          'text': 'Trascrivi TUTTO il testo visibile in questo documento. '
              'Il documento potrebbe essere ruotato, storto, fotografato di lato. '
              'Trascrivi OGNI parola, numero, codice e data che riesci a leggere, riga per riga. '
              'Non saltare nulla. Non aggiungere commenti. Solo il testo che vedi.',
        },
      ];

      final transcribeBody = <String, dynamic>{
        'model': _model,
        'max_tokens': 2000,
        'messages': [
          {'role': 'user', 'content': transcribeBlocks},
        ],
      };

      final transcribeResponse = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode(transcribeBody),
      ).timeout(const Duration(seconds: 45));

      final transcribeResult = _parseResponse(transcribeResponse);
      if (!transcribeResult.isSuccess) return transcribeResult;

      final transcribedText = transcribeResult.text;

      // ── CHIAMATA 2: Estrai dati dal testo (NO immagine) ──
      final extractResult = await chat(
        messages: [
          {'role': 'user', 'content': 'Testo trascritto da un documento:\n\n$transcribedText\n\n$prompt'},
        ],
        systemPrompt: systemPrompt,
      );

      return extractResult;
    } on TimeoutException {
      return AiResponse.error('Timeout analisi documento. Riprova.');
    } on SocketException {
      return AiResponse.error('Nessuna connessione internet.');
    } catch (e) {
      return AiResponse.error('Errore analisi documento: $e');
    }
  }

  // ── Chat con immagine allegata ──
  Future<AiResponse> chatWithImage({
    required File imageFile,
    required String text,
    String? systemPrompt,
  }) async {
    return analyzeDocument(
      imageFile: imageFile,
      prompt: text,
      systemPrompt: systemPrompt,
    );
  }

  // ── Helpers ──
  AiResponse _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // Anthropic format: { content: [ { type: "text", text: "..." } ] }
      final content = json['content'] as List?;
      if (content != null && content.isNotEmpty) {
        final text = content.firstWhere(
          (c) => c['type'] == 'text',
          orElse: () => {'text': ''},
        )['text'] ?? '';
        return AiResponse.success(text);
      }
      return AiResponse.error('Risposta vuota dal server.');
    } else if (response.statusCode == 429) {
      return AiResponse.error('Troppe richieste. Riprova tra qualche secondo.');
    } else if (response.statusCode == 401) {
      return AiResponse.error('API Key non valida.');
    } else {
      try {
        final json = jsonDecode(response.body);
        final msg = json['error']?['message'] ?? 'Errore sconosciuto';
        return AiResponse.error('Errore API: $msg');
      } catch (_) {
        return AiResponse.error('Errore API (${response.statusCode})');
      }
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':  return 'image/png';
      case 'gif':  return 'image/gif';
      case 'webp': return 'image/webp';
      case 'pdf':  return 'application/pdf';
      default:     return 'image/jpeg';
    }
  }
}

// ---------------------------------------------------------------------------
// Modello risposta AI
// ---------------------------------------------------------------------------
class AiResponse {
  final bool isSuccess;
  final String text;
  final String? errorMessage;

  AiResponse._({required this.isSuccess, required this.text, this.errorMessage});

  factory AiResponse.success(String text) =>
      AiResponse._(isSuccess: true, text: text);

  factory AiResponse.error(String message) =>
      AiResponse._(isSuccess: false, text: '', errorMessage: message);

  Map<String, dynamic>? tryParseJson() {
    if (!isSuccess) return null;
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) return null;
      return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
