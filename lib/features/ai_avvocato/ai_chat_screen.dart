import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../config/constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';
import '../../core/widgets/rich_message_widget.dart';

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

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  static const _systemPrompt =
      'Sei un assistente esperto in immigrazione italiana, diritto del lavoro, bonus, agevolazioni e pratiche burocratiche. '
      'HAI ACCESSO A INFORMAZIONI IN TEMPO REALE tramite ricerca web. '
      'Rispondi sempre in italiano, in modo chiaro, pratico e comprensibile. '
      'Quando ricevi risultati di ricerca web, usali per dare informazioni aggiornate e precise. '
      'Se l\'utente invia una foto di un documento, analizzalo e spiega cosa contiene. '
      'Se non sei sicuro di qualcosa, consiglia di consultare un patronato o un professionista. '
      'Non inventare leggi o numeri: se non sai, dillo.\n\n'
      'REGOLE DI FORMATTAZIONE (OBBLIGATORIE):\n'
      '1. Rispondi in modo BREVE e CHIARO. Massimo 3-4 righe di riassunto iniziale.\n'
      '2. Poi aggiungi una riga vuota e scrivi esattamente "---DETTAGLI---"\n'
      '3. Dopo "---DETTAGLI---" scrivi i dettagli.\n'
      '4. NON usare MAI asterischi ** per il grassetto. Scrivi il testo normalmente.\n'
      '5. Per i link: scrivi SEMPRE il link come URL completo su una riga separata, es:\nhttps://www.inps.it/bonus\n'
      '6. Per le liste numerate scrivi:\n1. Primo passo\n2. Secondo passo\n'
      '7. Per i titoli di sezione, mettili su una riga separata con ## davanti, es:\n## Come fare domanda\n'
      '8. Scrivi frasi CORTE. Vai a capo spesso. NON fare muri di testo.\n'
      '9. Quando dai un link, metti PRIMA una breve descrizione e poi il link su riga nuova.\n'
      '10. NON mettere parentesi tonde o quadre attorno ai link.\n'
      'Esempio di risposta perfetta:\n'
      'Puoi richiedere il bonus bebè sul sito INPS.\n\n'
      '## Come fare domanda\n'
      '1. Vai sul sito INPS\nhttps://www.inps.it\n'
      '2. Accedi con SPID o CIE\n'
      '3. Cerca "Bonus bebè" nella barra di ricerca\n'
      '4. Compila il modulo online\n\n'
      '---DETTAGLI---\n'
      '## Requisiti\n'
      '- ISEE inferiore a 40.000 euro\n'
      '- Figlio nato o adottato nel 2026\n';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _messages.add(_ChatMessage(
      text: 'Ciao! Sono il tuo Assistente AI Immigrazione.\n\n'
          'Posso aiutarti con:\n'
          '• Permesso di soggiorno\n'
          '• Cittadinanza italiana\n'
          '• Ricongiungimento familiare\n'
          '• Documenti e pratiche\n'
          '• Diritti dei lavoratori\n'
          '• Analisi documenti (inviami una foto!)\n\n'
          'Scrivi o parla con il microfono!',
      isUser: false,
    ));
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          setState(() => _isListening = false);
        }
      },
    );
    setState(() {});
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (_speechAvailable) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            });
            if (result.finalResult) {
              setState(() => _isListening = false);
            }
          },
          localeId: 'it_IT',
          listenMode: stt.ListenMode.dictation,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

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
      response = await GeminiService().chatWithImage(
        imageFile: image,
        text: text.isNotEmpty ? text : 'Analizza questo documento e dimmi cosa contiene.',
        systemPrompt: _systemPrompt,
      );
    } else {
      _apiMessages.add({'role': 'user', 'content': text});
      response = await GeminiService().chatWithSearch(
        messages: _apiMessages,
        userMessage: text,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
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
            _chip('Bonus 2026'),
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
      // Listening indicator
      if (_isListening)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.primary.withValues(alpha: 0.08),
          child: Row(children: [
            Icon(Icons.mic, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text('Sto ascoltando... parla ora', style: TextStyle(fontSize: 13, color: AppColors.textMedium, fontStyle: FontStyle.italic))),
            GestureDetector(
              onTap: _toggleListening,
              child: const Icon(Icons.close, size: 20, color: AppColors.textLight),
            ),
          ]),
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
          const SizedBox(width: 6),
          // Mic button
          GestureDetector(
            onTap: _isTyping ? null : _toggleListening,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isListening ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: _isListening ? Border.all(color: Colors.red.shade300, width: 1.5) : null,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Send button
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
    ]),
    );
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
    // AI message with expandable details
    return _ExpandableAiMessage(text: msg.text);
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

// ── Messaggio AI con "Maggiori dettagli" espandibile ──

class _ExpandableAiMessage extends StatefulWidget {
  final String text;
  const _ExpandableAiMessage({required this.text});

  @override
  State<_ExpandableAiMessage> createState() => _ExpandableAiMessageState();
}

class _ExpandableAiMessageState extends State<_ExpandableAiMessage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Separa riassunto e dettagli
    String summary;
    String? details;

    final separatorIndex = widget.text.indexOf('---DETTAGLI---');
    if (separatorIndex != -1) {
      summary = widget.text.substring(0, separatorIndex).trim();
      details = widget.text.substring(separatorIndex + 14).trim();
    } else {
      // Fallback: se l'AI non ha usato il formato, mostra le prime 4 righe come riassunto
      final lines = widget.text.split('\n');
      if (lines.length > 5) {
        summary = lines.take(4).join('\n');
        details = lines.skip(4).join('\n');
      } else {
        summary = widget.text;
        details = null;
      }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Riassunto (sempre visibile)
                RichMessageWidget(text: summary),
                // Dettagli espandibili
                if (details != null && details.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  if (_expanded) ...[
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 10),
                    RichMessageWidget(text: details),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = false),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Nascondi dettagli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ]),
                    ),
                  ] else
                    GestureDetector(
                      onTap: () => setState(() => _expanded = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.primary.withValues(alpha: 0.04),
                          ]),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Maggiori dettagli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                        ]),
                      ),
                    ),
                ],
              ],
            ),
          ),
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
