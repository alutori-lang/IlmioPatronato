import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class NaspiScreen extends StatefulWidget {
  const NaspiScreen({super.key});

  @override
  State<NaspiScreen> createState() => _NaspiScreenState();
}

class _NaspiScreenState extends State<NaspiScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzingDoc = false;
  bool _showResult = false;

  // Dati estratti dall'AI
  double _retribuzioneLorda = 0;
  int _settimaneContributi = 0;
  String _azienda = '';
  String _dipendente = '';
  String _tipoContratto = '';

  // Risultati calcolo
  double _importoMensile = 0;
  int _durataMesi = 0;
  double _totaleStimato = 0;
  List<_MeseNaspi> _tabellaMesi = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const double _sogliaRetribuzione = 1425.21;
  static const double _importoMassimo = 1550.42;
  static const double _percentualeSotto = 0.75;
  static const double _percentualeSopra = 0.25;
  static const double _percentualeDecalage = 0.03;

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
      prompt: '''Sei un consulente del lavoro italiano. Guarda questa busta paga e leggi i valori ESATTI per calcolare la NASpI.

Rispondi SOLO con JSON valido, niente altro testo:
{
  "retribuzione_media": 0,
  "settimane_contributi": 0,
  "azienda": "nome azienda",
  "dipendente": "nome dipendente",
  "tipo_contratto": "tipo contratto"
}

COME TROVARE I CAMPI:

RETRIBUZIONE MEDIA MENSILE LORDA:
- Cerca la RETRIBUZIONE MENSILE piena (es. "MINIMO" + "EDR" + "EPA" oppure il totale degli "elementi retributivi")
- Oppure cerca "totale" nella sezione elementi retributivi
- NON usare "imponibile lordo" perché quello è il lordo del mese parziale se il dipendente non ha lavorato tutto il mese
- La retribuzione media è lo stipendio PIENO mensile come da contratto

SETTIMANE CONTRIBUTI:
- Cerca la data di assunzione e calcola le settimane fino ad oggi (aprile 2026)
- Se ci sono contributi precedenti da altri lavori, sommali
- Se non trovi info, metti null

FORMATO NUMERI (IMPORTANTISSIMO):
- Usa punto come decimale: 1657.00 (NON 16570, NON 1.657,00)
- La retribuzione mensile in Italia è tipicamente tra 800 e 4000 euro
- Se leggi "1.657,00" nel documento, il punto è separatore migliaia e la virgola è decimale → scrivi 1657.00 nel JSON
- La retribuzione media per NASpI è quella CONTRATTUALE piena, non quella di un mese parziale''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        final retrib = _pAi(parsed['retribuzione_media']);

        if (retrib <= 0) {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Retribuzione non trovata. Riprova con una foto piu nitida.'),
              backgroundColor: Color(0xFFF44336),
            ));
          }
          return;
        }

        // Sanity check: stipendio mensile italiano tra 400 e 5000
        _retribuzioneLorda = retrib > 5000 ? retrib / 10 : retrib;
        final sett = _pAi(parsed['settimane_contributi']);
        _settimaneContributi = sett > 0 ? sett.toInt().clamp(13, 208) : 52;
        _azienda = parsed['azienda']?.toString() ?? '';
        _dipendente = parsed['dipendente']?.toString() ?? '';
        _tipoContratto = parsed['tipo_contratto']?.toString() ?? '';

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
      prompt: '''Sei un consulente del lavoro italiano. Guarda questa busta paga e leggi i valori ESATTI per calcolare la NASpI.

Rispondi SOLO con JSON valido, niente altro testo:
{
  "retribuzione_media": 0,
  "settimane_contributi": 0,
  "azienda": "nome azienda",
  "dipendente": "nome dipendente",
  "tipo_contratto": "tipo contratto"
}

COME TROVARE I CAMPI:

RETRIBUZIONE MEDIA MENSILE LORDA:
- Cerca la RETRIBUZIONE MENSILE piena (es. "MINIMO" + "EDR" + "EPA" oppure il totale degli "elementi retributivi")
- Oppure cerca "totale" nella sezione elementi retributivi
- NON usare "imponibile lordo" perché quello è il lordo del mese parziale se il dipendente non ha lavorato tutto il mese
- La retribuzione media è lo stipendio PIENO mensile come da contratto

SETTIMANE CONTRIBUTI:
- Cerca la data di assunzione e calcola le settimane fino ad oggi (aprile 2026)
- Se ci sono contributi precedenti da altri lavori, sommali
- Se non trovi info, metti null

FORMATO NUMERI (IMPORTANTISSIMO):
- Usa punto come decimale: 1657.00 (NON 16570, NON 1.657,00)
- La retribuzione mensile in Italia è tipicamente tra 800 e 4000 euro
- Se leggi "1.657,00" nel documento, il punto è separatore migliaia e la virgola è decimale → scrivi 1657.00 nel JSON
- La retribuzione media per NASpI è quella CONTRATTUALE piena, non quella di un mese parziale''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        final retrib = _pAi(parsed['retribuzione_media']);

        if (retrib <= 0) {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Retribuzione non trovata. Riprova con una foto piu nitida.'),
              backgroundColor: Color(0xFFF44336),
            ));
          }
          return;
        }

        // Sanity check: stipendio mensile italiano tra 400 e 5000
        _retribuzioneLorda = retrib > 5000 ? retrib / 10 : retrib;
        final sett = _pAi(parsed['settimane_contributi']);
        _settimaneContributi = sett > 0 ? sett.toInt().clamp(13, 208) : 52;
        _azienda = parsed['azienda']?.toString() ?? '';
        _dipendente = parsed['dipendente']?.toString() ?? '';
        _tipoContratto = parsed['tipo_contratto']?.toString() ?? '';

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
    double importo;
    if (_retribuzioneLorda <= _sogliaRetribuzione) {
      importo = _retribuzioneLorda * _percentualeSotto;
    } else {
      importo = _sogliaRetribuzione * _percentualeSotto +
          (_retribuzioneLorda - _sogliaRetribuzione) * _percentualeSopra;
    }
    if (importo > _importoMassimo) importo = _importoMassimo;

    final durataMesi = (_settimaneContributi / 2).floor().clamp(1, 24);

    final tabella = <_MeseNaspi>[];
    double totale = 0;

    for (int mese = 1; mese <= durataMesi; mese++) {
      double importoCorrente;
      if (mese >= 6) {
        final riduzione = 1.0 - (_percentualeDecalage * (mese - 5).toDouble());
        importoCorrente = importo * (riduzione > 0 ? riduzione : 0);
      } else {
        importoCorrente = importo;
      }
      tabella.add(_MeseNaspi(
        mese: mese,
        importo: importoCorrente,
        riduzione: mese >= 6 ? _percentualeDecalage * (mese - 5).toDouble() * 100 : 0,
      ));
      totale += importoCorrente;
    }

    setState(() {
      _showResult = true;
      _importoMensile = importo;
      _durataMesi = durataMesi;
      _totaleStimato = totale;
      _tabellaMesi = tabella;
    });
    _animController.forward(from: 0);
  }

  Future<void> _generaPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('CALCOLO NASpI', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            if (_dipendente.isNotEmpty) pw.Text('Dipendente: $_dipendente', style: const pw.TextStyle(fontSize: 14)),
            if (_azienda.isNotEmpty) pw.Text('Azienda: $_azienda', style: const pw.TextStyle(fontSize: 14)),
            if (_tipoContratto.isNotEmpty) pw.Text('Contratto: $_tipoContratto', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('Retribuzione lorda mensile', '\u20AC ${_retribuzioneLorda.toStringAsFixed(2)}'),
            _pdfRow('Settimane contributi', '$_settimaneContributi'),
            _pdfRow('Durata NASpI', '$_durataMesi mesi'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('Importo mensile iniziale', '\u20AC ${_importoMensile.toStringAsFixed(2)}'),
            _pdfRow('Decalage', 'Dal 6 mese: -3% al mese'),
            _pdfRow('TOTALE STIMATO', '\u20AC ${_totaleStimato.toStringAsFixed(2)}'),
            pw.SizedBox(height: 20),
            pw.Text('Generato da Il Mio Patronato', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        );
      },
    ));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'calcolo_naspi.pdf');
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
              label: 'Carica Busta Paga / Contratto',
              subtitle: 'Scatta una foto della busta paga o contratto di lavoro',
              icon: Icons.work_history,
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
            SliverToBoxAdapter(child: _buildDecalageCard()),
            SliverToBoxAdapter(child: _buildInfoCard()),
            SliverToBoxAdapter(child: _buildActionButtons()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 6, right: 20, bottom: 14),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
          const Icon(Icons.work_off, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calcolo NASpI', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                SizedBox(height: 1),
                Text('Carica documenti e calcola', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
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
          const Text('Carica busta paga o contratto di lavoro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'L\'AI leggera automaticamente retribuzione e contributi per calcolare l\'indennita NASpI spettante.',
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
          gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1E88E5)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            const Text('NASpI STIMATA', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 12),
            Text('\u20AC${_importoMensile.toStringAsFixed(2)}/mese', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _resultPill(Icons.timer, '$_durataMesi mesi'),
                const SizedBox(width: 12),
                _resultPill(Icons.savings, 'Tot. \u20AC${_totaleStimato.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDettaglioCard() {
    final sottoSoglia = _retribuzioneLorda <= _sogliaRetribuzione;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dati Estratti e Calcolo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            if (_dipendente.isNotEmpty) _detailRow('Dipendente', _dipendente),
            if (_azienda.isNotEmpty) _detailRow('Azienda', _azienda),
            if (_tipoContratto.isNotEmpty) _detailRow('Contratto', _tipoContratto),
            _detailRow('Retribuzione lorda', '\u20AC${_retribuzioneLorda.toStringAsFixed(2)}'),
            _detailRow('Settimane contributi', '$_settimaneContributi'),
            _detailRow('Soglia 2025', '\u20AC${_sogliaRetribuzione.toStringAsFixed(2)}'),
            if (sottoSoglia)
              _detailRow('Calcolo', '75% di \u20AC${_retribuzioneLorda.toStringAsFixed(2)}')
            else ...[
              _detailRow('75% di \u20AC${_sogliaRetribuzione.toStringAsFixed(2)}', '\u20AC${(_sogliaRetribuzione * _percentualeSotto).toStringAsFixed(2)}'),
              _detailRow('25% di \u20AC${(_retribuzioneLorda - _sogliaRetribuzione).toStringAsFixed(2)}', '\u20AC${((_retribuzioneLorda - _sogliaRetribuzione) * _percentualeSopra).toStringAsFixed(2)}'),
            ],
            if (_importoMensile >= _importoMassimo)
              _detailRow('Tetto massimo applicato', '\u20AC${_importoMassimo.toStringAsFixed(2)}', bold: true),
            const Divider(height: 20),
            _detailRow('Importo mensile iniziale', '\u20AC${_importoMensile.toStringAsFixed(2)}', bold: true),
            _detailRow('Durata', '$_durataMesi mesi', bold: true),
            _detailRow('Totale stimato', '\u20AC${_totaleStimato.toStringAsFixed(2)}', bold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDecalageCard() {
    // Show first 4 and last 2
    final total = _tabellaMesi.length;
    final showAll = total <= 8;
    List<_MeseNaspi> display;
    if (showAll) {
      display = _tabellaMesi;
    } else {
      display = [..._tabellaMesi.take(4), ..._tabellaMesi.skip(total - 2)];
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_down, color: Color(0xFFFF9800), size: 20),
                SizedBox(width: 8),
                Text('Tabella importi mensili', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Dal 6\u00B0 mese: -3% ogni mese', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  SizedBox(width: 50, child: Text('Mese', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                  Expanded(child: Text('Importo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                  SizedBox(width: 70, child: Text('Riduzione', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...display.asMap().entries.map((entry) {
              final m = entry.value;
              final hasRiduzione = m.riduzione > 0;
              final showEllipsis = !showAll && entry.key == 4;
              return Column(
                children: [
                  if (showEllipsis)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Center(child: Text('...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textLight)))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(
                      children: [
                        SizedBox(width: 50, child: Text('${m.mese}\u00B0', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
                        Expanded(child: Text('\u20AC${m.importo.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hasRiduzione ? const Color(0xFFFF9800) : AppColors.textDark))),
                        SizedBox(width: 70, child: Text(hasRiduzione ? '-${m.riduzione.toStringAsFixed(0)}%' : '-', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hasRiduzione ? Colors.red.shade400 : AppColors.textLight))),
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

  Widget _buildInfoCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Come fare domanda NASpI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 16),
            _buildStep('1', 'Entro 68 giorni dalla cessazione', 'Presenta domanda entro 68 giorni'),
            _buildStep('2', 'Accedi a myINPS con SPID/CIE', 'Sezione "Prestazioni e servizi" > "NASpI"'),
            _buildStep('3', 'Compila la domanda online', 'Oppure rivolgiti a un Patronato/CAF'),
            _buildStep('4', 'Dichiarazione di disponibilita (DID)', 'Renditi disponibile al Centro per l\'Impiego'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.3)),
              ],
            ),
          ),
        ],
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

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: bold ? AppColors.textDark : AppColors.textMedium, fontWeight: bold ? FontWeight.w600 : FontWeight.w400))),
          const SizedBox(width: 10),
          Flexible(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? AppColors.primary : AppColors.textDark), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, maxLines: 2)),
        ],
      ),
    );
  }
}

class _MeseNaspi {
  final int mese;
  final double importo;
  final double riduzione;
  const _MeseNaspi({required this.mese, required this.importo, required this.riduzione});
}
