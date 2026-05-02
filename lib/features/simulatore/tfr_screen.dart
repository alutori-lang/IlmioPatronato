import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/constants.dart';
import '../../core/widgets/disclaimer_widget.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class TfrScreen extends StatefulWidget {
  const TfrScreen({super.key});

  @override
  State<TfrScreen> createState() => _TfrScreenState();
}

class _TfrScreenState extends State<TfrScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzingDoc = false;
  bool _showResult = false;

  // Dati estratti dall'AI
  double _ral = 0;
  int _anniLavoro = 0;
  String _azienda = '';
  String _dipendente = '';
  String _ccnl = '';

  // Risultati calcolo
  double _tfrLordo = 0;
  double _tfrNetto = 0;
  double _tassazioneSeparata = 0;
  double _aliquotaMedia = 0;
  double _tfrAnnuoLordo = 0;
  double _contributoInps = 0;
  double _tfrAnnuoNetto = 0;
  List<_TfrAnnuale> _dettaglioAnnuale = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _pAi(dynamic v) {
    if (v == null) return 0;
    final s = v.toString().replaceAll('€', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
  }

  Future<void> _pickPdf() async {
    final file = await pickPdfFile();
    if (file == null) return;

    setState(() {
      _isAnalyzingDoc = true;
      _showResult = false;
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Sei un consulente del lavoro italiano. Guarda questa busta paga e leggi i valori ESATTI per calcolare il TFR.

Rispondi SOLO con JSON valido, niente altro testo:
{"ral_annua": 0, "retribuzione_mensile": 0, "anni_lavoro": 0, "azienda": "", "dipendente": "", "ccnl": ""}

COME TROVARE I CAMPI:

RETRIBUZIONE MENSILE:
- Cerca la retribuzione mensile piena nella sezione "elementi retributivi" (MINIMO + EDR + EPA + altri)
- Oppure il "totale" degli elementi retributivi
- È lo stipendio PIENO mensile da contratto (NON l'imponibile lordo che può essere parziale)
- Tipicamente tra 800 e 4000 euro

RAL ANNUA:
- Se trovi "RAL" o "retribuzione annua lorda" usa quel valore
- Se NON trovi la RAL, metti 0 e compila retribuzione_mensile (la calcolo io: mensile × 13)

ANNI LAVORO:
- Calcola dalla data di assunzione ad oggi (aprile 2026)
- Se assunto da pochi mesi, metti 1

FORMATO NUMERI (IMPORTANTISSIMO):
- Usa punto come decimale: 1657.00
- Se nel documento vedi "1.657,00" → scrivi 1657.00
- La retribuzione mensile è tra 800 e 4000, la RAL tra 10000 e 60000''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        double ral = _pAi(parsed['ral_annua']);
        final mensile = _pAi(parsed['retribuzione_mensile']);
        final anni = _pAi(parsed['anni_lavoro']);

        // Se RAL non trovata ma mensile sì, calcola RAL
        if (ral <= 0 && mensile > 0) {
          final m = mensile > 5000 ? mensile / 10 : mensile;
          ral = m * 13;
        }
        // Sanity check RAL
        if (ral > 100000) ral = ral / 100;
        if (ral > 60000) ral = ral / 10;

        if (ral <= 0) {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('RAL non trovata nel documento. Riprova con una foto piu nitida.'),
              backgroundColor: Color(0xFFF44336),
            ));
          }
          return;
        }

        _ral = ral;
        _anniLavoro = anni > 0 ? anni.toInt().clamp(1, 40) : 5;
        _azienda = parsed['azienda']?.toString() ?? '';
        _dipendente = parsed['dipendente']?.toString() ?? '';
        _ccnl = parsed['ccnl']?.toString() ?? '';

        _calcola();
        setState(() => _isAnalyzingDoc = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Documento analizzato con successo!'),
            backgroundColor: Color(0xFF4CAF50),
          ));
        }
      } else {
        setState(() => _isAnalyzingDoc = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impossibile leggere i dati. Riprova con una foto piu nitida.'),
            backgroundColor: Color(0xFFF44336),
          ));
        }
      }
    } else {
      setState(() => _isAnalyzingDoc = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.errorMessage ?? 'Errore'),
          backgroundColor: const Color(0xFFF44336),
        ));
      }
    }
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return;

    setState(() {
      _isAnalyzingDoc = true;
      _showResult = false;
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Sei un consulente del lavoro italiano. Guarda questa busta paga e leggi i valori ESATTI per calcolare il TFR.

Rispondi SOLO con JSON valido, niente altro testo:
{"ral_annua": 0, "retribuzione_mensile": 0, "anni_lavoro": 0, "azienda": "", "dipendente": "", "ccnl": ""}

COME TROVARE I CAMPI:

RETRIBUZIONE MENSILE:
- Cerca la retribuzione mensile piena nella sezione "elementi retributivi" (MINIMO + EDR + EPA + altri)
- Oppure il "totale" degli elementi retributivi
- È lo stipendio PIENO mensile da contratto (NON l'imponibile lordo che può essere parziale)
- Tipicamente tra 800 e 4000 euro

RAL ANNUA:
- Se trovi "RAL" o "retribuzione annua lorda" usa quel valore
- Se NON trovi la RAL, metti 0 e compila retribuzione_mensile (la calcolo io: mensile × 13)

ANNI LAVORO:
- Calcola dalla data di assunzione ad oggi (aprile 2026)
- Se assunto da pochi mesi, metti 1

FORMATO NUMERI (IMPORTANTISSIMO):
- Usa punto come decimale: 1657.00
- Se nel documento vedi "1.657,00" → scrivi 1657.00
- La retribuzione mensile è tra 800 e 4000, la RAL tra 10000 e 60000''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        double ral = _pAi(parsed['ral_annua']);
        final mensile = _pAi(parsed['retribuzione_mensile']);
        final anni = _pAi(parsed['anni_lavoro']);

        // Se RAL non trovata ma mensile sì, calcola RAL
        if (ral <= 0 && mensile > 0) {
          final m = mensile > 5000 ? mensile / 10 : mensile;
          ral = m * 13;
        }
        // Sanity check RAL
        if (ral > 100000) ral = ral / 100;
        if (ral > 60000) ral = ral / 10;

        if (ral <= 0) {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('RAL non trovata nel documento. Riprova con una foto piu nitida.'),
              backgroundColor: Color(0xFFF44336),
            ));
          }
          return;
        }

        _ral = ral;
        _anniLavoro = anni > 0 ? anni.toInt().clamp(1, 40) : 5;
        _azienda = parsed['azienda']?.toString() ?? '';
        _dipendente = parsed['dipendente']?.toString() ?? '';
        _ccnl = parsed['ccnl']?.toString() ?? '';

        _calcola();
        setState(() => _isAnalyzingDoc = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Documento analizzato con successo!'),
            backgroundColor: Color(0xFF4CAF50),
          ));
        }
      } else {
        setState(() => _isAnalyzingDoc = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impossibile leggere i dati. Riprova con una foto piu nitida.'),
            backgroundColor: Color(0xFFF44336),
          ));
        }
      }
    } else {
      setState(() => _isAnalyzingDoc = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.errorMessage ?? 'Errore'),
          backgroundColor: const Color(0xFFF44336),
        ));
      }
    }
  }

  void _calcola() {
    _tfrAnnuoLordo = _ral / 13.5;
    _contributoInps = _ral * 0.005;
    _tfrAnnuoNetto = _tfrAnnuoLordo - _contributoInps;

    _dettaglioAnnuale = [];
    double tfrAccumulato = 0;
    const rivalutazioneAnnua = 0.03; // 3% media

    for (int anno = 1; anno <= _anniLavoro; anno++) {
      double rivalutazione = 0;
      if (anno > 1 && tfrAccumulato > 0) {
        rivalutazione = tfrAccumulato * rivalutazioneAnnua;
      }
      tfrAccumulato += _tfrAnnuoNetto + rivalutazione;
      _dettaglioAnnuale.add(_TfrAnnuale(anno: anno, tfrAnnuo: _tfrAnnuoNetto, rivalutazione: rivalutazione, tfrCumulato: tfrAccumulato));
    }

    _tfrLordo = tfrAccumulato;

    // Tassazione separata
    final redditoRiferimento = (_tfrLordo / _anniLavoro.toDouble()) * 12.0;
    _aliquotaMedia = _calcolaAliquotaMediaIrpef(redditoRiferimento);
    _tassazioneSeparata = _tfrLordo * _aliquotaMedia;
    _tfrNetto = _tfrLordo - _tassazioneSeparata;

    setState(() => _showResult = true);
    _animController.forward(from: 0);
  }

  double _calcolaAliquotaMediaIrpef(double reddito) {
    if (reddito <= 0) return 0;
    double imposta = 0;
    double residuo = reddito;
    if (residuo > 0) {
      final base1 = residuo.clamp(0.0, 28000.0);
      imposta += base1 * 0.23;
      residuo -= base1;
    }
    if (residuo > 0) {
      final base2 = residuo.clamp(0.0, 22000.0);
      imposta += base2 * 0.35;
      residuo -= base2;
    }
    if (residuo > 0) {
      imposta += residuo * 0.43;
    }
    return imposta / reddito;
  }

  Future<void> _generaPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('CALCOLO TFR', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            if (_dipendente.isNotEmpty) pw.Text('Dipendente: $_dipendente', style: const pw.TextStyle(fontSize: 14)),
            if (_azienda.isNotEmpty) pw.Text('Azienda: $_azienda', style: const pw.TextStyle(fontSize: 14)),
            if (_ccnl.isNotEmpty) pw.Text('CCNL: $_ccnl', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('RAL annua', '\u20AC ${_fmt.format(_ral)}'),
            _pdfRow('Anni di lavoro', '$_anniLavoro'),
            _pdfRow('TFR annuo lordo (RAL/13.5)', '\u20AC ${_fmt.format(_tfrAnnuoLordo)}'),
            _pdfRow('Contributo INPS 0.5%', '- \u20AC ${_fmt.format(_contributoInps)}'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('TFR lordo accumulato', '\u20AC ${_fmt.format(_tfrLordo)}'),
            _pdfRow('Aliquota tassazione', '${(_aliquotaMedia * 100).toStringAsFixed(1)}%'),
            _pdfRow('Tassazione separata', '- \u20AC ${_fmt.format(_tassazioneSeparata)}'),
            _pdfRow('TFR NETTO', '\u20AC ${_fmt.format(_tfrNetto)}'),
            pw.SizedBox(height: 20),
            pw.Text('Generato da Il Mio Patronato', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        );
      },
    ));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'calcolo_tfr.pdf');
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: DocumentUploadWidget(
              label: 'Carica Busta Paga',
              subtitle: 'Scatta una foto della busta paga o contratto di lavoro',
              icon: Icons.receipt_long,
              isLoading: _isAnalyzingDoc,
              onPickCamera: () => _pickAndAnalyze(ImageSource.camera),
              onPickGallery: () => _pickAndAnalyze(ImageSource.gallery),
              onPickPdf: _pickPdf,
            ),
          ),
          if (!_showResult && !_isAnalyzingDoc)
            SliverToBoxAdapter(child: _buildHint()),
          if (_showResult) ...[
            SliverToBoxAdapter(child: _buildResultCard()),
            SliverToBoxAdapter(child: _buildDettaglioCard()),
            SliverToBoxAdapter(child: _buildAnnualeCard()),
            SliverToBoxAdapter(child: _buildActionButtons()),
          ],
          SliverToBoxAdapter(child: CalculatorDisclaimer(specificSource: 'Art. 2120 c.c. (TFR) e tabelle INPS')),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 14),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
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
            child: const Icon(Icons.savings, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CALCOLO TFR', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Carica la busta paga e calcola', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, color: Colors.purple.shade300, size: 40),
          const SizedBox(height: 12),
          const Text('Carica una foto della busta paga', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'L\'AI leggera automaticamente RAL, anzianita lavorativa e dati azienda per calcolare il TFR.',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('TFR NETTO STIMATO', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('\u20AC ${_fmt.format(_tfrNetto)}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('TFR lordo: \u20AC ${_fmt.format(_tfrLordo)}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tassazione (${(_aliquotaMedia * 100).toStringAsFixed(1)}%): \u20AC ${_fmt.format(_tassazioneSeparata)}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDettaglioCard() {
    final tfrMensile = _tfrAnnuoNetto / 12;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_dipendente.isNotEmpty || _azienda.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_dipendente.isNotEmpty ? _dipendente : ""} ${_azienda.isNotEmpty ? "- $_azienda" : ""}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            _row('TFR mensile', '\u20AC ${_fmt.format(tfrMensile)}', bold: true),
            _row('TFR annuo', '\u20AC ${_fmt.format(_tfrAnnuoNetto)}', bold: true),
            if (_anniLavoro > 0)
              _row('TFR totale (${_anniLavoro} anni)', '\u20AC ${_fmt.format(_tfrNetto)}', bold: true, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnualeCard() {
    if (_dettaglioAnnuale.length <= 1) return const SizedBox.shrink();
    // Show first 3 and last 2 if long
    final showAll = _dettaglioAnnuale.length <= 8;
    final displayRows = showAll
        ? _dettaglioAnnuale
        : [..._dettaglioAnnuale.take(3), ..._dettaglioAnnuale.skip(_dettaglioAnnuale.length - 2)];

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dettaglio Annuale', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  SizedBox(width: 40, child: Text('Anno', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  Expanded(child: Text('TFR Annuo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary), textAlign: TextAlign.right)),
                  Expanded(child: Text('Rivalut.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary), textAlign: TextAlign.right)),
                  Expanded(child: Text('Cumulato', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...displayRows.asMap().entries.map((entry) {
              final d = entry.value;
              final showEllipsis = !showAll && entry.key == 3;
              return Column(
                children: [
                  if (showEllipsis)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Center(child: Text('...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textLight))),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(
                      children: [
                        SizedBox(width: 40, child: Text('${d.anno}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark))),
                        Expanded(child: Text('\u20AC ${_fmt.format(d.tfrAnnuo)}', style: const TextStyle(fontSize: 11, color: AppColors.textMedium), textAlign: TextAlign.right)),
                        Expanded(child: Text(d.rivalutazione > 0 ? '\u20AC ${_fmt.format(d.rivalutazione)}' : '-', style: TextStyle(fontSize: 11, color: d.rivalutazione > 0 ? const Color(0xFF4CAF50) : AppColors.textLight), textAlign: TextAlign.right)),
                        Expanded(child: Text('\u20AC ${_fmt.format(d.tfrCumulato)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _generaPdf,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('PDF & Condividi', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _showResult = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.refresh, color: AppColors.primary, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 3))],
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: bold ? AppColors.textDark : AppColors.textMedium, fontWeight: bold ? FontWeight.w600 : FontWeight.w400))),
          const SizedBox(width: 10),
          Flexible(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? (bold ? AppColors.primary : AppColors.textDark)), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _TfrAnnuale {
  final int anno;
  final double tfrAnnuo;
  final double rivalutazione;
  final double tfrCumulato;
  const _TfrAnnuale({required this.anno, required this.tfrAnnuo, required this.rivalutazione, required this.tfrCumulato});
}
