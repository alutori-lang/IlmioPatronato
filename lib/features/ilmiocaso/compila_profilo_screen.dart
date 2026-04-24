import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../core/services/isee_parser_service.dart';
import '../../core/services/profilo_utente_service.dart';
import 'risultati_diritti_screen.dart';

// ---------------------------------------------------------------------------
// Flusso "Il Mio Caso" semplificato:
// Step 0 — Carica ISEE (AI compila automaticamente età, figli, stato civile, disabilità, ISEE)
// Step 1 — Domande rapide a tap (no tastiera): sesso, cittadinanza, anni Italia,
//          situazione lavoro, fascia reddito, affitto, merito, (disabilità se non rilevata)
// Step 2 — Risultati (screen separata)
// ---------------------------------------------------------------------------

class CompilaProfiloScreen extends StatefulWidget {
  final ProfiloUtenteService service;
  const CompilaProfiloScreen({super.key, required this.service});

  @override
  State<CompilaProfiloScreen> createState() => _CompilaProfiloScreenState();
}

class _CompilaProfiloScreenState extends State<CompilaProfiloScreen> {
  int _step = 0;

  // ── Stato ISEE ──
  bool _parsingIsee = false;
  IseeParsed? _iseeImported;
  bool _disabilitaRilevataAI = false;

  // ── Dati dalle risposte ──
  String _sesso = '';
  String _cittadinanza = '';
  String _anniItaliaBand = ''; // '0-4', '5-9', '10+'
  String _situazioneLavoro = '';
  String _fasciaReddito = '';
  bool? _inAffitto;
  bool? _merito100;
  bool? _disabilitaConfermata; // null = non chiesto / non noto

  @override
  void initState() {
    super.initState();
    final p = widget.service.profilo;
    if (p != null && p.isee > 0) {
      // Pre-carica dati precedenti se già completato una volta
      _sesso = p.sesso;
      _cittadinanza = p.cittadinanza;
      _situazioneLavoro = p.situazioneLavoro;
      _fasciaReddito = p.fasciaReddito;
      _inAffitto = p.inAffitto;
      _merito100 = p.merito100;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _step == 0 ? 'Il Mio Caso' : 'Qualche info in più',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              background: Container(decoration: const BoxDecoration(gradient: AppColors.headerGradient)),
            ),
            backgroundColor: AppColors.primaryDark,
          ),
          SliverToBoxAdapter(child: _buildProgressBar()),
          SliverToBoxAdapter(child: _step == 0 ? _buildStepIsee() : _buildStepDomande()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final pct = _step == 0 ? 0.2 : 0.7;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(children: [
            Text('Passo ${_step + 1} di 2',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
            const Spacer(),
            Text('${(pct * 100).toInt()}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 0 — ISEE UPLOAD
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStepIsee() {
    final imported = _iseeImported;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PASSO 1',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        SizedBox(height: 2),
                        Text('Carica il tuo ISEE',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(
                  'L\'AI legge la tua attestazione ISEE (foto o PDF) e compila automaticamente: valore ISEE, età, figli, stato civile, disabilità.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 18),
                if (_parsingIsee) ...[
                  const Row(children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                    SizedBox(width: 14),
                    Text('Leggo l\'ISEE…',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ]),
                ] else if (imported != null) ...[
                  _iseePreviewLine('Valore ISEE', imported.isee != null ? '€ ${imported.isee!.toStringAsFixed(0)}' : 'non letto'),
                  _iseePreviewLine('Età richiedente', imported.etaRichiedente != null ? '${imported.etaRichiedente} anni' : 'non letta'),
                  _iseePreviewLine('Figli',
                      '${imported.numeroFigli ?? 0}${imported.etaFigli.isEmpty ? '' : ' (${imported.etaFigli.join(", ")} anni)'}'),
                  _iseePreviewLine('Stato civile', imported.statoFamiliare ?? 'non letto'),
                  _iseePreviewLine('Disabilità', imported.hasDisabilita ? 'Sì (rilevata)' : 'Non rilevata'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _startUpload,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Ricarica', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _step = 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0D47A1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Continua',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ]),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0D47A1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.upload_file, size: 22),
                      label: const Text('CARICA ISEE (foto o PDF)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.4)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (imported == null)
            GestureDetector(
              onTap: () => setState(() {
                _iseeImported = const IseeParsed(); // profilo vuoto: nessun dato ISEE
                _step = 1;
              }),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(children: [
                  Icon(Icons.skip_next, color: AppColors.textMedium, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Non ho l\'ISEE — continua senza',
                      style: TextStyle(fontSize: 13, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textLight),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iseePreviewLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 15),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 1 — DOMANDE RAPIDE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStepDomande() {
    final eta = _iseeImported?.etaRichiedente ?? 0;
    final mostraMerito = eta == 18 || eta == 19;
    final mostraDisabilita = !_disabilitaRilevataAI && !(_iseeImported?.hasDisabilita ?? false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _domanda('1. Sesso', [
            _opt('Uomo', _sesso == 'M', () => setState(() => _sesso = 'M'), icona: Icons.male),
            _opt('Donna', _sesso == 'F', () => setState(() => _sesso = 'F'), icona: Icons.female),
          ]),
          _domanda('2. Cittadinanza', [
            _opt('Italiana', _cittadinanza == 'italiana', () => setState(() {
              _cittadinanza = 'italiana';
              _anniItaliaBand = '10+';
            }), icona: Icons.flag),
            _opt('UE', _cittadinanza == 'ue', () => setState(() {
              _cittadinanza = 'ue';
              _anniItaliaBand = '';
            }), icona: Icons.public),
            _opt('Extra-UE', _cittadinanza == 'extraue', () => setState(() => _cittadinanza = 'extraue'), icona: Icons.language),
          ]),
          if (_cittadinanza == 'extraue' || _cittadinanza == 'ue')
            _domanda('3. Da quanti anni vivi in Italia?', [
              _opt('0-4 anni', _anniItaliaBand == '0-4', () => setState(() => _anniItaliaBand = '0-4')),
              _opt('5-9 anni', _anniItaliaBand == '5-9', () => setState(() => _anniItaliaBand = '5-9')),
              _opt('10+ anni', _anniItaliaBand == '10+', () => setState(() => _anniItaliaBand = '10+')),
            ]),
          _domanda('${_cittadinanza == 'extraue' || _cittadinanza == 'ue' ? '4' : '3'}. Situazione lavorativa', [
            _opt('Dipendente', _situazioneLavoro == 'dipendente', () => setState(() => _situazioneLavoro = 'dipendente'), icona: Icons.work),
            _opt('Co.co.co.', _situazioneLavoro == 'cococo', () => setState(() => _situazioneLavoro = 'cococo'), icona: Icons.assignment_ind),
            _opt('Partita IVA', _situazioneLavoro == 'partita_iva', () => setState(() => _situazioneLavoro = 'partita_iva'), icona: Icons.badge),
            _opt('Disoccupato/a', _situazioneLavoro == 'disoccupato', () => setState(() => _situazioneLavoro = 'disoccupato'), icona: Icons.work_off),
            _opt('Pensionato/a', _situazioneLavoro == 'pensionato', () => setState(() => _situazioneLavoro = 'pensionato'), icona: Icons.elderly),
            _opt('Studente', _situazioneLavoro == 'studente', () => setState(() => _situazioneLavoro = 'studente'), icona: Icons.school),
          ]),
          _domanda('Reddito personale annuale LORDO (diverso dall\'ISEE)', [
            _opt('Meno di 8.000 €', _fasciaReddito == '<8k', () => setState(() => _fasciaReddito = '<8k')),
            _opt('8.000 – 15.000 €', _fasciaReddito == '8-15k', () => setState(() => _fasciaReddito = '8-15k')),
            _opt('15.000 – 28.000 €', _fasciaReddito == '15-28k', () => setState(() => _fasciaReddito = '15-28k')),
            _opt('28.000 – 50.000 €', _fasciaReddito == '28-50k', () => setState(() => _fasciaReddito = '28-50k')),
            _opt('Oltre 50.000 €', _fasciaReddito == '>50k', () => setState(() => _fasciaReddito = '>50k')),
          ]),
          _domanda('Vivi in affitto?', [
            _opt('Sì', _inAffitto == true, () => setState(() => _inAffitto = true), icona: Icons.home),
            _opt('No (casa di proprietà o altro)', _inAffitto == false, () => setState(() => _inAffitto = false), icona: Icons.house),
          ]),
          if (mostraMerito)
            _domanda('Hai preso 100/100 al diploma?', [
              _opt('Sì', _merito100 == true, () => setState(() => _merito100 = true), icona: Icons.star),
              _opt('No', _merito100 == false, () => setState(() => _merito100 = false)),
            ]),
          if (mostraDisabilita)
            _domanda('Hai una disabilità riconosciuta (invalidità civile)?', [
              _opt('Sì', _disabilitaConfermata == true, () => setState(() => _disabilitaConfermata = true), icona: Icons.accessible),
              _opt('No', _disabilitaConfermata == false, () => setState(() => _disabilitaConfermata = false)),
            ]),
          const SizedBox(height: 24),
          _buildBottoniFinali(),
        ],
      ),
    );
  }

  Widget _domanda(String titolo, List<Widget> opzioni) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titolo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: opzioni),
        ],
      ),
    );
  }

  Widget _opt(String label, bool selected, VoidCallback onTap, {IconData? icona}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icona != null) ...[
              Icon(icona, size: 16, color: selected ? Colors.white : AppColors.textMedium),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textDark,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottoniFinali() {
    final pronto = _isFormCompleto();
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _step = 0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Text('Indietro',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: pronto ? _salvaEVediRisultati : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: pronto ? AppColors.buttonGradient : null,
              color: pronto ? null : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(14),
              boxShadow: pronto
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Center(
              child: Text(
                pronto ? 'SCOPRI I TUOI DIRITTI' : 'Completa le risposte',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: pronto ? Colors.white : Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  bool _isFormCompleto() {
    if (_sesso.isEmpty) return false;
    if (_cittadinanza.isEmpty) return false;
    if ((_cittadinanza == 'extraue' || _cittadinanza == 'ue') && _anniItaliaBand.isEmpty) return false;
    if (_situazioneLavoro.isEmpty) return false;
    if (_fasciaReddito.isEmpty) return false;
    if (_inAffitto == null) return false;
    final eta = _iseeImported?.etaRichiedente ?? 0;
    if ((eta == 18 || eta == 19) && _merito100 == null) return false;
    final mostraDisabilita = !_disabilitaRilevataAI && !(_iseeImported?.hasDisabilita ?? false);
    if (mostraDisabilita && _disabilitaConfermata == null) return false;
    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UPLOAD ISEE
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _startUpload() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).padding.bottom + 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            const Text('Come vuoi caricare l\'ISEE?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 16),
            _sourceTile(ctx, Icons.camera_alt, 'Scatta foto', 'camera'),
            _sourceTile(ctx, Icons.image, 'Scegli dalla galleria', 'gallery'),
            _sourceTile(ctx, Icons.picture_as_pdf, 'Carica PDF', 'pdf'),
          ],
        ),
      ),
    );
    if (source == null) return;

    File? file;
    try {
      if (source == 'pdf') {
        final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
        final path = res?.files.firstOrNull?.path;
        if (path != null) file = File(path);
      } else {
        final picker = ImagePicker();
        final x = await picker.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 92,
        );
        if (x != null) file = File(x.path);
      }
    } catch (e) {
      _showError('Errore selezione file: $e');
      return;
    }
    if (file == null) return;
    await _runParse(file);
  }

  Widget _sourceTile(BuildContext ctx, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(ctx, value),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _runParse(File file) async {
    setState(() => _parsingIsee = true);
    final res = await IseeParserService().parse(file);
    if (!mounted) return;
    if (!res.ok) {
      setState(() => _parsingIsee = false);
      _showError(res.error ?? 'Errore lettura ISEE');
      return;
    }
    setState(() {
      _iseeImported = res.data;
      _parsingIsee = false;
      _disabilitaRilevataAI = res.data!.hasDisabilita;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ ISEE letto. I dati del nucleo sono stati compilati.'),
        backgroundColor: AppColors.iconGreen,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 7),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SALVA & VAI A RISULTATI
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _salvaEVediRisultati() async {
    final iseeData = _iseeImported;
    final eta = iseeData?.etaRichiedente ?? 0;

    // Anni in Italia → numero approssimato dalla band
    int anniItalia;
    switch (_anniItaliaBand) {
      case '0-4': anniItalia = 2; break;
      case '5-9': anniItalia = 7; break;
      case '10+': anniItalia = 12; break;
      default: anniItalia = _cittadinanza == 'italiana' ? eta : 0;
    }

    // Disabilità: priorità al flag AI, poi alla conferma utente
    final disabilita = (iseeData?.hasDisabilita ?? false) ||
        _disabilitaRilevataAI ||
        (_disabilitaConfermata ?? false);

    final profilo = ProfiloUtente(
      isee: iseeData?.isee ?? 0,
      eta: eta,
      numeriFigli: iseeData?.numeroFigli ?? 0,
      etaFigli: iseeData?.etaFigli ?? const [],
      statoFamiliare: iseeData?.statoFamiliare ?? 'single',
      disabilita: disabilita,
      sesso: _sesso,
      cittadinanza: _cittadinanza,
      anniInItalia: anniItalia,
      situazioneLavoro: _situazioneLavoro,
      fasciaReddito: _fasciaReddito,
      inAffitto: _inAffitto ?? false,
      merito100: _merito100 ?? false,
      // Legacy mirror
      lavora: _situazioneLavoro != 'disoccupato' && _situazioneLavoro != 'studente' && _situazioneLavoro != 'pensionato',
      tipoContratto: _situazioneLavoro == 'dipendente'
          ? 'indeterminato'
          : _situazioneLavoro == 'cococo'
              ? 'cococo'
              : _situazioneLavoro == 'partita_iva'
                  ? 'autonomo'
                  : 'disoccupato',
      tipoPermesso: _cittadinanza == 'italiana'
          ? 'cittadino_italiano'
          : _cittadinanza == 'ue'
              ? 'cittadino_ue'
              : anniItalia >= 5
                  ? 'lungo_soggiornante'
                  : 'altro',
    );

    await widget.service.save(profilo);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => RisultatiDirittiScreen(profilo: profilo)),
    );
  }
}
