import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Google Cloud Vision OCR — Singleton
// Immagini: Vision API direttamente
// PDF: converti in immagine → Vision API
// ---------------------------------------------------------------------------
class VisionService {
  static final VisionService _instance = VisionService._();
  factory VisionService() => _instance;
  VisionService._();

  static const _apiKey = 'AIzaSyCH4Zdk_-a8AaCEOB-5lf2MFOXChhTKw7I';
  static const _baseUrl =
      'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

  /// Estrae testo da qualsiasi file (immagine o PDF)
  Future<VisionResult> extractText(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    if (ext == 'pdf') {
      return _extractFromPdf(file);
    }
    return _ocrFromBytes(await file.readAsBytes());
  }

  /// PDF → renderizza ogni pagina come immagine → OCR Vision
  Future<VisionResult> _extractFromPdf(File pdfFile) async {
    try {
      final document = await PdfDocument.openFile(pdfFile.path);
      final pageCount = document.pagesCount;
      final allText = StringBuffer();

      // Leggi tutte le pagine (max 5 per sicurezza)
      final maxPages = pageCount > 5 ? 5 : pageCount;
      for (int i = 1; i <= maxPages; i++) {
        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.png,
        );
        await page.close();

        if (pageImage == null) continue;

        final result = await _ocrFromBytes(pageImage.bytes);
        if (result.isSuccess) {
          if (allText.isNotEmpty) allText.write('\n\n--- PAGINA ${i + 1} ---\n\n');
          allText.write(result.text);
        }
      }

      await document.close();

      if (allText.isEmpty) {
        return VisionResult.error('Nessun testo trovato nel PDF.');
      }
      return VisionResult.success(allText.toString());
    } catch (e) {
      return VisionResult.error('Errore lettura PDF: $e');
    }
  }

  /// OCR con Google Cloud Vision da bytes immagine
  Future<VisionResult> _ocrFromBytes(Uint8List imageBytes) async {
    try {
      final base64Data = base64Encode(imageBytes);

      final body = {
        'requests': [
          {
            'image': {'content': base64Data},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1},
            ],
            'imageContext': {
              'languageHints': ['it', 'en'],
            },
          },
        ],
      };

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final responses = json['responses'] as List?;

        if (responses == null || responses.isEmpty) {
          return VisionResult.error('Nessuna risposta da Vision API.');
        }

        final first = responses[0] as Map<String, dynamic>;

        final error = first['error'];
        if (error != null) {
          return VisionResult.error(
              'Vision API: ${error['message'] ?? 'Errore sconosciuto'}');
        }

        final fullText = first['fullTextAnnotation'];
        if (fullText != null) {
          final text = fullText['text'] as String? ?? '';
          if (text.isNotEmpty) return VisionResult.success(text);
        }

        final annotations = first['textAnnotations'] as List?;
        if (annotations != null && annotations.isNotEmpty) {
          final text = annotations[0]['description'] as String? ?? '';
          if (text.isNotEmpty) return VisionResult.success(text);
        }

        return VisionResult.error(
            'Nessun testo trovato. Prova con una foto più nitida.');
      } else {
        try {
          final json = jsonDecode(response.body);
          final msg = json['error']?['message'] ?? 'Errore sconosciuto';
          return VisionResult.error('Vision API: $msg');
        } catch (_) {
          return VisionResult.error('Vision API errore (${response.statusCode})');
        }
      }
    } on TimeoutException {
      return VisionResult.error('Timeout lettura documento. Riprova.');
    } on SocketException {
      return VisionResult.error('Nessuna connessione internet.');
    } catch (e) {
      return VisionResult.error('Errore OCR: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Risultato OCR
// ---------------------------------------------------------------------------
class VisionResult {
  final bool isSuccess;
  final String text;
  final String? errorMessage;

  VisionResult._({required this.isSuccess, required this.text, this.errorMessage});

  factory VisionResult.success(String text) =>
      VisionResult._(isSuccess: true, text: text);

  factory VisionResult.error(String message) =>
      VisionResult._(isSuccess: false, text: '', errorMessage: message);
}
