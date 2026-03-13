import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';

// ---------------------------------------------------------------------------
// GENERATORE CV EUROPASS
// Multi-step wizard: Dati Personali -> Esperienze -> Istruzione ->
// Competenze -> Preview + Genera PDF
// ---------------------------------------------------------------------------

class CvEuropassScreen extends StatefulWidget {
  const CvEuropassScreen({super.key});

  @override
  State<CvEuropassScreen> createState() => _CvEuropassScreenState();
}

class _CvEuropassScreenState extends State<CvEuropassScreen> {
  int _currentStep = 0;
  static const _totalSteps = 5;
  final _formKey = GlobalKey<FormState>();

  // ── Step 1: Dati Personali ──
  final _nomeCtrl = TextEditingController();
  final _cognomeCtrl = TextEditingController();
  final _dataNascitaCtrl = TextEditingController();
  final _nazionalitaCtrl = TextEditingController();
  final _indirizzoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _codiceFiscaleCtrl = TextEditingController();

  // ── Step 2: Esperienze Lavorative ──
  final List<_Esperienza> _esperienze = [_Esperienza()];

  // ── Step 3: Istruzione e Formazione ──
  final List<_Istruzione> _istruzione = [_Istruzione()];

  // ── Step 4: Competenze ──
  String _italianoLevel = 'B1';
  String _linguaMadre = 'Arabo';
  final List<_AltraLingua> _altreLingue = [];

  bool _compWord = false;
  bool _compExcel = false;
  bool _compInternet = false;
  bool _compSocialMedia = false;

  final Set<String> _patenti = {};

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _lingueMadreOptions = [
    'Arabo',
    'Albanese',
    'Bangla',
    'Cinese',
    'Francese',
    'Hindi',
    'Inglese',
    'Pakistano (Urdu)',
    'Portoghese',
    'Rumeno',
    'Russo',
    'Spagnolo',
    'Tagalog',
    'Ucraino',
    'Altro',
  ];
  static const _patenteOptions = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _loadAutoFill();
  }

  Future<void> _loadAutoFill() async {
    final prefs = await SharedPreferences.getInstance();
    final mapping = {
      'autofill_nome': _nomeCtrl,
      'autofill_cognome': _cognomeCtrl,
      'autofill_codice_fiscale': _codiceFiscaleCtrl,
      'autofill_indirizzo': _indirizzoCtrl,
    };
    for (final entry in mapping.entries) {
      final val = prefs.getString(entry.key);
      if (val != null && val.isNotEmpty) {
        entry.value.text = val;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveAutoFill() async {
    final prefs = await SharedPreferences.getInstance();
    final mapping = {
      'autofill_nome': _nomeCtrl.text.trim(),
      'autofill_cognome': _cognomeCtrl.text.trim(),
      'autofill_codice_fiscale': _codiceFiscaleCtrl.text.trim(),
      'autofill_indirizzo': _indirizzoCtrl.text.trim(),
    };
    for (final entry in mapping.entries) {
      if (entry.value.isNotEmpty) {
        await prefs.setString(entry.key, entry.value);
      }
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cognomeCtrl.dispose();
    _dataNascitaCtrl.dispose();
    _nazionalitaCtrl.dispose();
    _indirizzoCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _codiceFiscaleCtrl.dispose();
    for (final e in _esperienze) {
      e.dispose();
    }
    for (final i in _istruzione) {
      i.dispose();
    }
    for (final l in _altreLingue) {
      l.dispose();
    }
    super.dispose();
  }

  // ── Navigation ──
  void _avanti() {
    if (_currentStep < 4) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }
    if (_currentStep == 0) _saveAutoFill();
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _indietro() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
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
        child: Column(
          children: [
            _buildHeader(context),
            _buildProgressBar(),
            Expanded(
              child: _currentStep == 4
                  ? _buildPreview()
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                        children: _buildStepContent(),
                      ),
                    ),
            ),
            _buildBottomBar(),
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
            child:
                const Icon(Icons.description, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GENERATORE CV EUROPASS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Crea il tuo CV professionale in PDF',
                    style: TextStyle(
                        color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──
  Widget _buildProgressBar() {
    final labels = [
      'Dati',
      'Lavoro',
      'Studio',
      'Competenze',
      'Preview',
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Passo ${_currentStep + 1} di $_totalSteps',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              Text('${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_totalSteps, (i) {
              final isActive = i <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((l) {
              final idx = labels.indexOf(l);
              final isActive = idx <= _currentStep;
              return Text(l,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppColors.primary : AppColors.textLight,
                  ));
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step content dispatch ──
  List<Widget> _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1DatiPersonali();
      case 1:
        return _buildStep2Esperienze();
      case 2:
        return _buildStep3Istruzione();
      case 3:
        return _buildStep4Competenze();
      default:
        return [];
    }
  }

  // ─────────────────────────────────────────────
  // STEP 1: DATI PERSONALI
  // ─────────────────────────────────────────────
  List<Widget> _buildStep1DatiPersonali() {
    return [
      _stepCard(
        icon: Icons.person,
        title: 'Dati Personali',
        subtitle: 'Informazioni di base per il CV',
      ),
      const SizedBox(height: 14),
      _card(children: [
        _textField(_nomeCtrl, 'Nome *', TextInputType.name),
        _textField(_cognomeCtrl, 'Cognome *', TextInputType.name),
        _dateField(_dataNascitaCtrl, 'Data di nascita *'),
        _textField(_nazionalitaCtrl, 'Nazionalit\u00e0 *', TextInputType.text),
        _textField(_indirizzoCtrl, 'Indirizzo completo', TextInputType.streetAddress),
        _textField(_telefonoCtrl, 'Telefono *', TextInputType.phone),
        _textField(_emailCtrl, 'Email *', TextInputType.emailAddress),
        _textField(_codiceFiscaleCtrl, 'Codice Fiscale', TextInputType.text,
            required: false),
      ]),
    ];
  }

  // ─────────────────────────────────────────────
  // STEP 2: ESPERIENZE LAVORATIVE
  // ─────────────────────────────────────────────
  List<Widget> _buildStep2Esperienze() {
    return [
      _stepCard(
        icon: Icons.work,
        title: 'Esperienze Lavorative',
        subtitle: 'Aggiungi le tue esperienze di lavoro',
      ),
      const SizedBox(height: 14),
      ..._esperienze.asMap().entries.map((entry) {
        final idx = entry.key;
        final esp = entry.value;
        return _card(
          margin: const EdgeInsets.only(bottom: 14),
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Esperienza ${idx + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
                const Spacer(),
                if (_esperienze.length > 1)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _esperienze.removeAt(idx)),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _textField(esp.aziendaCtrl, 'Azienda / Datore di lavoro *',
                TextInputType.text),
            _textField(
                esp.ruoloCtrl, 'Ruolo / Mansione *', TextInputType.text),
            Row(
              children: [
                Expanded(
                    child: _dateField(esp.daCtrl, 'Dal *')),
                const SizedBox(width: 12),
                Expanded(
                    child: _dateField(esp.aCtrl, 'Al (o "Presente")',
                        required: false)),
              ],
            ),
            _textField(
                esp.descrizioneCtrl, 'Descrizione attivit\u00e0', TextInputType.text,
                required: false, maxLines: 3),
          ],
        );
      }),
      _addButton('Aggiungi esperienza', () {
        setState(() => _esperienze.add(_Esperienza()));
      }),
    ];
  }

  // ─────────────────────────────────────────────
  // STEP 3: ISTRUZIONE E FORMAZIONE
  // ─────────────────────────────────────────────
  List<Widget> _buildStep3Istruzione() {
    return [
      _stepCard(
        icon: Icons.school,
        title: 'Istruzione e Formazione',
        subtitle: 'Aggiungi i tuoi titoli di studio',
      ),
      const SizedBox(height: 14),
      ..._istruzione.asMap().entries.map((entry) {
        final idx = entry.key;
        final ist = entry.value;
        return _card(
          margin: const EdgeInsets.only(bottom: 14),
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Titolo ${idx + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
                const Spacer(),
                if (_istruzione.length > 1)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _istruzione.removeAt(idx)),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _textField(
                ist.istitutoCtrl, 'Istituto / Universit\u00e0 *', TextInputType.text),
            _textField(ist.titoloCtrl, 'Titolo di studio *',
                TextInputType.text),
            Row(
              children: [
                Expanded(child: _dateField(ist.daCtrl, 'Dal *')),
                const SizedBox(width: 12),
                Expanded(
                    child: _dateField(ist.aCtrl, 'Al (o "In corso")',
                        required: false)),
              ],
            ),
            _textField(ist.paeseCtrl, 'Paese', TextInputType.text,
                required: false),
          ],
        );
      }),
      _addButton('Aggiungi titolo di studio', () {
        setState(() => _istruzione.add(_Istruzione()));
      }),
    ];
  }

  // ─────────────────────────────────────────────
  // STEP 4: COMPETENZE
  // ─────────────────────────────────────────────
  List<Widget> _buildStep4Competenze() {
    return [
      _stepCard(
        icon: Icons.star,
        title: 'Competenze',
        subtitle: 'Lingue, digitale e patente',
      ),
      const SizedBox(height: 14),

      // ── Lingua Italiana ──
      _card(children: [
        const _SectionLabel('Conoscenza Italiano'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _italianoLevel,
          isExpanded: true,
          decoration: _inputDeco('Livello Italiano'),
          items: _levels
              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _italianoLevel = v);
          },
        ),
      ]),
      const SizedBox(height: 14),

      // ── Lingua Madre ──
      _card(children: [
        const _SectionLabel('Lingua Madre'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _linguaMadre,
          isExpanded: true,
          decoration: _inputDeco('Seleziona lingua madre'),
          items: _lingueMadreOptions
              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _linguaMadre = v);
          },
        ),
      ]),
      const SizedBox(height: 14),

      // ── Altre Lingue ──
      _card(children: [
        Row(
          children: [
            const _SectionLabel('Altre Lingue'),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _altreLingue.add(_AltraLingua())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('Aggiungi',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_altreLingue.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nessuna altra lingua aggiunta',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontStyle: FontStyle.italic)),
          ),
        ..._altreLingue.asMap().entries.map((entry) {
          final idx = entry.key;
          final lingua = entry.value;
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: lingua.nomeCtrl,
                        decoration: _inputDeco('Nome lingua'),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: DropdownButtonFormField<String>(
                        initialValue: lingua.livello,
                        decoration: _inputDeco('Livello'),
                        items: _levels
                            .map((l) =>
                                DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => lingua.livello = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _altreLingue.removeAt(idx)),
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ]),
      const SizedBox(height: 14),

      // ── Competenze Digitali ──
      _card(children: [
        const _SectionLabel('Competenze Digitali'),
        const SizedBox(height: 8),
        _checkTile('Microsoft Word', _compWord,
            (v) => setState(() => _compWord = v ?? false)),
        _checkTile('Microsoft Excel', _compExcel,
            (v) => setState(() => _compExcel = v ?? false)),
        _checkTile('Internet e Email', _compInternet,
            (v) => setState(() => _compInternet = v ?? false)),
        _checkTile('Social Media', _compSocialMedia,
            (v) => setState(() => _compSocialMedia = v ?? false)),
      ]),
      const SizedBox(height: 14),

      // ── Patente di Guida ──
      _card(children: [
        const _SectionLabel('Patente di Guida'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _patenteOptions.map((p) {
            final selected = _patenti.contains(p);
            return FilterChip(
              label: Text('Patente $p'),
              selected: selected,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.textMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected
                      ? AppColors.primary
                      : const Color(0xFFE0E0E0),
                ),
              ),
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _patenti.add(p);
                  } else {
                    _patenti.remove(p);
                  }
                });
              },
            );
          }).toList(),
        ),
      ]),
    ];
  }

  // ─────────────────────────────────────────────
  // STEP 5: PREVIEW
  // ─────────────────────────────────────────────
  Widget _buildPreview() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        _stepCard(
          icon: Icons.preview,
          title: 'Anteprima CV',
          subtitle: 'Controlla i dati prima di generare il PDF',
        ),
        const SizedBox(height: 14),

        // ── Dati Personali ──
        _previewSection('Dati Personali', Icons.person, [
          _previewRow('Nome', '${_nomeCtrl.text} ${_cognomeCtrl.text}'),
          _previewRow('Data di nascita', _dataNascitaCtrl.text),
          _previewRow('Nazionalit\u00e0', _nazionalitaCtrl.text),
          if (_indirizzoCtrl.text.isNotEmpty)
            _previewRow('Indirizzo', _indirizzoCtrl.text),
          _previewRow('Telefono', _telefonoCtrl.text),
          _previewRow('Email', _emailCtrl.text),
          if (_codiceFiscaleCtrl.text.isNotEmpty)
            _previewRow('Codice Fiscale', _codiceFiscaleCtrl.text),
        ]),

        // ── Esperienze ──
        _previewSection('Esperienze Lavorative', Icons.work, [
          for (final esp in _esperienze) ...[
            _previewRow('Azienda', esp.aziendaCtrl.text),
            _previewRow('Ruolo', esp.ruoloCtrl.text),
            _previewRow('Periodo',
                '${esp.daCtrl.text} - ${esp.aCtrl.text.isNotEmpty ? esp.aCtrl.text : "Presente"}'),
            if (esp.descrizioneCtrl.text.isNotEmpty)
              _previewRow('Descrizione', esp.descrizioneCtrl.text),
            const Divider(height: 16),
          ],
        ]),

        // ── Istruzione ──
        _previewSection('Istruzione e Formazione', Icons.school, [
          for (final ist in _istruzione) ...[
            _previewRow('Istituto', ist.istitutoCtrl.text),
            _previewRow('Titolo', ist.titoloCtrl.text),
            _previewRow('Periodo',
                '${ist.daCtrl.text} - ${ist.aCtrl.text.isNotEmpty ? ist.aCtrl.text : "In corso"}'),
            if (ist.paeseCtrl.text.isNotEmpty)
              _previewRow('Paese', ist.paeseCtrl.text),
            const Divider(height: 16),
          ],
        ]),

        // ── Competenze ──
        _previewSection('Competenze', Icons.star, [
          _previewRow('Italiano', _italianoLevel),
          _previewRow('Lingua madre', _linguaMadre),
          for (final l in _altreLingue)
            _previewRow(l.nomeCtrl.text, l.livello),
          const Divider(height: 16),
          _previewRow('Competenze digitali', [
            if (_compWord) 'Word',
            if (_compExcel) 'Excel',
            if (_compInternet) 'Internet/Email',
            if (_compSocialMedia) 'Social Media',
          ].join(', ')),
          if (_patenti.isNotEmpty)
            _previewRow('Patente', _patenti.join(', ')),
        ]),
      ],
    );
  }

  Widget _previewSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _indietro,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(
                _currentStep == 0 ? 'Chiudi' : 'Indietro',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _currentStep == 4
                ? _buildGeneraPdfButton()
                : ElevatedButton.icon(
                    onPressed: _avanti,
                    icon: const Text('Avanti',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    label: const Icon(Icons.arrow_forward,
                        size: 18, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneraPdfButton() {
    return GestureDetector(
      onTap: _generatePdf,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Genera PDF',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PDF GENERATION
  // ─────────────────────────────────────────────
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    const bluScuro = PdfColor.fromInt(0xFF0D2D5E);
    const bluPrimario = PdfColor.fromInt(0xFF1565C0);
    const bluChiaro = PdfColor.fromInt(0xFFE3F2FD);
    const grigio = PdfColor.fromInt(0xFF666666);
    const grigioChiaro = PdfColor.fromInt(0xFFF5F5F5);

    final nomeCompleto = '${_nomeCtrl.text.trim()} ${_cognomeCtrl.text.trim()}';
    final dataOggi = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── LEFT SIDEBAR ──
              pw.Container(
                width: 180,
                padding: const pw.EdgeInsets.all(20),
                color: bluScuro,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Name initials circle
                    pw.Center(
                      child: pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: bluPrimario,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${_nomeCtrl.text.isNotEmpty ? _nomeCtrl.text[0].toUpperCase() : ''}${_cognomeCtrl.text.isNotEmpty ? _cognomeCtrl.text[0].toUpperCase() : ''}',
                            style: pw.TextStyle(
                              fontSize: 26,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    _pdfSidebarSection('CONTATTI', [
                      if (_telefonoCtrl.text.isNotEmpty)
                        _pdfSidebarItem('Tel', _telefonoCtrl.text),
                      if (_emailCtrl.text.isNotEmpty)
                        _pdfSidebarItem('Email', _emailCtrl.text),
                      if (_indirizzoCtrl.text.isNotEmpty)
                        _pdfSidebarItem('Indirizzo', _indirizzoCtrl.text),
                    ]),
                    pw.SizedBox(height: 14),
                    _pdfSidebarSection('INFO', [
                      if (_dataNascitaCtrl.text.isNotEmpty)
                        _pdfSidebarItem('Nascita', _dataNascitaCtrl.text),
                      if (_nazionalitaCtrl.text.isNotEmpty)
                        _pdfSidebarItem('Nazionalit\u00e0', _nazionalitaCtrl.text),
                      if (_codiceFiscaleCtrl.text.isNotEmpty)
                        _pdfSidebarItem('CF', _codiceFiscaleCtrl.text),
                    ]),
                    pw.SizedBox(height: 14),
                    _pdfSidebarSection('LINGUE', [
                      _pdfSidebarItem('Italiano', _italianoLevel),
                      _pdfSidebarItem(_linguaMadre, 'Madrelingua'),
                      for (final l in _altreLingue)
                        if (l.nomeCtrl.text.isNotEmpty)
                          _pdfSidebarItem(l.nomeCtrl.text, l.livello),
                    ]),
                    if (_patenti.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      _pdfSidebarSection('PATENTE', [
                        _pdfSidebarItem('Tipo', _patenti.join(', ')),
                      ]),
                    ],
                  ],
                ),
              ),

              // ── RIGHT MAIN CONTENT ──
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Name header
                      pw.Text(
                        nomeCompleto.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: bluScuro,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'CURRICULUM VITAE - FORMATO EUROPASS',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: bluPrimario,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.Divider(color: bluPrimario, thickness: 2),
                      pw.SizedBox(height: 16),

                      // ── ESPERIENZE LAVORATIVE ──
                      _pdfMainSection('ESPERIENZE LAVORATIVE', bluPrimario),
                      for (final esp in _esperienze) ...[
                        pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 12),
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: grigioChiaro,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                esp.ruoloCtrl.text,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: bluScuro,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                esp.aziendaCtrl.text,
                                style: const pw.TextStyle(
                                    fontSize: 10, color: grigio),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                '${esp.daCtrl.text} - ${esp.aCtrl.text.isNotEmpty ? esp.aCtrl.text : "Presente"}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: bluPrimario,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                              if (esp.descrizioneCtrl.text.isNotEmpty) ...[
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  esp.descrizioneCtrl.text,
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      pw.SizedBox(height: 10),

                      // ── ISTRUZIONE ──
                      _pdfMainSection(
                          'ISTRUZIONE E FORMAZIONE', bluPrimario),
                      for (final ist in _istruzione) ...[
                        pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 12),
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: grigioChiaro,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                ist.titoloCtrl.text,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: bluScuro,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                ist.istitutoCtrl.text,
                                style: const pw.TextStyle(
                                    fontSize: 10, color: grigio),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(
                                      '${ist.daCtrl.text} - ${ist.aCtrl.text.isNotEmpty ? ist.aCtrl.text : "In corso"}',
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        color: bluPrimario,
                                        fontStyle: pw.FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  if (ist.paeseCtrl.text.isNotEmpty)
                                    pw.Text(
                                      ist.paeseCtrl.text,
                                      style: const pw.TextStyle(
                                          fontSize: 9, color: grigio),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      pw.SizedBox(height: 10),

                      // ── COMPETENZE LINGUISTICHE (table) ──
                      _pdfMainSection(
                          'COMPETENZE LINGUISTICHE', bluPrimario),
                      _buildLanguageTable(bluScuro, bluChiaro),
                      pw.SizedBox(height: 14),

                      // ── COMPETENZE DIGITALI ──
                      _pdfMainSection('COMPETENZE DIGITALI', bluPrimario),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Text(
                          [
                            if (_compWord) 'Microsoft Word',
                            if (_compExcel) 'Microsoft Excel',
                            if (_compInternet) 'Internet e Email',
                            if (_compSocialMedia) 'Social Media',
                          ].join(' \u2022 '),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),

                      // ── PATENTE ──
                      if (_patenti.isNotEmpty) ...[
                        _pdfMainSection('PATENTE DI GUIDA', bluPrimario),
                        pw.Text(
                          'Patente: ${_patenti.join(", ")}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],

                      pw.SizedBox(height: 20),

                      // ── FOOTER ──
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Generato il $dataOggi',
                            style: pw.TextStyle(
                              fontSize: 7,
                              color: grigio,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                          pw.Text(
                            'Autorizzo il trattamento dei dati personali ai sensi del D.Lgs. 196/2003',
                            style: const pw.TextStyle(
                                fontSize: 7, color: grigio),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    if (!mounted) return;

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'CV_Europass_${_cognomeCtrl.text.trim()}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // ── PDF helper: language table ──
  pw.Widget _buildLanguageTable(PdfColor bluScuro, PdfColor bluChiaro) {
    final allLingue = <MapEntry<String, String>>[
      MapEntry('Italiano', _italianoLevel),
      MapEntry(_linguaMadre, 'Madrelingua'),
      for (final l in _altreLingue)
        if (l.nomeCtrl.text.isNotEmpty) MapEntry(l.nomeCtrl.text, l.livello),
    ];

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: bluChiaro),
          children: [
            _tableCell('Lingua', bold: true, color: bluScuro),
            _tableCell('A1', bold: true, color: bluScuro),
            _tableCell('A2', bold: true, color: bluScuro),
            _tableCell('B1', bold: true, color: bluScuro),
            _tableCell('B2', bold: true, color: bluScuro),
            _tableCell('C1', bold: true, color: bluScuro),
            _tableCell('C2', bold: true, color: bluScuro),
          ],
        ),
        // Data rows
        for (final entry in allLingue)
          pw.TableRow(
            children: [
              _tableCell(entry.key),
              for (final lvl in _levels)
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Center(
                    child: pw.Text(
                      entry.value == 'Madrelingua'
                          ? (lvl == 'C2' ? '\u2713' : '')
                          : (entry.value == lvl ? '\u2713' : ''),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  pw.Widget _tableCell(String text,
      {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  pw.Widget _pdfSidebarSection(String title, List<pw.Widget> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 1,
          ),
        ),
        pw.Container(
          width: 30,
          height: 2,
          color: PdfColor.fromInt(0xFF42A5F5),
          margin: const pw.EdgeInsets.only(top: 3, bottom: 8),
        ),
        ...items,
      ],
    );
  }

  pw.Widget _pdfSidebarItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF90CAF9),
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMainSection(String title, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
          pw.Container(
            width: double.infinity,
            height: 1.5,
            color: color,
            margin: const pw.EdgeInsets.only(top: 3),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // REUSABLE FLUTTER WIDGETS
  // ─────────────────────────────────────────────
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 3)),
      ],
    );
  }

  Widget _card(
      {required List<Widget> children, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _stepCard(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    TextInputType keyboardType, {
    bool required = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: _inputDeco(label),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null
            : null,
      ),
    );
  }

  Widget _dateField(TextEditingController controller, String label,
      {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: _inputDeco(label).copyWith(
          suffixIcon: const Icon(Icons.calendar_today,
              size: 18, color: AppColors.primary),
        ),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: DateTime(1950),
            lastDate: DateTime(now.year + 10),
            builder: (ctx, child) {
              return Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.textDark,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            controller.text = DateFormat('dd/MM/yyyy').format(picked);
          }
        },
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Seleziona una data' : null
            : null,
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMedium),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  Widget _checkTile(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _addButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                size: 20,
                color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark));
  }
}

class _Esperienza {
  final aziendaCtrl = TextEditingController();
  final ruoloCtrl = TextEditingController();
  final daCtrl = TextEditingController();
  final aCtrl = TextEditingController();
  final descrizioneCtrl = TextEditingController();

  void dispose() {
    aziendaCtrl.dispose();
    ruoloCtrl.dispose();
    daCtrl.dispose();
    aCtrl.dispose();
    descrizioneCtrl.dispose();
  }
}

class _Istruzione {
  final istitutoCtrl = TextEditingController();
  final titoloCtrl = TextEditingController();
  final daCtrl = TextEditingController();
  final aCtrl = TextEditingController();
  final paeseCtrl = TextEditingController();

  void dispose() {
    istitutoCtrl.dispose();
    titoloCtrl.dispose();
    daCtrl.dispose();
    aCtrl.dispose();
    paeseCtrl.dispose();
  }
}

class _AltraLingua {
  final nomeCtrl = TextEditingController();
  String livello = 'A1';

  void dispose() {
    nomeCtrl.dispose();
  }
}
