import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'device_id_service.dart';
import 'web_search_service.dart';

// ---------------------------------------------------------------------------
// Servizio Google Gemini AI — Singleton
// - Modelli: gemini-2.5-flash (analisi), gemini-2.5-flash-lite (chat veloce)
// - Le richieste passano dal nostro proxy Cloudflare Worker; l'API key
//   Gemini vive SOLO sul server, mai nel binario app.
// ---------------------------------------------------------------------------
class GeminiService {
  static final GeminiService _instance = GeminiService._();
  factory GeminiService() => _instance;
  GeminiService._();

  static const _model = 'gemini-2.5-flash';
  static const _modelFast = 'gemini-2.5-flash-lite';
  static const _baseUrl =
      'https://bonus-italia-ai.alutori.workers.dev/v1beta/models';

  Uri _endpoint(String model) =>
      Uri.parse('$_baseUrl/$model:generateContent');

  Future<Map<String, String>> _headers() async {
    final deviceId = await DeviceIdService.getId();
    return {
      'Content-Type': 'application/json',
      'X-Device-Id': deviceId,
    };
  }

  // ── Verifica connessione API ──
  Future<bool> testConnection() async {
    try {
      final response = await http.post(
        _endpoint(_modelFast),
        headers: await _headers(),
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
      final headers = await _headers();

      final result = await Future.any([
        http.post(_endpoint(modelToUse), headers: headers, body: jsonEncode(body))
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
      final sizeMb = bytes.lengthInBytes / (1024 * 1024);
      debugPrint('[Gemini] analyzeDocument: file=${imageFile.path} ext=$ext size=${sizeMb.toStringAsFixed(2)}MB');

      // Gemini inline_data limit ≈ 20 MB (after base64). Reject early to avoid a 400.
      if (bytes.lengthInBytes > 18 * 1024 * 1024) {
        return AiResponse.error(
            'File troppo grande (${sizeMb.toStringAsFixed(1)} MB). Max 18 MB. Prova una foto più piccola o un PDF ridotto.');
      }

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

      debugPrint('[Gemini] POST $_model (mime=$mimeType, base64Len=${base64Data.length})');

      // Retry on 429 (rate limit) / 503 (overload) with exponential backoff:
      // 1.5s, 3s, 6s. Total max wait ≈ 10.5s before surfacing the error.
      final headers = await _headers();
      http.Response? response;
      int delayMs = 1500;
      for (int attempt = 0; attempt < 3; attempt++) {
        response = await http.post(
          _endpoint(_model),
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 90));

        if (response.statusCode != 429 && response.statusCode != 503) break;
        debugPrint('[Gemini] rate-limited (${response.statusCode}), retrying in ${delayMs}ms (attempt ${attempt + 1}/3)');
        if (attempt == 2) break;
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
      }

      debugPrint('[Gemini] status=${response!.statusCode} bodyLen=${response.body.length}');
      if (response.statusCode != 200) {
        debugPrint('[Gemini] body: ${response.body.substring(0, response.body.length.clamp(0, 1500))}');
      }
      return _parseResponse(response);
    } on TimeoutException {
      debugPrint('[Gemini] TimeoutException');
      return AiResponse.error('Timeout analisi documento (90s). Riprova con file più piccolo o rete migliore.');
    } on SocketException catch (e) {
      debugPrint('[Gemini] SocketException: $e');
      return AiResponse.error('Nessuna connessione internet.');
    } catch (e, st) {
      debugPrint('[Gemini] Exception: $e\n$st');
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
      if (candidates == null || candidates.isEmpty) {
        final promptFeedback = json['promptFeedback'];
        final blockReason = promptFeedback?['blockReason'];
        if (blockReason != null) {
          return AiResponse.error('Contenuto bloccato dal filtro AI: $blockReason');
        }
        return AiResponse.error('Risposta vuota dal server (nessun candidate).');
      }
      final first = candidates.first as Map<String, dynamic>;
      final finishReason = first['finishReason'];
      final content = first['content'];
      final parts = content?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        final text = parts
            .whereType<Map>()
            .map((p) => p['text'] as String? ?? '')
            .where((t) => t.isNotEmpty)
            .join('\n');
        if (text.isNotEmpty) return AiResponse.success(text);
      }
      if (finishReason == 'SAFETY') {
        return AiResponse.error('Contenuto bloccato per motivi di sicurezza AI.');
      }
      if (finishReason == 'MAX_TOKENS') {
        return AiResponse.error('Risposta troncata (MAX_TOKENS). Prova con meno testo.');
      }
      return AiResponse.error('Risposta vuota (finishReason=$finishReason).');
    } else if (response.statusCode == 429) {
      return AiResponse.error('Servizio AI momentaneamente sovraccarico. Riprova tra 30 secondi.');
    } else if (response.statusCode == 503) {
      return AiResponse.error('Servizio AI temporaneamente non disponibile. Riprova tra qualche minuto.');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      return AiResponse.error('API Key non valida o senza permessi.');
    } else {
      try {
        final json = jsonDecode(response.body);
        final msg = json['error']?['message'] ?? 'Errore sconosciuto';
        return AiResponse.error('Errore API (${response.statusCode}): $msg');
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
