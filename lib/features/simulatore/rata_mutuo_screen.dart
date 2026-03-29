import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class RataMutuoScreen extends StatefulWidget {
  const RataMutuoScreen({super.key});

  @override
  State<RataMutuoScreen> createState() => _RataMutuoScreenState();
}

class _RataMutuoScreenState extends State<RataMutuoScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzingDoc = false;
  bool _showResult = false;

  // Dati estratti dall'AI
  double _importo = 0;
  double _tassoAnnuo = 0;
  int _durataAnni = 0;
  String _tipoTasso = '';
  String _banca = '';
  String _intestatario = '';

  // Risultati calcolo
  double _rataMensile = 0;
  double _totaleInteressi = 0;
  double _totaleRestituito = 0;
  int _totaleMesi = 0;
  List<_RataDetail> _pianoFirst6 = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');

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
    _animController.dispose();
    super.dispose();
  }

  double _pAi(dynamic v) {
    if (v == null) return 0;
    final s = v.toString().replaceAll('€', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
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
      prompt: '''Analizza questo contratto di mutuo o contratto casa. Estrai TUTTI i dati possibili e restituisci SOLO un JSON valido (senza markdown):
{
  "importo": "importo del mutuo numerico",
  "tasso": "tasso di interesse annuo numerico (es. 3.5)",
  "durata_anni": "durata in anni numerico",
  "tipo_tasso": "Fisso o Variabile",
  "banca": "nome banca o istituto",
  "intestatario": "nome intestatario"
}
Importi come numeri senza simbolo €. Se un campo non è leggibile, metti null.''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        final importo = _pAi(parsed['importo']);
        final tasso = _pAi(parsed['tasso']);
        final durata = _pAi(parsed['durata_anni']);

        if (importo <= 0 || tasso <= 0 || durata <= 0) {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Dati insufficienti nel documento. Riprova con una foto piu nitida.'),
              backgroundColor: Color(0xFFF44336),
            ));
          }
          return;
        }

        _importo = importo;
        _tassoAnnuo = tasso;
        _durataAnni = durata.toInt().clamp(1, 40);
        _tipoTasso = (parsed['tipo_tasso']?.toString() ?? '').contains('ariabil') ? 'Variabile' : 'Fisso';
        _banca = parsed['banca']?.toString() ?? '';
        _intestatario = parsed['intestatario']?.toString() ?? '';

        _calcola();
        setState(() => _isAnalyzingDoc = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Contratto analizzato con successo!'),
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
    _totaleMesi = _durataAnni * 12;
    final double r = _tassoAnnuo / 100.0 / 12.0;
    final int n = _totaleMesi;

    _rataMensile = _importo * r / (1.0 - pow(1.0 + r, -n).toDouble());
    _totaleRestituito = _rataMensile * n.toDouble();
    _totaleInteressi = _totaleRestituito - _importo;

    final List<_RataDetail> piano = [];
    double debitoResiduo = _importo;
    for (int mese = 1; mese <= n && mese <= 6; mese++) {
      final quotaInteressi = debitoResiduo * r;
      final quotaCapitale = _rataMensile - quotaInteressi;
      debitoResiduo -= quotaCapitale;
      if (debitoResiduo < 0) debitoResiduo = 0;
      piano.add(_RataDetail(mese: mese, rata: _rataMensile, quotaCapitale: quotaCapitale, quotaInteressi: quotaInteressi, debitoResiduo: debitoResiduo));
    }
    _pianoFirst6 = piano;

    setState(() => _showResult = true);
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
            pw.Text('CALCOLO RATA MUTUO', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            if (_banca.isNotEmpty) pw.Text('Banca: $_banca', style: const pw.TextStyle(fontSize: 14)),
            if (_intestatario.isNotEmpty) pw.Text('Intestatario: $_intestatario', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('Importo mutuo', '\u20AC ${_fmt.format(_importo)}'),
            _pdfRow('Tasso annuo (TAN)', '${_tassoAnnuo.toStringAsFixed(2)}%'),
            _pdfRow('Tipo tasso', _tipoTasso),
            _pdfRow('Durata', '$_durataAnni anni ($_totaleMesi rate)'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('RATA MENSILE', '\u20AC ${_fmt.format(_rataMensile)}'),
            _pdfRow('Totale interessi', '\u20AC ${_fmt.format(_totaleInteressi)}'),
            _pdfRow('Totale restituito', '\u20AC ${_fmt.format(_totaleRestituito)}'),
            _pdfRow('Incidenza interessi', '${(_totaleInteressi / _totaleRestituito * 100).toStringAsFixed(1)}%'),
            pw.SizedBox(height: 20),
            pw.Text('Generato da Il Mio Patronato', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        );
      },
    ));

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'rata_mutuo.pdf');
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
              label: 'Carica Contratto Mutuo',
              subtitle: 'Scatta una foto del contratto di mutuo o contratto casa',
              icon: Icons.description_rounded,
              isLoading: _isAnalyzingDoc,
              onPickCamera: () => _pickAndAnalyze(ImageSource.camera),
              onPickGallery: () => _pickAndAnalyze(ImageSource.gallery),
            ),
          ),
          if (!_showResult && !_isAnalyzingDoc)
            SliverToBoxAdapter(child: _buildHint()),
          if (_showResult) ...[
            SliverToBoxAdapter(child: _buildResultCard()),
            SliverToBoxAdapter(child: _buildDettaglioCard()),
            SliverToBoxAdapter(child: _buildProgressCard()),
            if (_pianoFirst6.isNotEmpty)
              SliverToBoxAdapter(child: _buildPianoCard()),
            SliverToBoxAdapter(child: _buildActionButtons()),
          ],
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
            child: const Icon(Icons.home, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RATA MUTUO', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Carica il contratto e calcola', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
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
            'Carica una foto del contratto di mutuo',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'L\'AI leggera automaticamente importo, tasso, durata e tipo di tasso dal contratto e calcolera la rata mensile.',
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
            const Text('RATA MENSILE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('\u20AC ${_fmt.format(_rataMensile)}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Tasso $_tipoTasso ${_tassoAnnuo.toStringAsFixed(2)}% - $_durataAnni anni', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _resultMini('Totale Interessi', '\u20AC ${_fmt.format(_totaleInteressi)}'),
                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3)),
                _resultMini('Totale Restituito', '\u20AC ${_fmt.format(_totaleRestituito)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultMini(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
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
            const Text('Dati Estratti dal Contratto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            if (_banca.isNotEmpty) _row('Banca / Istituto', _banca),
            if (_intestatario.isNotEmpty) _row('Intestatario', _intestatario),
            _row('Importo mutuo', '\u20AC ${_fmt.format(_importo)}'),
            _row('Tasso annuo (TAN)', '${_tassoAnnuo.toStringAsFixed(2)}%'),
            _row('Tipo tasso', _tipoTasso),
            _row('Durata', '$_durataAnni anni ($_totaleMesi rate)'),
            const Divider(height: 16),
            _row('Rata mensile', '\u20AC ${_fmt.format(_rataMensile)}', bold: true),
            _row('Totale interessi', '\u20AC ${_fmt.format(_totaleInteressi)}', color: const Color(0xFFFF9800)),
            _row('Totale restituito', '\u20AC ${_fmt.format(_totaleRestituito)}', bold: true),
            _row('Incidenza interessi', '${(_totaleInteressi / _totaleRestituito * 100).toStringAsFixed(1)}% del totale'),
            if (_tipoTasso == 'Variabile') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Con tasso variabile la rata puo\' cambiare nel tempo in base all\'andamento dell\'Euribor.',
                        style: TextStyle(fontSize: 11, color: Colors.brown.shade700, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    if (_totaleRestituito <= 0) return const SizedBox.shrink();
    final percCapitale = _importo / _totaleRestituito;
    final percInteressi = _totaleInteressi / _totaleRestituito;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Capitale vs Interessi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Expanded(
                      flex: (percCapitale * 1000).round().clamp(1, 999),
                      child: Container(
                        color: const Color(0xFF4CAF50),
                        alignment: Alignment.center,
                        child: Text('${(percCapitale * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Expanded(
                      flex: (percInteressi * 1000).round().clamp(1, 999),
                      child: Container(
                        color: const Color(0xFFFF9800),
                        alignment: Alignment.center,
                        child: Text('${(percInteressi * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _legendRow(const Color(0xFF4CAF50), 'Capitale', '\u20AC ${_fmt.format(_importo)}'),
            const SizedBox(height: 6),
            _legendRow(const Color(0xFFFF9800), 'Interessi', '\u20AC ${_fmt.format(_totaleInteressi)}'),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text('$label: $value', style: const TextStyle(fontSize: 13, color: AppColors.textMedium))),
      ],
    );
  }

  Widget _buildPianoCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prime 6 Rate', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  SizedBox(width: 34, child: Text('N.', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  Expanded(child: Text('Rata', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary), textAlign: TextAlign.right)),
                  Expanded(child: Text('Capitale', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary), textAlign: TextAlign.right)),
                  Expanded(child: Text('Interessi', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ..._pianoFirst6.map((d) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
              child: Row(
                children: [
                  SizedBox(width: 34, child: Text('${d.mese}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark))),
                  Expanded(child: Text('\u20AC ${_fmt.format(d.rata)}', style: const TextStyle(fontSize: 10, color: AppColors.textMedium), textAlign: TextAlign.right)),
                  Expanded(child: Text('\u20AC ${_fmt.format(d.quotaCapitale)}', style: const TextStyle(fontSize: 10, color: Color(0xFF4CAF50)), textAlign: TextAlign.right)),
                  Expanded(child: Text('\u20AC ${_fmt.format(d.quotaInteressi)}', style: const TextStyle(fontSize: 10, color: Color(0xFFFF9800)), textAlign: TextAlign.right)),
                ],
              ),
            )),
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
              onTap: () => setState(() {
                _showResult = false;
                _isAnalyzingDoc = false;
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

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: bold ? AppColors.textDark : AppColors.textMedium, fontWeight: bold ? FontWeight.w600 : FontWeight.w400))),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? (bold ? AppColors.primary : AppColors.textDark))),
        ],
      ),
    );
  }
}

class _RataDetail {
  final int mese;
  final double rata;
  final double quotaCapitale;
  final double quotaInteressi;
  final double debitoResiduo;
  const _RataDetail({required this.mese, required this.rata, required this.quotaCapitale, required this.quotaInteressi, required this.debitoResiduo});
}
