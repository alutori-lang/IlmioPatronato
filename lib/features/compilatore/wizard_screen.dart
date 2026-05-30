import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';
import '../../core/services/ad_service.dart';
import 'moduli_data.dart';
import 'pdf_generator.dart';

// ---------------------------------------------------------------------------
// Wizard multi-step per la compilazione di un Modulo
// ---------------------------------------------------------------------------
class WizardScreen extends StatefulWidget {
  final Modulo modulo;

  const WizardScreen({super.key, required this.modulo});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  int _currentStep = 0;
  final Map<String, String> _dati = {};
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showSummary = false;

  // Campi che vengono salvati / caricati in SharedPreferences
  static const _autoFillKeys = [
    'cognome',
    'nome',
    'codice_fiscale',
    'indirizzo',
    'comune',
    'cap',
    'provincia',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadAutoFillData();
  }

  void _initControllers() {
    for (final step in widget.modulo.steps) {
      for (final campo in step.campi) {
        _controllers[campo.id] = TextEditingController();
      }
    }
  }

  Future<void> _loadAutoFillData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _autoFillKeys) {
      final value = prefs.getString('autofill_$key');
      if (value != null && value.isNotEmpty && _controllers.containsKey(key)) {
        _controllers[key]!.text = value;
        _dati[key] = value;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveAutoFillData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _autoFillKeys) {
      final value = _dati[key];
      if (value != null && value.isNotEmpty) {
        await prefs.setString('autofill_$key', value);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  StepModulo get _step => widget.modulo.steps[_currentStep];
  int get _totalSteps => widget.modulo.steps.length;
  bool get _isLastStep => _currentStep == _totalSteps - 1;

  // -----------------------------------------------------------------------
  // Navigazione tra step
  // -----------------------------------------------------------------------
  void _avanti() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _syncCurrentStepData();

    if (_isLastStep) {
      _saveAutoFillData();
      setState(() => _showSummary = true);
    } else {
      setState(() => _currentStep++);
    }
  }

  void _indietro() {
    if (_showSummary) {
      setState(() => _showSummary = false);
      return;
    }
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _syncCurrentStepData() {
    for (final campo in _step.campi) {
      if (_controllers.containsKey(campo.id)) {
        final text = _controllers[campo.id]!.text.trim();
        if (text.isNotEmpty) {
          _dati[campo.id] = text;
        }
      }
    }
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _showSummary ? _buildSummary() : _buildWizard(),
    );
  }

  // -----------------------------------------------------------------------
  // Wizard (form step-by-step)
  // -----------------------------------------------------------------------
  Widget _buildWizard() {
    return Column(
      children: [
        _buildAppBar(),
        _buildProgressBar(),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                _buildStepHeader(),
                const SizedBox(height: 16),
                ..._step.campi.map(_buildField),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.modulo.titolo,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / _totalSteps;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passo ${_currentStep + 1} di $_totalSteps',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_step.icona, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _step.titolo,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (_step.sottotitolo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _step.sottotitolo,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Generazione dei campi in base al tipo
  // -----------------------------------------------------------------------
  Widget _buildField(CampoModulo campo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _fieldWidget(campo),
    );
  }

  Widget _fieldWidget(CampoModulo campo) {
    switch (campo.tipo) {
      case CampoTipo.dropdown:
        return _buildDropdown(campo);
      case CampoTipo.data:
        return _buildDateField(campo);
      case CampoTipo.radio:
        return _buildRadioField(campo);
      case CampoTipo.numero:
        return _buildTextField(campo, keyboardType: TextInputType.number);
      case CampoTipo.telefono:
        return _buildTextField(campo, keyboardType: TextInputType.phone);
      case CampoTipo.email:
        return _buildTextField(campo, keyboardType: TextInputType.emailAddress);
      case CampoTipo.multilinea:
        return _buildTextField(campo, maxLines: 4);
      case CampoTipo.testo:
        return _buildTextField(campo);
    }
  }

  // -- TextField generico ---------------------------------------------------
  Widget _buildTextField(
    CampoModulo campo, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: _controllers[campo.id],
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
      decoration: _inputDecoration(campo),
      validator: campo.obbligatorio
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null
          : null,
      onChanged: (v) => _dati[campo.id] = v.trim(),
    );
  }

  // -- Dropdown -------------------------------------------------------------
  Widget _buildDropdown(CampoModulo campo) {
    final currentValue = _dati[campo.id];
    final isValid = campo.opzioni?.contains(currentValue) ?? false;

    return DropdownButtonFormField<String>(
      initialValue: isValid ? currentValue : null,
      isExpanded: true,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
      decoration: _inputDecoration(campo),
      items: campo.opzioni
              ?.map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList() ??
          [],
      onChanged: (v) {
        if (v != null) {
          setState(() => _dati[campo.id] = v);
        }
      },
      validator: campo.obbligatorio
          ? (v) => (v == null || v.isEmpty) ? 'Seleziona un\'opzione' : null
          : null,
    );
  }

  // -- Date picker ----------------------------------------------------------
  Widget _buildDateField(CampoModulo campo) {
    return TextFormField(
      controller: _controllers[campo.id],
      readOnly: true,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
      decoration: _inputDecoration(campo).copyWith(
        suffixIcon: const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
      ),
      onTap: () => _pickDate(campo),
      validator: campo.obbligatorio
          ? (v) => (v == null || v.trim().isEmpty) ? 'Seleziona una data' : null
          : null,
    );
  }

  Future<void> _pickDate(CampoModulo campo) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year + 10),
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      _controllers[campo.id]!.text = formatted;
      _dati[campo.id] = formatted;
    }
  }

  // -- Radio / ChoiceChip ---------------------------------------------------
  Widget _buildRadioField(CampoModulo campo) {
    final currentValue = _dati[campo.id] ?? '';
    return FormField<String>(
      initialValue: currentValue,
      validator: campo.obbligatorio
          ? (v) => (v == null || v.isEmpty) ? 'Seleziona un\'opzione' : null
          : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              campo.etichetta,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (campo.opzioni ?? []).map((opzione) {
                final selected = currentValue == opzione;
                return ChoiceChip(
                  label: Text(opzione),
                  selected: selected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.primary : AppColors.textMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
                    ),
                  ),
                  onSelected: (_) {
                    setState(() => _dati[campo.id] = opzione);
                    state.didChange(opzione);
                  },
                );
              }).toList(),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }

  // -- Decorazione input condivisa -----------------------------------------
  InputDecoration _inputDecoration(CampoModulo campo) {
    return InputDecoration(
      labelText: campo.etichetta,
      hintText: campo.suggerimento.isNotEmpty ? campo.suggerimento : null,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMedium),
      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Barra inferiore con pulsanti Avanti/Indietro
  // -----------------------------------------------------------------------
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
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _indietro,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(
                  'Indietro',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: _isLastStep ? _buildGeneraButton() : _buildAvantiButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvantiButton() {
    return ElevatedButton.icon(
      onPressed: _avanti,
      icon: Text(
        'Avanti',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      label: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildGeneraButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: _avanti,
        icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
        label: Text(
          'Genera PDF',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Schermata riassuntiva
  // -----------------------------------------------------------------------
  Widget _buildSummary() {
    return Column(
      children: [
        _buildSummaryAppBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              _buildSummaryNote(),
              const SizedBox(height: 14),
              ...widget.modulo.steps.map(_buildSummarySection),
            ],
          ),
        ),
        _buildSummaryBottom(),
      ],
    );
  }

  Widget _buildSummaryAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: _indietro,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Riepilogo',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.modulo.nomeUfficiale,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryNote() {
    if (widget.modulo.note.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE65100), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.modulo.note,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF5D4037),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(StepModulo step) {
    final filledFields = step.campi.where((c) {
      final v = _dati[c.id]?.trim() ?? '';
      return v.isNotEmpty;
    }).toList();

    if (filledFields.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titolo sezione
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(step.icona, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  step.titolo,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Campi
          ...filledFields.map((campo) {
            final value = _dati[campo.id] ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      campo.etichetta,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildSummaryBottom() {
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
              icon: const Icon(Icons.edit, size: 18),
              label: Text(
                'Modifica',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () => AdService().showRewardedThen(
                  () => PdfGenerator.genera(context, widget.modulo, _dati),
                ),
                icon: const Icon(Icons.download, size: 18, color: Colors.white),
                label: Text(
                  'Scarica PDF',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
