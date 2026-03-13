import 'package:flutter/material.dart';
import '../../config/constants.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

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
          '• Diritti dei lavoratori\n\n'
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

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: _getResponse(text), isUser: false));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _getResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('permesso') || q.contains('soggiorno')) {
      return 'Per il permesso di soggiorno:\n\nDocumenti necessari:\n• Kit postale (uffici postali)\n• Passaporto + fotocopia\n• 4 foto tessera\n• Marca da bollo €16\n• Contributo €40-€100\n\nTempi: 60-90 giorni\n\nConsiglio: Invia il kit il prima possibile. Il cedolino ti copre fino alla convocazione.\n\nQuesto è solo informativo. Consulta un patronato per il tuo caso specifico.';
    }
    if (q.contains('cittadinanza')) {
      return 'Cittadinanza italiana - 2 vie:\n\nPer matrimonio:\n• Sposato/a con italiano/a da 2+ anni\n• Livello italiano B1\n• Domanda online su portale ALI\n• Tempi: ~24 mesi\n\nPer residenza:\n• 10 anni di residenza legale (UE: 4 anni)\n• Reddito sufficiente\n• Nessun precedente penale\n\nCosti: €250 contributo + €16 marca da bollo';
    }
    if (q.contains('spid')) {
      return 'Per creare lo SPID:\n\nMetodo più semplice - Poste Italiane:\n1. Vai all\'ufficio postale con:\n   • Documento o permesso di soggiorno\n   • Codice fiscale\n   • Email e telefono\n2. Chiedi di attivare PosteID\n3. Gratuito in ufficio!\n\nCon lo SPID accedi a INPS, Agenzia Entrate, ANPR e tutti i servizi online.';
    }
    if (q.contains('isee')) {
      return 'L\'ISEE - Indicatore Situazione Economica:\n\nA cosa serve:\n• Richiedere bonus e agevolazioni\n• ADI (Assegno di Inclusione)\n• Bonus bollette, asilo nido\n\nDocumenti per il CAF:\n• Documenti identità di tutti in famiglia\n• Codici fiscali\n• CU (Certificazione Unica)\n• Saldi conti correnti al 31/12\n\nL\'ISEE al CAF è GRATUITO!';
    }
    return 'Grazie per la domanda!\n\nNella versione completa, collegherò Gemini AI per risposte personalizzate.\n\nIntanto consulta:\n• Le 18 Guide nella sezione Guide\n• Le Domande della community\n\nProva a chiedermi di: permesso di soggiorno, cittadinanza, SPID, ISEE';
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
            Text('Assistente legale', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.badge, borderRadius: BorderRadius.circular(12)),
            child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
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
      // Input
      Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Chiedi all\'avvocato AI...', hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
                  border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
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
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(4)),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Text(msg.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, height: 1.4)),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 40),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Text(msg.text, style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.4)),
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
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
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
