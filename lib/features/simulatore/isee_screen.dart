import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../core/widgets/disclaimer_widget.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class IseeScreen extends StatefulWidget {
  const IseeScreen({super.key});

  @override
  State<IseeScreen> createState() => _IseeScreenState();
}

class _IseeScreenState extends State<IseeScreen> with SingleTickerProviderStateMixin {
  // ── Nucleo familiare ──
  int _componenti = 1;
  int _figliMinorenni = 0;
  int _figliSotto3 = 0;
  bool _genitoreSolo = false;
  bool _componenteDisabile = false;
  bool _entrambiLavorano = false;

  // ── Redditi ──
  final _redditoController = TextEditingController();

  // ── Patrimonio Mobiliare ──
  final _mobiliareController = TextEditingController();

  // ── Patrimonio Immobiliare ──
  final _immobiliareController = TextEditingController();
  final _mutuoController = TextEditingController();
  bool _abitazionePrincipale = true;

  // ── AI upload ──
  bool _isAnalyzingDoc = false;
  String? _aiError;

  // ── Result ──
  bool _showResult = false;
  double _iseeValue = 0;
  double _iseValue = 0;
  double _scalaEquivalenza = 0;
  double _patMobNetto = 0;
  double _patImmNetto = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _numberFormat = NumberFormat('#,##0.00', 'it_IT');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _redditoController.dispose();
    _mobiliareController.dispose();
    _immobiliareController.dispose();
    _mutuoController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // ISEE CALCULATION (formula ufficiale DPCM 159/2013)
  // ─────────────────────────────────────────────
  void _calcola() {
    final reddito = _parseNum(_redditoController.text);
    final mobiliare = _parseNum(_mobiliareController.text);
    final immobiliare = _parseNum(_immobiliareController.text);
    final mutuo = _parseNum(_mutuoController.text);

    // ── Scala di equivalenza ──
    double scala;
    switch (_componenti) {
      case 1:
        scala = 1.00;
        break;
      case 2:
        scala = 1.57;
        break;
      case 3:
        scala = 2.04;
        break;
      case 4:
        scala = 2.46;
        break;
      case 5:
        scala = 2.85;
        break;
      default:
        scala = 2.85 + (_componenti - 5) * 0.35;
    }

    // Maggiorazioni
    if (_genitoreSolo && _figliMinorenni > 0) {
      scala += 0.35;
    }
    if (_componenteDisabile) {
      scala += 0.50;
    }
    if (_componenti >= 4 && _figliMinorenni >= 3) {
      scala += 0.20;
    }
    if (_entrambiLavorano && _figliMinorenni > 0 && _figliSotto3 > 0) {
      scala += 0.35;
    }

    // ── Patrimonio mobiliare netto ──
    // Franchigia: €6,000 base + €2,000 per ogni componente dopo il primo (max €10,000)
    // + €1,000 per ogni figlio dopo il secondo
    double franchigiaMob = 6000.0;
    franchigiaMob += (_componenti - 1).clamp(0, 99) * 2000.0;
    if (franchigiaMob > 10000.0) franchigiaMob = 10000.0;
    final figliExtra = (_figliMinorenni - 2).clamp(0, 99);
    franchigiaMob += figliExtra * 1000.0;

    _patMobNetto = (mobiliare - franchigiaMob).clamp(0, double.infinity);

    // ── Patrimonio immobiliare netto ──
    double immNetto = immobiliare;
    if (mutuo > 0) {
      immNetto = (immNetto - mutuo).clamp(0, double.infinity);
    }
    if (_abitazionePrincipale) {
      // Detrazione abitazione principale: €52,500 + €2,500 per componente (max 2 incrementi)
      double detrazioneAbitazione = 52500.0;
      final incrementi = (_componenti - 1).clamp(0, 2);
      detrazioneAbitazione += incrementi * 2500.0;
      immNetto = (immNetto - detrazioneAbitazione).clamp(0, double.infinity);
    }
    _patImmNetto = immNetto;

    // ── ISE = Reddito + 20% del Patrimonio ──
    _iseValue = reddito + 0.20 * (_patMobNetto + _patImmNetto);

    // ── ISEE = ISE / Scala di equivalenza ──
    _iseeValue = scala > 0 ? _iseValue / scala : 0;
    _scalaEquivalenza = scala;

    setState(() => _showResult = true);
    _animController.forward(from: 0);
  }

  double _parseNum(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  double _parseAiNum(dynamic v) {
    if (v == null) return 0;
    final s = v.toString().replaceAll('€', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
  }

  int _parseAiInt(dynamic v) {
    if (v == null) return 1;
    final s = v.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(s) ?? 1;
  }

  Future<void> _pickAndAnalyzeIsee(ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return;

    setState(() { _isAnalyzingDoc = true; _aiError = null; });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Analizza questa attestazione ISEE italiana. Estrai i dati e restituisci SOLO un JSON valido (senza markdown, senza \`\`\`):
{
  "valore_isee": "importo numerico",
  "valore_ise": "importo numerico",
  "nucleo_familiare_componenti": "numero",
  "reddito_complessivo": "importo numerico",
  "patrimonio_mobiliare": "importo numerico",
  "patrimonio_immobiliare": "importo numerico",
  "scala_equivalenza": "numero decimale"
}
Importi come numeri senza simbolo €. Se un campo non è leggibile, metti null.''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        setState(() {
          _componenti = _parseAiInt(parsed['nucleo_familiare_componenti']).clamp(1, 12);
          _redditoController.text = _parseAiNum(parsed['reddito_complessivo']).toStringAsFixed(0);
          _mobiliareController.text = _parseAiNum(parsed['patrimonio_mobiliare']).toStringAsFixed(0);
          _immobiliareController.text = _parseAiNum(parsed['patrimonio_immobiliare']).toStringAsFixed(0);
          _isAnalyzingDoc = false;
        });
        _calcola();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dati ISEE importati! Puoi modificarli prima di ricalcolare.'),
            backgroundColor: Color(0xFF4CAF50),
          ));
        }
      } else {
        setState(() { _aiError = 'Impossibile leggere i dati. Riprova con una foto più nitida.'; _isAnalyzingDoc = false; });
      }
    } else {
      setState(() { _aiError = response.errorMessage; _isAnalyzingDoc = false; });
    }
  }

  // ── Fascia colore in base all'ISEE ──
  Color _fasciColor() {
    if (_iseeValue <= 9360) return const Color(0xFF4CAF50);
    if (_iseeValue <= 15000) return const Color(0xFF2196F3);
    if (_iseeValue <= 25000) return const Color(0xFFFFC107);
    if (_iseeValue <= 40000) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _fasciLabel() {
    if (_iseeValue <= 9360) return 'FASCIA BASSA - Accesso ADI, bonus, esenzioni';
    if (_iseeValue <= 15000) return 'FASCIA MEDIO-BASSA - Agevolazioni tariffe, bonus';
    if (_iseeValue <= 25000) return 'FASCIA MEDIA - Alcune agevolazioni';
    if (_iseeValue <= 40000) return 'FASCIA MEDIO-ALTA - Poche agevolazioni';
    return 'FASCIA ALTA - Nessuna agevolazione ISEE';
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildAiUploadBanner()),
            SliverToBoxAdapter(child: _buildInfoBanner()),
            SliverToBoxAdapter(child: _sectionTitle('Nucleo Familiare')),
            SliverToBoxAdapter(child: _buildNucleoSection()),
            SliverToBoxAdapter(child: _sectionTitle('Redditi Complessivi')),
            SliverToBoxAdapter(child: _buildRedditoSection()),
            SliverToBoxAdapter(child: _sectionTitle('Patrimonio Mobiliare')),
            SliverToBoxAdapter(child: _buildMobiliareSection()),
            SliverToBoxAdapter(child: _sectionTitle('Patrimonio Immobiliare')),
            SliverToBoxAdapter(child: _buildImmobiliareSection()),
            SliverToBoxAdapter(child: _buildCalcolaButton()),
            if (_showResult)
              SliverToBoxAdapter(child: _buildResultCard()),
            if (_showResult)
              SliverToBoxAdapter(child: _buildDettaglioCard()),
            if (_showResult)
              SliverToBoxAdapter(child: _buildAgevolazioniCard()),
            SliverToBoxAdapter(child: CalculatorDisclaimer(specificSource: 'DPCM 159/2013 (formula ufficiale ISEE)')),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calculate, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIMULATORE ISEE', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Formula ufficiale DPCM 159/2013', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Upload Banner ──
  Widget _buildAiUploadBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.06), const Color(0xFF42A5F5).withValues(alpha: 0.06)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isAnalyzingDoc ? null : () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => SafeArea(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Text('Carica Attestazione ISEE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.camera_alt, color: AppColors.primary)),
                    title: const Text('Fotocamera', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Scatta una foto dell\'attestazione', style: TextStyle(fontSize: 12)),
                    onTap: () { Navigator.pop(context); _pickAndAnalyzeIsee(ImageSource.camera); },
                  ),
                  ListTile(
                    leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.photo_library, color: AppColors.primary)),
                    title: const Text('Galleria', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Scegli dalla galleria foto', style: TextStyle(fontSize: 12)),
                    onTap: () { Navigator.pop(context); _pickAndAnalyzeIsee(ImageSource.gallery); },
                  ),
                ]),
              )),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(12)),
                child: _isAnalyzingDoc
                    ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.document_scanner, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _isAnalyzingDoc ? 'Analisi AI in corso...' : 'Carica Attestazione ISEE',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                Text(
                  _isAnalyzingDoc ? 'Claude sta leggendo il documento' : 'Foto o immagine → auto-compila i campi',
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ])),
              if (!_isAnalyzingDoc) const Icon(Icons.chevron_right, color: AppColors.primary),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Info banner ──
  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFFA000), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: Color(0xFF5D4037), height: 1.4),
                children: [
                  TextSpan(text: 'Questo è un calcolo indicativo. ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: 'L\'ISEE ufficiale deve essere rilasciato da un CAF o tramite il sito INPS con la DSU precompilata.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    );
  }

  // ── Nucleo familiare ──
  Widget _buildNucleoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildCounter('Componenti nucleo', _componenti, 1, 12, (v) => setState(() {
            _componenti = v;
            if (_figliMinorenni > _componenti - 1) _figliMinorenni = (_componenti - 1).clamp(0, 99);
          })),
          const Divider(height: 24),
          _buildCounter('Figli minorenni', _figliMinorenni, 0, _componenti - 1, (v) => setState(() {
            _figliMinorenni = v;
            if (_figliSotto3 > v) _figliSotto3 = v;
          })),
          const Divider(height: 24),
          _buildCounter('Di cui sotto 3 anni', _figliSotto3, 0, _figliMinorenni, (v) => setState(() => _figliSotto3 = v)),
          const Divider(height: 24),
          _buildSwitch('Genitore solo (unico)', _genitoreSolo, (v) => setState(() => _genitoreSolo = v)),
          _buildSwitch('Componente con disabilità', _componenteDisabile, (v) => setState(() => _componenteDisabile = v)),
          _buildSwitch('Entrambi i genitori lavorano', _entrambiLavorano, (v) => setState(() => _entrambiLavorano = v)),
        ],
      ),
    );
  }

  // ── Reddito ──
  Widget _buildRedditoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Somma dei redditi di TUTTI i componenti del nucleo familiare (lordo, da CU/730)',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3)),
          const SizedBox(height: 12),
          _buildMoneyField(_redditoController, 'Reddito complessivo annuo'),
        ],
      ),
    );
  }

  // ── Patrimonio mobiliare ──
  Widget _buildMobiliareSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Conti correnti, libretti, titoli, fondi, azioni, obbligazioni, BOT, CCT, etc. (saldo medio o al 31/12)',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3)),
          const SizedBox(height: 12),
          _buildMoneyField(_mobiliareController, 'Totale patrimonio mobiliare'),
        ],
      ),
    );
  }

  // ── Patrimonio immobiliare ──
  Widget _buildImmobiliareSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Valore ai fini IMU di tutti gli immobili (casa, terreni, box, etc.)',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3)),
          const SizedBox(height: 12),
          _buildMoneyField(_immobiliareController, 'Valore immobili (IMU)'),
          const SizedBox(height: 12),
          _buildMoneyField(_mutuoController, 'Mutuo residuo (opzionale)'),
          const SizedBox(height: 12),
          _buildSwitch('Abitazione principale nel nucleo', _abitazionePrincipale, (v) => setState(() => _abitazionePrincipale = v)),
        ],
      ),
    );
  }

  // ── Calcola button ──
  Widget _buildCalcolaButton() {
    return GestureDetector(
      onTap: _calcola,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('CALCOLA ISEE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  // ── Result card ──
  Widget _buildResultCard() {
    final color = _fasciColor();
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('IL TUO ISEE STIMATO', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(
                '€ ${_numberFormat.format(_iseeValue)}',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _fasciLabel(),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dettaglio calcolo ──
  Widget _buildDettaglioCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dettaglio Calcolo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            _detailRow('Scala di equivalenza', _scalaEquivalenza.toStringAsFixed(2)),
            _detailRow('Patrimonio mob. netto', '€ ${_numberFormat.format(_patMobNetto)}'),
            _detailRow('Patrimonio imm. netto', '€ ${_numberFormat.format(_patImmNetto)}'),
            _detailRow('20% patrimonio totale', '€ ${_numberFormat.format(0.20 * (_patMobNetto + _patImmNetto))}'),
            const Divider(height: 20),
            _detailRow('ISE (reddito + 20% patrimonio)', '€ ${_numberFormat.format(_iseValue)}', bold: true),
            _detailRow('ISEE (ISE / scala)', '€ ${_numberFormat.format(_iseeValue)}', bold: true),
          ],
        ),
      ),
    );
  }

  // ── Agevolazioni possibili ──
  Widget _buildAgevolazioniCard() {
    final agevolazioni = <_Agevolazione>[
      _Agevolazione('ADI - Assegno di Inclusione', 9360, Icons.account_balance_wallet),
      _Agevolazione('Assegno Unico (importo max)', 17090.61, Icons.child_care),
      _Agevolazione('Bonus Asilo Nido', 25000, Icons.school),
      _Agevolazione('Esenzione ticket sanitario', 8263.31, Icons.local_hospital),
      _Agevolazione('Bonus Sociale Luce/Gas', 9530, Icons.bolt),
      _Agevolazione('Reddito di Libertà', 9360, Icons.favorite),
      _Agevolazione('Riduzione tasse universitarie', 26000, Icons.menu_book),
      _Agevolazione('Bonus Psicologo', 50000, Icons.psychology),
    ];

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agevolazioni con il tuo ISEE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 4),
            const Text('Verifica indicativa - Controlla sempre i requisiti specifici', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
            const SizedBox(height: 14),
            ...agevolazioni.map((a) {
              final idoneo = _iseeValue <= a.soglia;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: (idoneo ? const Color(0xFF4CAF50) : const Color(0xFFF44336)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.icon, size: 18, color: idoneo ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          Text('Soglia: € ${_numberFormat.format(a.soglia)}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (idoneo ? const Color(0xFF4CAF50) : const Color(0xFFF44336)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        idoneo ? 'IDONEO' : 'NON IDONEO',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: idoneo ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // REUSABLE WIDGETS
  // ─────────────────────────────────────────────
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 3))],
    );
  }

  Widget _buildCounter(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark))),
        _counterBtn(Icons.remove, value > min, () => onChanged(value - 1)),
        Container(
          width: 40, alignment: Alignment.center,
          child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ),
        _counterBtn(Icons.add, value < max, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _counterBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: enabled ? AppColors.primary : Colors.grey.shade400),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
          Switch.adaptive(
            value: value, onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        prefixText: '€  ',
        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: bold ? AppColors.textDark : AppColors.textMedium, fontWeight: bold ? FontWeight.w600 : FontWeight.w400))),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? AppColors.primary : AppColors.textDark)),
        ],
      ),
    );
  }
}

class _Agevolazione {
  final String nome;
  final double soglia;
  final IconData icon;
  const _Agevolazione(this.nome, this.soglia, this.icon);
}
