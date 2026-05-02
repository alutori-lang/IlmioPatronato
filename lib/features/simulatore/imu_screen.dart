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

class ImuScreen extends StatefulWidget {
  const ImuScreen({super.key});

  @override
  State<ImuScreen> createState() => _ImuScreenState();
}

class _ImuScreenState extends State<ImuScreen> with SingleTickerProviderStateMixin {
  bool _isAnalyzingDoc = false;
  bool _showResult = false;
  bool _needAliquota = false;

  // Dati estratti dall'AI
  double _rendita = 0;
  String _categoriaSelected = 'A/2';
  double _quotaPossesso = 100;
  final int _mesiPossesso = 12;
  double _aliquotaPermille = 10.6;
  String _indirizzo = '';
  String _proprietario = '';
  String _comune = '';

  // Risultati calcolo
  double _baseImponibile = 0;
  double _imuAnnuale = 0;
  double _imuDovuta = 0;
  double _acconto = 0;
  double _saldo = 0;
  double _coefficiente = 0;
  double _rivalutazione = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');
  final _aliquotaCtrl = TextEditingController(text: '10.6');

  static const _categorie = {
    'A/1': 'Abitazione signorile',
    'A/2': 'Abitazione civile',
    'A/3': 'Abitazione economica',
    'A/4': 'Abitazione popolare',
    'A/5': 'Abitazione ultrapopolare',
    'A/6': 'Abitazione rurale',
    'A/7': 'Abitazione villini',
    'A/8': 'Abitazione in ville',
    'A/9': 'Castelli/palazzi',
    'A/10': 'Uffici/studi privati',
    'C/1': 'Negozio/bottega',
    'C/2': 'Magazzino/deposito',
    'C/3': 'Laboratorio',
    'C/6': 'Box/garage',
    'C/7': 'Tettoie chiuse',
    'D/1': 'Opificio',
    'D/2': 'Albergo/pensione',
    'D/5': 'Istituto di credito',
    'D/7': 'Fabbricato industriale',
    'D/8': 'Fabbricato commerciale',
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _aliquotaCtrl.dispose();
    _animCtrl.dispose();
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
      _needAliquota = false;
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Analizza questa visura catastale o documento immobiliare italiano. Estrai TUTTI i dati e restituisci SOLO un JSON valido (senza markdown):
{
  "rendita_catastale": "rendita catastale numerico",
  "categoria": "categoria catastale es. A/2, C/6, D/1 ecc.",
  "quota_possesso": "percentuale di possesso numerico (es. 100, 50)",
  "indirizzo": "indirizzo dell'immobile",
  "proprietario": "nome del proprietario",
  "comune": "nome del comune"
}
Importi come numeri senza simbolo €. Se un campo non è leggibile, metti null.''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        final rendita = _pAi(parsed['rendita_catastale']);

        if (rendita <= 0) {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Rendita catastale non trovata. Riprova con una foto piu nitida.'),
              backgroundColor: Color(0xFFF44336),
            ));
          }
          return;
        }

        _rendita = rendita;
        _indirizzo = parsed['indirizzo']?.toString() ?? '';
        _proprietario = parsed['proprietario']?.toString() ?? '';
        _comune = parsed['comune']?.toString() ?? '';

        final cat = parsed['categoria']?.toString() ?? '';
        if (cat.isNotEmpty && _categorie.containsKey(cat)) _categoriaSelected = cat;

        final quota = _pAi(parsed['quota_possesso']);
        if (quota > 0) _quotaPossesso = quota.clamp(10, 100);

        setState(() {
          _isAnalyzingDoc = false;
          _needAliquota = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dati catastali estratti! Conferma l\'aliquota per calcolare.'),
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
      _needAliquota = false;
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Analizza questa visura catastale o documento immobiliare italiano. Estrai TUTTI i dati e restituisci SOLO un JSON valido (senza markdown):
{
  "rendita_catastale": "rendita catastale numerico",
  "categoria": "categoria catastale es. A/2, C/6, D/1 ecc.",
  "quota_possesso": "percentuale di possesso numerico (es. 100, 50)",
  "indirizzo": "indirizzo dell'immobile",
  "proprietario": "nome del proprietario",
  "comune": "nome del comune"
}
Importi come numeri senza simbolo €. Se un campo non è leggibile, metti null.''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        final rendita = _pAi(parsed['rendita_catastale']);

        if (rendita <= 0) {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Rendita catastale non trovata. Riprova con una foto piu nitida.'),
              backgroundColor: Color(0xFFF44336),
            ));
          }
          return;
        }

        _rendita = rendita;
        _indirizzo = parsed['indirizzo']?.toString() ?? '';
        _proprietario = parsed['proprietario']?.toString() ?? '';
        _comune = parsed['comune']?.toString() ?? '';

        final cat = parsed['categoria']?.toString() ?? '';
        if (cat.isNotEmpty && _categorie.containsKey(cat)) _categoriaSelected = cat;

        final quota = _pAi(parsed['quota_possesso']);
        if (quota > 0) _quotaPossesso = quota.clamp(10, 100);

        // Ask for aliquota since it's municipality-specific
        setState(() {
          _isAnalyzingDoc = false;
          _needAliquota = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dati catastali estratti! Conferma l\'aliquota per calcolare.'),
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

  double _p(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  void _calcola() {
    if (_rendita <= 0) return;
    _aliquotaPermille = _p(_aliquotaCtrl.text);

    _coefficiente = _getCoefficient();
    _rivalutazione = _rendita * 1.05;
    _baseImponibile = _rivalutazione * _coefficiente;

    _imuAnnuale = _baseImponibile * _aliquotaPermille / 1000;
    _imuDovuta = _imuAnnuale * (_quotaPossesso / 100) * (_mesiPossesso / 12);

    _acconto = _imuDovuta / 2;
    _saldo = _imuDovuta - _acconto;

    setState(() {
      _showResult = true;
      _needAliquota = false;
    });
    _animCtrl.forward(from: 0);
  }

  double _getCoefficient() {
    if (_categoriaSelected.startsWith('A/') && _categoriaSelected != 'A/10') {
      return 160;
    } else if (_categoriaSelected == 'A/10') {
      return 80;
    } else if (_categoriaSelected == 'C/1') {
      return 55;
    } else if (_categoriaSelected == 'C/2' || _categoriaSelected == 'C/6' || _categoriaSelected == 'C/7') {
      return 160;
    } else if (_categoriaSelected == 'C/3') {
      return 140;
    } else if (_categoriaSelected.startsWith('D/')) {
      return 65;
    }
    return 160;
  }

  Future<void> _generaPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('CALCOLO IMU', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            if (_proprietario.isNotEmpty) pw.Text('Proprietario: $_proprietario', style: const pw.TextStyle(fontSize: 14)),
            if (_indirizzo.isNotEmpty) pw.Text('Indirizzo: $_indirizzo', style: const pw.TextStyle(fontSize: 14)),
            if (_comune.isNotEmpty) pw.Text('Comune: $_comune', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('Rendita catastale', '\u20AC ${_fmt.format(_rendita)}'),
            _pdfRow('Categoria', '$_categoriaSelected - ${_categorie[_categoriaSelected] ?? ""}'),
            _pdfRow('Rivalutazione (+5%)', '\u20AC ${_fmt.format(_rivalutazione)}'),
            _pdfRow('Coefficiente', '${_coefficiente.toInt()}'),
            _pdfRow('Base imponibile', '\u20AC ${_fmt.format(_baseImponibile)}'),
            _pdfRow('Aliquota', '${_aliquotaPermille.toStringAsFixed(1)}\u2030'),
            _pdfRow('Quota possesso', '${_quotaPossesso.toInt()}%'),
            _pdfRow('Mesi possesso', '$_mesiPossesso / 12'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _pdfRow('IMU DOVUTA', '\u20AC ${_fmt.format(_imuDovuta)}'),
            _pdfRow('Acconto (16 giugno)', '\u20AC ${_fmt.format(_acconto)}'),
            _pdfRow('Saldo (16 dicembre)', '\u20AC ${_fmt.format(_saldo)}'),
            pw.SizedBox(height: 20),
            pw.Text('Generato da Il Mio Patronato', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        );
      },
    ));

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'calcolo_imu.pdf');
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
          SliverToBoxAdapter(child: _buildInfoBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: DocumentUploadWidget(
              label: 'Carica Visura Catastale',
              subtitle: 'Scatta una foto e l\'AI legge rendita, categoria e quota',
              icon: Icons.home_work,
              isLoading: _isAnalyzingDoc,
              onPickCamera: () => _pickAndAnalyze(ImageSource.camera),
              onPickGallery: () => _pickAndAnalyze(ImageSource.gallery),
              onPickPdf: _pickPdf,
            ),
          ),
          if (_needAliquota)
            SliverToBoxAdapter(child: _buildAliquotaSelector()),
          if (!_showResult && !_isAnalyzingDoc && !_needAliquota)
            SliverToBoxAdapter(child: _buildHint()),
          if (_showResult) ...[
            SliverToBoxAdapter(child: _buildResultCard()),
            SliverToBoxAdapter(child: _buildDettaglioCard()),
            SliverToBoxAdapter(child: _buildScadenzeCard()),
            SliverToBoxAdapter(child: _buildActionButtons()),
          ],
          SliverToBoxAdapter(child: CalculatorDisclaimer(specificSource: 'D.Lgs. 504/1992 e Legge 160/2019')),
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
            child: const Icon(Icons.home_work, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CALCOLATORE IMU', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Carica visura e calcola', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF388E3C), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'L\'abitazione principale (prima casa) con categorie A/2-A/7 e\' ESENTE da IMU. '
              'L\'IMU si paga su seconde case, negozi, uffici, terreni, etc.',
              style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.4),
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
          const Text(
            'Carica una foto della visura catastale',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'L\'AI leggera automaticamente la rendita catastale, la categoria e la quota di possesso per calcolare l\'IMU dovuta.',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAliquotaSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Color(0xFFFF9800), size: 22),
              SizedBox(width: 8),
              Text('Conferma Aliquota Comunale', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dati estratti: Rendita \u20AC${_fmt.format(_rendita)} · Cat. $_categoriaSelected · Quota ${_quotaPossesso.toInt()}%'
            '${_comune.isNotEmpty ? " · Comune: $_comune" : ""}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3),
          ),
          const SizedBox(height: 12),
          const Text('L\'aliquota varia per Comune. Base 8.6\u2030, massima 10.6\u2030.',
              style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 10),
          TextField(
            controller: _aliquotaCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
            decoration: InputDecoration(
              labelText: 'Aliquota (\u2030)',
              labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMedium),
              suffixText: '\u2030',
              suffixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMedium),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _calcola,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('CALCOLA IMU', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
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
            const Text('IMU DOVUTA', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('\u20AC ${_fmt.format(_imuDovuta)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(
                'Categoria $_categoriaSelected \u00B7 Coefficiente ${_coefficiente.toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDettaglioCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dati Estratti & Formula', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            if (_proprietario.isNotEmpty) _row('Proprietario', _proprietario),
            if (_indirizzo.isNotEmpty) _row('Indirizzo', _indirizzo),
            if (_comune.isNotEmpty) _row('Comune', _comune),
            const Divider(height: 16),
            _row('Rendita catastale', '\u20AC ${_fmt.format(_rendita)}'),
            _row('Rivalutazione (+5%)', '\u20AC ${_fmt.format(_rivalutazione)}'),
            _row('\u00D7 Coefficiente', '${_coefficiente.toInt()}'),
            const Divider(height: 16),
            _row('= Base imponibile', '\u20AC ${_fmt.format(_baseImponibile)}', bold: true),
            _row('\u00D7 Aliquota', '${_aliquotaPermille.toStringAsFixed(1)}\u2030'),
            _row('= IMU annuale', '\u20AC ${_fmt.format(_imuAnnuale)}'),
            const Divider(height: 16),
            _row('Quota possesso', '${_quotaPossesso.toInt()}%'),
            _row('Mesi possesso', '$_mesiPossesso / 12'),
            const Divider(height: 16),
            _row('IMU DOVUTA', '\u20AC ${_fmt.format(_imuDovuta)}', bold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildScadenzeCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFFFF9800).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event, color: Color(0xFFFF9800), size: 22),
                SizedBox(width: 10),
                Text('Scadenze Pagamento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 16),
            _scadenzaRow('ACCONTO', '16 Giugno 2026', _acconto, const Color(0xFFFF9800)),
            const SizedBox(height: 12),
            _scadenzaRow('SALDO', '16 Dicembre 2026', _saldo, const Color(0xFFF44336)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Pagamento tramite modello F24 con codice tributo 3918 (seconde case). '
                'Codice catastale del Comune reperibile sul sito dell\'Agenzia delle Entrate.',
                style: TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scadenzaRow(String tipo, String data, double importo, Color color) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.calendar_today, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tipo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
              Text(data, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
            ],
          ),
        ),
        Text('\u20AC ${_fmt.format(importo)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ],
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
              onTap: () => setState(() {
                _showResult = false;
                _isAnalyzingDoc = false;
                _needAliquota = false;
              }),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 3))],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
