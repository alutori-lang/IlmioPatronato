import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class StipendioNettoScreen extends StatefulWidget {
  const StipendioNettoScreen({super.key});

  @override
  State<StipendioNettoScreen> createState() => _StipendioNettoScreenState();
}

class _StipendioNettoScreenState extends State<StipendioNettoScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzingDoc = false;
  bool _showResult = false;
  bool _needRegione = false;
  bool _needManualRal = false;
  final _ralController = TextEditingController();

  // Dati estratti dall'AI
  double _ral = 0;
  String _tipoContratto = 'dipendente';
  String _settore = 'Commercio';
  String _regione = 'Lazio';
  String _dipendente = '';
  String _azienda = '';

  // Risultati calcolo
  double _contributiInps = 0;
  double _imponibileIrpef = 0;
  double _irpefLorda = 0;
  double _detrazioniLavoro = 0;
  double _irpefNetta = 0;
  double _addizionaleRegionale = 0;
  double _addizionaleComunale = 0;
  double _nettoAnnuo = 0;
  double _nettoMensile12 = 0;
  double _nettoMensile13 = 0;
  double _nettoMensile14 = 0;
  double _aliquotaInps = 0;
  List<_ScaglioneDetail> _scaglioni = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');

  static const _settori = ['Commercio', 'Industria', 'Artigianato', 'Pubblico'];

  static const _regioni = [
    'Abruzzo', 'Basilicata', 'Calabria', 'Campania', 'Emilia-Romagna',
    'Friuli Venezia Giulia', 'Lazio', 'Liguria', 'Lombardia', 'Marche',
    'Molise', 'Piemonte', 'Puglia', 'Sardegna', 'Sicilia', 'Toscana',
    'Trentino-Alto Adige', 'Umbria', "Valle d'Aosta", 'Veneto',
  ];

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

  static const _bustaPagaPrompt = '''Sei un esperto di buste paga italiane. Trova lo stipendio MENSILE (di UN mese, NON annuale). Rispondi SOLO con JSON:
{"lordo_mensile":1850.50,"netto_mensile":1350.00,"tipo":"dipendente","settore":"Commercio","regione":"Lombardia","nome":"Mario Rossi","azienda":"Azienda Srl"}
ATTENZIONE: lordo_mensile e netto_mensile devono essere importi di UN SINGOLO MESE (tipicamente tra 800 e 5000 euro). NON mettere il totale annuale. Usa punto come decimale, senza euro.''';

  Future<void> _pickPdf() async {
    final file = await pickPdfFile();
    if (file == null) return;
    _analyzeFile(file);
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return;
    _analyzeFile(file);
  }

  Future<void> _analyzeFile(File file) async {
    setState(() {
      _isAnalyzingDoc = true;
      _showResult = false;
      _needRegione = false;
      _needManualRal = false;
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: _bustaPagaPrompt,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      // Prova a parsare JSON dalla risposta AI
      final parsed = response.tryParseJson();

      // Se il JSON non è parsabile, prova a estrarre numeri dalla risposta testuale
      if (parsed == null) {
        // Cerca qualsiasi numero nella risposta che potrebbe essere lordo/netto
        final text = response.text;
        final numRegex = RegExp(r'(\d{1,2}[\.,]\d{3}[\.,]\d{2}|\d{3,5}[\.,]\d{2})');
        final matches = numRegex.allMatches(text).toList();

        if (matches.length >= 2) {
          // Primo numero grande = lordo, secondo = netto (tipico ordine busta paga)
          final nums = matches.map((m) => _pAi(m.group(0))).where((n) => n > 100).toList();
          if (nums.isNotEmpty) {
            final lordo = nums.reduce((a, b) => a > b ? a : b); // il più grande = lordo
            _ral = lordo > 5000 ? lordo : lordo * 13;
            _calcola();
            setState(() => _isAnalyzingDoc = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Busta paga analizzata!'),
                backgroundColor: Color(0xFF4CAF50),
              ));
            }
            return;
          }
        }

        setState(() => _isAnalyzingDoc = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('AI risposta: ${text.length > 100 ? text.substring(0, 100) : text}'),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 5),
          ));
        }
        return;
      }

      if (parsed != null) {
        _dipendente = (parsed['nome'] ?? parsed['dipendente'] ?? '').toString();
        _azienda = (parsed['azienda'] ?? '').toString();

        // Cerca lordo e netto mensile
        double lordoMensile = _pAi(parsed['lordo_mensile'] ?? parsed['lordo'] ?? parsed['totale_competenze'] ?? parsed['stipendio_lordo_mensile']);
        double nettoMensile = _pAi(parsed['netto_mensile'] ?? parsed['netto'] ?? parsed['netto_in_busta'] ?? parsed['stipendio_netto']);

        // Sanity check: se i numeri sono troppo alti, probabilmente sono annuali
        if (lordoMensile > 8000) lordoMensile = lordoMensile / 13;
        if (nettoMensile > 6000) nettoMensile = nettoMensile / 13;

        // Calcola RAL: lordo mensile x 13
        if (lordoMensile > 0) {
          _ral = lordoMensile * 13;
        } else if (nettoMensile > 0) {
          _ral = nettoMensile * 1.45 * 13;
        } else {
          setState(() => _isAnalyzingDoc = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Importi non trovati. Dati: ${parsed.toString().substring(0, parsed.toString().length.clamp(0, 80))}'),
              backgroundColor: const Color(0xFFF44336),
              duration: const Duration(seconds: 5),
            ));
          }
          return;
        }

        // Tipo contratto
        final tipo = (parsed['tipo'] ?? parsed['tipo_contratto'] ?? '').toString().toLowerCase();
        if (tipo.contains('apprend')) {
          _tipoContratto = 'apprendista';
        } else if (tipo.contains('cococo') || tipo.contains('co.co')) {
          _tipoContratto = 'cococo';
        } else {
          _tipoContratto = 'dipendente';
        }

        // Settore
        final ccnl = (parsed['settore'] ?? parsed['ccnl'] ?? '').toString();
        if (ccnl.isNotEmpty) {
          for (final s in _settori) {
            if (ccnl.toLowerCase().contains(s.toLowerCase())) {
              _settore = s;
              break;
            }
          }
        }

        // Regione — se non trovata usa Lazio come default
        final regione = (parsed['regione'] ?? '').toString();
        if (regione.isNotEmpty) {
          for (final r in _regioni) {
            if (regione.toLowerCase().contains(r.toLowerCase())) {
              _regione = r;
              break;
            }
          }
        }

        _calcola();
        setState(() => _isAnalyzingDoc = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Busta paga analizzata con successo!'),
            backgroundColor: Color(0xFF4CAF50),
          ));
        }
      } else {
        setState(() => _isAnalyzingDoc = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Documento non leggibile. Riprova con una foto piu chiara.'),
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

  // ── CALCOLO STIPENDIO NETTO ──
  void _calcola() {
    if (_ral <= 0) return;

    // 1. Contributi INPS
    switch (_tipoContratto) {
      case 'apprendista':
        _aliquotaInps = 5.84;
        break;
      case 'cococo':
        _aliquotaInps = 11.24;
        break;
      default:
        if (_ral <= 25000) {
          _aliquotaInps = 2.19;
        } else if (_ral <= 35000) {
          _aliquotaInps = 3.19;
        } else {
          _aliquotaInps = 9.19;
        }
    }
    _contributiInps = _ral * (_aliquotaInps / 100);

    // 2. Imponibile IRPEF
    _imponibileIrpef = (_ral - _contributiInps).clamp(0.0, double.infinity);

    // 3. IRPEF Lorda (scaglioni 2025)
    _scaglioni = [];
    double imposta = 0;
    double residuo = _imponibileIrpef;

    if (residuo > 0) {
      final double base1 = residuo.clamp(0.0, 28000.0).toDouble();
      final tax1 = base1 * 0.23;
      imposta += tax1;
      residuo -= base1;
      _scaglioni.add(_ScaglioneDetail('Fino a \u20AC28.000', '23%', base1, tax1));
    }
    if (residuo > 0) {
      final double base2 = residuo.clamp(0.0, 22000.0).toDouble();
      final tax2 = base2 * 0.35;
      imposta += tax2;
      residuo -= base2;
      _scaglioni.add(_ScaglioneDetail('\u20AC28.001 - \u20AC50.000', '35%', base2, tax2));
    }
    if (residuo > 0) {
      final tax3 = residuo * 0.43;
      imposta += tax3;
      _scaglioni.add(_ScaglioneDetail('Oltre \u20AC50.000', '43%', residuo, tax3));
    }

    _irpefLorda = imposta;

    // 4. Detrazioni lavoro dipendente
    _detrazioniLavoro = _detrazioneLavoroDipendente(_imponibileIrpef);

    // 5. IRPEF Netta
    _irpefNetta = (_irpefLorda - _detrazioniLavoro).clamp(0.0, double.infinity);

    // 6. Addizionale regionale
    _addizionaleRegionale = _calcolaAddizionaleRegionale(_imponibileIrpef, _regione);

    // 7. Addizionale comunale (media 0.8%)
    _addizionaleComunale = _imponibileIrpef * 0.008;

    // 8. Netto annuo
    _nettoAnnuo = _ral - _contributiInps - _irpefNetta - _addizionaleRegionale - _addizionaleComunale;
    _nettoAnnuo = _nettoAnnuo.clamp(0.0, double.infinity);

    // 9. Netto mensile
    _nettoMensile12 = _nettoAnnuo / 12;
    _nettoMensile13 = _nettoAnnuo / 13;
    _nettoMensile14 = _nettoAnnuo / 14;

    setState(() {
      _showResult = true;
      _needRegione = false;
    });
    _animController.forward(from: 0);
  }

  double _detrazioneLavoroDipendente(double reddito) {
    if (reddito <= 15000) {
      return 1955.0;
    } else if (reddito <= 28000) {
      return 1910.0 + 1190.0 * ((28000 - reddito) / 13000);
    } else if (reddito <= 50000) {
      return 1910.0 * ((50000 - reddito) / 22000);
    }
    return 0;
  }

  double _calcolaAddizionaleRegionale(double imponibile, String regione) {
    final aliquote = <String, double>{
      'Abruzzo': 0.0173, 'Basilicata': 0.0123, 'Calabria': 0.0203,
      'Campania': 0.0203, 'Emilia-Romagna': 0.0173, 'Friuli Venezia Giulia': 0.0123,
      'Lazio': 0.0173, 'Liguria': 0.0173, 'Lombardia': 0.0173,
      'Marche': 0.0173, 'Molise': 0.0203, 'Piemonte': 0.0173,
      'Puglia': 0.0173, 'Sardegna': 0.0173, 'Sicilia': 0.0173,
      'Toscana': 0.0162, 'Trentino-Alto Adige': 0.0123, 'Umbria': 0.0173,
      "Valle d'Aosta": 0.0123, 'Veneto': 0.0173,
    };
    final aliquota = aliquote[regione] ?? 0.0173;
    return imponibile * aliquota;
  }

  Future<void> _generaPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('CALCOLO STIPENDIO NETTO', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            if (_dipendente.isNotEmpty) pw.Text('Dipendente: $_dipendente', style: const pw.TextStyle(fontSize: 14)),
            if (_azienda.isNotEmpty) pw.Text('Azienda: $_azienda', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _pdfRow('RAL (lordo annuo)', '\u20AC ${_fmt.format(_ral)}'),
            _pdfRow('Tipo contratto', _tipoContratto),
            _pdfRow('Settore', _settore),
            _pdfRow('Regione', _regione),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _pdfRow('Contributi INPS (${_aliquotaInps.toStringAsFixed(2)}%)', '- \u20AC ${_fmt.format(_contributiInps)}'),
            _pdfRow('Imponibile IRPEF', '\u20AC ${_fmt.format(_imponibileIrpef)}'),
            _pdfRow('IRPEF lorda', '\u20AC ${_fmt.format(_irpefLorda)}'),
            _pdfRow('Detrazioni lavoro', '- \u20AC ${_fmt.format(_detrazioniLavoro)}'),
            _pdfRow('IRPEF netta', '\u20AC ${_fmt.format(_irpefNetta)}'),
            _pdfRow('Addizionale regionale', '- \u20AC ${_fmt.format(_addizionaleRegionale)}'),
            _pdfRow('Addizionale comunale', '- \u20AC ${_fmt.format(_addizionaleComunale)}'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _pdfRow('NETTO ANNUO', '\u20AC ${_fmt.format(_nettoAnnuo)}'),
            _pdfRow('Netto mensile x12', '\u20AC ${_fmt.format(_nettoMensile12)}'),
            _pdfRow('Netto mensile x13', '\u20AC ${_fmt.format(_nettoMensile13)}'),
            _pdfRow('Netto mensile x14', '\u20AC ${_fmt.format(_nettoMensile14)}'),
            pw.SizedBox(height: 20),
            pw.Text('Generato da Il Mio Patronato', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        );
      },
    ));

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'stipendio_netto.pdf');
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
              subtitle: 'Scatta una foto e l\'AI calcola il netto automaticamente',
              icon: Icons.payments,
              isLoading: _isAnalyzingDoc,
              onPickCamera: () => _pickAndAnalyze(ImageSource.camera),
              onPickGallery: () => _pickAndAnalyze(ImageSource.gallery),
              onPickPdf: _pickPdf,
            ),
          ),
          if (_needRegione)
            SliverToBoxAdapter(child: _buildRegioneSelector()),
          if (!_showResult && !_isAnalyzingDoc && !_needRegione)
            SliverToBoxAdapter(child: _buildHint()),
          if (_showResult) ...[
            SliverToBoxAdapter(child: _buildNettoResultCard()),
            SliverToBoxAdapter(child: _buildSplitBarsCard()),
            SliverToBoxAdapter(child: _buildScaglioniCard()),
            SliverToBoxAdapter(child: _buildDettaglioCard()),
            SliverToBoxAdapter(child: _buildMensileCard()),
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
            child: const Icon(Icons.payments, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STIPENDIO NETTO', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Carica busta paga e calcola', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualRalForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inserisci il tuo stipendio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    SizedBox(height: 2),
                    Text('Quanto prendi al mese?', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_dipendente.isNotEmpty || _azienda.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${_dipendente.isNotEmpty ? _dipendente : ""} ${_azienda.isNotEmpty ? "- $_azienda" : ""}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w600),
              ),
            ),
          TextField(
            controller: _ralController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Stipendio Netto Mensile',
              hintText: 'Es: 1200',
              helperText: 'Quanto ti arriva in banca ogni mese',
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.euro, size: 20),
              suffixText: '€ netto/mese',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final text = _ralController.text.replaceAll('.', '').replaceAll(',', '.').replaceAll('€', '').trim();
                final netto = double.tryParse(text) ?? 0;
                if (netto <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Inserisci lo stipendio netto mensile'),
                    backgroundColor: Color(0xFFF44336),
                  ));
                  return;
                }
                // Stima RAL dal netto: netto x 1.45 x 13 mensilità
                _ral = netto * 1.45 * 13;
                _needManualRal = false;

                // Check regione
                if (_regione.isEmpty) {
                  setState(() => _needRegione = true);
                  return;
                }

                _calcola();
                setState(() {});
              },
              icon: const Icon(Icons.calculate),
              label: const Text('CALCOLA STIPENDIO NETTO', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
            'Carica una foto della busta paga',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'L\'AI leggera automaticamente la RAL, il tipo di contratto e il settore, calcolando IRPEF, contributi e netto mensile.',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegioneSelector() {
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
              Icon(Icons.location_on, color: Color(0xFFFF9800), size: 22),
              SizedBox(width: 8),
              Text('Seleziona la Regione', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('La regione non e\' stata trovata nel documento. Selezionala per calcolare l\'addizionale regionale.',
              style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _regione,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _regioni.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) => setState(() => _regione = v ?? 'Lazio'),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              _calcola();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('CALCOLA NETTO', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNettoResultCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 28),
            const SizedBox(height: 6),
            const Text('NETTO MENSILE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('\u20AC ${_fmt.format(_nettoMensile13)}', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('su 13 mensilita', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _nettoMiniCol('x12', _nettoMensile12),
                  Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                  _nettoMiniCol('x13', _nettoMensile13),
                  Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                  _nettoMiniCol('x14', _nettoMensile14),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('Netto annuo: \u20AC ${_fmt.format(_nettoAnnuo)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _nettoMiniCol(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('\u20AC ${_fmt.format(value)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildSplitBarsCard() {
    final totaleTrattenute = _contributiInps + _irpefNetta + _addizionaleRegionale + _addizionaleComunale;
    if (_ral <= 0) return const SizedBox.shrink();

    final percNetto = (_nettoAnnuo / _ral * 100).clamp(0.0, 100.0);
    final percInps = (_contributiInps / _ral * 100).clamp(0.0, 100.0);
    final percIrpef = (_irpefNetta / _ral * 100).clamp(0.0, 100.0);
    final percAddiz = ((_addizionaleRegionale + _addizionaleComunale) / _ral * 100).clamp(0.0, 100.0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Composizione RAL', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('Totale trattenute: \u20AC ${_fmt.format(totaleTrattenute)} (${(totaleTrattenute / _ral * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Flexible(flex: (percNetto * 10).round().clamp(1, 1000), child: Container(color: const Color(0xFF4CAF50))),
                    Flexible(flex: (percInps * 10).round().clamp(1, 1000), child: Container(color: const Color(0xFFFF9800))),
                    Flexible(flex: (percIrpef * 10).round().clamp(1, 1000), child: Container(color: const Color(0xFFF44336))),
                    Flexible(flex: (percAddiz * 10).round().clamp(1, 1000), child: Container(color: const Color(0xFF9C27B0))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _legendRow(const Color(0xFF4CAF50), 'Netto in tasca', percNetto, _nettoAnnuo),
            const SizedBox(height: 8),
            _legendRow(const Color(0xFFFF9800), 'Contributi INPS (${_aliquotaInps.toStringAsFixed(2)}%)', percInps, _contributiInps),
            const SizedBox(height: 8),
            _legendRow(const Color(0xFFF44336), 'IRPEF netta', percIrpef, _irpefNetta),
            const SizedBox(height: 8),
            _legendRow(const Color(0xFF9C27B0), 'Addizionali reg. + com.', percAddiz, _addizionaleRegionale + _addizionaleComunale),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, double perc, double amount) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark))),
        Text('${perc.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMedium)),
        const SizedBox(width: 8),
        Text('\u20AC ${_fmt.format(amount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildScaglioniCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scaglioni IRPEF 2025', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            ..._scaglioni.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(s.aliquota, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.fascia, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        Text('Imponibile: \u20AC ${_fmt.format(s.imponibile)}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                  Text('\u20AC ${_fmt.format(s.imposta)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IRPEF Lorda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                Text('\u20AC ${_fmt.format(_irpefLorda)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
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
            const Text('Dettaglio Calcolo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            if (_dipendente.isNotEmpty) _row('Dipendente', _dipendente),
            if (_azienda.isNotEmpty) _row('Azienda', _azienda),
            _row('Tipo contratto', _tipoContratto),
            _row('Settore', _settore),
            _row('Regione', _regione),
            const Divider(height: 16),
            _row('1. RAL (lordo annuo)', '\u20AC ${_fmt.format(_ral)}', bold: true),
            const SizedBox(height: 4),
            _row('2. Contributi INPS (${_aliquotaInps.toStringAsFixed(2)}%)', '- \u20AC ${_fmt.format(_contributiInps)}', color: const Color(0xFFFF9800)),
            _row('3. Imponibile IRPEF', '\u20AC ${_fmt.format(_imponibileIrpef)}'),
            const Divider(height: 16),
            _row('4. IRPEF Lorda', '\u20AC ${_fmt.format(_irpefLorda)}'),
            _row('   Detraz. lavoro dipendente', '- \u20AC ${_fmt.format(_detrazioniLavoro)}', color: const Color(0xFF4CAF50)),
            _row('5. IRPEF Netta', '\u20AC ${_fmt.format(_irpefNetta)}', bold: true),
            const Divider(height: 16),
            _row('6. Addizionale regionale ($_regione)', '- \u20AC ${_fmt.format(_addizionaleRegionale)}'),
            _row('7. Addizionale comunale (0,8%)', '- \u20AC ${_fmt.format(_addizionaleComunale)}'),
            const Divider(height: 16),
            _row('NETTO ANNUO', '\u20AC ${_fmt.format(_nettoAnnuo)}', bold: true, color: const Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }

  Widget _buildMensileCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Text('NETTO MENSILE PER MENSILITA\'', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.3)),
            const SizedBox(height: 16),
            Row(
              children: [
                _mensileBox('12 mensilita', _nettoMensile12, 'Senza tredicesima'),
                const SizedBox(width: 10),
                _mensileBox('13 mensilita', _nettoMensile13, 'Standard'),
                const SizedBox(width: 10),
                _mensileBox('14 mensilita', _nettoMensile14, 'Commercio/CCNL'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF7B1FA2), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _settore == 'Commercio'
                          ? 'Il CCNL Commercio prevede 14 mensilita.'
                          : _settore == 'Pubblico'
                              ? 'Il settore pubblico prevede 13 mensilita.'
                              : 'Le mensilita dipendono dal CCNL applicato. Verifica il tuo contratto.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF4A148C), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mensileBox(String label, double value, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('\u20AC ${_fmt.format(value)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
            ),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 9, color: AppColors.textLight), textAlign: TextAlign.center),
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

class _ScaglioneDetail {
  final String fascia;
  final String aliquota;
  final double imponibile;
  final double imposta;
  const _ScaglioneDetail(this.fascia, this.aliquota, this.imponibile, this.imposta);
}
