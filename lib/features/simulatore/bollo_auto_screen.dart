import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class BolloAutoScreen extends StatefulWidget {
  const BolloAutoScreen({super.key});

  @override
  State<BolloAutoScreen> createState() => _BolloAutoScreenState();
}

class _BolloAutoScreenState extends State<BolloAutoScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzingDoc = false;
  bool _showResult = false;
  bool _needRegione = false;

  // Dati estratti dall'AI
  double _kwValue = 0;
  int _classeEuro = 6;
  String _regione = 'Lazio';
  String _marca = '';
  String _modello = '';
  String _targa = '';

  // Risultati calcolo
  double _bolloAnnuale = 0;
  double _tariffaBase = 0;
  double _tariffaOltre = 0;
  String _scadenza = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');

  static const _regioni = [
    'Abruzzo', 'Basilicata', 'Calabria', 'Campania', 'Emilia-Romagna',
    'Friuli Venezia Giulia', 'Lazio', 'Liguria', 'Lombardia', 'Marche',
    'Molise', 'Piemonte', 'Puglia', 'Sardegna', 'Sicilia', 'Toscana',
    'Trentino-Alto Adige', 'Umbria', "Valle d'Aosta", 'Veneto',
  ];

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

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return;

    setState(() {
      _isAnalyzingDoc = true;
      _showResult = false;
      _needRegione = false;
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Analizza questa foto del libretto di circolazione auto italiano. Estrai TUTTI i dati possibili e restituisci SOLO un JSON valido (senza markdown):
{
  "potenza_kw": "potenza in kW numerico",
  "classe_euro": "numero classe euro (0-6)",
  "marca": "marca del veicolo",
  "modello": "modello del veicolo",
  "targa": "numero di targa",
  "regione": "regione di immatricolazione se visibile"
}
Se un campo non e leggibile, metti null.''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        final kw = _pAi(parsed['potenza_kw']);
        if (kw <= 0) {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Potenza kW non trovata. Riprova con una foto piu nitida.'),
              backgroundColor: Color(0xFFF44336),
            ));
          }
          return;
        }

        _kwValue = kw;
        final euro = _pAi(parsed['classe_euro']);
        if (euro >= 0 && euro <= 6) _classeEuro = euro.toInt();
        _marca = parsed['marca']?.toString() ?? '';
        _modello = parsed['modello']?.toString() ?? '';
        _targa = parsed['targa']?.toString() ?? '';

        final regioneAi = parsed['regione']?.toString() ?? '';
        bool regioneTrovata = false;
        if (regioneAi.isNotEmpty) {
          for (final r in _regioni) {
            if (regioneAi.toLowerCase().contains(r.toLowerCase())) {
              _regione = r;
              regioneTrovata = true;
              break;
            }
          }
        }

        if (!regioneTrovata) {
          setState(() {
            _isAnalyzingDoc = false;
            _needRegione = true;
          });
          return;
        }

        _calcola();
        setState(() => _isAnalyzingDoc = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Libretto analizzato con successo!'),
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

  ({double base, double oltre}) _getTariffe() {
    final isLombardia = _regione == 'Lombardia';
    final isPiemonte = _regione == 'Piemonte';
    switch (_classeEuro) {
      case 0:
        if (isLombardia) return (base: 3.12, oltre: 4.69);
        if (isPiemonte) return (base: 3.06, oltre: 4.59);
        return (base: 3.00, oltre: 4.50);
      case 1:
        if (isLombardia) return (base: 3.02, oltre: 4.53);
        if (isPiemonte) return (base: 2.96, oltre: 4.44);
        return (base: 2.90, oltre: 4.35);
      case 2:
        if (isLombardia) return (base: 2.91, oltre: 4.37);
        if (isPiemonte) return (base: 2.86, oltre: 4.29);
        return (base: 2.80, oltre: 4.20);
      case 3:
        if (isLombardia) return (base: 2.81, oltre: 4.21);
        if (isPiemonte) return (base: 2.76, oltre: 4.13);
        return (base: 2.70, oltre: 4.05);
      default:
        if (isLombardia) return (base: 2.68, oltre: 4.02);
        if (isPiemonte) return (base: 2.63, oltre: 3.95);
        return (base: 2.58, oltre: 3.87);
    }
  }

  String _calcolaScadenza() {
    final now = DateTime.now();
    final month = now.month;
    if (month >= 1 && month <= 4) {
      return 'Aprile ${now.year}';
    } else if (month >= 5 && month <= 8) {
      return 'Agosto ${now.year}';
    } else {
      return 'Dicembre ${now.year}';
    }
  }

  void _calcola() {
    final tariffe = _getTariffe();
    _tariffaBase = tariffe.base;
    _tariffaOltre = tariffe.oltre;

    if (_kwValue <= 100) {
      _bolloAnnuale = _kwValue * tariffe.base;
    } else {
      _bolloAnnuale = (100 * tariffe.base) + ((_kwValue - 100) * tariffe.oltre);
    }

    _scadenza = _calcolaScadenza();
    setState(() {
      _showResult = true;
      _needRegione = false;
    });
    _animController.forward(from: 0);
  }

  Color _getEuroColor(int euro) {
    switch (euro) {
      case 6: return const Color(0xFF4CAF50);
      case 5: return const Color(0xFF8BC34A);
      case 4: return const Color(0xFF2196F3);
      case 3: return const Color(0xFFFF9800);
      case 2: return const Color(0xFFFF5722);
      case 1: return const Color(0xFFF44336);
      case 0: return const Color(0xFF9E9E9E);
      default: return const Color(0xFF2196F3);
    }
  }

  Future<void> _generaPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('CALCOLO BOLLO AUTO', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            if (_targa.isNotEmpty) pw.Text('Targa: $_targa', style: const pw.TextStyle(fontSize: 14)),
            if (_marca.isNotEmpty) pw.Text('Veicolo: $_marca $_modello', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('Potenza', '${_kwValue.toStringAsFixed(0)} kW'),
            _pdfRow('Classe Euro', 'Euro $_classeEuro'),
            _pdfRow('Regione', _regione),
            _pdfRow('Tariffa fino 100 kW', '${_tariffaBase.toStringAsFixed(2)} EUR/kW'),
            _pdfRow('Tariffa oltre 100 kW', '${_tariffaOltre.toStringAsFixed(2)} EUR/kW'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('BOLLO ANNUALE', '\u20AC ${_fmt.format(_bolloAnnuale)}'),
            _pdfRow('Costo mensile', '\u20AC ${(_bolloAnnuale / 12).toStringAsFixed(2)}'),
            _pdfRow('Prossima scadenza', _scadenza),
            pw.SizedBox(height: 20),
            pw.Text('Generato da Il Mio Patronato', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        );
      },
    ));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'bollo_auto.pdf');
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
              label: 'Carica Foto Libretto',
              subtitle: 'Scatta una foto del libretto di circolazione',
              icon: Icons.directions_car,
              isLoading: _isAnalyzingDoc,
              onPickCamera: () => _pickAndAnalyze(ImageSource.camera),
              onPickGallery: () => _pickAndAnalyze(ImageSource.gallery),
            ),
          ),
          if (_needRegione)
            SliverToBoxAdapter(child: _buildRegioneSelector()),
          if (!_showResult && !_isAnalyzingDoc && !_needRegione)
            SliverToBoxAdapter(child: _buildHint()),
          if (_showResult) ...[
            SliverToBoxAdapter(child: _buildResultCard()),
            SliverToBoxAdapter(child: _buildDettaglioCard()),
            SliverToBoxAdapter(child: _buildScadenzaCard()),
            SliverToBoxAdapter(child: _buildDovePagareCard()),
            SliverToBoxAdapter(child: _buildActionButtons()),
          ],
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
            child: const Icon(Icons.directions_car, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BOLLO AUTO', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Carica il libretto e calcola', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
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
          const Text('Carica una foto del libretto di circolazione', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'L\'AI leggera automaticamente potenza kW, classe Euro, marca e modello dal libretto e calcolera il bollo auto.',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegioneSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFFF9800).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_on, color: Color(0xFFFF9800), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Regione non trovata nel libretto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Seleziona la tua regione per calcolare la tariffa corretta:', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _regione,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Regione',
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _regioni.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) => setState(() => _regione = v ?? 'Lazio'),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _calcola,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('CALCOLA BOLLO', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final euroColor = _getEuroColor(_classeEuro);
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [euroColor, euroColor.withValues(alpha: 0.7)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: euroColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('BOLLO AUTO ANNUALE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('\u20AC ${_fmt.format(_bolloAnnuale)}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${_kwValue.toStringAsFixed(0)} kW - Euro $_classeEuro - $_regione', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('\u20AC ${(_bolloAnnuale / 12).toStringAsFixed(2)} / mese', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
            const Text('Dati Estratti dal Libretto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            if (_targa.isNotEmpty) _row('Targa', _targa),
            if (_marca.isNotEmpty) _row('Marca', _marca),
            if (_modello.isNotEmpty) _row('Modello', _modello),
            _row('Potenza veicolo', '${_kwValue.toStringAsFixed(0)} kW'),
            _row('Classe emissioni', 'Euro $_classeEuro'),
            _row('Regione', _regione),
            const Divider(height: 16),
            _row('Tariffa fino a 100 kW', '\u20AC ${_tariffaBase.toStringAsFixed(2)} / kW'),
            _row('Tariffa oltre 100 kW', '\u20AC ${_tariffaOltre.toStringAsFixed(2)} / kW'),
            const Divider(height: 16),
            if (_kwValue <= 100)
              _row('Calcolo', '${_kwValue.toStringAsFixed(0)} kW x \u20AC ${_tariffaBase.toStringAsFixed(2)}')
            else ...[
              _row('Primi 100 kW', '100 x \u20AC ${_tariffaBase.toStringAsFixed(2)} = \u20AC ${_fmt.format(100 * _tariffaBase)}'),
              _row('kW eccedenti (${(_kwValue - 100).toStringAsFixed(0)})', '${(_kwValue - 100).toStringAsFixed(0)} x \u20AC ${_tariffaOltre.toStringAsFixed(2)} = \u20AC ${_fmt.format((_kwValue - 100) * _tariffaOltre)}'),
            ],
            const Divider(height: 16),
            _row('BOLLO ANNUALE', '\u20AC ${_fmt.format(_bolloAnnuale)}', bold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildScadenzaCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFFFF9800).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFFF9800).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calendar_today, color: Color(0xFFFF9800), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Scadenza Pagamento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 12),
            Text(_scadenza, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFF9800))),
            const SizedBox(height: 8),
            const Text('Il bollo si paga entro l\'ultimo giorno del mese successivo alla scadenza.', style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildDovePagareCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dove Pagare', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            _pagamentoItem(Icons.language, 'ACI Online', 'www.aci.it', const Color(0xFF1565C0)),
            _pagamentoItem(Icons.store, 'Tabaccheria', 'Punti Lottomatica', const Color(0xFF4CAF50)),
            _pagamentoItem(Icons.account_balance, 'PagoPA', 'Home banking o app IO', const Color(0xFF9C27B0)),
            _pagamentoItem(Icons.local_post_office, 'Poste Italiane', 'Ufficio postale o app', const Color(0xFFFF9800)),
          ],
        ),
      ),
    );
  }

  Widget _pagamentoItem(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
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
                _needRegione = false;
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
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? (bold ? AppColors.primary : AppColors.textDark))),
        ],
      ),
    );
  }
}
