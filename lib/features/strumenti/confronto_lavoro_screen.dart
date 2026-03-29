import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class ConfrontoLavoroScreen extends StatefulWidget {
  const ConfrontoLavoroScreen({super.key});

  @override
  State<ConfrontoLavoroScreen> createState() => _ConfrontoLavoroScreenState();
}

class _ConfrontoLavoroScreenState extends State<ConfrontoLavoroScreen>
    with SingleTickerProviderStateMixin {
  // ── Offerta A ──
  final _aziendaACtrl = TextEditingController();
  final _ralACtrl = TextEditingController();
  String _contrattoA = 'Indeterminato';
  int _mensilitaA = 13;
  final _buoniPastoACtrl = TextEditingController();
  int _smartWorkingA = 0;
  final _distanzaACtrl = TextEditingController();
  bool _autoAziendaleA = false;
  bool _telefonoA = false;
  bool _assicurazioneA = false;

  // ── Offerta B ──
  final _aziendaBCtrl = TextEditingController();
  final _ralBCtrl = TextEditingController();
  String _contrattoB = 'Indeterminato';
  int _mensilitaB = 13;
  final _buoniPastoBCtrl = TextEditingController();
  int _smartWorkingB = 0;
  final _distanzaBCtrl = TextEditingController();
  bool _autoAziendaleB = false;
  bool _telefonoB = false;
  bool _assicurazioneB = false;

  // ── AI scanning ──
  bool _isAnalyzingA = false;
  bool _isAnalyzingB = false;

  // ── Risultati ──
  bool _showResult = false;
  _OfferResult? _resultA;
  _OfferResult? _resultB;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');
  final _fmtInt = NumberFormat('#,##0', 'it_IT');

  static const _tipiContratto = ['Indeterminato', 'Determinato', 'Apprendista'];

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
    _aziendaACtrl.dispose();
    _ralACtrl.dispose();
    _buoniPastoACtrl.dispose();
    _distanzaACtrl.dispose();
    _aziendaBCtrl.dispose();
    _ralBCtrl.dispose();
    _buoniPastoBCtrl.dispose();
    _distanzaBCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  double _p(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  // ─────────────────────────────────────────────
  // CALCOLO OFFERTA
  // ─────────────────────────────────────────────
  _OfferResult _calcolaOfferta({
    required String azienda,
    required double ral,
    required String contratto,
    required int mensilita,
    required double buoniPasto,
    required int smartWorking,
    required double distanza,
    required bool autoAziendale,
    required bool telefono,
    required bool assicurazione,
  }) {
    // 1. INPS (9.19%)
    final contributiInps = ral * 0.0919;

    // 2. Imponibile IRPEF
    final imponibile = ral - contributiInps;

    // 3. IRPEF Lorda (scaglioni 2025)
    double irpefLorda = 0;
    double residuo = imponibile;

    if (residuo > 0) {
      final base1 = residuo.clamp(0.0, 28000.0);
      irpefLorda += base1 * 0.23;
      residuo -= base1;
    }
    if (residuo > 0) {
      final base2 = residuo.clamp(0.0, 22000.0);
      irpefLorda += base2 * 0.35;
      residuo -= base2;
    }
    if (residuo > 0) {
      irpefLorda += residuo * 0.43;
    }

    // 4. Detrazioni lavoro dipendente
    double detrazioni = 0;
    if (imponibile <= 15000) {
      detrazioni = 1955.0;
    } else if (imponibile <= 28000) {
      detrazioni = 1910.0 + 1190.0 * ((28000 - imponibile) / 13000);
    } else if (imponibile <= 50000) {
      detrazioni = 1910.0 * ((50000 - imponibile) / 22000);
    }

    // 5. IRPEF Netta
    final irpefNetta = (irpefLorda - detrazioni).clamp(0.0, double.infinity);

    // 6. Addizionali (stima media: regionale 1.73% + comunale 0.8%)
    final addizionali = imponibile * (0.0173 + 0.008);

    // 7. Netto annuo
    final nettoAnnuo = ral - contributiInps - irpefNetta - addizionali;

    // 8. Netto mensile
    final nettoMensile = nettoAnnuo / mensilita;

    // 9. TFR annuo
    final tfrAnnuo = ral / 13.5;

    // 10. Buoni pasto annuo (220 giorni lavorativi)
    final buoniPastoAnnuo = buoniPasto * 220;

    // 11. Costo trasporto (km * 2 viaggi * 220 giorni * 0.15 EUR/km)
    // Smart working riduce i giorni in ufficio
    final giorniInUfficio = 220.0 * ((5 - smartWorking) / 5);
    final costoTrasporto = distanza * 2 * giorniInUfficio * 0.15;

    // 12. Valore benefit
    double valoreBenefit = 0;
    if (autoAziendale) valoreBenefit += 3000;
    if (telefono) valoreBenefit += 600;
    if (assicurazione) valoreBenefit += 1200;

    // 13. TOTALE VALORE REALE
    final totaleValoreReale =
        nettoAnnuo + buoniPastoAnnuo + valoreBenefit - costoTrasporto;

    return _OfferResult(
      azienda: azienda.isEmpty ? 'N/D' : azienda,
      ral: ral,
      contributiInps: contributiInps,
      irpefLorda: irpefLorda,
      detrazioni: detrazioni,
      irpefNetta: irpefNetta,
      addizionali: addizionali,
      nettoAnnuo: nettoAnnuo,
      nettoMensile: nettoMensile,
      tfrAnnuo: tfrAnnuo,
      buoniPastoAnnuo: buoniPastoAnnuo,
      costoTrasporto: costoTrasporto,
      valoreBenefit: valoreBenefit,
      totaleValoreReale: totaleValoreReale,
    );
  }

  // ─────────────────────────────────────────────
  // AI DOCUMENT SCANNING
  // ─────────────────────────────────────────────
  Future<void> _pickAndAnalyzeOffer(ImageSource source, bool isOfferA) async {
    final file = await pickImage(source);
    if (file == null) return;

    setState(() {
      if (isOfferA) {
        _isAnalyzingA = true;
      } else {
        _isAnalyzingB = true;
      }
    });

    try {
      final response = await GeminiService().analyzeDocument(
        imageFile: file,
        prompt:
            'Analizza questa offerta di lavoro o contratto italiano. '
            'Estrai e restituisci SOLO un JSON valido (senza markdown): '
            '{"azienda": "", "ral_annua": "numero", '
            '"tipo_contratto": "indeterminato/determinato/apprendistato", '
            '"mensilita": "13 o 14", '
            '"buoni_pasto_valore": "numero o null", '
            '"smart_working_giorni": "numero o null"}. '
            'Importi come numeri senza simbolo \u20AC.',
      );

      if (!mounted) return;

      if (response.isSuccess) {
        final json = response.tryParseJson();
        if (json != null) {
          _fillFieldsFromJson(json, isOfferA);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Offerta ${isOfferA ? "A" : "B"} compilata automaticamente!',
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Non sono riuscito a estrarre i dati. Riprova con una foto pi\u00F9 nitida.'),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.errorMessage ?? 'Errore durante l\'analisi'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isOfferA) {
            _isAnalyzingA = false;
          } else {
            _isAnalyzingB = false;
          }
        });
      }
    }
  }

  void _fillFieldsFromJson(Map<String, dynamic> json, bool isOfferA) {
    setState(() {
      // Azienda
      final azienda = json['azienda']?.toString() ?? '';
      if (azienda.isNotEmpty) {
        if (isOfferA) {
          _aziendaACtrl.text = azienda;
        } else {
          _aziendaBCtrl.text = azienda;
        }
      }

      // RAL
      final ral = json['ral_annua']?.toString() ?? '';
      if (ral.isNotEmpty && ral != 'null') {
        if (isOfferA) {
          _ralACtrl.text = ral;
        } else {
          _ralBCtrl.text = ral;
        }
      }

      // Tipo contratto
      final tipo = (json['tipo_contratto']?.toString() ?? '').toLowerCase();
      if (tipo.contains('indeterminato')) {
        if (isOfferA) {
          _contrattoA = 'Indeterminato';
        } else {
          _contrattoB = 'Indeterminato';
        }
      } else if (tipo.contains('determinato')) {
        if (isOfferA) {
          _contrattoA = 'Determinato';
        } else {
          _contrattoB = 'Determinato';
        }
      } else if (tipo.contains('apprendist')) {
        if (isOfferA) {
          _contrattoA = 'Apprendista';
        } else {
          _contrattoB = 'Apprendista';
        }
      }

      // Mensilita
      final mens = int.tryParse(json['mensilita']?.toString() ?? '');
      if (mens == 13 || mens == 14) {
        if (isOfferA) {
          _mensilitaA = mens!;
        } else {
          _mensilitaB = mens!;
        }
      }

      // Buoni pasto
      final buoni = json['buoni_pasto_valore']?.toString() ?? '';
      if (buoni.isNotEmpty && buoni != 'null') {
        if (isOfferA) {
          _buoniPastoACtrl.text = buoni;
        } else {
          _buoniPastoBCtrl.text = buoni;
        }
      }

      // Smart working
      final sw = int.tryParse(json['smart_working_giorni']?.toString() ?? '');
      if (sw != null && sw >= 0 && sw <= 5) {
        if (isOfferA) {
          _smartWorkingA = sw;
        } else {
          _smartWorkingB = sw;
        }
      }
    });
  }

  void _confronta() {
    final ralA = _p(_ralACtrl.text);
    final ralB = _p(_ralBCtrl.text);
    if (ralA <= 0 || ralB <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci la RAL per entrambe le offerte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _resultA = _calcolaOfferta(
      azienda: _aziendaACtrl.text,
      ral: ralA,
      contratto: _contrattoA,
      mensilita: _mensilitaA,
      buoniPasto: _p(_buoniPastoACtrl.text),
      smartWorking: _smartWorkingA,
      distanza: _p(_distanzaACtrl.text),
      autoAziendale: _autoAziendaleA,
      telefono: _telefonoA,
      assicurazione: _assicurazioneA,
    );

    _resultB = _calcolaOfferta(
      azienda: _aziendaBCtrl.text,
      ral: ralB,
      contratto: _contrattoB,
      mensilita: _mensilitaB,
      buoniPasto: _p(_buoniPastoBCtrl.text),
      smartWorking: _smartWorkingB,
      distanza: _p(_distanzaBCtrl.text),
      autoAziendale: _autoAziendaleB,
      telefono: _telefonoB,
      assicurazione: _assicurazioneB,
    );

    setState(() => _showResult = true);
    _animController.forward(from: 0);
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
            SliverToBoxAdapter(child: _buildInfoBanner()),
            SliverToBoxAdapter(child: _sectionTitle('Offerta A')),
            SliverToBoxAdapter(child: _buildOfferCard(isA: true)),
            SliverToBoxAdapter(child: _sectionTitle('Offerta B')),
            SliverToBoxAdapter(child: _buildOfferCard(isA: false)),
            SliverToBoxAdapter(child: _buildConfrontaButton()),
            if (_showResult && _resultA != null && _resultB != null) ...[
              SliverToBoxAdapter(child: _buildVerdictCard()),
              SliverToBoxAdapter(child: _buildComparisonCard()),
              SliverToBoxAdapter(child: _buildBarChartCard()),
            ],
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
        left: 20,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.compare_arrows,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONFRONTO OFFERTE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Confronta due offerte di lavoro',
                    style: TextStyle(
                        color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
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
        border:
            Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFFA000), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF5D4037), height: 1.4),
                children: [
                  TextSpan(
                      text: 'Confronto reale. ',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                      text:
                          'Calcola IRPEF 2025 reale, INPS, TFR, buoni pasto, costo trasporto e benefit per trovare l\'offerta migliore.'),
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
      child: Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark)),
    );
  }

  // ── Upload banner (AI scan) ──
  Widget _buildUploadBanner(bool isA, Color color) {
    final isAnalyzing = isA ? _isAnalyzingA : _isAnalyzingB;
    final label = isA ? 'A' : 'B';

    if (isAnalyzing) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI sta analizzando l\'offerta $label...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Estrazione dati dal documento',
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showUploadSheet(isA),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carica Contratto/Offerta',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'AI compila i campi automaticamente',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.auto_awesome,
              color: color.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadSheet(bool isOfferA) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Carica Offerta ${isOfferA ? "A" : "B"}',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Scatta una foto o scegli dalla galleria.\nL\'AI estrarra\u0300 i dati automaticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
              const SizedBox(height: 20),
              _sheetUploadOption(
                Icons.camera_alt_rounded,
                'Scatta foto',
                'Fotografa il contratto o la lettera d\'offerta',
                () {
                  Navigator.pop(context);
                  _pickAndAnalyzeOffer(ImageSource.camera, isOfferA);
                },
              ),
              const SizedBox(height: 10),
              _sheetUploadOption(
                Icons.photo_library_rounded,
                'Scegli dalla galleria',
                'Seleziona una foto gia\u0300 presente sul telefono',
                () {
                  Navigator.pop(context);
                  _pickAndAnalyzeOffer(ImageSource.gallery, isOfferA);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetUploadOption(
      IconData icon, String title, String desc, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(desc,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  // ── Offer card ──
  Widget _buildOfferCard({required bool isA}) {
    final aziendaCtrl = isA ? _aziendaACtrl : _aziendaBCtrl;
    final ralCtrl = isA ? _ralACtrl : _ralBCtrl;
    final contratto = isA ? _contrattoA : _contrattoB;
    final mensilita = isA ? _mensilitaA : _mensilitaB;
    final buoniPastoCtrl = isA ? _buoniPastoACtrl : _buoniPastoBCtrl;
    final smartWorking = isA ? _smartWorkingA : _smartWorkingB;
    final distanzaCtrl = isA ? _distanzaACtrl : _distanzaBCtrl;
    final autoAziendale = isA ? _autoAziendaleA : _autoAziendaleB;
    final telefono = isA ? _telefonoA : _telefonoB;
    final assicurazione = isA ? _assicurazioneA : _assicurazioneB;
    final color = isA ? const Color(0xFF1565C0) : const Color(0xFFE65100);
    final label = isA ? 'A' : 'B';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('OFFERTA $label',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // AI Upload banner
          _buildUploadBanner(isA, color),
          const SizedBox(height: 14),

          // Azienda
          _textField(aziendaCtrl, 'Nome azienda'),
          const SizedBox(height: 12),

          // RAL
          _moneyField(ralCtrl, 'RAL - Reddito Annuo Lordo'),
          const SizedBox(height: 12),

          // Tipo contratto
          const Text('Tipo contratto',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium)),
          const SizedBox(height: 8),
          Row(
            children: _tipiContratto.map((tipo) {
              final selected = contratto == tipo;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (isA) {
                      _contrattoA = tipo;
                    } else {
                      _contrattoB = tipo;
                    }
                  }),
                  child: Container(
                    margin: EdgeInsets.only(
                        right: tipo != _tipiContratto.last ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? color : Colors.grey.shade200,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(tipo,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected ? color : AppColors.textMedium)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Mensilita
          Row(
            children: [
              const Expanded(
                child: Text('Mensilit\u00E0',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark)),
              ),
              _mensilitaChip(isA, 13, mensilita, color),
              const SizedBox(width: 8),
              _mensilitaChip(isA, 14, mensilita, color),
            ],
          ),
          const SizedBox(height: 14),

          // Buoni pasto
          _moneyField(buoniPastoCtrl, 'Buoni pasto (\u20AC/giorno, 0 se assenti)'),
          const SizedBox(height: 12),

          // Smart working
          _buildSmartWorkingRow(isA, smartWorking, color),
          const SizedBox(height: 12),

          // Distanza
          _textField(distanzaCtrl, 'Distanza casa-lavoro (km)',
              keyboardType: TextInputType.number, prefix: 'km  '),
          const SizedBox(height: 14),

          // Benefit
          const Text('Benefit',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium)),
          const SizedBox(height: 8),
          _buildBenefitSwitch('Auto aziendale (\u20AC3.000/anno)', autoAziendale,
              (v) {
            setState(() {
              if (isA) {
                _autoAziendaleA = v;
              } else {
                _autoAziendaleB = v;
              }
            });
          }),
          _buildBenefitSwitch('Telefono aziendale (\u20AC600/anno)', telefono,
              (v) {
            setState(() {
              if (isA) {
                _telefonoA = v;
              } else {
                _telefonoB = v;
              }
            });
          }),
          _buildBenefitSwitch(
              'Assicurazione sanitaria (\u20AC1.200/anno)', assicurazione, (v) {
            setState(() {
              if (isA) {
                _assicurazioneA = v;
              } else {
                _assicurazioneB = v;
              }
            });
          }),
        ],
      ),
    );
  }

  Widget _mensilitaChip(bool isA, int value, int current, Color color) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => setState(() {
        if (isA) {
          _mensilitaA = value;
        } else {
          _mensilitaB = value;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text('$value',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? color : AppColors.textMedium)),
      ),
    );
  }

  Widget _buildSmartWorkingRow(bool isA, int value, Color color) {
    return Row(
      children: [
        const Expanded(
          child: Text('Smart working gg/sett.',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark)),
        ),
        _cBtn(Icons.remove, value > 0, () {
          setState(() {
            if (isA) {
              _smartWorkingA--;
            } else {
              _smartWorkingB--;
            }
          });
        }),
        Container(
          width: 36,
          alignment: Alignment.center,
          child: Text('$value',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
        ),
        _cBtn(Icons.add, value < 5, () {
          setState(() {
            if (isA) {
              _smartWorkingA++;
            } else {
              _smartWorkingB++;
            }
          });
        }),
      ],
    );
  }

  Widget _buildBenefitSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark))),
          Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary),
        ],
      ),
    );
  }

  // ── Confronta button ──
  Widget _buildConfrontaButton() {
    return GestureDetector(
      onTap: _confronta,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('CONFRONTA OFFERTE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  // ── Verdict card ──
  Widget _buildVerdictCard() {
    final a = _resultA!;
    final b = _resultB!;
    final diff = (a.totaleValoreReale - b.totaleValoreReale).abs();
    final winnerIsA = a.totaleValoreReale >= b.totaleValoreReale;
    final winnerLabel = winnerIsA ? 'OFFERTA A' : 'OFFERTA B';
    final winnerAzienda = winnerIsA ? a.azienda : b.azienda;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2E7D32),
              const Color(0xFF4CAF50),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, color: Colors.white70, size: 32),
            const SizedBox(height: 8),
            Text('$winnerLabel CONVIENE',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(winnerAzienda,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '+\u20AC ${_fmt.format(diff)}/anno',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'di valore reale in pi\u00F9',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Side by side comparison ──
  Widget _buildComparisonCard() {
    final a = _resultA!;
    final b = _resultB!;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confronto Dettagliato',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 14),
            // Column headers
            Row(
              children: [
                const Expanded(
                    flex: 3,
                    child: Text('Voce',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight))),
                Expanded(
                    flex: 2,
                    child: Text(a.azienda,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1565C0)))),
                Expanded(
                    flex: 2,
                    child: Text(b.azienda,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE65100)))),
              ],
            ),
            const Divider(height: 16),
            _compRow('RAL', a.ral, b.ral, higherIsBetter: true),
            _compRow('Contributi INPS', a.contributiInps, b.contributiInps,
                higherIsBetter: false),
            _compRow('IRPEF Netta', a.irpefNetta, b.irpefNetta,
                higherIsBetter: false),
            _compRow('Netto Annuo', a.nettoAnnuo, b.nettoAnnuo,
                higherIsBetter: true),
            _compRow('Netto Mensile', a.nettoMensile, b.nettoMensile,
                higherIsBetter: true),
            const Divider(height: 12),
            _compRow('TFR Annuo', a.tfrAnnuo, b.tfrAnnuo,
                higherIsBetter: true),
            _compRow('Buoni Pasto/anno', a.buoniPastoAnnuo, b.buoniPastoAnnuo,
                higherIsBetter: true),
            _compRow('Costo Trasporto', a.costoTrasporto, b.costoTrasporto,
                higherIsBetter: false),
            _compRow('Valore Benefit', a.valoreBenefit, b.valoreBenefit,
                higherIsBetter: true),
            const Divider(height: 12),
            _compRow(
                'VALORE REALE', a.totaleValoreReale, b.totaleValoreReale,
                higherIsBetter: true, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _compRow(String label, double valA, double valB,
      {required bool higherIsBetter, bool bold = false}) {
    final bool aWins = higherIsBetter ? valA > valB : valA < valB;
    final bool bWins = higherIsBetter ? valB > valA : valB < valA;
    final bool tie = valA == valB;

    Color colorA = bold ? AppColors.textDark : AppColors.textMedium;
    Color colorB = bold ? AppColors.textDark : AppColors.textMedium;
    if (!tie) {
      if (aWins) {
        colorA = const Color(0xFF2E7D32);
      }
      if (bWins) {
        colorB = const Color(0xFF2E7D32);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textDark)),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                color: aWins && !tie
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '\u20AC${_fmtInt.format(valA)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold || aWins ? FontWeight.w700 : FontWeight.w500,
                  color: colorA,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                color: bWins && !tie
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '\u20AC${_fmtInt.format(valB)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold || bWins ? FontWeight.w700 : FontWeight.w500,
                  color: colorB,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar chart card ──
  Widget _buildBarChartCard() {
    final a = _resultA!;
    final b = _resultB!;
    final maxVal = [
      a.totaleValoreReale,
      b.totaleValoreReale,
      a.nettoAnnuo,
      b.nettoAnnuo,
    ].reduce((a, b) => a > b ? a : b);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confronto Visuale',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 20),
            _barGroup('Netto Annuo', a.nettoAnnuo, b.nettoAnnuo, maxVal),
            const SizedBox(height: 16),
            _barGroup('Buoni Pasto', a.buoniPastoAnnuo, b.buoniPastoAnnuo,
                maxVal),
            const SizedBox(height: 16),
            _barGroup(
                'Benefit', a.valoreBenefit, b.valoreBenefit, maxVal),
            const SizedBox(height: 16),
            _barGroup(
                'Costo Trasporto', a.costoTrasporto, b.costoTrasporto, maxVal),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _barGroup('VALORE REALE TOTALE', a.totaleValoreReale,
                b.totaleValoreReale, maxVal),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(const Color(0xFF1565C0), 'Offerta A'),
                const SizedBox(width: 20),
                _legendDot(const Color(0xFFE65100), 'Offerta B'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _barGroup(
      String label, double valA, double valB, double maxVal) {
    final fracA = maxVal > 0 ? (valA / maxVal).clamp(0.0, 1.0) : 0.0;
    final fracB = maxVal > 0 ? (valB / maxVal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        // Bar A
        Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('A',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1565C0))),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 16,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fracA > 0.02 ? fracA : 0.02,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: Text('\u20AC${_fmtInt.format(valA)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Bar B
        Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('B',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE65100))),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 16,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fracB > 0.02 ? fracB : 0.02,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: Text('\u20AC${_fmtInt.format(valB)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // REUSABLE WIDGETS
  // ─────────────────────────────────────────────
  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 3))
      ],
    );
  }

  Widget _textField(TextEditingController ctrl, String label,
      {TextInputType? keyboardType, String? prefix}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType ?? TextInputType.text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMedium),
        prefixText: prefix,
        prefixStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _moneyField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMedium),
        prefixText: '\u20AC  ',
        prefixStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _cBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? AppColors.primary : Colors.grey.shade400),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RESULT MODEL
// ─────────────────────────────────────────────
class _OfferResult {
  final String azienda;
  final double ral;
  final double contributiInps;
  final double irpefLorda;
  final double detrazioni;
  final double irpefNetta;
  final double addizionali;
  final double nettoAnnuo;
  final double nettoMensile;
  final double tfrAnnuo;
  final double buoniPastoAnnuo;
  final double costoTrasporto;
  final double valoreBenefit;
  final double totaleValoreReale;

  const _OfferResult({
    required this.azienda,
    required this.ral,
    required this.contributiInps,
    required this.irpefLorda,
    required this.detrazioni,
    required this.irpefNetta,
    required this.addizionali,
    required this.nettoAnnuo,
    required this.nettoMensile,
    required this.tfrAnnuo,
    required this.buoniPastoAnnuo,
    required this.costoTrasporto,
    required this.valoreBenefit,
    required this.totaleValoreReale,
  });
}
