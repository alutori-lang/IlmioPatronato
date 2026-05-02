import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../core/widgets/disclaimer_widget.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class Irpef730Screen extends StatefulWidget {
  const Irpef730Screen({super.key});

  @override
  State<Irpef730Screen> createState() => _Irpef730ScreenState();
}

class _Irpef730ScreenState extends State<Irpef730Screen>
    with SingleTickerProviderStateMixin {
  // ── Tipo contribuente ──
  String _tipoReddito = 'dipendente'; // dipendente, pensionato, autonomo

  // ── Redditi ──
  final _redditoLordoCtrl = TextEditingController();
  final _altriRedditiCtrl = TextEditingController();

  // ── Deduzioni ──
  final _contributiCtrl = TextEditingController(); // contributi previdenziali

  // ── Detrazioni ──
  int _figliACarico = 0;
  bool _coniugeACarico = false;
  final _speseMediacheCtrl = TextEditingController();
  final _interessiMutuoCtrl = TextEditingController();
  final _affittoCtrl = TextEditingController();
  final _ristrutturazionCtrl = TextEditingController();

  // ── Addizionali ──
  String _regione = 'Lazio';

  // ── AI upload ──
  bool _isAnalyzingDoc = false;

  // ── Risultato ──
  bool _showResult = false;
  double _redditoComplessivo = 0;
  double _redditoImponibile = 0;
  double _irpefLorda = 0;
  double _detrazioniTotali = 0;
  double _irpefNetta = 0;
  double _addizionaleRegionale = 0;
  double _addizionaleComunale = 0;
  double _totaleTasse = 0;
  double _redditoNetto = 0;
  double _aliquotaEffettiva = 0;
  List<_ScaglioneDetail> _scaglioni = [];

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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _redditoLordoCtrl.dispose();
    _altriRedditiCtrl.dispose();
    _contributiCtrl.dispose();
    _speseMediacheCtrl.dispose();
    _interessiMutuoCtrl.dispose();
    _affittoCtrl.dispose();
    _ristrutturazionCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  double _p(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  double _pAi(dynamic v) {
    if (v == null) return 0;
    final s = v.toString().replaceAll('€', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
  }

  Future<void> _pickAndAnalyze730(ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return;

    setState(() => _isAnalyzingDoc = true);

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Analizza questo documento fiscale italiano (CU o Modello 730). Estrai e restituisci SOLO un JSON valido (senza markdown):
{
  "reddito_complessivo": "importo numerico",
  "contributi_previdenziali": "importo numerico o null",
  "spese_mediche": "importo numerico o null",
  "interessi_mutuo": "importo numerico o null",
  "canone_affitto": "importo numerico o null"
}
Importi come numeri senza simbolo €. Se un campo non è leggibile, metti null.''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        setState(() {
          final reddito = _pAi(parsed['reddito_complessivo']);
          if (reddito > 0) _redditoLordoCtrl.text = reddito.toStringAsFixed(0);
          final contrib = _pAi(parsed['contributi_previdenziali']);
          if (contrib > 0) _contributiCtrl.text = contrib.toStringAsFixed(0);
          final med = _pAi(parsed['spese_mediche']);
          if (med > 0) _speseMediacheCtrl.text = med.toStringAsFixed(0);
          final mutuo = _pAi(parsed['interessi_mutuo']);
          if (mutuo > 0) _interessiMutuoCtrl.text = mutuo.toStringAsFixed(0);
          final affitto = _pAi(parsed['canone_affitto']);
          if (affitto > 0) _affittoCtrl.text = affitto.toStringAsFixed(0);
          _isAnalyzingDoc = false;
        });
        _calcola();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dati importati dal documento! Puoi modificarli.'),
            backgroundColor: Color(0xFF4CAF50),
          ));
        }
      } else {
        setState(() => _isAnalyzingDoc = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppStrings.of(context).payslipReadError),
            backgroundColor: const Color(0xFFF44336),
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

  // ─────────────────────────────────────────────
  // CALCOLO IRPEF 2025/2026 (Scaglioni aggiornati)
  // ─────────────────────────────────────────────
  void _calcola() {
    final lordo = _p(_redditoLordoCtrl.text);
    final altri = _p(_altriRedditiCtrl.text);
    final contributi = _p(_contributiCtrl.text);
    final speseMed = _p(_speseMediacheCtrl.text);
    final interessi = _p(_interessiMutuoCtrl.text);
    final affitto = _p(_affittoCtrl.text);
    final ristrutturazione = _p(_ristrutturazionCtrl.text);

    // ── Reddito complessivo ──
    _redditoComplessivo = lordo + altri;

    // ── Reddito imponibile (deduzioni) ──
    _redditoImponibile = (_redditoComplessivo - contributi).clamp(0, double.infinity);

    // ── IRPEF LORDA (scaglioni 2025) ──
    // Scaglione 1: fino a €28,000 → 23%
    // Scaglione 2: €28,001 - €50,000 → 35%
    // Scaglione 3: oltre €50,000 → 43%
    _scaglioni = [];
    double imposta = 0;
    double residuo = _redditoImponibile;

    if (residuo > 0) {
      final double base1 = residuo.clamp(0.0, 28000.0).toDouble();
      final tax1 = base1 * 0.23;
      imposta += tax1;
      residuo -= base1;
      _scaglioni.add(_ScaglioneDetail('Fino a €28.000', '23%', base1, tax1));
    }
    if (residuo > 0) {
      final double base2 = residuo.clamp(0.0, 22000.0).toDouble();
      final tax2 = base2 * 0.35;
      imposta += tax2;
      residuo -= base2;
      _scaglioni.add(_ScaglioneDetail('€28.001 - €50.000', '35%', base2, tax2));
    }
    if (residuo > 0) {
      final tax3 = residuo * 0.43;
      imposta += tax3;
      _scaglioni.add(_ScaglioneDetail('Oltre €50.000', '43%', residuo, tax3));
    }

    _irpefLorda = imposta;

    // ── DETRAZIONI ──
    double detrazioni = 0;

    // 1. Detrazione lavoro dipendente / pensione
    if (_tipoReddito == 'dipendente') {
      detrazioni += _detrazioneLavoroDipendente(_redditoComplessivo);
    } else if (_tipoReddito == 'pensionato') {
      detrazioni += _detrazionePensione(_redditoComplessivo);
    }

    // 2. Detrazione coniuge a carico
    if (_coniugeACarico) {
      detrazioni += _detrazioneConiuge(_redditoComplessivo);
    }

    // 3. Detrazione figli a carico (solo > 21 anni, sotto 21 c'è Assegno Unico)
    if (_figliACarico > 0) {
      detrazioni += _detrazioneFigli(_redditoComplessivo, _figliACarico);
    }

    // 4. Spese mediche (19% sulla parte eccedente €129,11)
    if (speseMed > 129.11) {
      detrazioni += (speseMed - 129.11) * 0.19;
    }

    // 5. Interessi mutuo (19% fino a max €4,000)
    if (interessi > 0) {
      detrazioni += interessi.clamp(0, 4000.0) * 0.19;
    }

    // 6. Canone affitto (detrazione fissa)
    if (affitto > 0 && _redditoComplessivo <= 30987.41) {
      if (_redditoComplessivo <= 15493.71) {
        detrazioni += 300;
      } else {
        detrazioni += 150;
      }
    }

    // 7. Ristrutturazione (50% in 10 anni)
    if (ristrutturazione > 0) {
      detrazioni += (ristrutturazione.clamp(0, 96000.0) * 0.50) / 10;
    }

    _detrazioniTotali = detrazioni;

    // ── IRPEF NETTA ──
    _irpefNetta = (_irpefLorda - _detrazioniTotali).clamp(0, double.infinity);

    // ── Addizionale regionale ──
    _addizionaleRegionale = _calcolaAddizionaleRegionale(_redditoImponibile, _regione);

    // ── Addizionale comunale (media 0.8%) ──
    _addizionaleComunale = _redditoImponibile * 0.008;

    // ── Totale tasse ──
    _totaleTasse = _irpefNetta + _addizionaleRegionale + _addizionaleComunale;

    // ── Reddito netto ──
    _redditoNetto = _redditoComplessivo - _totaleTasse - contributi;

    // ── Aliquota effettiva ──
    _aliquotaEffettiva = _redditoComplessivo > 0
        ? (_totaleTasse / _redditoComplessivo) * 100
        : 0;

    setState(() => _showResult = true);
    _animController.forward(from: 0);
  }

  // ── Detrazione lavoro dipendente (2025) ──
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

  // ── Detrazione pensione ──
  double _detrazionePensione(double reddito) {
    if (reddito <= 8500) {
      return 1955.0;
    } else if (reddito <= 28000) {
      return 700.0 + 1255.0 * ((28000 - reddito) / 19500);
    } else if (reddito <= 50000) {
      return 700.0 * ((50000 - reddito) / 22000);
    }
    return 0;
  }

  // ── Detrazione coniuge a carico ──
  double _detrazioneConiuge(double reddito) {
    if (reddito <= 15000) {
      return 800.0 - 110.0 * (reddito / 15000);
    } else if (reddito <= 29000) {
      return 690.0;
    } else if (reddito <= 29200) {
      return 700.0;
    } else if (reddito <= 34700) {
      return 710.0;
    } else if (reddito <= 35000) {
      return 720.0;
    } else if (reddito <= 35100) {
      return 710.0;
    } else if (reddito <= 35200) {
      return 700.0;
    } else if (reddito <= 40000) {
      return 690.0;
    } else if (reddito <= 80000) {
      return 690.0 * ((80000 - reddito) / 40000);
    }
    return 0;
  }

  // ── Detrazione figli a carico (>21 anni, €950 per figlio) ──
  double _detrazioneFigli(double reddito, int figli) {
    if (reddito > 95000) return 0;
    final base = 950.0 * figli;
    return base * ((95000 - reddito) / 95000);
  }

  // ── Addizionale regionale (aliquote medie 2025) ──
  double _calcolaAddizionaleRegionale(double imponibile, String regione) {
    // Aliquote medie per regione (semplificate)
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
            SliverToBoxAdapter(child: _buildAiUploadBanner730()),
            SliverToBoxAdapter(child: _buildInfoBanner()),
            SliverToBoxAdapter(child: _sectionTitle('Tipo Contribuente')),
            SliverToBoxAdapter(child: _buildTipoContribuente()),
            SliverToBoxAdapter(child: _sectionTitle('Redditi')),
            SliverToBoxAdapter(child: _buildRedditiSection()),
            SliverToBoxAdapter(child: _sectionTitle('Deduzioni')),
            SliverToBoxAdapter(child: _buildDeduzioniSection()),
            SliverToBoxAdapter(child: _sectionTitle('Detrazioni & Spese')),
            SliverToBoxAdapter(child: _buildDetrazioniSection()),
            SliverToBoxAdapter(child: _sectionTitle('Regione')),
            SliverToBoxAdapter(child: _buildRegioneSection()),
            SliverToBoxAdapter(child: _buildCalcolaButton()),
            if (_showResult) ...[
              SliverToBoxAdapter(child: _buildResultCard()),
              SliverToBoxAdapter(child: _buildScaglioniCard()),
              SliverToBoxAdapter(child: _buildDettaglioCard()),
              SliverToBoxAdapter(child: _buildNettoCard()),
            ],
            SliverToBoxAdapter(child: CalculatorDisclaimer(specificSource: 'DPR 917/1986 (TUIR) e tabelle Agenzia delle Entrate')),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
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
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIMULATORE 730', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('IRPEF + Addizionali 2025/2026', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiUploadBanner730() {
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
                  const Text('Carica CU o Modello 730', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.camera_alt, color: AppColors.primary)),
                    title: const Text('Fotocamera', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () { Navigator.pop(context); _pickAndAnalyze730(ImageSource.camera); },
                  ),
                  ListTile(
                    leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.photo_library, color: AppColors.primary)),
                    title: const Text('Galleria', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () { Navigator.pop(context); _pickAndAnalyze730(ImageSource.gallery); },
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
                Text(_isAnalyzingDoc ? 'Analisi AI in corso...' : 'Carica CU o Modello 730', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                Text(_isAnalyzingDoc ? 'Claude sta leggendo il documento' : 'Foto → auto-compila reddito e detrazioni', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ])),
              if (!_isAnalyzingDoc) const Icon(Icons.chevron_right, color: AppColors.primary),
            ]),
          ),
        ),
      ),
    );
  }

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
                  TextSpan(text: 'Calcolo indicativo IRPEF. ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: 'Gli scaglioni e le detrazioni sono aggiornati al 2025. Per il 730 ufficiale rivolgiti al CAF.'),
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

  // ── Tipo contribuente ──
  Widget _buildTipoContribuente() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Row(
        children: [
          _tipoChip('dipendente', 'Dipendente', Icons.work),
          const SizedBox(width: 8),
          _tipoChip('pensionato', 'Pensionato', Icons.elderly),
          const SizedBox(width: 8),
          _tipoChip('autonomo', 'Autonomo', Icons.business_center),
        ],
      ),
    );
  }

  Widget _tipoChip(String value, String label, IconData icon) {
    final selected = _tipoReddito == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipoReddito = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.textLight),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textMedium)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Redditi ──
  Widget _buildRedditiSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reddito annuo lordo da lavoro/pensione', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 10),
          _moneyField(_redditoLordoCtrl, 'Reddito lordo annuo'),
          const SizedBox(height: 12),
          _moneyField(_altriRedditiCtrl, 'Altri redditi (affitti, etc.)'),
        ],
      ),
    );
  }

  // ── Deduzioni ──
  Widget _buildDeduzioniSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contributi previdenziali (INPS) versati nel 2025', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 10),
          _moneyField(_contributiCtrl, 'Contributi previdenziali'),
        ],
      ),
    );
  }

  // ── Detrazioni ──
  Widget _buildDetrazioniSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCounter('Figli a carico (>21 anni)', _figliACarico, 0, 10, (v) => setState(() => _figliACarico = v)),
          const Divider(height: 20),
          _buildSwitch('Coniuge a carico', _coniugeACarico, (v) => setState(() => _coniugeACarico = v)),
          const Divider(height: 20),
          _moneyField(_speseMediacheCtrl, 'Spese mediche (19% oltre €129)'),
          const SizedBox(height: 12),
          _moneyField(_interessiMutuoCtrl, 'Interessi mutuo (19% max €4.000)'),
          const SizedBox(height: 12),
          _moneyField(_affittoCtrl, 'Canone affitto annuo'),
          const SizedBox(height: 12),
          _moneyField(_ristrutturazionCtrl, 'Spese ristrutturazione (50%/10 anni)'),
        ],
      ),
    );
  }

  // ── Regione ──
  Widget _buildRegioneSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: DropdownButtonFormField<String>(
        value: _regione,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Regione di residenza',
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMedium),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: _regioni.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: (v) => setState(() => _regione = v ?? 'Lazio'),
      ),
    );
  }

  // ── Calcola ──
  Widget _buildCalcolaButton() {
    return GestureDetector(
      onTap: _calcola,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('CALCOLA 730', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  // ── Risultato principale ──
  Widget _buildResultCard() {
    Color color;
    String label;
    if (_aliquotaEffettiva <= 15) {
      color = const Color(0xFF4CAF50);
      label = 'PRESSIONE FISCALE BASSA';
    } else if (_aliquotaEffettiva <= 25) {
      color = const Color(0xFF2196F3);
      label = 'PRESSIONE FISCALE MEDIA';
    } else if (_aliquotaEffettiva <= 35) {
      color = const Color(0xFFFF9800);
      label = 'PRESSIONE FISCALE ALTA';
    } else {
      color = const Color(0xFFF44336);
      label = 'PRESSIONE FISCALE MOLTO ALTA';
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('IRPEF + ADDIZIONALI', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('€ ${_fmt.format(_totaleTasse)}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Aliquota effettiva: ${_aliquotaEffettiva.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Scaglioni dettaglio ──
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
                        Text('Imponibile: € ${_fmt.format(s.imponibile)}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                  Text('€ ${_fmt.format(s.imposta)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IRPEF Lorda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                Text('€ ${_fmt.format(_irpefLorda)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ],
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
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dettaglio Calcolo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            _row('Reddito complessivo', '€ ${_fmt.format(_redditoComplessivo)}'),
            _row('Reddito imponibile', '€ ${_fmt.format(_redditoImponibile)}'),
            const Divider(height: 16),
            _row('IRPEF lorda', '€ ${_fmt.format(_irpefLorda)}'),
            _row('Detrazioni totali', '- € ${_fmt.format(_detrazioniTotali)}', color: const Color(0xFF4CAF50)),
            _row('IRPEF netta', '€ ${_fmt.format(_irpefNetta)}', bold: true),
            const Divider(height: 16),
            _row('Addizionale regionale ($_regione)', '€ ${_fmt.format(_addizionaleRegionale)}'),
            _row('Addizionale comunale (media)', '€ ${_fmt.format(_addizionaleComunale)}'),
            const Divider(height: 16),
            _row('TOTALE TASSE', '€ ${_fmt.format(_totaleTasse)}', bold: true),
          ],
        ),
      ),
    );
  }

  // ── Reddito netto ──
  Widget _buildNettoCard() {
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
            const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50), size: 32),
            const SizedBox(height: 8),
            const Text('REDDITO NETTO ANNUO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text('€ ${_fmt.format(_redditoNetto)}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF4CAF50))),
            const SizedBox(height: 4),
            Text('€ ${_fmt.format(_redditoNetto / 12)} / mese (x12)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
            if (_redditoNetto > 0) ...[
              const SizedBox(height: 4),
              Text('€ ${_fmt.format(_redditoNetto / 13)} / mese (x13 con tredicesima)', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WIDGETS RIUTILIZZABILI
  // ─────────────────────────────────────────────
  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 3))],
    );
  }

  Widget _moneyField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
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

  Widget _buildCounter(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark))),
        _cBtn(Icons.remove, value > min, () => onChanged(value - 1)),
        Container(width: 40, alignment: Alignment.center, child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark))),
        _cBtn(Icons.add, value < max, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _cBtn(IconData icon, bool enabled, VoidCallback onTap) {
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
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
        Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: AppColors.primary),
      ],
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
