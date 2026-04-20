import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'web_search_service.dart';

// ---------------------------------------------------------------------------
// Servizio Google Gemini AI — Singleton
// - Modelli: gemini-2.5-flash (analisi), gemini-2.5-flash-lite (chat veloce)
// - Supporta: testo, immagini, PDF nativamente
// - Free tier generoso via Google AI Studio
// ---------------------------------------------------------------------------
class GeminiService {
  static final GeminiService _instance = GeminiService._();
  factory GeminiService() => _instance;
  GeminiService._();

  static const _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const _model = 'gemini-2.5-flash';
  static const _modelFast = 'gemini-2.5-flash-lite';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  Uri _endpoint(String model) =>
      Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // ── Verifica connessione API ──
  Future<bool> testConnection() async {
    try {
      final response = await http.post(
        _endpoint(_modelFast),
        headers: _headers,
        body: jsonEncode({
          'contents': [
            {'role': 'user', 'parts': [{'text': 'OK'}]}
          ],
          'generationConfig': {'maxOutputTokens': 8},
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
    bool useGoogleSearch = false,
    int maxTokens = 2048,
    int timeoutSeconds = 20,
  }) async {
    final geminiContents = <Map<String, dynamic>>[];
    for (final msg in messages) {
      final role = msg['role'] as String;
      if (role == 'system') continue;
      final geminiRole = role == 'assistant' ? 'model' : 'user';
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
      geminiContents.add({
        'role': geminiRole,
        'parts': [{'text': text}],
      });
    }

    try {
      final body = <String, dynamic>{
        'contents': geminiContents,
        'generationConfig': {'maxOutputTokens': maxTokens},
      };
      if (useGoogleSearch) {
        body['tools'] = [{'google_search': {}}];
      }
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        body['systemInstruction'] = {
          'parts': [{'text': systemPrompt}],
        };
      }

      // Con Google Search serve il modello full, non flash-lite
      final modelToUse = useGoogleSearch ? _model : _modelFast;

      final result = await Future.any([
        http.post(_endpoint(modelToUse), headers: _headers, body: jsonEncode(body))
            .then((r) => r as Object),
        Future.delayed(Duration(seconds: timeoutSeconds), () => 'timeout' as Object),
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

  // ── Analisi documento (immagine o PDF) ──
  Future<AiResponse> analyzeDocument({
    required File imageFile,
    required String prompt,
    String? systemPrompt,
  }) async {
    final ext = imageFile.path.split('.').last.toLowerCase();

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Data = base64Encode(bytes);
      final mimeType = ext == 'pdf' ? 'application/pdf'
          : ext == 'png' ? 'image/png'
          : ext == 'webp' ? 'image/webp'
          : ext == 'gif' ? 'image/gif'
          : 'image/jpeg';

      final parts = <Map<String, dynamic>>[
        {
          'inline_data': {
            'mime_type': mimeType,
            'data': base64Data,
          },
        },
        {'text': prompt},
      ];

      final promptLower = prompt.toLowerCase();
      final expectsJson = promptLower.contains('json');

      final body = <String, dynamic>{
        'contents': [
          {'role': 'user', 'parts': parts},
        ],
        'generationConfig': {
          'maxOutputTokens': 4096,
          if (expectsJson) 'responseMimeType': 'application/json',
        },
      };
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        body['systemInstruction'] = {
          'parts': [{'text': systemPrompt}],
        };
      }

      final response = await http.post(
        _endpoint(_model),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      return _parseResponse(response);
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
      // Gemini format: { candidates: [ { content: { parts: [ { text: "..." } ] } } ] }
      final candidates = json['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates.first['content'];
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts
              .whereType<Map>()
              .map((p) => p['text'] as String? ?? '')
              .where((t) => t.isNotEmpty)
              .join('\n');
          if (text.isNotEmpty) return AiResponse.success(text);
        }
      }
      return AiResponse.error('Risposta vuota dal server.');
    } else if (response.statusCode == 429) {
      return AiResponse.error('Troppe richieste. Riprova tra qualche secondo.');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
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

}

// ---------------------------------------------------------------------------
// Modello risposta AI
// ---------------------------------------------------------------------------
class AiResponse {
  final bool isSuccess;
  final String text;
  final String? errorMessage;
  final String? ocrText;

  AiResponse._({required this.isSuccess, required this.text, this.errorMessage, this.ocrText});

  factory AiResponse.success(String text, {String? ocrText}) =>
      AiResponse._(isSuccess: true, text: text, ocrText: ocrText);

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
