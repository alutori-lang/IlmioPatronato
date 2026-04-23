import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../core/services/isee_parser_service.dart';
import '../../core/services/profilo_utente_service.dart';
import 'risultati_diritti_screen.dart';

class CompilaProfiloScreen extends StatefulWidget {
  final ProfiloUtenteService service;
  const CompilaProfiloScreen({super.key, required this.service});

  @override
  State<CompilaProfiloScreen> createState() => _CompilaProfiloScreenState();
}

class _CompilaProfiloScreenState extends State<CompilaProfiloScreen> {
  int _step = 0;

  // Dati
  String _nazionalita = '';
  bool _isCittadinoUE = false;
  bool _isCittadinoIT = false;
  String _tipoPermesso = '';
  String _scadenzaPermesso = '';
  int _anniInItalia = 0;
  int _eta = 0;
  String _statoFamiliare = 'single';
  int _numeriFigli = 0;
  List<int> _etaFigli = [];
  bool _lavora = false;
  String _tipoContratto = 'disoccupato';
  double _isee = 0;
  String _citta = '';
  bool _disabilita = false;

  bool _parsingIsee = false;
  IseeParsed? _iseeImported;

  final _nazionalitaCtrl = TextEditingController();
  final _etaCtrl = TextEditingController();
  final _anniCtrl = TextEditingController();
  final _figliEtaCtrl = TextEditingController();
  final _iseeCtrl = TextEditingController();
  final _cittaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.service.profilo;
    if (p != null) {
      _nazionalita = p.nazionalita;
      _nazionalitaCtrl.text = p.nazionalita;
      _tipoPermesso = p.tipoPermesso;
      _scadenzaPermesso = p.scadenzaPermesso;
      _anniInItalia = p.anniInItalia;
      _anniCtrl.text = p.anniInItalia > 0 ? '${p.anniInItalia}' : '';
      _eta = p.eta;
      _etaCtrl.text = p.eta > 0 ? '${p.eta}' : '';
      _statoFamiliare = p.statoFamiliare.isNotEmpty ? p.statoFamiliare : 'single';
      _numeriFigli = p.numeriFigli;
      _etaFigli = List.from(p.etaFigli);
      _lavora = p.lavora;
      _tipoContratto = p.tipoContratto.isNotEmpty ? p.tipoContratto : 'disoccupato';
      _isee = p.isee;
      _iseeCtrl.text = p.isee > 0 ? '${p.isee.toInt()}' : '';
      _citta = p.citta;
      _cittaCtrl.text = p.citta;
      _disabilita = p.disabilita;
      _isCittadinoIT = p.tipoPermesso == 'cittadino_italiano';
      _isCittadinoUE = p.tipoPermesso == 'cittadino_ue';
    }
  }

  @override
  void dispose() {
    _nazionalitaCtrl.dispose();
    _etaCtrl.dispose();
    _anniCtrl.dispose();
    _figliEtaCtrl.dispose();
    _iseeCtrl.dispose();
    _cittaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvaEVediRisultati() async {
    final profilo = ProfiloUtente(
      nazionalita: _nazionalita,
      tipoPermesso: _isCittadinoIT ? 'cittadino_italiano' : (_isCittadinoUE ? 'cittadino_ue' : _tipoPermesso),
      scadenzaPermesso: _scadenzaPermesso,
      anniInItalia: _anniInItalia,
      statoFamiliare: _statoFamiliare,
      numeriFigli: _numeriFigli,
      etaFigli: _etaFigli,
      lavora: _lavora,
      tipoContratto: _lavora ? _tipoContratto : 'disoccupato',
      isee: _isee,
      citta: _citta,
      provincia: '',
      disabilita: _disabilita,
      eta: _eta,
    );

    await widget.service.save(profilo);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RisultatiDirittiScreen(profilo: profilo)),
      );
    }
  }

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
              title: const Text('Il Mio Caso', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              background: Container(decoration: const BoxDecoration(gradient: AppColors.headerGradient)),
            ),
            backgroundColor: AppColors.primaryDark,
          ),
          SliverToBoxAdapter(child: _buildProgressBar()),
          SliverToBoxAdapter(child: _buildCurrentStep()),
          SliverToBoxAdapter(child: _buildButtons()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text('Passo ${_step + 1} di 5', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
              const Spacer(),
              Text('${((_step + 1) / 5 * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_step + 1) / 5,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _stepPersonale();
      case 1: return _stepPermesso();
      case 2: return _stepFamiglia();
      case 3: return _stepLavoro();
      case 4: return _stepEconomia();
      default: return const SizedBox();
    }
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _step--),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Center(child: Text('Indietro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary))),
                ),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                if (_step < 4) {
                  setState(() => _step++);
                } else {
                  _salvaEVediRisultati();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text(
                  _step < 4 ? 'Avanti' : 'SCOPRI I TUOI DIRITTI',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: Dati Personali ──
  Widget _stepPersonale() {
    return Column(
      children: [
        _buildIseeUploadCard(),
        _card(
          'Dati Personali',
          'Inserisci le tue informazioni di base',
          Icons.person,
          [
            _textField('Nazionalita (es. Pakistan, Romania...)', _nazionalitaCtrl, (v) => _nazionalita = v),
            const SizedBox(height: 14),
            _textField('Eta', _etaCtrl, (v) => _eta = int.tryParse(v) ?? 0, isNumber: true),
            const SizedBox(height: 14),
            _textField('Citta di residenza', _cittaCtrl, (v) => _citta = v),
            const SizedBox(height: 14),
            _switchTile('Hai una disabilita riconosciuta?', _disabilita, (v) => setState(() => _disabilita = v)),
          ],
        ),
      ],
    );
  }

  Widget _buildIseeUploadCard() {
    final imported = _iseeImported;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COMPILA AUTOMATICAMENTE',
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  SizedBox(height: 2),
                  Text('Carica il tuo ISEE',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            'L\'AI legge la tua attestazione ISEE (foto o PDF) e compila per te ISEE, figli, età e disabilità.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          if (_parsingIsee) ...[
            const Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text('Leggo l\'ISEE…', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ] else if (imported != null) ...[
            _iseePreviewLine('Valore ISEE', imported.isee != null ? '€ ${imported.isee!.toStringAsFixed(0)}' : 'non letto'),
            _iseePreviewLine('Figli', '${imported.numeroFigli ?? 0}${imported.etaFigli.isEmpty ? '' : ' (${imported.etaFigli.join(", ")} anni)'}'),
            _iseePreviewLine('Disabilità', imported.hasDisabilita ? 'Sì' : 'No'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _startUpload(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Carica di nuovo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ]),
          ] else ...[
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startUpload(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Carica ISEE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _iseePreviewLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

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
    final d = res.data!;
    setState(() {
      _iseeImported = d;
      _parsingIsee = false;
      if (d.isee != null) {
        _isee = d.isee!;
        _iseeCtrl.text = d.isee!.toInt().toString();
      }
      if (d.etaRichiedente != null && d.etaRichiedente! > 0) {
        _eta = d.etaRichiedente!;
        _etaCtrl.text = '${d.etaRichiedente}';
      }
      if (d.numeroFigli != null) {
        _numeriFigli = d.numeroFigli!;
      }
      if (d.etaFigli.isNotEmpty) {
        _etaFigli = List<int>.from(d.etaFigli);
      }
      if (d.hasDisabilita) {
        _disabilita = true;
      }
      if (d.statoFamiliare != null && d.statoFamiliare!.isNotEmpty) {
        _statoFamiliare = d.statoFamiliare!;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ISEE letto. Ho compilato i campi disponibili.'),
        backgroundColor: AppColors.iconGreen,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ── STEP 2: Permesso di Soggiorno ──
  Widget _stepPermesso() {
    return _card(
      'Permesso di Soggiorno',
      'Informazioni sul tuo status in Italia',
      Icons.badge,
      [
        _switchTile('Sei cittadino italiano?', _isCittadinoIT, (v) => setState(() { _isCittadinoIT = v; if (v) _isCittadinoUE = false; })),
        if (!_isCittadinoIT) ...[
          const SizedBox(height: 10),
          _switchTile('Sei cittadino UE?', _isCittadinoUE, (v) => setState(() => _isCittadinoUE = v)),
        ],
        if (!_isCittadinoIT && !_isCittadinoUE) ...[
          const SizedBox(height: 14),
          _dropdown('Tipo permesso di soggiorno', _tipoPermesso, [
            'lavoro', 'famiglia', 'lungo_soggiornante', 'asilo', 'studio', 'altro',
          ], (v) => setState(() => _tipoPermesso = v)),
        ],
        const SizedBox(height: 14),
        _textField('Da quanti anni vivi in Italia?', _anniCtrl, (v) => _anniInItalia = int.tryParse(v) ?? 0, isNumber: true),
      ],
    );
  }

  // ── STEP 3: Famiglia ──
  Widget _stepFamiglia() {
    return _card(
      'Situazione Familiare',
      'Informazioni sulla tua famiglia',
      Icons.family_restroom,
      [
        _dropdown('Stato civile', _statoFamiliare, [
          'single', 'sposato', 'convivente', 'separato', 'vedovo',
        ], (v) => setState(() => _statoFamiliare = v)),
        const SizedBox(height: 14),
        const Text('Quanti figli hai?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(6, (i) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _numeriFigli = i;
                if (_etaFigli.length > i) _etaFigli = _etaFigli.sublist(0, i);
                while (_etaFigli.length < i) _etaFigli.add(0);
              }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _numeriFigli == i ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text('$i', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: _numeriFigli == i ? Colors.white : AppColors.textDark,
                ))),
              ),
            ),
          )),
        ),
        if (_numeriFigli > 0) ...[
          const SizedBox(height: 14),
          const Text('Eta dei figli:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 8),
          ...List.generate(_numeriFigli, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('Figlio ${i + 1}:', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Eta',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    controller: TextEditingController(text: i < _etaFigli.length && _etaFigli[i] > 0 ? '${_etaFigli[i]}' : ''),
                    onChanged: (v) {
                      final age = int.tryParse(v) ?? 0;
                      if (i < _etaFigli.length) {
                        _etaFigli[i] = age;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('anni', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
              ],
            ),
          )),
        ],
      ],
    );
  }

  // ── STEP 4: Lavoro ──
  Widget _stepLavoro() {
    return _card(
      'Situazione Lavorativa',
      'Informazioni sul tuo lavoro',
      Icons.work,
      [
        _switchTile('Lavori attualmente?', _lavora, (v) => setState(() => _lavora = v)),
        if (_lavora) ...[
          const SizedBox(height: 14),
          _dropdown('Tipo contratto', _tipoContratto, [
            'indeterminato', 'determinato', 'apprendista', 'autonomo', 'stagionale',
          ], (v) => setState(() => _tipoContratto = v)),
        ],
      ],
    );
  }

  // ── STEP 5: Economia ──
  Widget _stepEconomia() {
    return _card(
      'Situazione Economica',
      'Serve per calcolare i bonus a cui hai diritto',
      Icons.euro,
      [
        _textField('ISEE (anche approssimativo, es. 12000)', _iseeCtrl, (v) => _isee = double.tryParse(v) ?? 0, isNumber: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFE65100), size: 18),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Se non hai l\'ISEE, puoi farlo gratis al CAF. Inserisci 0 se non lo sai.',
                style: TextStyle(fontSize: 11, color: Color(0xFFE65100)),
              )),
            ],
          ),
        ),
      ],
    );
  }

  // ── WIDGETS HELPER ──
  Widget _card(String title, String subtitle, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController ctrl, ValueChanged<String> onChanged, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark))),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(_labelFor(e), style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) { if (v != null) onChanged(v); },
            ),
          ),
        ),
      ],
    );
  }

  String _labelFor(String key) {
    switch (key) {
      case 'single': return 'Single';
      case 'sposato': return 'Sposato/a';
      case 'convivente': return 'Convivente';
      case 'separato': return 'Separato/a - Divorziato/a';
      case 'vedovo': return 'Vedovo/a';
      case 'indeterminato': return 'Tempo indeterminato';
      case 'determinato': return 'Tempo determinato';
      case 'apprendista': return 'Apprendistato';
      case 'autonomo': return 'Autonomo / P.IVA';
      case 'stagionale': return 'Stagionale';
      case 'disoccupato': return 'Disoccupato';
      case 'lavoro': return 'Permesso di lavoro';
      case 'famiglia': return 'Ricongiungimento familiare';
      case 'lungo_soggiornante': return 'Lungo soggiornante (illimitato)';
      case 'asilo': return 'Protezione internazionale / Asilo';
      case 'studio': return 'Studio';
      case 'altro': return 'Altro';
      default: return key;
    }
  }
}
