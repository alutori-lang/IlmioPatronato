import 'package:flutter/material.dart';
import '../../config/constants.dart';
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
    return _card(
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
