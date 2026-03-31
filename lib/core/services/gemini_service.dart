import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncpdf;
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
    final ext = imageFile.path.split('.').last.toLowerCase();

    try {
      // ── PDF: estrai testo e usa modello testo (più affidabile) ──
      if (ext == 'pdf') {
        try {
          // Estrai testo dal PDF con Syncfusion
          final bytes = await imageFile.readAsBytes();
          final pdfDoc = syncpdf.PdfDocument(inputBytes: bytes);
          final extractor = syncpdf.PdfTextExtractor(pdfDoc);
          final extractedText = extractor.extractText();
          pdfDoc.dispose();

          // Se c'è testo, usa il modello testo (molto più affidabile dei numeri!)
          if (extractedText.trim().length > 30) {
            // Taglia il testo a max 3000 caratteri per stare nei limiti API
            final trimmedText = extractedText.length > 3000
                ? extractedText.substring(0, 3000)
                : extractedText;
            return chat(
              messages: [
                {'role': 'user', 'content': 'Testo busta paga:\n$trimmedText\n\n$prompt'},
              ],
              systemPrompt: systemPrompt,
            );
          }

          // Se il PDF non ha testo (scansionato), converti in immagine ad alta risoluzione
          final doc = await PdfDocument.openFile(imageFile.path);
          final page = await doc.getPage(1);
          final pageImage = await page.render(
            width: page.width * 4,
            height: page.height * 4,
            format: PdfPageImageFormat.jpeg,
            quality: 100,
          );
          await page.close();
          await doc.close();

          if (pageImage == null) {
            return AiResponse.error('PDF non leggibile. Prova con una foto.');
          }

          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(pageImage.bytes);

          final imgBytes = await tempFile.readAsBytes();
          final base64Img = base64Encode(imgBytes);
          final imgMessages = <Map<String, dynamic>>[];
          if (systemPrompt != null) imgMessages.add({'role': 'system', 'content': systemPrompt});
          imgMessages.add({'role': 'user', 'content': [
            {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Img'}},
            {'type': 'text', 'text': prompt},
          ]});
          final imgResponse = await http.post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
            body: jsonEncode({'model': _modelVision, 'messages': imgMessages, 'max_tokens': 4096}),
          ).timeout(const Duration(seconds: 30));
          return _parseResponse(imgResponse);
        } catch (e) {
          return AiResponse.error('Errore lettura PDF: $e');
        }
      }

      // ── Immagine: usa modello vision ──
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
