import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../config/constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

// ---------------------------------------------------------------------------
// GENERATORE CV — Semplice, 6 Step, 10 Stili
// ---------------------------------------------------------------------------

class CvEuropassScreen extends StatefulWidget {
  const CvEuropassScreen({super.key});
  @override
  State<CvEuropassScreen> createState() => _CvEuropassScreenState();
}

class _Esperienza {
  String azienda, ruolo, dalAl, descrizione;
  bool isAi;
  _Esperienza({this.azienda = '', this.ruolo = '', this.dalAl = '', this.descrizione = '', this.isAi = false});
}

class _CvEuropassScreenState extends State<CvEuropassScreen> {
  int _step = 0;

  // Step 1 - Foto
  File? _photo;

  // Step 2 - Dati personali
  final _nomeCtrl = TextEditingController();
  final _cognomeCtrl = TextEditingController();
  final _dataNascitaCtrl = TextEditingController();
  final _luogoNascitaCtrl = TextEditingController();
  final _nazionalitaCtrl = TextEditingController();
  final _cfCtrl = TextEditingController();
  bool _isScanning = false;

  // Step 3 - Indirizzo
  final _indirizzoCtrl = TextEditingController();
  final _cittaCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Step 4 - Esperienze
  final List<_Esperienza> _esperienze = [];
  final _lavoroCercatoCtrl = TextEditingController();
  bool _isGenerating = false;

  // Step 5 - Patente e Lingue
  bool _haPatente = false;
  final Set<String> _patenti = {};
  String _linguaMadre = 'Arabo';
  String _italianoLevel = 'B1';

  // Step 6 - Stile
  int _selectedStyle = 0;

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _lingue = [
    'Arabo', 'Albanese', 'Bangla', 'Cinese', 'Francese', 'Hindi',
    'Inglese', 'Pakistano (Urdu)', 'Portoghese', 'Rumeno', 'Russo',
    'Spagnolo', 'Tagalog', 'Ucraino', 'Altro',
  ];
  static const _patenteOpts = ['A', 'B', 'C', 'D', 'E'];

  @override
  void dispose() {
    _nomeCtrl.dispose(); _cognomeCtrl.dispose(); _dataNascitaCtrl.dispose();
    _luogoNascitaCtrl.dispose(); _nazionalitaCtrl.dispose(); _cfCtrl.dispose();
    _indirizzoCtrl.dispose(); _cittaCtrl.dispose(); _capCtrl.dispose();
    _telCtrl.dispose(); _emailCtrl.dispose(); _lavoroCercatoCtrl.dispose();
    super.dispose();
  }

  // ── AI: Scansiona documento ──
  Future<void> _scanDocument(ImageSource src) async {
    final file = await pickImage(src);
    if (file == null) return;
    setState(() => _isScanning = true);
    final res = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: 'Analizza questo documento d\'identità italiano (CI, passaporto, permesso di soggiorno). '
          'Estrai SOLO JSON valido senza markdown:\n'
          '{"nome":"","cognome":"","data_nascita":"dd/mm/yyyy","luogo_nascita":"","nazionalita":"","codice_fiscale":""}',
    );
    if (mounted) {
      setState(() => _isScanning = false);
      if (res.isSuccess) {
        final j = res.tryParseJson();
        if (j != null) {
          _nomeCtrl.text = j['nome'] ?? '';
          _cognomeCtrl.text = j['cognome'] ?? '';
          _dataNascitaCtrl.text = j['data_nascita'] ?? '';
          _luogoNascitaCtrl.text = j['luogo_nascita'] ?? '';
          _nazionalitaCtrl.text = j['nazionalita'] ?? '';
          _cfCtrl.text = j['codice_fiscale'] ?? '';
          setState(() {});
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? 'Errore'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── AI: Genera esperienze ──
  Future<void> _generateExperiences() async {
    final lavoro = _lavoroCercatoCtrl.text.trim();
    if (lavoro.isEmpty) return;
    setState(() => _isGenerating = true);

    final existing = _esperienze.where((e) => !e.isAi).map((e) => '${e.ruolo} presso ${e.azienda}').join(', ');

    final res = await GeminiService().chat(
      messages: [
        {
          'role': 'user',
          'content': 'L\'utente cerca lavoro come "$lavoro". '
              '${existing.isNotEmpty ? "Ha queste esperienze: $existing. " : ""}'
              'Genera 4 esperienze lavorative credibili e pertinenti al ruolo cercato. '
              'SOLO JSON valido, nessun markdown:\n'
              '[{"azienda":"","ruolo":"","dal_al":"MM/YYYY - MM/YYYY","descrizione":"breve descrizione mansioni"}]\n'
              'Usa aziende italiane generiche credibili. Date realistiche negli ultimi 5 anni.',
        }
      ],
    );

    if (mounted) {
      setState(() => _isGenerating = false);
      if (res.isSuccess) {
        try {
          final start = res.text.indexOf('[');
          final end = res.text.lastIndexOf(']');
          if (start != -1 && end > start) {
            final list = jsonDecode(res.text.substring(start, end + 1)) as List;
            for (final item in list) {
              _esperienze.add(_Esperienza(
                azienda: item['azienda'] ?? '',
                ruolo: item['ruolo'] ?? '',
                dalAl: item['dal_al'] ?? '',
                descrizione: item['descrizione'] ?? '',
                isAi: true,
              ));
            }
            setState(() {});
          }
        } catch (_) {}
      }
    }
  }

  // ── Pick photo ──
  Future<void> _pickPhoto(ImageSource src) async {
    final file = await pickImage(src);
    if (file != null) setState(() => _photo = file);
  }

  void _showPickerSheet(String title, void Function(ImageSource) onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _sheetBtn(Icons.camera_alt, 'Fotocamera', () { Navigator.pop(context); onPick(ImageSource.camera); })),
            const SizedBox(width: 12),
            Expanded(child: _sheetBtn(Icons.photo_library, 'Galleria', () { Navigator.pop(context); onPick(ImageSource.gallery); })),
          ]),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ]),
      ),
    );
  }

  Widget _sheetBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ]),
      ),
    );
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(),
        _buildProgress(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: [_step1Photo, _step2Dati, _step3Indirizzo, _step4Esperienze, _step5Patente, _step6Stile][_step](),
        )),
        _buildNavBar(),
      ]),
    );
  }

  Widget _buildHeader() {
    final titles = ['Foto Profilo', 'Dati Personali', 'Indirizzo', 'Esperienze', 'Patente & Lingue', 'Scegli Stile'];
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 12),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)]), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.description, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('GENERA CV', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(titles[_step], style: const TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: List.generate(6, (i) => Expanded(
        child: Container(
          height: 4,
          margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
          decoration: BoxDecoration(
            color: i <= _step ? AppColors.primary : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ))),
    );
  }

  Widget _buildNavBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(children: [
        if (_step > 0) Expanded(child: GestureDetector(
          onTap: () => setState(() => _step--),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Indietro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary))),
          ),
        )),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(child: GestureDetector(
          onTap: _step < 5 ? () => setState(() => _step++) : _generatePdf,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(
              _step < 5 ? 'Avanti' : 'Genera PDF',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            )),
          ),
        )),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 1: FOTO PROFILO
  // ══════════════════════════════════════════════════════════════
  Widget _step1Photo() {
    return Column(children: [
      const SizedBox(height: 30),
      const Icon(Icons.camera_alt_rounded, size: 48, color: AppColors.primary),
      const SizedBox(height: 16),
      const Text('Aggiungi una foto profilo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 6),
      const Text('Opzionale — puoi saltare questo step', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
      const SizedBox(height: 30),
      GestureDetector(
        onTap: () => _showPickerSheet('Foto Profilo', _pickPhoto),
        child: Container(
          width: 160, height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
            border: Border.all(color: _photo != null ? AppColors.primary : Colors.grey.shade300, width: 3),
            image: _photo != null ? DecorationImage(image: FileImage(_photo!), fit: BoxFit.cover) : null,
          ),
          child: _photo == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
        ),
      ),
      if (_photo != null) ...[
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() => _photo = null),
          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
          label: const Text('Rimuovi foto', style: TextStyle(color: Colors.red)),
        ),
      ],
    ]);
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 2: DATI PERSONALI
  // ══════════════════════════════════════════════════════════════
  Widget _step2Dati() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Scan banner
      GestureDetector(
        onTap: _isScanning ? null : () => _showPickerSheet('Scansiona Documento', _scanDocument),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            _isScanning
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.document_scanner, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_isScanning ? 'Analisi in corso...' : 'Scansiona Documento', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const Text('CI, Passaporto o Permesso — AI compila tutto', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
            if (!_isScanning) const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      const Center(child: Text('oppure compila manualmente', style: TextStyle(fontSize: 12, color: AppColors.textLight))),
      const SizedBox(height: 12),
      _field(_nomeCtrl, 'Nome', Icons.person),
      _field(_cognomeCtrl, 'Cognome', Icons.person_outline),
      _field(_dataNascitaCtrl, 'Data di nascita', Icons.cake),
      _field(_luogoNascitaCtrl, 'Luogo di nascita', Icons.location_city),
      _field(_nazionalitaCtrl, 'Nazionalità', Icons.flag),
      _field(_cfCtrl, 'Codice Fiscale', Icons.badge),
    ]);
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 3: INDIRIZZO
  // ══════════════════════════════════════════════════════════════
  Widget _step3Indirizzo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('Dove vivi attualmente?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 4),
      const Text('Inserisci il tuo indirizzo attuale', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
      const SizedBox(height: 16),
      _field(_indirizzoCtrl, 'Indirizzo (Via, N°)', Icons.home),
      Row(children: [
        Expanded(flex: 2, child: _field(_cittaCtrl, 'Città', Icons.location_on)),
        const SizedBox(width: 10),
        Expanded(child: _field(_capCtrl, 'CAP', Icons.markunread_mailbox)),
      ]),
      _field(_telCtrl, 'Telefono', Icons.phone, keyboard: TextInputType.phone),
      _field(_emailCtrl, 'Email', Icons.email, keyboard: TextInputType.emailAddress),
    ]);
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 4: ESPERIENZE LAVORATIVE
  // ══════════════════════════════════════════════════════════════
  Widget _step4Esperienze() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // AI Generator
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
            SizedBox(width: 8),
            Text('AI Completa il CV', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.purple)),
          ]),
          const SizedBox(height: 8),
          const Text('Scrivi che lavoro cerchi e AI aggiunge esperienze pertinenti', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 10),
          TextField(
            controller: _lavoroCercatoCtrl,
            decoration: InputDecoration(
              hintText: 'Es: confezionamento, magazziniere, pulizie...',
              hintStyle: const TextStyle(fontSize: 13),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _isGenerating ? null : _generateExperiences,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: _isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Genera Esperienze con AI', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      // Esperienze list
      Row(children: [
        const Text('Le tue esperienze', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const Spacer(),
        GestureDetector(
          onTap: () {
            setState(() => _esperienze.add(_Esperienza()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, size: 16, color: AppColors.primary),
              SizedBox(width: 4),
              Text('Aggiungi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      if (_esperienze.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Text('Nessuna esperienza. Aggiungi manualmente o usa AI!', style: TextStyle(color: AppColors.textLight, fontSize: 13))),
        ),
      ..._esperienze.asMap().entries.map((entry) => _buildEsperienzaCard(entry.key, entry.value)),
    ]);
  }

  Widget _buildEsperienzaCard(int index, _Esperienza e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: e.isAi ? Colors.purple.shade200 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (e.isAi) Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
            child: const Text('AI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.purple)),
          ),
          Expanded(child: Text(e.ruolo.isNotEmpty ? e.ruolo : 'Esperienza ${index + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          GestureDetector(
            onTap: () => setState(() => _esperienze.removeAt(index)),
            child: const Icon(Icons.close, size: 18, color: Colors.red),
          ),
        ]),
        const SizedBox(height: 8),
        _miniField('Azienda', e.azienda, (v) => e.azienda = v),
        _miniField('Ruolo', e.ruolo, (v) => e.ruolo = v),
        _miniField('Periodo (es: 01/2022 - 06/2023)', e.dalAl, (v) => e.dalAl = v),
        _miniField('Descrizione mansioni', e.descrizione, (v) => e.descrizione = v),
      ]),
    );
  }

  Widget _miniField(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextField(
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 5: PATENTE E LINGUE
  // ══════════════════════════════════════════════════════════════
  Widget _step5Patente() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      // Patente
      const Text('Patente di guida', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 10),
      Row(children: [
        _choiceChip('Sì', _haPatente, () => setState(() => _haPatente = true)),
        const SizedBox(width: 10),
        _choiceChip('No', !_haPatente, () => setState(() { _haPatente = false; _patenti.clear(); })),
      ]),
      if (_haPatente) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: _patenteOpts.map((p) => FilterChip(
          label: Text(p),
          selected: _patenti.contains(p),
          onSelected: (v) => setState(() => v ? _patenti.add(p) : _patenti.remove(p)),
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
        )).toList()),
      ],
      const SizedBox(height: 24),
      // Lingua madre
      const Text('Lingua madre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 10),
      _dropdown(_linguaMadre, _lingue, (v) => setState(() => _linguaMadre = v!)),
      const SizedBox(height: 24),
      // Livello italiano
      const Text('Livello di Italiano', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: _levels.map((l) => ChoiceChip(
        label: Text(l),
        selected: _italianoLevel == l,
        onSelected: (_) => setState(() => _italianoLevel = l),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
      )).toList()),
    ]);
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textDark)),
      ),
    );
  }

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      )),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 6: SCEGLI STILE
  // ══════════════════════════════════════════════════════════════
  Widget _step6Stile() {
    final styles = [
      _StyleInfo('Classico', Colors.grey.shade800, Icons.article),
      _StyleInfo('Moderno', Colors.blue.shade700, Icons.dashboard),
      _StyleInfo('Europass', const Color(0xFF003399), Icons.euro),
      _StyleInfo('Minimalista', Colors.grey.shade600, Icons.crop_square),
      _StyleInfo('Creativo', Colors.orange.shade700, Icons.palette),
      _StyleInfo('Professionale', const Color(0xFF1B5E20), Icons.business_center),
      _StyleInfo('Elegante', Colors.brown.shade700, Icons.auto_awesome),
      _StyleInfo('Colorato', Colors.purple.shade700, Icons.color_lens),
      _StyleInfo('Tech', Colors.teal.shade700, Icons.code),
      _StyleInfo('Semplice', Colors.black87, Icons.text_fields),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('Scegli lo stile del tuo CV', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 4),
      const Text('Tocca per selezionare, poi premi Genera PDF', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.2),
        itemCount: 10,
        itemBuilder: (_, i) {
          final s = styles[i];
          final selected = _selectedStyle == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedStyle = i),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? s.color : Colors.grey.shade200, width: selected ? 3 : 1),
                boxShadow: selected ? [BoxShadow(color: s.color.withValues(alpha: 0.2), blurRadius: 12)] : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: s.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(s.icon, color: s.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(s.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? s.color : AppColors.textDark)),
                if (selected) ...[
                  const SizedBox(height: 4),
                  Icon(Icons.check_circle, color: s.color, size: 18),
                ],
              ]),
            ),
          );
        },
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════════
  // COMMON WIDGETS
  // ══════════════════════════════════════════════════════════════
  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PDF GENERATION
  // ══════════════════════════════════════════════════════════════
  Future<void> _generatePdf() async {
    final nome = '${_nomeCtrl.text.trim()} ${_cognomeCtrl.text.trim()}'.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inserisci almeno il nome'), backgroundColor: Colors.orange));
      return;
    }

    pw.MemoryImage? photoImage;
    if (_photo != null) {
      photoImage = pw.MemoryImage(await _photo!.readAsBytes());
    }

    final data = _CvData(
      nome: nome,
      dataNascita: _dataNascitaCtrl.text.trim(),
      luogoNascita: _luogoNascitaCtrl.text.trim(),
      nazionalita: _nazionalitaCtrl.text.trim(),
      cf: _cfCtrl.text.trim(),
      indirizzo: '${_indirizzoCtrl.text.trim()}, ${_capCtrl.text.trim()} ${_cittaCtrl.text.trim()}'.trim(),
      telefono: _telCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      esperienze: _esperienze,
      haPatente: _haPatente,
      patenti: _patenti.toList()..sort(),
      linguaMadre: _linguaMadre,
      italianoLevel: _italianoLevel,
      photo: photoImage,
    );

    final doc = _buildPdf(data, _selectedStyle);

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  pw.Document _buildPdf(_CvData d, int style) {
    final colors = [
      PdfColors.grey800,     // 0 Classico
      PdfColors.blue700,     // 1 Moderno
      PdfColor.fromHex('#003399'), // 2 Europass
      PdfColors.grey600,     // 3 Minimalista
      PdfColors.orange700,   // 4 Creativo
      PdfColor.fromHex('#1B5E20'), // 5 Professionale
      PdfColors.brown700,    // 6 Elegante
      PdfColors.purple700,   // 7 Colorato
      PdfColors.teal700,     // 8 Tech
      PdfColors.grey900,     // 9 Semplice
    ];
    final accent = colors[style];

    final doc = pw.Document();
    final hasPhoto = d.photo != null;

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) {
        final widgets = <pw.Widget>[];

        // ── Header ──
        if (style == 1 || style == 4 || style == 7) {
          // Moderno / Creativo / Colorato — full-width header bar
          widgets.add(pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(color: accent, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(children: [
              if (hasPhoto) ...[
                pw.ClipOval(child: pw.Image(d.photo!, width: 60, height: 60, fit: pw.BoxFit.cover)),
                pw.SizedBox(width: 16),
              ],
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(d.nome, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                if (d.telefono.isNotEmpty || d.email.isNotEmpty)
                  pw.Text('${d.telefono}  ${d.email}'.trim(), style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                if (d.indirizzo.isNotEmpty && d.indirizzo != ', ')
                  pw.Text(d.indirizzo, style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
              ])),
            ]),
          ));
        } else {
          // Other styles — classic header
          widgets.add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (hasPhoto) ...[
              pw.ClipOval(child: pw.Image(d.photo!, width: 56, height: 56, fit: pw.BoxFit.cover)),
              pw.SizedBox(width: 14),
            ],
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(d.nome, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: accent)),
              pw.SizedBox(height: 4),
              if (d.telefono.isNotEmpty || d.email.isNotEmpty)
                pw.Text('${d.telefono}  |  ${d.email}'.trim(), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (d.indirizzo.isNotEmpty && d.indirizzo != ', ')
                pw.Text(d.indirizzo, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ])),
          ]));
        }

        widgets.add(pw.SizedBox(height: 6));
        widgets.add(pw.Divider(color: accent, thickness: 2));
        widgets.add(pw.SizedBox(height: 10));

        // ── Dati personali ──
        widgets.add(_pdfSection('DATI PERSONALI', accent));
        final info = <String>[];
        if (d.dataNascita.isNotEmpty) info.add('Data di nascita: ${d.dataNascita}');
        if (d.luogoNascita.isNotEmpty) info.add('Luogo di nascita: ${d.luogoNascita}');
        if (d.nazionalita.isNotEmpty) info.add('Nazionalità: ${d.nazionalita}');
        if (d.cf.isNotEmpty) info.add('Codice Fiscale: ${d.cf}');
        for (final i in info) {
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(i, style: const pw.TextStyle(fontSize: 10)),
          ));
        }

        // ── Esperienze ──
        if (d.esperienze.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 12));
          widgets.add(_pdfSection('ESPERIENZE LAVORATIVE', accent));
          for (final e in d.esperienze) {
            widgets.add(pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('${e.ruolo} — ${e.azienda}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (e.dalAl.isNotEmpty) pw.Text(e.dalAl, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
                if (e.descrizione.isNotEmpty) pw.Text(e.descrizione, style: const pw.TextStyle(fontSize: 10)),
              ]),
            ));
          }
        }

        // ── Lingue ──
        widgets.add(pw.SizedBox(height: 12));
        widgets.add(_pdfSection('COMPETENZE LINGUISTICHE', accent));
        widgets.add(pw.Text('Lingua madre: ${d.linguaMadre}', style: const pw.TextStyle(fontSize: 10)));
        widgets.add(pw.Text('Italiano: ${d.italianoLevel}', style: const pw.TextStyle(fontSize: 10)));

        // ── Patente ──
        if (d.haPatente && d.patenti.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 12));
          widgets.add(_pdfSection('PATENTE', accent));
          widgets.add(pw.Text('Patente: ${d.patenti.join(", ")}', style: const pw.TextStyle(fontSize: 10)));
        }

        // ── Footer ──
        widgets.add(pw.SizedBox(height: 20));
        widgets.add(pw.Divider(color: PdfColors.grey300));
        widgets.add(pw.Text(
          'Autorizzo il trattamento dei miei dati personali ai sensi del D.Lgs. 196/03 e del GDPR (UE) 2016/679.',
          style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey500),
        ));

        return widgets;
      },
    ));

    return doc;
  }

  pw.Widget _pdfSection(String title, PdfColor accent) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent)),
    );
  }
}

// ── Helper classes ──
class _StyleInfo {
  final String name;
  final Color color;
  final IconData icon;
  const _StyleInfo(this.name, this.color, this.icon);
}

class _CvData {
  final String nome, dataNascita, luogoNascita, nazionalita, cf, indirizzo, telefono, email;
  final List<_Esperienza> esperienze;
  final bool haPatente;
  final List<String> patenti;
  final String linguaMadre, italianoLevel;
  final pw.MemoryImage? photo;
  _CvData({
    required this.nome, required this.dataNascita, required this.luogoNascita,
    required this.nazionalita, required this.cf, required this.indirizzo,
    required this.telefono, required this.email, required this.esperienze,
    required this.haPatente, required this.patenti, required this.linguaMadre,
    required this.italianoLevel, this.photo,
  });
}
