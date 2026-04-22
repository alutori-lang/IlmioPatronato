import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../config/constants.dart';
import '../../core/services/language_service.dart';
import '../../core/services/translator_service.dart';

enum _Mode { text, voice, photo }

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  _Mode _mode = _Mode.text;

  String _fromCode = 'it';
  String _toCode = 'en';

  final _inputCtrl = TextEditingController();
  String _output = '';
  String? _explanation;
  bool _busy = false;

  final _tts = FlutterTts();
  late final stt.SpeechToText _stt;
  bool _sttReady = false;
  bool _listening = false;

  File? _photo;

  @override
  void initState() {
    super.initState();
    final lang = context.read<LanguageService>().currentCode;
    _toCode = lang == 'it' ? 'en' : lang;
    _stt = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _sttReady = await _stt.initialize(onError: (_) {}, onStatus: (_) {});
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _tts.stop();
    _stt.stop();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // Language utilities
  // ─────────────────────────────────────────
  AppLanguage _lang(String code) => supportedLanguages.firstWhere(
        (l) => l.code == code,
        orElse: () => supportedLanguages.first,
      );

  void _swap() {
    setState(() {
      final t = _fromCode;
      _fromCode = _toCode;
      _toCode = t;
      final oldOutput = _output;
      _output = _inputCtrl.text;
      _inputCtrl.text = oldOutput;
    });
  }

  Future<String?> _pickLanguage(String current) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            const Text('Scegli lingua',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: supportedLanguages.length,
                itemBuilder: (_, i) {
                  final lang = supportedLanguages[i];
                  final selected = lang.code == current;
                  return ListTile(
                    leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(lang.name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? AppColors.primary : AppColors.textDark)),
                    subtitle: Text(lang.nameEn,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                    trailing: selected
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(ctx, lang.code),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────
  Future<void> _translateText() async {
    FocusScope.of(context).unfocus();
    if (_inputCtrl.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _output = '';
      _explanation = null;
    });
    final res = await TranslatorService().translateText(
      text: _inputCtrl.text,
      fromCode: _fromCode,
      toCode: _toCode,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _output = res.ok ? res.translation : '';
    });
    if (!res.ok) {
      _showError(res.error ?? 'Errore');
    }
  }

  Future<void> _speak(String text, String code) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(_ttsLocale(code));
      await _tts.setSpeechRate(0.45);
      await _tts.speak(text);
    } catch (_) {}
  }

  String _ttsLocale(String code) {
    switch (code) {
      case 'it': return 'it-IT';
      case 'en': return 'en-US';
      case 'ar': return 'ar-SA';
      case 'sq': return 'sq-AL';
      case 'ro': return 'ro-RO';
      case 'zh': return 'zh-CN';
      case 'bn': return 'bn-IN';
      case 'ur': return 'ur-PK';
      case 'uk': return 'uk-UA';
      case 'fr': return 'fr-FR';
      case 'hi': return 'hi-IN';
      case 'pa': return 'pa-IN';
      default: return 'en-US';
    }
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      if (_inputCtrl.text.trim().isNotEmpty) {
        await _translateText();
      }
      return;
    }
    if (!_sttReady) {
      _showError('Microfono non disponibile.');
      return;
    }
    setState(() {
      _listening = true;
      _inputCtrl.clear();
      _output = '';
    });
    await _stt.listen(
      localeId: _ttsLocale(_fromCode),
      onResult: (r) {
        setState(() => _inputCtrl.text = r.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 95);
    if (file == null) return;
    setState(() {
      _photo = File(file.path);
      _output = '';
      _explanation = null;
      _busy = true;
    });
    final res = await TranslatorService().translateImage(
      imageFile: _photo!,
      toCode: _toCode,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _output = res.ok ? res.translation : '';
      _explanation = res.explanation;
    });
    if (!res.ok) {
      _showError(res.error ?? 'Errore');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _copy(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiato'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildLangBar(),
          _buildModeTabs(),
          Expanded(
            child: switch (_mode) {
              _Mode.text => _buildTextMode(),
              _Mode.voice => _buildVoiceMode(),
              _Mode.photo => _buildPhotoMode(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Icon(Icons.translate, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        const Text('Traduttore',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildLangBar() {
    final from = _lang(_fromCode);
    final to = _lang(_toCode);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(child: _langChip(from, onTap: () async {
            final c = await _pickLanguage(_fromCode);
            if (c != null) setState(() => _fromCode = c);
          })),
          IconButton(
            onPressed: _mode == _Mode.photo ? null : _swap,
            icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
            tooltip: 'Inverti lingue',
          ),
          Expanded(child: _langChip(to, onTap: () async {
            final c = await _pickLanguage(_toCode);
            if (c != null) setState(() => _toCode = c);
          })),
        ],
      ),
    );
  }

  Widget _langChip(AppLanguage lang, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(lang.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(lang.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more, size: 18, color: AppColors.textLight),
          ]),
        ),
      ),
    );
  }

  Widget _buildModeTabs() {
    final modes = [
      (_Mode.text, Icons.keyboard, 'Testo'),
      (_Mode.voice, Icons.mic, 'Voce'),
      (_Mode.photo, Icons.photo_camera, 'Foto'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: modes.map((m) {
          final selected = m.$1 == _mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _mode = m.$1;
                _output = '';
                _explanation = null;
              }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.buttonGradient : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                ),
                child: Column(children: [
                  Icon(m.$2, color: selected ? Colors.white : AppColors.primary, size: 22),
                  const SizedBox(height: 2),
                  Text(m.$3,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textDark,
                      )),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────── TEXT MODE ───────────
  Widget _buildTextMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _inputCard(
          title: _lang(_fromCode).name,
          child: TextField(
            controller: _inputCtrl,
            maxLines: 5,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Scrivi o incolla il testo…',
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 16, color: AppColors.textDark),
            onChanged: (_) => setState(() {}),
          ),
          trailing: _inputCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textLight,
                  onPressed: () => setState(() {
                    _inputCtrl.clear();
                    _output = '';
                  }),
                )
              : null,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy || _inputCtrl.text.trim().isEmpty ? null : _translateText,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            ),
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.translate),
            label: Text(_busy ? 'Traduzione…' : 'Traduci',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 14),
        _outputCard(
          title: _lang(_toCode).name,
          text: _output,
          langCode: _toCode,
        ),
      ]),
    );
  }

  // ─────────── VOICE MODE ───────────
  Widget _buildVoiceMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _inputCard(
          title: _lang(_fromCode).name,
          child: Text(
            _inputCtrl.text.isEmpty
                ? (_listening ? 'Sto ascoltando… parla pure.' : 'Premi il microfono e parla.')
                : _inputCtrl.text,
            style: TextStyle(
              fontSize: 17,
              color: _inputCtrl.text.isEmpty ? AppColors.textLight : AppColors.textDark,
            ),
          ),
          minHeight: 100,
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _busy ? null : _toggleListen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: _listening
                  ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)])
                  : AppColors.buttonGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_listening ? Colors.red : AppColors.primary).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: _listening ? 6 : 0,
                ),
              ],
            ),
            child: Icon(_listening ? Icons.stop : Icons.mic,
                color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _listening ? 'Tocca per fermare' : 'Tocca e parla',
          style: const TextStyle(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 18),
        _outputCard(
          title: _lang(_toCode).name,
          text: _output,
          langCode: _toCode,
          autoSpeak: true,
        ),
      ]),
    );
  }

  // ─────────── PHOTO MODE ───────────
  Widget _buildPhotoMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_photo == null)
          _buildPhotoPicker()
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(_photo!, height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Altra foto'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.image, size: 18),
                label: const Text('Galleria'),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 14),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Column(children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 14),
              Text('Analizzo il documento…',
                  style: TextStyle(fontSize: 14, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
            ]),
          )
        else if (_output.isNotEmpty) ...[
          _resultSection(
            icon: Icons.translate,
            title: 'Traduzione in ${_lang(_toCode).name}',
            text: _output,
            color: AppColors.primary,
            langCode: _toCode,
          ),
          if (_explanation != null && _explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _resultSection(
              icon: Icons.lightbulb,
              title: 'Cosa significa',
              text: _explanation!,
              color: const Color(0xFFF57C00),
              langCode: _toCode,
              highlight: true,
            ),
          ],
        ],
      ]),
    );
  }

  Widget _buildPhotoPicker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
      ),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.document_scanner, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 14),
        const Text('Fotografa un documento',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(
          'Traduci e capisci moduli italiani: ISEE, permesso di soggiorno, 730, bollette e molto altro.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMedium.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _busy ? null : () => _pickPhoto(ImageSource.camera),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scatta', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _pickPhoto(ImageSource.gallery),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.image),
              label: const Text('Galleria', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }

  // ─────────── Building blocks ───────────
  Widget _inputCard({
    required String title,
    required Widget child,
    Widget? trailing,
    double minHeight = 120,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
          const Spacer(),
          if (trailing != null) trailing,
        ]),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ]),
    );
  }

  Widget _outputCard({
    required String title,
    required String text,
    required String langCode,
    bool autoSpeak = false,
    double minHeight = 120,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.iconGreen, letterSpacing: 0.5)),
          const Spacer(),
          if (text.isNotEmpty) ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.volume_up, size: 20, color: AppColors.textMedium),
              onPressed: () => _speak(text, langCode),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.copy, size: 18, color: AppColors.textMedium),
              onPressed: () => _copy(text),
            ),
            const SizedBox(width: 4),
          ],
        ]),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: text.isEmpty
              ? const Text('La traduzione apparirà qui.',
                  style: TextStyle(fontSize: 15, color: AppColors.textLight))
              : Text(text,
                  style: const TextStyle(fontSize: 16, color: AppColors.textDark, height: 1.4)),
        ),
      ]),
    );
  }

  Widget _resultSection({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
    required String langCode,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: highlight ? Border.all(color: color.withValues(alpha: 0.25)) : null,
        boxShadow: highlight
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.volume_up, size: 20, color: AppColors.textMedium),
            onPressed: () => _speak(text, langCode),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.copy, size: 18, color: AppColors.textMedium),
            onPressed: () => _copy(text),
          ),
        ]),
        const SizedBox(height: 6),
        SelectableText(text,
            style: const TextStyle(fontSize: 15, color: AppColors.textDark, height: 1.5)),
      ]),
    );
  }
}
