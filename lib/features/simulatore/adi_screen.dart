import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/constants.dart';
import '../../core/widgets/disclaimer_widget.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class AdiScreen extends StatefulWidget {
  const AdiScreen({super.key});

  @override
  State<AdiScreen> createState() => _AdiScreenState();
}

class _AdiScreenState extends State<AdiScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzingDoc = false;
  bool _showResult = false;
  bool _needPermesso = false;

  // Dati estratti dall'AI
  double _isee = 0;
  double _immobiliare = 0;
  double _mobiliare = 0;
  int _componenti = 1;
  int _minori = 0;
  int _disabili = 0;
  int _over60 = 0;
  int _anniResidenza = 0;
  String _tipoPermesso = 'lungo_soggiorno';
  String _intestatario = '';

  // Risultato
  bool _isEligible = false;
  double _importoStimato = 0;
  List<_RequisitoResult> _requisiti = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ADI thresholds
  static const double _iseeMax = 9360.00;
  static const double _immobiliareMax = 30000.00;
  static const double _mobiliareBase = 6000.00;
  static const double _mobiliarePerComponente = 2000.00;
  static const double _mobiliareMax = 10000.00;
  static const double _mobiliarePerMinoreExtra = 1000.00;
  static const int _anniResidenzaMin = 5;
  static const double _importoBase = 500.00;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
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
      _needPermesso = false;
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Analizza questa attestazione ISEE o documento relativo ai requisiti ADI (Assegno di Inclusione) italiano. Estrai TUTTI i dati e restituisci SOLO un JSON valido (senza markdown):
{
  "isee": "valore ISEE numerico",
  "immobiliare": "patrimonio immobiliare numerico",
  "mobiliare": "patrimonio mobiliare numerico",
  "componenti": "numero componenti nucleo familiare",
  "minori": "numero figli minori",
  "disabili": "numero componenti disabili",
  "over60": "numero componenti over 60",
  "anni_residenza": "anni di residenza in Italia",
  "intestatario": "nome e cognome del richiedente"
}
Importi come numeri senza simbolo €. Se un campo non è leggibile, metti null.''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        final isee = _pAi(parsed['isee']);

        if (isee <= 0) {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Valore ISEE non trovato. Riprova con una foto piu nitida.'),
              backgroundColor: Color(0xFFF44336),
            ));
          }
          return;
        }

        _isee = isee;
        _intestatario = parsed['intestatario']?.toString() ?? '';

        final imm = _pAi(parsed['immobiliare']);
        if (imm > 0) _immobiliare = imm;
        final mob = _pAi(parsed['mobiliare']);
        if (mob > 0) _mobiliare = mob;

        final comp = _pAi(parsed['componenti']);
        if (comp > 0) _componenti = comp.toInt().clamp(1, 20);
        final min = _pAi(parsed['minori']);
        if (min > 0) _minori = min.toInt();
        final dis = _pAi(parsed['disabili']);
        if (dis > 0) _disabili = dis.toInt();
        final over = _pAi(parsed['over60']);
        if (over > 0) _over60 = over.toInt();
        final anni = _pAi(parsed['anni_residenza']);
        if (anni > 0) _anniResidenza = anni.toInt();

        setState(() {
          _isAnalyzingDoc = false;
          _needPermesso = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dati ISEE estratti! Seleziona il tipo di permesso per verificare.'),
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
      _needPermesso = false;
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Analizza questa attestazione ISEE o documento relativo ai requisiti ADI (Assegno di Inclusione) italiano. Estrai TUTTI i dati e restituisci SOLO un JSON valido (senza markdown):
{
  "isee": "valore ISEE numerico",
  "immobiliare": "patrimonio immobiliare numerico",
  "mobiliare": "patrimonio mobiliare numerico",
  "componenti": "numero componenti nucleo familiare",
  "minori": "numero figli minori",
  "disabili": "numero componenti disabili",
  "over60": "numero componenti over 60",
  "anni_residenza": "anni di residenza in Italia",
  "intestatario": "nome e cognome del richiedente"
}
Importi come numeri senza simbolo €. Se un campo non è leggibile, metti null.''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        final isee = _pAi(parsed['isee']);

        if (isee <= 0) {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Valore ISEE non trovato. Riprova con una foto piu nitida.'),
              backgroundColor: Color(0xFFF44336),
            ));
          }
          return;
        }

        _isee = isee;
        _intestatario = parsed['intestatario']?.toString() ?? '';

        final imm = _pAi(parsed['immobiliare']);
        if (imm > 0) _immobiliare = imm;
        final mob = _pAi(parsed['mobiliare']);
        if (mob > 0) _mobiliare = mob;

        final comp = _pAi(parsed['componenti']);
        if (comp > 0) _componenti = comp.toInt().clamp(1, 20);
        final min = _pAi(parsed['minori']);
        if (min > 0) _minori = min.toInt();
        final dis = _pAi(parsed['disabili']);
        if (dis > 0) _disabili = dis.toInt();
        final over = _pAi(parsed['over60']);
        if (over > 0) _over60 = over.toInt();
        final anni = _pAi(parsed['anni_residenza']);
        if (anni > 0) _anniResidenza = anni.toInt();

        // tipo_permesso can't be in ISEE, ask user
        setState(() {
          _isAnalyzingDoc = false;
          _needPermesso = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dati ISEE estratti! Seleziona il tipo di permesso per verificare.'),
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

  double _calcolaSogliaMobiliare(int componenti, int minori) {
    double soglia = _mobiliareBase;
    if (componenti > 1) {
      soglia += (componenti - 1) * _mobiliarePerComponente;
    }
    if (soglia > _mobiliareMax) soglia = _mobiliareMax;
    if (minori > 2) {
      soglia += (minori - 2) * _mobiliarePerMinoreExtra;
    }
    return soglia;
  }

  double _calcolaImporto(int minori, int disabili, int over60, int componenti) {
    double scala = 1.0;
    scala += disabili * 0.50;
    scala += over60 * 0.40;
    final altriMaggiorenni = (componenti - 1 - disabili - over60 - minori).clamp(0, componenti);
    if (minori > 0 && altriMaggiorenni > 0) {
      scala += altriMaggiorenni * 0.40;
    }
    scala += minori * 0.15;
    return _importoBase * scala;
  }

  void _verifica() {
    final sogliaMobiliare = _calcolaSogliaMobiliare(_componenti, _minori);

    final reqIsee = _isee <= _iseeMax;
    final reqImmobiliare = _immobiliare <= _immobiliareMax;
    final reqMobiliare = _mobiliare <= sogliaMobiliare;
    final reqNucleo = _minori > 0 || _disabili > 0 || _over60 > 0;
    final reqResidenza = _anniResidenza >= _anniResidenzaMin;
    final reqPermesso = _tipoPermesso == 'lungo_soggiorno' || _tipoPermesso == 'protezione_internazionale';

    final requisiti = <_RequisitoResult>[
      _RequisitoResult(
        label: 'ISEE \u2264 \u20AC${_iseeMax.toStringAsFixed(0)}',
        met: reqIsee,
        detail: reqIsee
            ? 'Il tuo ISEE (\u20AC${_isee.toStringAsFixed(0)}) rientra nel limite'
            : 'Il tuo ISEE (\u20AC${_isee.toStringAsFixed(0)}) supera il limite',
      ),
      _RequisitoResult(
        label: 'Patrimonio immobiliare \u2264 \u20AC${_immobiliareMax.toStringAsFixed(0)}',
        met: reqImmobiliare,
        detail: reqImmobiliare
            ? 'Patrimonio (\u20AC${_immobiliare.toStringAsFixed(0)}) entro il limite'
            : 'Patrimonio (\u20AC${_immobiliare.toStringAsFixed(0)}) supera il limite',
      ),
      _RequisitoResult(
        label: 'Patrimonio mobiliare \u2264 \u20AC${sogliaMobiliare.toStringAsFixed(0)}',
        met: reqMobiliare,
        detail: reqMobiliare
            ? 'Patrimonio (\u20AC${_mobiliare.toStringAsFixed(0)}) entro il limite'
            : 'Patrimonio (\u20AC${_mobiliare.toStringAsFixed(0)}) supera la soglia',
      ),
      _RequisitoResult(
        label: 'Nucleo con minore, disabile o over 60',
        met: reqNucleo,
        detail: reqNucleo
            ? 'Requisito nucleo soddisfatto'
            : 'Nessun minore, disabile o over 60 nel nucleo',
      ),
      _RequisitoResult(
        label: 'Residenza in Italia \u2265 5 anni',
        met: reqResidenza,
        detail: reqResidenza
            ? '$_anniResidenza anni di residenza'
            : 'Solo $_anniResidenza anni di residenza (minimo 5)',
      ),
      _RequisitoResult(
        label: 'Permesso lungo soggiorno o protezione internazionale',
        met: reqPermesso,
        detail: reqPermesso
            ? 'Tipo permesso idoneo'
            : 'Il tipo di permesso non da diritto all\'ADI',
      ),
    ];

    final eligible = requisiti.every((r) => r.met);
    final importo = eligible ? _calcolaImporto(_minori, _disabili, _over60, _componenti) : 0.0;

    setState(() {
      _showResult = true;
      _needPermesso = false;
      _isEligible = eligible;
      _importoStimato = importo;
      _requisiti = requisiti;
    });

    _animController.reset();
    _animController.forward();
  }

  Future<void> _generaPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('VERIFICA ADI - ASSEGNO DI INCLUSIONE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            if (_intestatario.isNotEmpty) pw.Text('Richiedente: $_intestatario', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('ISEE', '\u20AC ${_isee.toStringAsFixed(0)}'),
            _pdfRow('Patrimonio immobiliare', '\u20AC ${_immobiliare.toStringAsFixed(0)}'),
            _pdfRow('Patrimonio mobiliare', '\u20AC ${_mobiliare.toStringAsFixed(0)}'),
            _pdfRow('Componenti nucleo', '$_componenti'),
            _pdfRow('Minori', '$_minori'),
            _pdfRow('Disabili', '$_disabili'),
            _pdfRow('Over 60', '$_over60'),
            _pdfRow('Anni residenza', '$_anniResidenza'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Text(
              _isEligible ? 'ESITO: HAI DIRITTO ALL\'ADI' : 'ESITO: NON HAI I REQUISITI',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (_isEligible)
              _pdfRow('Importo stimato', '\u20AC ${_importoStimato.toStringAsFixed(0)}/mese'),
            pw.SizedBox(height: 12),
            pw.Text('Dettaglio requisiti:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ..._requisiti.map((r) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(r.met ? '\u2713 ' : '\u2717 ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(child: pw.Text('${r.label} - ${r.detail}', style: const pw.TextStyle(fontSize: 11))),
                ],
              ),
            )),
            pw.SizedBox(height: 20),
            pw.Text('Generato da Il Mio Patronato', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        );
      },
    ));

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'verifica_adi.pdf');
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
              label: 'Carica Attestazione ISEE',
              subtitle: 'Scatta una foto e l\'AI legge ISEE, patrimonio e nucleo',
              icon: Icons.account_balance_wallet,
              isLoading: _isAnalyzingDoc,
              onPickCamera: () => _pickAndAnalyze(ImageSource.camera),
              onPickGallery: () => _pickAndAnalyze(ImageSource.gallery),
              onPickPdf: _pickPdf,
            ),
          ),
          if (_needPermesso)
            SliverToBoxAdapter(child: _buildPermessoSelector()),
          if (!_showResult && !_isAnalyzingDoc && !_needPermesso)
            SliverToBoxAdapter(child: _buildHint()),
          if (_showResult) ...[
            SliverToBoxAdapter(child: _buildResultCard()),
            SliverToBoxAdapter(child: _buildRequisitiDetail()),
            SliverToBoxAdapter(child: _buildComeFareDomanda()),
            SliverToBoxAdapter(child: _buildActionButtons()),
          ],
          SliverToBoxAdapter(child: CalculatorDisclaimer(specificSource: 'D.L. 48/2023 (Assegno di Inclusione INPS)')),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
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
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VERIFICA ADI', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Carica ISEE e verifica requisiti', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
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
          const Text(
            'Carica una foto dell\'attestazione ISEE',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'L\'AI leggera automaticamente il valore ISEE, patrimoni e composizione del nucleo familiare per verificare se hai diritto all\'Assegno di Inclusione.',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermessoSelector() {
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
              Icon(Icons.badge, color: Color(0xFFFF9800), size: 22),
              SizedBox(width: 8),
              Text('Tipo Permesso di Soggiorno', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dati estratti: ISEE \u20AC${_isee.toStringAsFixed(0)} \u00B7 Componenti $_componenti'
            '${_intestatario.isNotEmpty ? " \u00B7 $_intestatario" : ""}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3),
          ),
          const SizedBox(height: 12),
          _permessoChip('lungo_soggiorno', 'Lungo Soggiorno', Icons.card_membership),
          const SizedBox(height: 8),
          _permessoChip('protezione_internazionale', 'Protezione Internazionale', Icons.shield),
          const SizedBox(height: 8),
          _permessoChip('altro', 'Altro tipo', Icons.badge_outlined),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _verifica,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('VERIFICA REQUISITI', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permessoChip(String value, String label, IconData icon) {
    final sel = _tipoPermesso == value;
    return GestureDetector(
      onTap: () => setState(() => _tipoPermesso = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? AppColors.primary : Colors.grey.shade200,
            width: sel ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: sel ? AppColors.primary : AppColors.textLight),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? AppColors.primary : AppColors.textMedium)),
            const Spacer(),
            if (sel) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isEligible ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isEligible ? Colors.green.shade200 : Colors.red.shade200),
            boxShadow: [
              BoxShadow(
                color: (_isEligible ? Colors.green : Colors.red).withValues(alpha: 0.12),
                blurRadius: 20, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: _isEligible ? Colors.green.shade100 : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEligible ? Icons.check_circle : Icons.cancel,
                  color: _isEligible ? Colors.green.shade700 : Colors.red.shade700,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEligible ? 'HAI DIRITTO ALL\'ADI!' : 'NON HAI I REQUISITI',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: _isEligible ? Colors.green.shade700 : Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isEligible) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Importo stimato', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: _importoStimato),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Text(
                            '\u20AC${value.toStringAsFixed(0)}/mese',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.green.shade700),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text('Calcolato con scala di equivalenza', style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequisitiDetail() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: _cardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.checklist, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Dettaglio requisiti', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const Spacer(),
                  if (_intestatario.isNotEmpty)
                    Text(_intestatario, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
              const SizedBox(height: 14),
              ..._requisiti.map((r) => _buildRequisitoRow(r)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequisitoRow(_RequisitoResult req) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: req.met ? Colors.green.shade50 : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              req.met ? Icons.check : Icons.close,
              color: req.met ? Colors.green.shade700 : Colors.red.shade700,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.label, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: req.met ? AppColors.textDark : Colors.red.shade700,
                )),
                const SizedBox(height: 2),
                Text(req.detail, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComeFareDomanda() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: _cardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Come fare domanda', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ],
              ),
              const SizedBox(height: 16),
              _buildStep('1', 'Vai su myINPS.it o al CAF', 'Accedi con SPID o CIE al portale INPS'),
              _buildStep('2', 'Presenta domanda con ISEE valido', 'L\'ISEE deve essere in corso di validita'),
              _buildStep('3', 'Sottoscrivi il PAD', 'Patto di Attivazione Digitale su SIISL'),
              _buildStep('4', 'Iscriviti al SIISL', 'Sistema Informativo per l\'Inclusione Sociale e Lavorativa'),
            ],
          ),
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
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
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
              onTap: () => setState(() {
                _showResult = false;
                _isAnalyzingDoc = false;
                _needPermesso = false;
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
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 2))],
    );
  }
}

class _RequisitoResult {
  final String label;
  final bool met;
  final String detail;
  const _RequisitoResult({required this.label, required this.met, required this.detail});
}
