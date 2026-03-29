import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final File? image;
  _ChatMessage({required this.text, required this.isUser, this.image});
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _apiMessages = [];
  bool _isTyping = false;
  File? _pendingImage;

  static const _systemPrompt =
      'Sei un assistente esperto in immigrazione italiana, diritto del lavoro, bonus, agevolazioni e pratiche burocratiche. '
      'Rispondi sempre in italiano, in modo chiaro, pratico e comprensibile. '
      'Se l\'utente invia una foto di un documento, analizzalo e spiega cosa contiene. '
      'Se non sei sicuro di qualcosa, consiglia di consultare un patronato o un professionista. '
      'Non inventare leggi o numeri: se non sai, dillo.';

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: 'Ciao! Sono il tuo Assistente AI Immigrazione.\n\n'
          'Posso aiutarti con:\n'
          '• Permesso di soggiorno\n'
          '• Cittadinanza italiana\n'
          '• Ricongiungimento familiare\n'
          '• Documenti e pratiche\n'
          '• Diritti dei lavoratori\n'
          '• Analisi documenti (inviami una foto!)\n\n'
          'Scrivi la tua domanda!',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    final image = _pendingImage;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, image: image));
      _isTyping = true;
      _pendingImage = null;
    });
    _controller.clear();
    _scrollToBottom();

    AiResponse response;

    if (image != null) {
      // Send with image
      response = await GeminiService().chatWithImage(
        imageFile: image,
        text: text.isNotEmpty ? text : 'Analizza questo documento e dimmi cosa contiene.',
        systemPrompt: _systemPrompt,
      );
    } else {
      // Text-only: build conversation
      _apiMessages.add({'role': 'user', 'content': text});
      response = await GeminiService().chat(
        messages: _apiMessages,
        systemPrompt: _systemPrompt,
      );
    }

    if (!mounted) return;

    if (response.isSuccess) {
      if (image == null) {
        _apiMessages.add({'role': 'assistant', 'content': response.text});
      }
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response.text, isUser: false));
      });
    } else {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: response.errorMessage ?? 'Errore nella risposta. Riprova.',
          isUser: false,
        ));
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await pickImage(source);
    if (file != null) {
      setState(() => _pendingImage = file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 14),
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Avvocato', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Assistente legale con Claude AI', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(12)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.smart_toy, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Text('AI', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
      // Suggestion chips
      SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          children: [
            _chip('Permesso di soggiorno'),
            _chip('Cittadinanza'),
            _chip('SPID'),
            _chip('ISEE'),
            _chip('Bonus 2025'),
          ],
        ),
      ),
      // Messages
      Expanded(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length + (_isTyping ? 1 : 0),
          itemBuilder: (_, i) {
            if (_isTyping && i == _messages.length) return _typingIndicator();
            return _buildMessage(_messages[i]);
          },
        ),
      ),
      // Pending image preview
      if (_pendingImage != null)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_pendingImage!, width: 60, height: 60, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Foto allegata', style: TextStyle(fontSize: 12, color: AppColors.textMedium))),
            GestureDetector(
              onTap: () => setState(() => _pendingImage = null),
              child: const Icon(Icons.close, size: 20, color: AppColors.textLight),
            ),
          ]),
        ),
      // Input
      Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(children: [
          // Attach image button
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => SafeArea(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    const Text('Allega documento', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                      title: const Text('Fotocamera'),
                      onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library, color: AppColors.primary),
                      title: const Text('Galleria'),
                      onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                    ),
                  ]),
                )),
              );
            },
            child: Container(
              width: 38, height: 38,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.attach_file, color: AppColors.primary, size: 20),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Chiedi all\'avvocato AI...',
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isTyping ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _chip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () { _controller.text = text; _sendMessage(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 50),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (msg.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(msg.image!, width: 180, height: 180, fit: BoxFit.cover),
              ),
            if (msg.text.isNotEmpty) ...[
              if (msg.image != null) const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(4)),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Text(msg.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, height: 1.4)),
              ),
            ],
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 40),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: SelectableText(msg.text, style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.4)),
          ),
        ),
      ]),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 80),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            _Dot(delay: 0), SizedBox(width: 4), _Dot(delay: 200), SizedBox(width: 4), _Dot(delay: 400),
          ]),
        ),
      ]),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _a = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.repeat(reverse: true); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.3 + _a.value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
