import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../config/constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/rich_message_widget.dart';

// ─────────────────────────────────────────────
// Modelli
// ─────────────────────────────────────────────

enum UserCategory {
  neogenitore,
  freelance,
  casaBonus,
  giovane,
}

extension UserCategoryExt on UserCategory {
  String get label {
    switch (this) {
      case UserCategory.neogenitore:
        return 'Neogenitore';
      case UserCategory.freelance:
        return 'Freelance / P.IVA';
      case UserCategory.casaBonus:
        return 'Casa & Bonus';
      case UserCategory.giovane:
        return 'Giovani';
    }
  }

  String get emoji {
    switch (this) {
      case UserCategory.neogenitore:
        return '👶';
      case UserCategory.freelance:
        return '💼';
      case UserCategory.casaBonus:
        return '🏠';
      case UserCategory.giovane:
        return '🎓';
    }
  }

  Color get color {
    switch (this) {
      case UserCategory.neogenitore:
        return const Color(0xFFE91E63);
      case UserCategory.freelance:
        return const Color(0xFF2196F3);
      case UserCategory.casaBonus:
        return const Color(0xFF4CAF50);
      case UserCategory.giovane:
        return const Color(0xFF9C27B0);
    }
  }

  List<String> get suggestedQuestions {
    switch (this) {
      case UserCategory.neogenitore:
        return [
          'Come richiedere Assegno Unico?',
          'Congedo parentale 2026',
          'Bonus Nido come funziona?',
          'ISEE per sussidi figli',
        ];
      case UserCategory.freelance:
        return [
          'Scadenze fiscali 2026',
          'Regime forfettario vantaggi',
          'Come fare fattura elettronica?',
          'Deduzioni P.IVA',
        ];
      case UserCategory.casaBonus:
        return [
          'Superbonus 2025 come funziona?',
          'Bonus Mobili requisiti',
          'CILA o SCIA: quale serve?',
          'Bonus Ristrutturazione 50%',
        ];
      case UserCategory.giovane:
        return [
          'Come fare l\'ISEE universitario?',
          'Carta Giovani Nazionale',
          'Cambio residenza procedura',
          'Registrare contratto affitto',
        ];
    }
  }

  String get systemPrompt {
    switch (this) {
      case UserCategory.neogenitore:
        return '''Sei Sbroglia.AI, l'esperto di burocrazia italiana specializzato in FAMIGLIA e GENITORI.
Conosci perfettamente: Assegno Unico Universale, Bonus Nido, Congedo parentale, Congedo di maternità/paternità,
Bonus bebè, Bonus asilo nido, iscrizioni scolastiche, detrazioni figli a carico, ISEE per sussidi familiari.
Regole fondamentali:
- Rispondi in italiano, in modo CHIARO, PRATICO e RASSICURANTE. I genitori sono stanchi.
- Usa liste puntate e passi numerati quando spieghi procedure.
- Indica sempre gli importi precisi (es. "fino a 175€/mese"), le scadenze e i link/portali giusti.
- Se serve l'ISEE, spiega brevemente come ottenerlo o aggiornarlo.
- Se un problema è troppo complesso, suggerisci di rivolgersi a un CAF o patronato.
- Non inventare mai leggi o importi: se non sei sicuro, dillo chiaramente.
- Tono: amichevole, come un amico esperto che ti aiuta.

REGOLE DI FORMATTAZIONE (OBBLIGATORIE):
1. Scrivi un RIASSUNTO BREVE di massimo 3-4 righe con le info essenziali.
2. Poi aggiungi una riga vuota e scrivi esattamente "---DETTAGLI---"
3. Dopo "---DETTAGLI---" scrivi i dettagli.
4. NON usare MAI asterischi ** per il grassetto. Scrivi il testo normalmente.
5. Per i link: scrivi SEMPRE il link come URL completo su una riga separata, es: https://www.inps.it
6. Per i titoli di sezione, mettili su una riga separata con ## davanti.
7. Scrivi frasi CORTE. Vai a capo spesso. NON fare muri di testo.''';
      case UserCategory.freelance:
        return '''Sei Sbroglia.AI, l'esperto di burocrazia italiana specializzato in FREELANCE e PARTITE IVA.
Conosci perfettamente: regime forfettario (coefficienti, limiti 85.000€), fatturazione elettronica SDI,
scadenze INPS Gestione Separata, F24, 730/Unico, dichiarazione IVA, apertura P.IVA, deduzioni e detrazioni,
contributi minimi, tassazione per scaglioni, cassa previdenziale per categorie.
Regole fondamentali:
- Rispondi in italiano, in modo PRECISO e CONCRETO. I freelance vogliono numeri esatti.
- Usa sempre percentuali, importi e scadenze precise (es. "Acconto IRPEF: 30 novembre").
- Distingui sempre tra regime forfettario e ordinario.
- Per domande su tasse: spiega sempre con esempi numerici semplici.
- Se serve un commercialista, dillo chiaramente.
- Non inventare mai aliquote o deduzioni: cita la fonte (es. "secondo art. 1 L. 190/2014").
- Tono: professionale ma diretto, come un commercialista amico.

REGOLE DI FORMATTAZIONE (OBBLIGATORIE):
1. Scrivi un RIASSUNTO BREVE di massimo 3-4 righe con le info essenziali.
2. Poi aggiungi una riga vuota e scrivi esattamente "---DETTAGLI---"
3. Dopo "---DETTAGLI---" scrivi i dettagli.
4. NON usare MAI asterischi ** per il grassetto. Scrivi il testo normalmente.
5. Per i link: scrivi SEMPRE il link come URL completo su una riga separata, es: https://www.inps.it
6. Per i titoli di sezione, mettili su una riga separata con ## davanti.
7. Scrivi frasi CORTE. Vai a capo spesso. NON fare muri di testo.''';
      case UserCategory.casaBonus:
        return '''Sei Sbroglia.AI, l'esperto di burocrazia italiana specializzato in CASA, RISTRUTTURAZIONI e BONUS EDILIZI.
Conosci perfettamente: Superbonus (110%, 90%, 70%, 65%), Ecobonus, Sismabonus, Bonus Mobili,
Bonus Facciate, CILA, CILAS, SCIA, permesso di costruire, cedolare secca, IMU, TARI,
contratti di locazione, agevolazioni prima casa, mutui, bonus giovani under 36.
Regole fondamentali:
- Rispondi in italiano, con PRECISIONE NORMATIVA.
- Distingui sempre tra quali lavori richiedono CILA vs SCIA vs permesso.
- Per i bonus: indica sempre la percentuale attuale (post-riduzioni 2024-2025), i limiti di spesa,
  la scadenza per i lavori e il tipo di immobile ammesso.
- Spiega sempre la differenza tra detrazione e cessione del credito/sconto in fattura.
- Se serve un geometra o architetto, dillo.
- Tono: tecnico ma accessibile.

REGOLE DI FORMATTAZIONE (OBBLIGATORIE):
1. Scrivi un RIASSUNTO BREVE di massimo 3-4 righe con le info essenziali.
2. Poi aggiungi una riga vuota e scrivi esattamente "---DETTAGLI---"
3. Dopo "---DETTAGLI---" scrivi i dettagli.
4. NON usare MAI asterischi ** per il grassetto. Scrivi il testo normalmente.
5. Per i link: scrivi SEMPRE il link come URL completo su una riga separata, es: https://www.inps.it
6. Per i titoli di sezione, mettili su una riga separata con ## davanti.
7. Scrivi frasi CORTE. Vai a capo spesso. NON fare muri di testo.''';
      case UserCategory.giovane:
        return '''Sei Sbroglia.AI, l'esperto di burocrazia italiana specializzato in GIOVANI e PRIMA AUTONOMIA.
Conosci perfettamente: ISEE universitario, borse di studio DSU, Carta Giovani Nazionale (18App),
cambio di residenza, registrazione contratto di affitto (cedolare secca, canone concordato),
SPID come ottenerlo, CIE, Carta d'Identità, patente di guida, dichiarazione redditi 730,
apertura conto corrente, bonus cultura 18enni, agevolazioni universitarie.
Regole fondamentali:
- Rispondi in italiano, in modo SEMPLICE e STEP-BY-STEP. Molti giovani fanno queste cose per la prima volta.
- Usa sempre passi numerati con spiegazioni brevi.
- Per ogni procedura indica: dove andare (fisico o online), cosa portare, quanto costa, quanto ci vuole.
- Usa link/portali ufficiali quando pertinente (es. "vai su inps.it > Servizi online").
- Tono: amichevole, come un amico più grande che ti spiega le cose.

REGOLE DI FORMATTAZIONE (OBBLIGATORIE):
1. Scrivi un RIASSUNTO BREVE di massimo 3-4 righe con le info essenziali.
2. Poi aggiungi una riga vuota e scrivi esattamente "---DETTAGLI---"
3. Dopo "---DETTAGLI---" scrivi i dettagli.
4. NON usare MAI asterischi ** per il grassetto. Scrivi il testo normalmente.
5. Per i link: scrivi SEMPRE il link come URL completo su una riga separata, es: https://www.inps.it
6. Per i titoli di sezione, mettili su una riga separata con ## davanti.
7. Scrivi frasi CORTE. Vai a capo spesso. NON fare muri di testo.''';
    }
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final File? imageFile; // allegato foto/immagine
  _ChatMessage({required this.text, required this.isUser, this.imageFile});
}

// ─────────────────────────────────────────────
// Schermata principale Sbroglia.AI
// ─────────────────────────────────────────────

class SbrogliaScreen extends StatefulWidget {
  const SbrogliaScreen({super.key});

  @override
  State<SbrogliaScreen> createState() => _SbrogliaScreenState();
}

class _SbrogliaScreenState extends State<SbrogliaScreen> {
  UserCategory? _selectedCategory;

  void _selectCategory(UserCategory cat) {
    setState(() => _selectedCategory = cat);
  }

  void _resetCategory() {
    setState(() => _selectedCategory = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCategory == null) {
      return _CategorySelectorScreen(onSelect: _selectCategory);
    }
    return _ChatScreen(
      category: _selectedCategory!,
      onBack: _resetCategory,
    );
  }
}

// ─────────────────────────────────────────────
// Selezione categoria (splash iniziale)
// ─────────────────────────────────────────────

class _CategorySelectorScreen extends StatelessWidget {
  final void Function(UserCategory) onSelect;
  const _CategorySelectorScreen({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D1B2A), Color(0xFF1B2E4E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D1B2A).withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('AI POWERED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Sbroglia.AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'La tua bussola nel caos\ndella burocrazia italiana.',
                        style: TextStyle(
                          color: Color(0xFF90CAF9),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          _FeaturePill(icon: Icons.bolt, text: 'Risposte istantanee'),
                          SizedBox(width: 8),
                          _FeaturePill(icon: Icons.verified, text: 'Dati ufficiali'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── CARD CHIEDI AL PATRONATO ──
                GestureDetector(
                  onTap: () => onSelect(UserCategory.neogenitore),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6A1B9A).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chiedi al Patronato',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                  fontFamily: 'serif',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Fai una domanda — risposta\nistantanea e precisa.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.psychology_rounded, color: Color(0xFF6A1B9A), size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Scrivi la tua domanda →',
                                      style: TextStyle(
                                        color: Color(0xFF6A1B9A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('🏛️', style: TextStyle(fontSize: 48)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                const Text(
                  'Chi sei?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0D1B2A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Scegli il tuo profilo per risposte\npersonalizzate al 100%',
                  style: TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.4),
                ),
                const SizedBox(height: 20),
                ...UserCategory.values.map((cat) => _CategoryCard(
                  category: cat,
                  onTap: () => onSelect(cat),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF6A1B9A).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SBROGLIA.AI', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text('Il tuo esperto di burocrazia', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, color: Colors.white, size: 7),
              SizedBox(width: 5),
              Text('ONLINE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeaturePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final UserCategory category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final descriptions = {
      UserCategory.neogenitore: 'Assegno Unico, Bonus Nido, Congedi, iscrizioni',
      UserCategory.freelance: 'Scadenze fiscali, fatture, P.IVA, deduzioni',
      UserCategory.casaBonus: 'Superbonus, CILA, SCIA, Bonus Mobili, IMU',
      UserCategory.giovane: 'ISEE uni, affitti, SPID, Carta Giovani, residenza',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: category.color.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: category.color.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    category.color.withValues(alpha: 0.15),
                    category.color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(category.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: category.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descriptions[category]!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3),
                  ),
                ],
              ),
            ),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: category.color, size: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Chat screen per una categoria specifica
// ─────────────────────────────────────────────

class _ChatScreen extends StatefulWidget {
  final UserCategory category;
  final VoidCallback onBack;
  const _ChatScreen({required this.category, required this.onBack});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _apiMessages = [];
  bool _isTyping = false;
  final _picker = ImagePicker();

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _addWelcomeMessage();
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

  void _addWelcomeMessage() {
    final welcomes = {
      UserCategory.neogenitore:
          'Ciao genitore! 👶 Sono il tuo esperto di burocrazia familiare.\n\n'
          'So tutto su:\n'
          '• Assegno Unico Universale\n'
          '• Bonus Nido e Congedi parentali\n'
          '• ISEE per sussidi figli\n'
          '• Iscrizioni scuola e agevolazioni\n\n'
          'Dimmi cosa ti serve, sono qui!',
      UserCategory.freelance:
          'Ciao! 💼 Sono il tuo commercialista AI.\n\n'
          'Conosco tutto su:\n'
          '• Regime forfettario e P.IVA\n'
          '• Fatturazione elettronica\n'
          '• Scadenze INPS e fiscali 2025\n'
          '• Deduzioni e ottimizzazione fiscale\n\n'
          'Cosa ti blocca oggi?',
      UserCategory.casaBonus:
          'Ciao! 🏠 Sono il tuo esperto di bonus casa e pratiche edilizie.\n\n'
          'Conosco tutto su:\n'
          '• Superbonus e Bonus Ristrutturazione\n'
          '• CILA, SCIA, permessi edilizi\n'
          '• Bonus Mobili e agevolazioni 2026\n'
          '• Affitti, cedolare secca, IMU\n\n'
          'Cosa stai cercando di fare?',
      UserCategory.giovane:
          'Ciao! 🎓 Sono il tuo guida nella burocrazia italiana.\n\n'
          'Ti aiuto con:\n'
          '• ISEE universitario e borse di studio\n'
          '• Affitto, cambio residenza, registrazione contratto\n'
          '• SPID, CIE, Carta Giovani\n'
          '• Dichiarazione dei redditi 730\n\n'
          'Dimmi da dove vuoi iniziare!',
    };

    _messages.add(_ChatMessage(
      text: welcomes[widget.category]!,
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = preset ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    _apiMessages.add({'role': 'user', 'content': text});

    final response = await GeminiService().chatWithSearch(
      messages: _apiMessages,
      userMessage: text,
      systemPrompt: widget.category.systemPrompt,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      _apiMessages.add({'role': 'assistant', 'content': response.text});
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response.text, isUser: false));
      });
    } else {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: response.errorMessage ?? 'Errore. Riprova.',
          isUser: false,
        ));
      });
    }
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Scatta foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Scegli dalla galleria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final picked = await _picker.pickImage(source: choice, imageQuality: 85);
    if (picked == null || !mounted) return;

    final imageFile = File(picked.path);
    final userText = _controller.text.trim().isNotEmpty
        ? _controller.text.trim()
        : 'Analizza questo documento e dimmi cosa contiene e cosa devo fare.';
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: userText, isUser: true, imageFile: imageFile));
      _isTyping = true;
    });
    _scrollToBottom();

    final response = await GeminiService().analyzeDocument(
      imageFile: imageFile,
      prompt: '${widget.category.systemPrompt}\n\nL\'utente ha inviato un\'immagine di un documento. $userText',
    );

    if (!mounted) return;
    if (response.isSuccess) {
      _apiMessages.add({'role': 'assistant', 'content': response.text});
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response.text, isUser: false));
      });
    } else {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response.errorMessage ?? 'Errore. Riprova.', isUser: false));
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

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Column(
      children: [
        // Header con categoria attiva
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20, right: 20, bottom: 14,
          ),
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sbroglia.AI — ${cat.label}',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    const Text('Esperto AI burocrazia italiana',
                        style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, color: Colors.white, size: 7),
                  SizedBox(width: 5),
                  Text('AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
        ),

        // Suggestion chips
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            children: cat.suggestedQuestions
                .map((q) => _SuggestionChip(
                      text: q,
                      color: cat.color,
                      onTap: () => _sendMessage(q),
                    ))
                .toList(),
          ),
        ),

        // Messaggi
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (_isTyping && i == _messages.length) return _TypingIndicator(color: cat.color);
              return _MessageBubble(msg: _messages[i], categoryColor: cat.color, categoryEmoji: cat.emoji);
            },
          ),
        ),

        // Listening indicator
        if (_isListening)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cat.color.withValues(alpha: 0.08),
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

        // Input
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              // Bottone allegato foto
              GestureDetector(
                onTap: _isTyping ? null : _sendImage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isTyping ? Colors.grey.shade100 : cat.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.attach_file_rounded,
                    color: _isTyping ? Colors.grey.shade400 : cat.color,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Chiedi a Sbroglia.AI...',
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
                    color: _isListening ? Colors.red.shade50 : cat.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: _isListening ? Border.all(color: Colors.red.shade300, width: 1.5) : null,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : cat.color,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _isTyping ? null : () => _sendMessage(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _isTyping
                        ? null
                        : LinearGradient(colors: [cat.color, cat.color.withValues(alpha: 0.8)]),
                    color: _isTyping ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isTyping
                        ? null
                        : [BoxShadow(color: cat.color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _isTyping ? Colors.grey.shade500 : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Widget ausiliari
// ─────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage msg;
  final Color categoryColor;
  final String categoryEmoji;
  const _MessageBubble({required this.msg, required this.categoryColor, required this.categoryEmoji});

  @override
  Widget build(BuildContext context) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 60),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [categoryColor, categoryColor.withValues(alpha: 0.85)]),
              borderRadius: BorderRadius.circular(18).copyWith(bottomRight: const Radius.circular(4)),
              boxShadow: [BoxShadow(color: categoryColor.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.imageFile != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(msg.imageFile!, width: 180, height: 130, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(msg.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, height: 1.45)),
              ],
            ),
          ),
        ),
      );
    }

    // AI message with expandable details
    return _ExpandableSbrogliaMessage(
      text: msg.text,
      categoryColor: categoryColor,
      categoryEmoji: categoryEmoji,
    );
  }
}

// ── Messaggio AI espandibile per Sbroglia ──

class _ExpandableSbrogliaMessage extends StatefulWidget {
  final String text;
  final Color categoryColor;
  final String categoryEmoji;
  const _ExpandableSbrogliaMessage({required this.text, required this.categoryColor, required this.categoryEmoji});

  @override
  State<_ExpandableSbrogliaMessage> createState() => _ExpandableSbrogliaMessageState();
}

class _ExpandableSbrogliaMessageState extends State<_ExpandableSbrogliaMessage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    String summary;
    String? details;

    final separatorIndex = widget.text.indexOf('---DETTAGLI---');
    if (separatorIndex != -1) {
      summary = widget.text.substring(0, separatorIndex).trim();
      details = widget.text.substring(separatorIndex + 14).trim();
    } else {
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
      padding: const EdgeInsets.only(bottom: 14, right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [widget.categoryColor, widget.categoryColor.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(widget.categoryEmoji, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: const Radius.circular(4)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
                border: Border.all(color: widget.categoryColor.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichMessageWidget(text: summary),
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
                          Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: widget.categoryColor),
                          const SizedBox(width: 4),
                          Text('Nascondi dettagli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.categoryColor)),
                        ]),
                      ),
                    ] else
                      GestureDetector(
                        onTap: () => setState(() => _expanded = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              widget.categoryColor.withValues(alpha: 0.08),
                              widget.categoryColor.withValues(alpha: 0.04),
                            ]),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: widget.categoryColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: widget.categoryColor),
                            const SizedBox(width: 6),
                            Text('Maggiori dettagli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.categoryColor)),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: widget.categoryColor),
                          ]),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _Dot(delay: 0, color: color),
              const SizedBox(width: 5),
              _Dot(delay: 200, color: color),
              const SizedBox(width: 5),
              _Dot(delay: 400, color: color),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  final Color color;
  const _Dot({required this.delay, required this.color});
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
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.3 + _a.value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
