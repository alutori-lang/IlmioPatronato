import 'dart:io';
import 'gemini_service.dart';

class TranslationResult {
  final String translation;
  final String? explanation;
  final String? error;

  TranslationResult({
    required this.translation,
    this.explanation,
    this.error,
  });

  factory TranslationResult.error(String msg) =>
      TranslationResult(translation: '', error: msg);

  bool get ok => error == null && translation.isNotEmpty;
}

class TranslatorService {
  TranslatorService._();
  static final TranslatorService _instance = TranslatorService._();
  factory TranslatorService() => _instance;

  final _gemini = GeminiService();

  /// Maps ISO code to a language name understood by the model.
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
    'de': 'German',
    'pt': 'Portuguese',
  };

  static String nameOf(String code) => _langNames[code] ?? code;

  /// Translate plain text between two languages.
  Future<TranslationResult> translateText({
    required String text,
    required String fromCode,
    required String toCode,
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult.error('Testo vuoto.');
    }

    final from = nameOf(fromCode);
    final to = nameOf(toCode);

    final systemPrompt =
        'You are a professional translator specialized in Italian bureaucratic and legal documents '
        '(patronato, CAF, ISEE, permesso di soggiorno, 730, INPS, Agenzia delle Entrate). '
        'Translate the user text from $from to $to accurately, naturally and fluently. '
        'Preserve the meaning of bureaucratic terminology. '
        'If the source contains Italian bureaucratic terms, choose the most common equivalent used by native $to speakers. '
        'Output ONLY the translated text, no preface, no quotes, no comments.';

    final res = await _gemini.chat(
      messages: [
        {'role': 'user', 'content': text},
      ],
      systemPrompt: systemPrompt,
      maxTokens: 2048,
    );

    if (!res.isSuccess) {
      return TranslationResult.error(res.errorMessage ?? 'Errore di traduzione.');
    }
    return TranslationResult(translation: res.text.trim());
  }

  /// Translate an image (document photo) and produce a simple explanation.
  Future<TranslationResult> translateImage({
    required File imageFile,
    required String toCode,
  }) async {
    final to = nameOf(toCode);

    final systemPrompt =
        'You are an expert assistant for immigrants in Italy helping them understand Italian bureaucratic documents '
        '(permesso di soggiorno, ISEE, 730, bollette, moduli INPS, Agenzia delle Entrate, patronato forms). '
        'Be clear, kind, and concrete.';

    final prompt = '''
Analyze this image of an Italian document. Then respond in $to with EXACTLY this format and nothing else:

===TRANSLATION===
<full faithful translation of the document text in $to>

===EXPLANATION===
<plain-language explanation in $to, maximum 6 short bullet points, of:
- what this document is,
- what it asks from the reader,
- what they must do (action required, if any),
- important deadlines or amounts,
- warnings or things to watch out for.
Use simple words. No jargon. Write as if explaining to a friend.>
''';

    final res = await _gemini.analyzeDocument(
      imageFile: imageFile,
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    if (!res.isSuccess) {
      return TranslationResult.error(res.errorMessage ?? 'Errore analisi documento.');
    }

    final raw = res.text.trim();
    final tMatch = RegExp(r'===TRANSLATION===\s*([\s\S]*?)\s*===EXPLANATION===')
        .firstMatch(raw);
    final eMatch = RegExp(r'===EXPLANATION===\s*([\s\S]*)').firstMatch(raw);

    if (tMatch != null && eMatch != null) {
      return TranslationResult(
        translation: tMatch.group(1)!.trim(),
        explanation: eMatch.group(1)!.trim(),
      );
    }
    return TranslationResult(translation: raw);
  }
}
