import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/language_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';
import 'busta_paga_translations.dart';

// ---------------------------------------------------------------------------
// BUSTA PAGA SPIEGATA - Analisi AI + Esempio Educativo
// ---------------------------------------------------------------------------

class BustaPagaScreen extends StatefulWidget {
  const BustaPagaScreen({super.key});

  @override
  State<BustaPagaScreen> createState() => _BustaPagaScreenState();
}

class _BustaPagaScreenState extends State<BustaPagaScreen> {
  final Set<String> _expanded = {};

  // ── AI analysis state ──
  File? _selectedFile;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aiData;
  String? _aiAnalysis;
  String? _errorMessage;
  bool _showExample = false;
  String? _ocrDebugText;

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  Future<void> _pickPdf() async {
    final file = await pickPdfFile();
    if (file == null) return;

    setState(() {
      _selectedFile = file;
      _isAnalyzing = true;
      _errorMessage = null;
      _aiData = null;
      _aiAnalysis = null;
      _showExample = false;
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Sei un consulente del lavoro italiano esperto. Guarda questa busta paga e leggi i valori ESATTI.

COME TROVARE OGNI CAMPO (le buste paga hanno formati diversi):

NETTO (cercalo per primo):
- Cerca "NETTO A PAGARE" o "NETTO BUSTA" o "NETTO IN BUSTA"

LORDO (stipendio lordo EFFETTIVO del mese):
- Cerca "IMPONIBILE LORDO" o "TOTALE LORDO" o "TOTALE COMPETENZE"
- Se c'è sia "totale" che "imponibile lordo", usa "IMPONIBILE LORDO"
- VERIFICA: il lordo deve essere maggiore del netto ma NON il doppio. Se è il doppio, stai leggendo il campo sbagliato.

INPS: cerca "IMPONIBILE INPS" con percentuale e risultato, oppure "TOT. CONTR. SOC."
IRPEF: cerca "IMPOSTA PAGATA" o "IRPEF PAGATA" (NON "IMPOSTA LORDA")
ADDIZIONALI: cerca "ADDIZ. REGIONALE" e "ADDIZ. COMUNALE"

IMPORTANTE: leggi numeri ESATTI, NON calcolare. Valori MENSILI. Importi con €.

Restituisci SOLO JSON valido (senza markdown, senza backtick):
{
  "azienda": "nome azienda",
  "dipendente": "nome e cognome",
  "qualifica": "qualifica/mansione",
  "livello_ccnl": "livello contratto",
  "periodo_riferimento": "mese anno",
  "ore_lavorate": "numero",
  "stipendio_lordo": "importo",
  "paga_base": "importo orario o mensile",
  "contingenza": "importo o null",
  "superminimo": "importo o null",
  "straordinario": "importo o null",
  "scatti_anzianita": "importo o null",
  "tredicesima_rateo": "importo o null",
  "altre_competenze": "importo o null",
  "contributi_inps": "importo",
  "irpef": "importo",
  "addizionale_regionale": "importo o null",
  "addizionale_comunale": "importo o null",
  "detrazioni_lavoro": "importo o null",
  "stipendio_netto": "importo",
  "tfr_maturato": "importo o null",
  "ferie_maturate": "giorni o ore",
  "ferie_godute": "giorni o ore",
  "ferie_residue": "giorni o ore",
  "permessi_maturati": "ore o null",
  "permessi_goduti": "ore o null",
  "permessi_residui": "ore o null",
  "analisi": "Analisi breve: contributi, netto vs lordo, TFR, ferie residue, consigli. 3-5 frasi."
}
Se un campo non è leggibile, metti null.''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        setState(() {
          _aiData = parsed;
          _aiAnalysis = parsed['analisi'] as String?;
          _ocrDebugText = response.ocrText;
          _isAnalyzing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Impossibile leggere i dati dal documento. Riprova con una foto più nitida.';
          _ocrDebugText = response.ocrText;
          _isAnalyzing = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = response.errorMessage;
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return;

    setState(() {
      _selectedFile = file;
      _isAnalyzing = true;
      _errorMessage = null;
      _aiData = null;
      _aiAnalysis = null;
      _showExample = false;
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: '''Sei un consulente del lavoro italiano esperto. Guarda questa busta paga e leggi i valori ESATTI.

COME TROVARE OGNI CAMPO (le buste paga hanno formati diversi):

NETTO (cercalo per primo):
- Cerca "NETTO A PAGARE" o "NETTO BUSTA" o "NETTO IN BUSTA"

LORDO (stipendio lordo EFFETTIVO del mese):
- Cerca "IMPONIBILE LORDO" o "TOTALE LORDO" o "TOTALE COMPETENZE"
- Se c'è sia "totale" che "imponibile lordo", usa "IMPONIBILE LORDO"
- VERIFICA: il lordo deve essere maggiore del netto ma NON il doppio. Se è il doppio, stai leggendo il campo sbagliato.

INPS: cerca "IMPONIBILE INPS" con percentuale e risultato, oppure "TOT. CONTR. SOC."
IRPEF: cerca "IMPOSTA PAGATA" o "IRPEF PAGATA" (NON "IMPOSTA LORDA")
ADDIZIONALI: cerca "ADDIZ. REGIONALE" e "ADDIZ. COMUNALE"

IMPORTANTE: leggi numeri ESATTI, NON calcolare. Valori MENSILI. Importi con €.

Restituisci SOLO JSON valido (senza markdown, senza backtick):
{
  "azienda": "nome azienda",
  "dipendente": "nome e cognome",
  "qualifica": "qualifica/mansione",
  "livello_ccnl": "livello contratto",
  "periodo_riferimento": "mese anno",
  "ore_lavorate": "numero",
  "stipendio_lordo": "importo",
  "paga_base": "importo orario o mensile",
  "contingenza": "importo o null",
  "superminimo": "importo o null",
  "straordinario": "importo o null",
  "scatti_anzianita": "importo o null",
  "tredicesima_rateo": "importo o null",
  "altre_competenze": "importo o null",
  "contributi_inps": "importo",
  "irpef": "importo",
  "addizionale_regionale": "importo o null",
  "addizionale_comunale": "importo o null",
  "detrazioni_lavoro": "importo o null",
  "stipendio_netto": "importo",
  "tfr_maturato": "importo o null",
  "ferie_maturate": "giorni o ore",
  "ferie_godute": "giorni o ore",
  "ferie_residue": "giorni o ore",
  "permessi_maturati": "ore o null",
  "permessi_goduti": "ore o null",
  "permessi_residui": "ore o null",
  "analisi": "Analisi breve: contributi, netto vs lordo, TFR, ferie residue, consigli. 3-5 frasi."
}
Se un campo non è leggibile, metti null.''',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        setState(() {
          _aiData = parsed;
          _aiAnalysis = parsed['analisi'] as String?;
          _ocrDebugText = response.ocrText;
          _isAnalyzing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Impossibile leggere i dati dal documento. Riprova con una foto più nitida.';
          _ocrDebugText = response.ocrText;
          _isAnalyzing = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = response.errorMessage;
        _isAnalyzing = false;
      });
    }
  }

  void _resetAnalysis() {
    setState(() {
      _selectedFile = null;
      _aiData = null;
      _aiAnalysis = null;
      _errorMessage = null;
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>().currentCode;
    final t = getBustaTranslation(lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, t)),

          // ── AI Upload Section ──
          if (_aiData == null && !_showExample) ...[
            SliverToBoxAdapter(child: _buildAiUploadSection()),
            if (_errorMessage != null) SliverToBoxAdapter(child: _buildError()),
            SliverToBoxAdapter(child: _buildOrDivider()),
            SliverToBoxAdapter(child: _buildExampleButton()),
          ],

          // ── AI Results ──
          if (_aiData != null) ...[
            SliverToBoxAdapter(child: _buildAiBustaPagaTitle()),
            SliverToBoxAdapter(child: _buildAiAnalysisBanner()),
            SliverToBoxAdapter(child: _sectionHeader('INTESTAZIONE', Icons.badge, const Color(0xFF5C6BC0))),
            SliverToBoxAdapter(child: _buildAiSection(_aiIntestazione())),
            SliverToBoxAdapter(child: _sectionHeader('COMPETENZE (LORDO)', Icons.trending_up, const Color(0xFF43A047))),
            SliverToBoxAdapter(child: _buildAiSection(_aiCompetenze())),
            SliverToBoxAdapter(child: _sectionHeader('TRATTENUTE', Icons.trending_down, const Color(0xFFE53935))),
            SliverToBoxAdapter(child: _buildAiSection(_aiTrattenute())),
            SliverToBoxAdapter(child: _sectionHeader('NETTO IN BUSTA', Icons.account_balance_wallet, const Color(0xFF1565C0))),
            SliverToBoxAdapter(child: _buildAiSection(_aiNetto())),
            SliverToBoxAdapter(child: _sectionHeader('FERIE E PERMESSI', Icons.event_available, const Color(0xFF00897B))),
            SliverToBoxAdapter(child: _buildAiSection(_aiFerie())),
            SliverToBoxAdapter(child: _buildResetButton()),
            if (_ocrDebugText != null)
              SliverToBoxAdapter(child: _buildOcrDebugButton()),
          ],

          // ── Static Example (original behavior) ──
          if (_showExample) ...[
            SliverToBoxAdapter(child: _buildInfoBanner(t)),
            SliverToBoxAdapter(child: _buildStaticBustaPagaTitle(t)),
            SliverToBoxAdapter(child: _sectionHeader(t.sectionHeader, Icons.badge, const Color(0xFF5C6BC0))),
            SliverToBoxAdapter(child: _buildStaticSection(_intestazioneIds, t)),
            SliverToBoxAdapter(child: _sectionHeader(t.sectionEarnings, Icons.trending_up, const Color(0xFF43A047))),
            SliverToBoxAdapter(child: _buildStaticSection(_competenzeIds, t)),
            SliverToBoxAdapter(child: _sectionHeader(t.sectionDeductions, Icons.trending_down, const Color(0xFFE53935))),
            SliverToBoxAdapter(child: _buildStaticSection(_trattenutIds, t)),
            SliverToBoxAdapter(child: _sectionHeader(t.sectionNet, Icons.account_balance_wallet, const Color(0xFF1565C0))),
            SliverToBoxAdapter(child: _buildStaticSection(_nettoIds, t)),
            SliverToBoxAdapter(child: _buildFooterTip(t)),
            SliverToBoxAdapter(child: _buildResetButton()),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // AI UPLOAD SECTION
  // ─────────────────────────────────────────────
  Widget _buildAiUploadSection() {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DocumentUploadWidget(
        label: 'Carica la tua Busta Paga',
        subtitle: s.payslipPickerHint,
        icon: Icons.receipt_long_rounded,
        selectedFile: _selectedFile,
        isLoading: _isAnalyzing,
        onPickCamera: () => _pickAndAnalyze(ImageSource.camera),
        onPickGallery: () => _pickAndAnalyze(ImageSource.gallery),
        onPickPdf: _pickPdf,
        onRemove: _resetAnalysis,
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF44336).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFFB71C1C), height: 1.3))),
      ]),
    );
  }

  Widget _buildOrDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('oppure', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ]),
    );
  }

  Widget _buildExampleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => setState(() => _showExample = true),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
            color: AppColors.primary.withValues(alpha: 0.04),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.visibility, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text('Vedi esempio educativo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ]),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: _resetAnalysis,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_photo_alternate, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Analizza un\'altra busta paga', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    );
  }

  Widget _buildOcrDebugButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) => Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Testo OCR (Google Vision)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _ocrDebugText ?? 'Nessun testo OCR disponibile',
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.bug_report, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Text('Vedi testo OCR (debug)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange)),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // AI RESULTS WIDGETS
  // ─────────────────────────────────────────────
  Widget _buildAiBustaPagaTitle() {
    final d = _aiData!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D2D5E), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.business, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
            (d['azienda'] ?? 'Azienda').toString().toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.smart_toy, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Text('AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dipendente', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text(d['dipendente'] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Periodo', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text(d['periodo_riferimento'] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAiAnalysisBanner() {
    if (_aiAnalysis == null || _aiAnalysis!.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF1565C0).withValues(alpha: 0.08), const Color(0xFF42A5F5).withValues(alpha: 0.08)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Text('Analisi AI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 10),
        Text(_aiAnalysis!, style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.5)),
      ]),
    );
  }

  // ── AI data extractors ──
  List<_AiRowData> _aiIntestazione() {
    final d = _aiData!;
    return [
      if (d['qualifica'] != null) _AiRowData('Qualifica / Mansione', d['qualifica']),
      if (d['livello_ccnl'] != null) _AiRowData('Livello CCNL', d['livello_ccnl']),
      if (d['ore_lavorate'] != null) _AiRowData('Ore lavorate', d['ore_lavorate']),
    ];
  }

  List<_AiRowData> _aiCompetenze() {
    final d = _aiData!;
    return [
      if (d['paga_base'] != null) _AiRowData('Paga base', d['paga_base']),
      if (d['contingenza'] != null) _AiRowData('Contingenza', d['contingenza']),
      if (d['superminimo'] != null) _AiRowData('Superminimo', d['superminimo']),
      if (d['straordinario'] != null) _AiRowData('Straordinario', d['straordinario']),
      if (d['scatti_anzianita'] != null) _AiRowData('Scatti anzianità', d['scatti_anzianita']),
      if (d['tredicesima_rateo'] != null) _AiRowData('Rateo 13ª', d['tredicesima_rateo']),
      if (d['altre_competenze'] != null) _AiRowData('Altre competenze', d['altre_competenze']),
      if (d['stipendio_lordo'] != null) _AiRowData('TOTALE LORDO', d['stipendio_lordo'], isBold: true),
    ];
  }

  List<_AiRowData> _aiTrattenute() {
    final d = _aiData!;
    return [
      if (d['contributi_inps'] != null) _AiRowData('Contributi INPS', d['contributi_inps'], isNeg: true),
      if (d['irpef'] != null) _AiRowData('IRPEF', d['irpef'], isNeg: true),
      if (d['addizionale_regionale'] != null) _AiRowData('Addizionale Regionale', d['addizionale_regionale'], isNeg: true),
      if (d['addizionale_comunale'] != null) _AiRowData('Addizionale Comunale', d['addizionale_comunale'], isNeg: true),
      if (d['detrazioni_lavoro'] != null) _AiRowData('Detrazioni lavoro', d['detrazioni_lavoro']),
    ];
  }

  List<_AiRowData> _aiNetto() {
    final d = _aiData!;
    return [
      if (d['stipendio_netto'] != null) _AiRowData('NETTO IN BUSTA', d['stipendio_netto'], isBold: true),
      if (d['tfr_maturato'] != null) _AiRowData('TFR maturato', d['tfr_maturato']),
    ];
  }

  List<_AiRowData> _aiFerie() {
    final d = _aiData!;
    return [
      if (d['ferie_maturate'] != null) _AiRowData('Ferie maturate', d['ferie_maturate']),
      if (d['ferie_godute'] != null) _AiRowData('Ferie godute', d['ferie_godute']),
      if (d['ferie_residue'] != null) _AiRowData('Ferie residue', d['ferie_residue'], isBold: true),
      if (d['permessi_maturati'] != null) _AiRowData('Permessi maturati', d['permessi_maturati']),
      if (d['permessi_goduti'] != null) _AiRowData('Permessi goduti', d['permessi_goduti']),
      if (d['permessi_residui'] != null) _AiRowData('Permessi residui', d['permessi_residui']),
    ];
  }

  Widget _buildAiSection(List<_AiRowData> items) {
    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text('Dati non trovati nel documento', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Expanded(child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: item.isBold ? FontWeight.w700 : FontWeight.w500,
                    color: item.isBold ? AppColors.primary : AppColors.textDark,
                  ),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isNeg
                        ? const Color(0xFFFFEBEE)
                        : item.isBold
                            ? const Color(0xFFE3F2FD)
                            : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.value.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: item.isNeg
                          ? const Color(0xFFE53935)
                          : item.isBold
                              ? AppColors.primary
                              : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ]),
            ),
            if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
          ]);
        }).toList(),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 3))],
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, BustaT t) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 14),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(children: [
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
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 1),
          Text(t.subtitle, style: const TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
        ])),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showLanguagePicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(context.watch<LanguageService>().current.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              const Icon(Icons.translate, color: Colors.white, size: 16),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final langService = context.read<LanguageService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.translate, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Scegli Lingua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: supportedLanguages.length,
              itemBuilder: (ctx, i) {
                final lang = supportedLanguages[i];
                final isSelected = lang.code == langService.currentCode;
                return ListTile(
                  leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(lang.name, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textDark)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22) : null,
                  onTap: () { langService.setLanguage(lang.code); Navigator.pop(ctx); },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION HEADER (shared)
  // ─────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5))),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  // STATIC EXAMPLE (original behavior preserved)
  // ─────────────────────────────────────────────
  Widget _buildInfoBanner(BustaT t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.school, color: AppColors.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: RichText(text: TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF1A237E), height: 1.4), children: [
          TextSpan(text: '${t.infoBold} ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: t.infoText),
        ]))),
      ]),
    );
  }

  Widget _buildStaticBustaPagaTitle(BustaT t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D2D5E), Color(0xFF1565C0)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        const Row(children: [
          Icon(Icons.business, color: Colors.white70, size: 18),
          SizedBox(width: 8),
          Text('AZIENDA ESEMPIO S.R.L.', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.employee, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              const Text('Mario Rossi', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('CCNL Commercio', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text('4\u00b0 Livello', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStaticSection(List<_BustaItemData> items, BustaT t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final translated = t.items[item.id];
          final voce = translated?.voce ?? item.id;
          final spiegazione = translated?.spiegazione ?? '';
          final isExp = _expanded.contains(item.id);
          final isLast = idx == items.length - 1;

          return Column(children: [
            InkWell(
              onTap: () => _toggle(item.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Expanded(child: Row(children: [
                    Icon(isExp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: AppColors.textLight),
                    const SizedBox(width: 8),
                    Expanded(child: Text(voce, style: TextStyle(fontSize: 13, fontWeight: isExp ? FontWeight.w700 : FontWeight.w500, color: isExp ? AppColors.primary : AppColors.textDark))),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: item.isNeg ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: Text(item.importo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: item.isNeg ? const Color(0xFFE53935) : const Color(0xFF2E7D32))),
                  ),
                ]),
              ),
            ),
            if (isExp)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(t.explanationLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 8),
                  Text(spiegazione, style: const TextStyle(fontSize: 13, color: Color(0xFF1A237E), height: 1.5)),
                ]),
              ),
            if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildFooterTip(BustaT t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.tips_and_updates, color: Color(0xFFFFA000), size: 20),
          const SizedBox(width: 8),
          Text(t.tipTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF5D4037))),
        ]),
        const SizedBox(height: 8),
        RichText(text: TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037), height: 1.5), children: [
          TextSpan(text: '${t.tipBold} ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: t.tipText),
        ])),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  // STATIC DATA (preserved from original)
  // ─────────────────────────────────────────────
  static const _intestazioneIds = [
    _BustaItemData('periodo', 'Gen 2025', false),
    _BustaItemData('livello', '4\u00b0 Liv.', false),
    _BustaItemData('ore', '168 ore', false),
  ];
  static const _competenzeIds = [
    _BustaItemData('paga_base', '\u20ac 1.618,75', false),
    _BustaItemData('contingenza', '\u20ac 524,22', false),
    _BustaItemData('superminimo', '\u20ac 150,00', false),
    _BustaItemData('straordinario', '\u20ac 87,50', false),
    _BustaItemData('scatti', '\u20ac 25,46', false),
    _BustaItemData('tredicesima', '\u20ac 194,95', false),
    _BustaItemData('quattordicesima', '\u20ac 194,95', false),
  ];
  static const _trattenutIds = [
    _BustaItemData('inps', '- \u20ac 214,99', true),
    _BustaItemData('irpef', '- \u20ac 356,00', true),
    _BustaItemData('addizionale_reg', '- \u20ac 35,00', true),
    _BustaItemData('addizionale_com', '- \u20ac 15,00', true),
    _BustaItemData('detrazioni', '+ \u20ac 155,00', false),
  ];
  static const _nettoIds = [
    _BustaItemData('netto', '\u20ac 1.680,38', false),
    _BustaItemData('tfr', '\u20ac 173,29', false),
  ];
}

class _BustaItemData {
  final String id;
  final String importo;
  final bool isNeg;
  const _BustaItemData(this.id, this.importo, this.isNeg);
}

class _AiRowData {
  final String label;
  final dynamic value;
  final bool isNeg;
  final bool isBold;
  const _AiRowData(this.label, this.value, {this.isNeg = false, this.isBold = false});
}
