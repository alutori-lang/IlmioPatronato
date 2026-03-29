import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'web_search_service.dart';

// ---------------------------------------------------------------------------
// Servizio Groq AI — Singleton
// - chat testuale: llama-3.1-8b-instant (14.400 req/giorno gratis)
// - chat con immagine: llama-3.2-11b-vision-preview (vision gratuita)
// ---------------------------------------------------------------------------
class GeminiService {
  static final GeminiService _instance = GeminiService._();
  factory GeminiService() => _instance;
  GeminiService._();

  static const _apiKey = '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';
  static const _modelText   = 'llama-3.1-8b-instant';
  static const _modelVision = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // ── Verifica connessione API ──

  Future<bool> testConnection() async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelText,
          'messages': [{'role': 'user', 'content': 'OK'}],
          'max_tokens': 8,
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
    final groqMessages = <Map<String, dynamic>>[];
    if (systemPrompt != null) {
      groqMessages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final msg in messages) {
      final role = msg['role'] as String;
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
      groqMessages.add({'role': role, 'content': text});
    }

    try {
      // Future.any garantisce timeout anche su Android
      final result = await Future.any([
        http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _modelText,
            'messages': groqMessages,
            'max_tokens': 1024,
            'temperature': 0.3,
          }),
        ).then((r) => r as Object),
        Future.delayed(const Duration(seconds: 15), () => 'timeout' as Object),
      ]);

      if (result == 'timeout') {
        return AiResponse.error('Timeout.');
      }
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

    // Se la domanda richiede info aggiornate, cerca su web
    if (search.needsWebSearch(userMessage)) {
      final results = await search.search('$userMessage Italia 2026');
      if (results.isNotEmpty) {
        enrichedPrompt += '\n\n--- INFORMAZIONI AGGIORNATE DA INTERNET (usa questi dati per rispondere) ---\n$results\n--- FINE RISULTATI WEB ---\n'
            'Usa le informazioni sopra per dare una risposta aggiornata e precisa. '
            'La data di oggi è ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}.';
      }
    }

    return chat(messages: messages, systemPrompt: enrichedPrompt);
  }

  // ── Analisi documento con immagine (Groq Vision) ──

  Future<AiResponse> analyzeDocument({
    required File imageFile,
    required String prompt,
    String? systemPrompt,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imageFile.path);

      final userContent = <dynamic>[
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:$mimeType;base64,$base64Image',
          },
        },
        {
          'type': 'text',
          'text': prompt,
        },
      ];

      final groqMessages = <Map<String, dynamic>>[];
      if (systemPrompt != null) {
        groqMessages.add({'role': 'system', 'content': systemPrompt});
      }
      groqMessages.add({'role': 'user', 'content': userContent});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelVision,
          'messages': groqMessages,
          'max_tokens': 4096,
        }),
      ).timeout(const Duration(seconds: 30));
      return _parseResponse(response);
    } on TimeoutException {
      return AiResponse.error('Timeout analisi immagine.');
    } on SocketException {
      return AiResponse.error('Nessuna connessione internet.');
    } catch (e) {
      return AiResponse.error('Errore analisi immagine: $e');
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
      final choices = json['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final text = choices[0]['message']?['content'] ?? '';
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
