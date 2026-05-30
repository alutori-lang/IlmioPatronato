import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/services/ad_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

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

  // Suggerimenti lavori per categoria
  static const _jobSuggestions = <String, List<String>>{
    'operaio': ['Operaio generico', 'Operaio metalmeccanico', 'Operaio edile', 'Operaio di produzione', 'Addetto linea di montaggio', 'Saldatore', 'Carpentiere', 'Tornitore CNC'],
    'magazzin': ['Magazziniere', 'Carrellista', 'Addetto logistica', 'Preparatore ordini', 'Addetto spedizioni', 'Mulettista'],
    'pulizi': ['Addetto pulizie', 'Operatore ecologico', 'Addetto sanificazione', 'Cameriera ai piani'],
    'ristoraz': ['Cuoco', 'Aiuto cuoco', 'Cameriere', 'Barista', 'Lavapiatti', 'Pizzaiolo', 'Addetto mensa'],
    'cucina': ['Cuoco', 'Aiuto cuoco', 'Pizzaiolo', 'Pasticcere', 'Addetto mensa'],
    'edil': ['Muratore', 'Carpentiere', 'Piastrellista', 'Imbianchino', 'Elettricista', 'Idraulico', 'Manovale edile'],
    'trasport': ['Autista', 'Corriere', 'Autista consegne', 'Rider', 'Autista bus', 'Camionista'],
    'autist': ['Autista patente B', 'Autista patente C', 'Camionista', 'Corriere', 'Autista consegne', 'Autista NCC'],
    'vendita': ['Commesso', 'Addetto vendite', 'Cassiere', 'Visual merchandiser', 'Promoter'],
    'agricol': ['Bracciante agricolo', 'Operaio agricolo', 'Raccoglitore', 'Giardiniere', 'Vivaista'],
    'facchin': ['Facchino', 'Addetto carico/scarico', 'Magazziniere', 'Movimentatore merci'],
    'confezion': ['Addetto confezionamento', 'Operaio confezionamento', 'Addetto packaging', 'Operaio alimentare'],
    'badant': ['Badante', 'Assistente familiare', 'OSS', 'Assistente anziani'],
    'colf': ['Colf', 'Collaboratrice domestica', 'Baby sitter', 'Governante'],
    'sanita': ['Infermiere', 'OSS', 'Assistente sanitario', 'Operatore socio-sanitario', 'Ausiliario ospedaliero'],
    'estetic': ['Parrucchiere', 'Barbiere', 'Estetista', 'Manicurista', 'Massaggiatore', 'Truccatore'],
    'meccanic': ['Meccanico auto', 'Carrozziere', 'Gommista', 'Elettrauto', 'Meccanico moto'],
    'portier': ['Portiere', 'Custode', 'Vigilanza', 'Guardia giurata', 'Steward'],
    'lavander': ['Addetto lavanderia', 'Stiratrice', 'Lavasecco', 'Operatore tintoria'],
  };

  // Preview rasterized images (one per style)
  final Map<int, Uint8List?> _previewBytes = {};
  bool _previewsBuilding = true;

  @override
  void initState() {
    super.initState();
    _buildAllPreviews();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose(); _cognomeCtrl.dispose(); _dataNascitaCtrl.dispose();
    _luogoNascitaCtrl.dispose(); _nazionalitaCtrl.dispose(); _cfCtrl.dispose();
    _indirizzoCtrl.dispose(); _cittaCtrl.dispose(); _capCtrl.dispose();
    _telCtrl.dispose(); _emailCtrl.dispose(); _lavoroCercatoCtrl.dispose();
    super.dispose();
  }

  // Sample CV data (Mario Rossi) used for preview thumbnails so the user can
  // see what each style looks like fully populated before choosing.
  _CvData _sampleData() => _CvData(
        nome: 'Mario Rossi',
        dataNascita: '15/06/1985',
        luogoNascita: 'Roma',
        nazionalita: 'Italiana',
        cf: 'RSSMRA85H15H501Z',
        indirizzo: 'Via Roma 12, 00100 Roma',
        telefono: '+39 333 123 4567',
        email: 'mario.rossi@email.com',
        posizione: 'Operaio Specializzato',
        esperienze: [
          _Esperienza(azienda: 'Edilcasa SRL', ruolo: 'Muratore', dalAl: '2020 - presente', descrizione: 'Costruzioni residenziali e ristrutturazioni edili.'),
          _Esperienza(azienda: 'Logistica Italia', ruolo: 'Magazziniere', dalAl: '2017 - 2020', descrizione: 'Gestione magazzino, mulettista patentato, carico/scarico merci.'),
        ],
        haPatente: true,
        patenti: ['B'],
        linguaMadre: 'Italiano',
        italianoLevel: 'C2',
        photo: null,
      );

  Future<void> _buildAllPreviews() async {
    final sample = _sampleData();
    for (int i = 0; i < 10; i++) {
      try {
        final pdf = _buildPdf(sample, i);
        final bytes = await pdf.save();
        await for (final page in Printing.raster(bytes, dpi: 60)) {
          final png = await page.toPng();
          if (!mounted) return;
          setState(() => _previewBytes[i] = png);
          break;
        }
      } catch (_) {
        if (!mounted) return;
        setState(() => _previewBytes[i] = null);
      }
    }
    if (mounted) setState(() => _previewsBuilding = false);
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
          child: [_stepStyleWithPreviews, _step1Photo, _step2Dati, _step3Indirizzo, _step4Esperienze, _step5Patente][_step](),
        )),
        _buildNavBar(),
      ]),
    );
  }

  Widget _buildHeader() {
    final titles = ['Scegli Stile', 'Foto Profilo', 'Dati Personali', 'Indirizzo', 'Esperienze', 'Patente & Lingue'];
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
          onTap: _step < 5
              ? () => setState(() => _step++)
              : () => AdService().showRewardedThen(_generatePdf),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(
              _step < 5 ? 'Avanti' : 'Scarica PDF',
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
  List<Widget> _buildJobSuggestions() {
    final input = _lavoroCercatoCtrl.text.trim().toLowerCase();
    final suggestions = <String>{};
    for (final entry in _jobSuggestions.entries) {
      if (input.contains(entry.key) || entry.key.contains(input)) {
        suggestions.addAll(entry.value);
      }
    }
    if (suggestions.isEmpty) return [];
    return [
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: suggestions.map((job) => GestureDetector(
          onTap: () {
            _lavoroCercatoCtrl.text = job;
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Text(job, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple.shade700)),
          ),
        )).toList(),
      ),
    ];
  }

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
          const Text('Scrivi che lavoro cerchi e AI aggiunge esperienze', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 10),
          TextField(
            controller: _lavoroCercatoCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Es: operaio, magazziniere, pulizie...',
              hintStyle: const TextStyle(fontSize: 13),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          // Suggerimenti smart
          if (_lavoroCercatoCtrl.text.trim().length >= 3)
            ..._buildJobSuggestions(),
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
  // STEP 0: SCEGLI STILE — anteprime PDF reali (Mario Rossi)
  // ══════════════════════════════════════════════════════════════
  Widget _stepStyleWithPreviews() {
    const names = [
      'Classico', 'Moderno', 'Europass', 'Minimalista', 'Creativo',
      'Professionale', 'Elegante', 'Colorato', 'Tech', 'Semplice',
    ];
    final accents = [
      Colors.grey.shade800, Colors.blue.shade700, const Color(0xFF003399),
      Colors.grey.shade600, Colors.orange.shade700, const Color(0xFF1B5E20),
      Colors.brown.shade700, Colors.purple.shade700, Colors.teal.shade700, Colors.black87,
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      const Text('Scegli lo stile del tuo CV', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      const SizedBox(height: 4),
      Text(_previewsBuilding
          ? 'Sto generando le anteprime con dati di esempio...'
          : 'Tocca un design per selezionarlo, poi premi Avanti per compilare i tuoi dati',
        style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72, // A4 portrait-ish
        ),
        itemCount: 10,
        itemBuilder: (_, i) {
          final selected = _selectedStyle == i;
          final accent = accents[i];
          final png = _previewBytes[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedStyle = i),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? accent : Colors.grey.shade300,
                  width: selected ? 3 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(children: [
                  Positioned.fill(
                    child: png != null
                        ? Image.memory(png, fit: BoxFit.cover, gaplessPlayback: true)
                        : Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
                                ),
                                const SizedBox(height: 10),
                                Text(names[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                              ]),
                            ),
                          ),
                  ),
                  // Bottom gradient overlay with name
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                        ),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            names[i],
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      ]),
                    ),
                  ),
                ]),
              ),
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
      posizione: _lavoroCercatoCtrl.text.trim(),
      haPatente: _haPatente,
      patenti: _patenti.toList()..sort(),
      linguaMadre: _linguaMadre,
      italianoLevel: _italianoLevel,
      photo: photoImage,
    );

    final doc = _buildPdf(data, _selectedStyle);
    final bytes = await doc.save();

    // Download directly to a file (no print dialog)
    Directory? dir;
    try {
      dir = await getExternalStorageDirectory();
    } catch (_) {}
    dir ??= await getApplicationDocumentsDirectory();
    final cleanName = nome.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    final filename = 'CV_$cleanName.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('PDF scaricato: $filename', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'APRI',
          textColor: Colors.white,
          onPressed: () {
            Share.shareXFiles([XFile(file.path)], subject: filename);
          },
        ),
      ),
    );
  }

  pw.Document _buildPdf(_CvData d, int style) {
    switch (style) {
      case 0: return _pdfClassico(d);
      case 1: return _pdfModerno(d);
      case 2: return _pdfEuropass(d);
      case 3: return _pdfMinimalista(d);
      case 4: return _pdfCreativo(d);
      case 5: return _pdfProfessionale(d);
      case 6: return _pdfElegante(d);
      case 7: return _pdfColorato(d);
      case 8: return _pdfTech(d);
      case 9: return _pdfSemplice(d);
      default: return _pdfClassico(d);
    }
  }

  // Shared helpers
  List<String> _personalInfo(_CvData d) {
    final l = <String>[];
    if (d.dataNascita.isNotEmpty) l.add('Data di nascita: ${d.dataNascita}');
    if (d.luogoNascita.isNotEmpty) l.add('Luogo: ${d.luogoNascita}');
    if (d.nazionalita.isNotEmpty) l.add('Nazionalità: ${d.nazionalita}');
    if (d.cf.isNotEmpty) l.add('CF: ${d.cf}');
    return l;
  }

  pw.Widget _privacyFooter() => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18),
        child: pw.Text(
          'Autorizzo il trattamento dei miei dati personali ai sensi del D.Lgs. 196/03 e del GDPR (UE) 2016/679.',
          style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey500),
        ),
      );

  // ════════════════════════════════════════════════════════════════
  // 0. CLASSICO — Centered name, double horizontal lines, traditional
  // ════════════════════════════════════════════════════════════════
  pw.Document _pdfClassico(_CvData d) {
    final accent = PdfColors.grey800;
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (_) => [
        if (d.photo != null) pw.Center(child: pw.ClipOval(child: pw.Image(d.photo!, width: 80, height: 80, fit: pw.BoxFit.cover))),
        if (d.photo != null) pw.SizedBox(height: 12),
        pw.Center(child: pw.Text(d.nome, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: accent, letterSpacing: 2))),
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text('${d.telefono} • ${d.email}'.replaceAll(' • ', d.telefono.isEmpty || d.email.isEmpty ? '' : ' • '), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
        if (d.indirizzo.trim().replaceAll(',', '').trim().isNotEmpty) pw.Center(child: pw.Text(d.indirizzo, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
        pw.SizedBox(height: 12),
        pw.Container(height: 2, color: accent),
        pw.SizedBox(height: 1),
        pw.Container(height: 1, color: accent),
        pw.SizedBox(height: 16),
        ..._classicoSections(d, accent),
        _privacyFooter(),
      ],
    ));
    return doc;
  }

  List<pw.Widget> _classicoSections(_CvData d, PdfColor accent) {
    final w = <pw.Widget>[];
    void section(String title) {
      w.add(pw.SizedBox(height: 8));
      w.add(pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent, letterSpacing: 1.5)));
      w.add(pw.Container(height: 0.6, color: accent, margin: const pw.EdgeInsets.only(top: 3, bottom: 8)));
    }
    section('DATI PERSONALI');
    for (final l in _personalInfo(d)) {
      w.add(pw.Text(l, style: const pw.TextStyle(fontSize: 10)));
    }
    if (d.posizione.isNotEmpty) { section('POSIZIONE DESIDERATA'); w.add(pw.Text(d.posizione, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))); }
    if (d.esperienze.isNotEmpty) {
      section('ESPERIENZE LAVORATIVE');
      for (final e in d.esperienze) {
        w.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('${e.ruolo} — ${e.azienda}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          if (e.dalAl.isNotEmpty) pw.Text(e.dalAl, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
          if (e.descrizione.isNotEmpty) pw.Text(e.descrizione, style: const pw.TextStyle(fontSize: 10)),
        ])));
      }
    }
    section('COMPETENZE LINGUISTICHE');
    w.add(pw.Text('Lingua madre: ${d.linguaMadre}', style: const pw.TextStyle(fontSize: 10)));
    w.add(pw.Text('Italiano: ${d.italianoLevel}', style: const pw.TextStyle(fontSize: 10)));
    if (d.haPatente && d.patenti.isNotEmpty) { section('PATENTE'); w.add(pw.Text(d.patenti.join(', '), style: const pw.TextStyle(fontSize: 10))); }
    return w;
  }

  // ════════════════════════════════════════════════════════════════
  // 1. MODERNO — Full-width colored header bar, white text, photo round
  // ════════════════════════════════════════════════════════════════
  pw.Document _pdfModerno(_CvData d) {
    final accent = PdfColors.blue700;
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => [
        // Banner header bleed
        pw.Container(
          color: accent,
          padding: const pw.EdgeInsets.fromLTRB(40, 36, 40, 28),
          child: pw.Row(children: [
            if (d.photo != null) ...[
              pw.Container(width: 80, height: 80, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: PdfColors.white, width: 3)),
                child: pw.ClipOval(child: pw.Image(d.photo!, fit: pw.BoxFit.cover))),
              pw.SizedBox(width: 20),
            ],
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(d.nome, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              if (d.posizione.isNotEmpty) pw.Text(d.posizione.toUpperCase(), style: pw.TextStyle(fontSize: 11, color: PdfColors.white, letterSpacing: 2)),
              pw.SizedBox(height: 8),
              if (d.telefono.isNotEmpty) pw.Text('TEL  ${d.telefono}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
              if (d.email.isNotEmpty) pw.Text('MAIL  ${d.email}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            ])),
          ]),
        ),
        pw.Padding(padding: const pw.EdgeInsets.fromLTRB(40, 20, 40, 28), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          ..._modernoSections(d, accent),
          _privacyFooter(),
        ])),
      ],
    ));
    return doc;
  }

  List<pw.Widget> _modernoSections(_CvData d, PdfColor accent) {
    final w = <pw.Widget>[];
    void section(String title) {
      w.add(pw.SizedBox(height: 12));
      w.add(pw.Row(children: [
        pw.Container(width: 4, height: 14, color: accent),
        pw.SizedBox(width: 8),
        pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: accent)),
      ]));
      w.add(pw.SizedBox(height: 8));
    }
    if (_personalInfo(d).isNotEmpty) { section('Dati Personali'); for (final l in _personalInfo(d)) w.add(pw.Text(l, style: const pw.TextStyle(fontSize: 10))); }
    if (d.esperienze.isNotEmpty) {
      section('Esperienze');
      for (final e in d.esperienze) {
        w.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 10), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(children: [
            pw.Expanded(child: pw.Text(e.ruolo, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent))),
            if (e.dalAl.isNotEmpty) pw.Text(e.dalAl, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ]),
          pw.Text(e.azienda, style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
          if (e.descrizione.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 3), child: pw.Text(e.descrizione, style: const pw.TextStyle(fontSize: 10))),
        ])));
      }
    }
    section('Lingue');
    w.add(pw.Text('${d.linguaMadre} (madre) • Italiano ${d.italianoLevel}', style: const pw.TextStyle(fontSize: 10)));
    if (d.haPatente && d.patenti.isNotEmpty) { section('Patente'); w.add(pw.Text(d.patenti.join(' • '), style: const pw.TextStyle(fontSize: 10))); }
    return w;
  }

  // ════════════════════════════════════════════════════════════════
  // 2. EUROPASS — Blue left vertical bar with "EUROPASS" wordmark
  // ════════════════════════════════════════════════════════════════
  pw.Document _pdfEuropass(_CvData d) {
    final accent = PdfColor.fromHex('#003399');
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Stack(children: [
        // Left blue bar
        pw.Positioned(left: 0, top: 0, bottom: 0, child: pw.Container(width: 50, color: accent, child: pw.Padding(
          padding: const pw.EdgeInsets.only(top: 30),
          child: pw.Center(child: pw.Transform.rotate(angle: -1.5708, child: pw.Text('EUROPASS  CURRICULUM VITAE', style: pw.TextStyle(fontSize: 12, color: PdfColors.white, letterSpacing: 4, fontWeight: pw.FontWeight.bold)))),
        ))),
        // Content
        pw.Positioned(left: 70, top: 36, right: 36, bottom: 36, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (d.photo != null) ...[
              pw.Container(width: 70, height: 90, decoration: pw.BoxDecoration(border: pw.Border.all(color: accent, width: 1)), child: pw.Image(d.photo!, fit: pw.BoxFit.cover)),
              pw.SizedBox(width: 16),
            ],
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('CURRICULUM VITAE', style: pw.TextStyle(fontSize: 9, color: accent, letterSpacing: 2)),
              pw.SizedBox(height: 2),
              pw.Text(d.nome, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: accent)),
              pw.SizedBox(height: 6),
              if (d.indirizzo.trim().replaceAll(',', '').trim().isNotEmpty) pw.Text('Indirizzo: ${d.indirizzo}', style: const pw.TextStyle(fontSize: 9)),
              if (d.telefono.isNotEmpty) pw.Text('Telefono: ${d.telefono}', style: const pw.TextStyle(fontSize: 9)),
              if (d.email.isNotEmpty) pw.Text('Email: ${d.email}', style: const pw.TextStyle(fontSize: 9)),
            ])),
          ]),
          pw.SizedBox(height: 16),
          pw.Container(height: 1, color: accent),
          pw.SizedBox(height: 12),
          ..._europassRows(d, accent),
          pw.Spacer(),
          _privacyFooter(),
        ])),
      ]),
    ));
    return doc;
  }

  List<pw.Widget> _europassRows(_CvData d, PdfColor accent) {
    final w = <pw.Widget>[];
    void row(String label, pw.Widget content) {
      w.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 10), child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(width: 130, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: accent, fontWeight: pw.FontWeight.bold))),
        pw.Expanded(child: content),
      ])));
    }
    row('INFORMAZIONI PERSONALI', pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: _personalInfo(d).map((l) => pw.Text(l, style: const pw.TextStyle(fontSize: 10))).toList()));
    if (d.posizione.isNotEmpty) row('POSIZIONE DESIDERATA', pw.Text(d.posizione, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)));
    if (d.esperienze.isNotEmpty) row('ESPERIENZA LAVORATIVA', pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: d.esperienze.map((e) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('${e.dalAl}  ${e.ruolo}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      pw.Text(e.azienda, style: const pw.TextStyle(fontSize: 9)),
      if (e.descrizione.isNotEmpty) pw.Text(e.descrizione, style: const pw.TextStyle(fontSize: 9)),
    ]))).toList()));
    row('LINGUA MADRE', pw.Text(d.linguaMadre, style: const pw.TextStyle(fontSize: 10)));
    row('ALTRA LINGUA', pw.Text('Italiano — Livello ${d.italianoLevel}', style: const pw.TextStyle(fontSize: 10)));
    if (d.haPatente && d.patenti.isNotEmpty) row('PATENTE DI GUIDA', pw.Text(d.patenti.join(', '), style: const pw.TextStyle(fontSize: 10)));
    return w;
  }

  // ════════════════════════════════════════════════════════════════
  // 3. MINIMALISTA — Pure white, hairlines, light typography
  // ════════════════════════════════════════════════════════════════
  pw.Document _pdfMinimalista(_CvData d) {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(70),
      build: (_) => [
        pw.Text(d.nome, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.normal, color: PdfColors.grey900, letterSpacing: 1)),
        pw.SizedBox(height: 4),
        pw.Text([if (d.telefono.isNotEmpty) d.telefono, if (d.email.isNotEmpty) d.email, if (d.indirizzo.trim().replaceAll(',', '').trim().isNotEmpty) d.indirizzo].join('   '), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, letterSpacing: 0.5)),
        pw.SizedBox(height: 30),
        ..._minimalistaSections(d),
        _privacyFooter(),
      ],
    ));
    return doc;
  }

  List<pw.Widget> _minimalistaSections(_CvData d) {
    final w = <pw.Widget>[];
    void section(String title) {
      w.add(pw.SizedBox(height: 18));
      w.add(pw.Row(children: [
        pw.Container(width: 18, height: 0.4, color: PdfColors.grey800, margin: const pw.EdgeInsets.only(right: 10, top: 6)),
        pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800, letterSpacing: 4, fontWeight: pw.FontWeight.bold)),
      ]));
      w.add(pw.SizedBox(height: 10));
    }
    section('Profilo');
    for (final l in _personalInfo(d)) w.add(pw.Text(l, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800, lineSpacing: 3)));
    if (d.posizione.isNotEmpty) { section('Obiettivo'); w.add(pw.Text(d.posizione, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey900))); }
    if (d.esperienze.isNotEmpty) {
      section('Esperienze');
      for (final e in d.esperienze) {
        w.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 12), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(e.ruolo.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
          pw.Text('${e.azienda}${e.dalAl.isEmpty ? '' : '  ·  ${e.dalAl}'}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          if (e.descrizione.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 4), child: pw.Text(e.descrizione, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800, lineSpacing: 2))),
        ])));
      }
    }
    section('Lingue');
    w.add(pw.Text('${d.linguaMadre}  ·  Italiano ${d.italianoLevel}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)));
    if (d.haPatente && d.patenti.isNotEmpty) { section('Patente'); w.add(pw.Text(d.patenti.join('  ·  '), style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800))); }
    return w;
  }

  // ════════════════════════════════════════════════════════════════
  // 4. CREATIVO — Top orange block with photo+name, asymmetric layout
  // ════════════════════════════════════════════════════════════════
  pw.Document _pdfCreativo(_CvData d) {
    final accent = PdfColors.orange700;
    final accentSoft = PdfColors.orange100;
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => [
        pw.Stack(children: [
          pw.Container(height: 200, color: accent),
          pw.Positioned(right: -40, top: -40, child: pw.Container(width: 200, height: 200, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: accentSoft))),
          pw.Padding(padding: const pw.EdgeInsets.fromLTRB(40, 50, 40, 0), child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (d.photo != null) ...[
              pw.Container(width: 100, height: 100, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: PdfColors.white, width: 4)),
                child: pw.ClipOval(child: pw.Image(d.photo!, fit: pw.BoxFit.cover))),
              pw.SizedBox(width: 18),
            ],
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.SizedBox(height: 10),
              pw.Text(d.nome.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 2)),
              pw.SizedBox(height: 6),
              if (d.posizione.isNotEmpty) pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4), color: PdfColors.white, child: pw.Text(d.posizione, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: accent))),
              pw.SizedBox(height: 10),
              if (d.telefono.isNotEmpty) pw.Text('☎  ${d.telefono}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
              if (d.email.isNotEmpty) pw.Text('✉  ${d.email}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            ])),
          ])),
        ]),
        pw.Padding(padding: const pw.EdgeInsets.fromLTRB(40, 24, 40, 30), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          ..._creativoSections(d, accent, accentSoft),
          _privacyFooter(),
        ])),
      ],
    ));
    return doc;
  }

  List<pw.Widget> _creativoSections(_CvData d, PdfColor accent, PdfColor accentSoft) {
    final w = <pw.Widget>[];
    void section(String title) {
      w.add(pw.SizedBox(height: 10));
      w.add(pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5), color: accentSoft,
        child: pw.Text('▶  $title', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: accent, letterSpacing: 1))));
      w.add(pw.SizedBox(height: 8));
    }
    section('CHI SONO');
    for (final l in _personalInfo(d)) w.add(pw.Text(l, style: const pw.TextStyle(fontSize: 10)));
    if (d.esperienze.isNotEmpty) {
      section('LE MIE ESPERIENZE');
      for (final e in d.esperienze) {
        w.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(width: 8, height: 8, margin: const pw.EdgeInsets.only(top: 4, right: 8), decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: accent)),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('${e.ruolo} @ ${e.azienda}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: accent)),
            if (e.dalAl.isNotEmpty) pw.Text(e.dalAl, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            if (e.descrizione.isNotEmpty) pw.Text(e.descrizione, style: const pw.TextStyle(fontSize: 10)),
          ])),
        ])));
      }
    }
    section('LINGUE & PATENTE');
    w.add(pw.Wrap(spacing: 8, runSpacing: 6, children: [
      pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: pw.BoxDecoration(border: pw.Border.all(color: accent, width: 1.2), borderRadius: pw.BorderRadius.circular(20)), child: pw.Text('${d.linguaMadre} ★', style: pw.TextStyle(fontSize: 10, color: accent, fontWeight: pw.FontWeight.bold))),
      pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: pw.BoxDecoration(border: pw.Border.all(color: accent, width: 1.2), borderRadius: pw.BorderRadius.circular(20)), child: pw.Text('Italiano ${d.italianoLevel}', style: pw.TextStyle(fontSize: 10, color: accent))),
      if (d.haPatente) ...d.patenti.map((p) => pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4), color: accent, child: pw.Text('Patente $p', style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)))),
    ]));
    return w;
  }

  // ════════════════════════════════════════════════════════════════
  // 5. PROFESSIONALE — Two-column with dark green sidebar on left
  // ════════════════════════════════════════════════════════════════
  pw.Document _pdfProfessionale(_CvData d) {
    final accent = PdfColor.fromHex('#1B5E20');
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        // SIDEBAR LEFT
        pw.Container(width: 180, height: PdfPageFormat.a4.availableHeight + 36, color: accent, padding: const pw.EdgeInsets.all(20),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (d.photo != null) pw.Center(child: pw.Container(width: 120, height: 120, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: PdfColors.white, width: 4)),
              child: pw.ClipOval(child: pw.Image(d.photo!, fit: pw.BoxFit.cover)))),
            pw.SizedBox(height: 20),
            pw.Text('CONTATTI', style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
            pw.Container(width: 30, height: 2, color: PdfColors.white, margin: const pw.EdgeInsets.symmetric(vertical: 6)),
            if (d.telefono.isNotEmpty) pw.Text(d.telefono, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            if (d.email.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 3), child: pw.Text(d.email, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white))),
            if (d.indirizzo.trim().replaceAll(',', '').trim().isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 3), child: pw.Text(d.indirizzo, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white))),
            pw.SizedBox(height: 20),
            pw.Text('LINGUE', style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
            pw.Container(width: 30, height: 2, color: PdfColors.white, margin: const pw.EdgeInsets.symmetric(vertical: 6)),
            pw.Text('${d.linguaMadre} (madre)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            pw.Text('Italiano — ${d.italianoLevel}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            if (d.haPatente && d.patenti.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('PATENTE', style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
              pw.Container(width: 30, height: 2, color: PdfColors.white, margin: const pw.EdgeInsets.symmetric(vertical: 6)),
              pw.Text(d.patenti.join('  '), style: pw.TextStyle(fontSize: 11, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ],
            pw.SizedBox(height: 20),
            pw.Text('DATI', style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
            pw.Container(width: 30, height: 2, color: PdfColors.white, margin: const pw.EdgeInsets.symmetric(vertical: 6)),
            for (final l in _personalInfo(d)) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 2), child: pw.Text(l, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white))),
          ])),
        // MAIN CONTENT RIGHT
        pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.fromLTRB(28, 36, 36, 36), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(d.nome, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: accent)),
          if (d.posizione.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 4), child: pw.Text(d.posizione.toUpperCase(), style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600, letterSpacing: 3))),
          pw.SizedBox(height: 18),
          pw.Container(height: 2, color: accent, width: 40),
          pw.SizedBox(height: 18),
          if (d.esperienze.isNotEmpty) ...[
            pw.Text('ESPERIENZE PROFESSIONALI', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent, letterSpacing: 1.5)),
            pw.SizedBox(height: 10),
            for (final e in d.esperienze) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 12), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              if (e.dalAl.isNotEmpty) pw.Text(e.dalAl.toUpperCase(), style: pw.TextStyle(fontSize: 9, color: accent, letterSpacing: 1)),
              pw.Text(e.ruolo, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(e.azienda, style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
              if (e.descrizione.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 4), child: pw.Text(e.descrizione, style: const pw.TextStyle(fontSize: 10))),
            ])),
          ],
          pw.Spacer(),
          _privacyFooter(),
        ]))),
      ]),
    ));
    return doc;
  }

  // ════════════════════════════════════════════════════════════════
  // 6. ELEGANTE — Brown serif, centered with flourishes, italic titles
  // ════════════════════════════════════════════════════════════════
  pw.Document _pdfElegante(_CvData d) {
    final accent = PdfColors.brown700;
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(56),
      build: (_) => [
        if (d.photo != null) pw.Center(child: pw.Container(width: 90, height: 90, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: accent, width: 1.5)),
          child: pw.ClipOval(child: pw.Image(d.photo!, fit: pw.BoxFit.cover)))),
        if (d.photo != null) pw.SizedBox(height: 14),
        pw.Center(child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
          pw.Container(width: 60, height: 0.6, color: accent),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 12), child: pw.Text(d.nome, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.normal, color: accent, fontStyle: pw.FontStyle.italic, letterSpacing: 1.5))),
          pw.Container(width: 60, height: 0.6, color: accent),
        ])),
        pw.SizedBox(height: 6),
        if (d.posizione.isNotEmpty) pw.Center(child: pw.Text(d.posizione, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic, letterSpacing: 2))),
        pw.SizedBox(height: 6),
        pw.Center(child: pw.Text([if (d.telefono.isNotEmpty) d.telefono, if (d.email.isNotEmpty) d.email].join('  ·  '), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
        pw.SizedBox(height: 24),
        ..._eleganteSections(d, accent),
        _privacyFooter(),
      ],
    ));
    return doc;
  }

  List<pw.Widget> _eleganteSections(_CvData d, PdfColor accent) {
    final w = <pw.Widget>[];
    void section(String title) {
      w.add(pw.SizedBox(height: 14));
      w.add(pw.Center(child: pw.Text(title, style: pw.TextStyle(fontSize: 12, color: accent, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold, letterSpacing: 3))));
      w.add(pw.SizedBox(height: 4));
      w.add(pw.Center(child: pw.Container(width: 30, height: 0.6, color: accent)));
      w.add(pw.SizedBox(height: 10));
    }
    section('Profilo personale');
    for (final l in _personalInfo(d)) w.add(pw.Center(child: pw.Text(l, style: const pw.TextStyle(fontSize: 10))));
    if (d.esperienze.isNotEmpty) {
      section('Esperienze');
      for (final e in d.esperienze) {
        w.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 10), child: pw.Column(children: [
          pw.Text(e.ruolo, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent, fontStyle: pw.FontStyle.italic)),
          pw.Text('${e.azienda}${e.dalAl.isEmpty ? '' : ' — ${e.dalAl}'}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          if (e.descrizione.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 3), child: pw.Text(e.descrizione, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
        ])));
      }
    }
    section('Lingue');
    w.add(pw.Center(child: pw.Text('${d.linguaMadre}  ·  Italiano ${d.italianoLevel}', style: const pw.TextStyle(fontSize: 10))));
    if (d.haPatente && d.patenti.isNotEmpty) { section('Patente'); w.add(pw.Center(child: pw.Text(d.patenti.join('  ·  '), style: const pw.TextStyle(fontSize: 10)))); }
    return w;
  }

  // ════════════════════════════════════════════════════════════════
  // 7. COLORATO — Each section has its own colored background block
  // ════════════════════════════════════════════════════════════════
  pw.Document _pdfColorato(_CvData d) {
    final doc = pw.Document();
    final c1 = PdfColors.purple700;
    final c2 = PdfColors.pink600;
    final c3 = PdfColors.teal600;
    final c4 = PdfColors.orange600;
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Container(padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(gradient: pw.LinearGradient(colors: [c1, c2], begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight), borderRadius: pw.BorderRadius.circular(12)),
          child: pw.Row(children: [
            if (d.photo != null) ...[
              pw.ClipOval(child: pw.Image(d.photo!, width: 80, height: 80, fit: pw.BoxFit.cover)),
              pw.SizedBox(width: 18),
            ],
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(d.nome, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              if (d.posizione.isNotEmpty) pw.Text(d.posizione, style: const pw.TextStyle(fontSize: 12, color: PdfColors.white)),
              pw.SizedBox(height: 6),
              pw.Text([if (d.telefono.isNotEmpty) d.telefono, if (d.email.isNotEmpty) d.email].join(' • '), style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            ])),
          ])),
        pw.SizedBox(height: 14),
        _coloredSection('DATI PERSONALI', c1, _personalInfo(d).map((l) => pw.Text(l, style: const pw.TextStyle(fontSize: 10, color: PdfColors.white))).toList()),
        if (d.esperienze.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _coloredSection('ESPERIENZE', c2, d.esperienze.map((e) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('${e.ruolo} @ ${e.azienda}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            if (e.dalAl.isNotEmpty) pw.Text(e.dalAl, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            if (e.descrizione.isNotEmpty) pw.Text(e.descrizione, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
          ]))).toList()),
        ],
        pw.SizedBox(height: 8),
        _coloredSection('LINGUE', c3, [pw.Text('${d.linguaMadre} (madre)  •  Italiano ${d.italianoLevel}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.white))]),
        if (d.haPatente && d.patenti.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _coloredSection('PATENTE', c4, [pw.Text(d.patenti.join('  •  '), style: pw.TextStyle(fontSize: 11, color: PdfColors.white, fontWeight: pw.FontWeight.bold))]),
        ],
        _privacyFooter(),
      ],
    ));
    return doc;
  }

  pw.Widget _coloredSection(String title, PdfColor color, List<pw.Widget> items) {
    return pw.Container(padding: const pw.EdgeInsets.all(14), decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 2)),
        pw.SizedBox(height: 8),
        ...items,
      ]));
  }

  // ════════════════════════════════════════════════════════════════
  // 8. TECH — Monospace, code-style headers, skills as [tags]
  // ════════════════════════════════════════════════════════════════
  pw.Document _pdfTech(_CvData d) {
    final accent = PdfColors.teal700;
    final mono = pw.Font.courier();
    final monoBold = pw.Font.courierBold();
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => [
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (d.photo != null) ...[
            pw.Container(width: 70, height: 70, decoration: pw.BoxDecoration(border: pw.Border.all(color: accent, width: 2)), child: pw.Image(d.photo!, fit: pw.BoxFit.cover)),
            pw.SizedBox(width: 16),
          ],
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('// ${d.nome}', style: pw.TextStyle(font: monoBold, fontSize: 22, color: accent)),
            pw.SizedBox(height: 4),
            if (d.posizione.isNotEmpty) pw.Text('> ${d.posizione}', style: pw.TextStyle(font: mono, fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 8),
            if (d.telefono.isNotEmpty) pw.Text('phone = "${d.telefono}";', style: pw.TextStyle(font: mono, fontSize: 9, color: PdfColors.grey800)),
            if (d.email.isNotEmpty) pw.Text('email = "${d.email}";', style: pw.TextStyle(font: mono, fontSize: 9, color: PdfColors.grey800)),
          ])),
        ]),
        pw.SizedBox(height: 14),
        pw.Container(height: 1, color: accent),
        pw.SizedBox(height: 14),
        ..._techSections(d, accent, mono, monoBold),
        _privacyFooter(),
      ],
    ));
    return doc;
  }

  List<pw.Widget> _techSections(_CvData d, PdfColor accent, pw.Font mono, pw.Font monoBold) {
    final w = <pw.Widget>[];
    void section(String title) {
      w.add(pw.SizedBox(height: 12));
      w.add(pw.Text('# $title', style: pw.TextStyle(font: monoBold, fontSize: 12, color: accent)));
      w.add(pw.Container(margin: const pw.EdgeInsets.only(top: 4, bottom: 8), child: pw.Text('─' * 50, style: pw.TextStyle(font: mono, fontSize: 8, color: accent))));
    }
    section('PROFILE');
    for (final l in _personalInfo(d)) w.add(pw.Text('  $l', style: pw.TextStyle(font: mono, fontSize: 9, color: PdfColors.grey800)));
    if (d.esperienze.isNotEmpty) {
      section('EXPERIENCE');
      for (final e in d.esperienze) {
        w.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('[${e.dalAl}] ${e.ruolo} @ ${e.azienda}', style: pw.TextStyle(font: monoBold, fontSize: 10, color: PdfColors.grey900)),
          if (e.descrizione.isNotEmpty) pw.Text('  ${e.descrizione}', style: pw.TextStyle(font: mono, fontSize: 9)),
        ])));
      }
    }
    section('LANGUAGES');
    w.add(pw.Wrap(spacing: 6, runSpacing: 6, children: [
      pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3), color: accent, child: pw.Text('[${d.linguaMadre}]', style: pw.TextStyle(font: monoBold, fontSize: 9, color: PdfColors.white))),
      pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: pw.BoxDecoration(border: pw.Border.all(color: accent, width: 1)), child: pw.Text('[Italiano:${d.italianoLevel}]', style: pw.TextStyle(font: monoBold, fontSize: 9, color: accent))),
    ]));
    if (d.haPatente && d.patenti.isNotEmpty) {
      section('LICENSE');
      w.add(pw.Wrap(spacing: 6, children: d.patenti.map((p) => pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: pw.BoxDecoration(border: pw.Border.all(color: accent, width: 1)), child: pw.Text('[$p]', style: pw.TextStyle(font: monoBold, fontSize: 9, color: accent)))).toList()));
    }
    return w;
  }

  // ════════════════════════════════════════════════════════════════
  // 9. SEMPLICE — Pure black & white, no decorations, just text
  // ════════════════════════════════════════════════════════════════
  pw.Document _pdfSemplice(_CvData d) {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(60),
      build: (_) => [
        pw.Text(d.nome.toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        if (d.telefono.isNotEmpty) pw.Text(d.telefono, style: const pw.TextStyle(fontSize: 10)),
        if (d.email.isNotEmpty) pw.Text(d.email, style: const pw.TextStyle(fontSize: 10)),
        if (d.indirizzo.trim().replaceAll(',', '').trim().isNotEmpty) pw.Text(d.indirizzo, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 16),
        if (d.posizione.isNotEmpty) ...[
          pw.Text('Posizione cercata: ${d.posizione}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
        ],
        pw.Text('DATI PERSONALI', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        for (final l in _personalInfo(d)) pw.Text(l, style: const pw.TextStyle(fontSize: 10)),
        if (d.esperienze.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text('ESPERIENZE LAVORATIVE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          for (final e in d.esperienze) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('${e.ruolo}, ${e.azienda}${e.dalAl.isEmpty ? '' : ' (${e.dalAl})'}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            if (e.descrizione.isNotEmpty) pw.Text(e.descrizione, style: const pw.TextStyle(fontSize: 10)),
          ])),
        ],
        pw.SizedBox(height: 12),
        pw.Text('LINGUE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.Text('Lingua madre: ${d.linguaMadre}', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Italiano: ${d.italianoLevel}', style: const pw.TextStyle(fontSize: 10)),
        if (d.haPatente && d.patenti.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text('PATENTE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text(d.patenti.join(', '), style: const pw.TextStyle(fontSize: 10)),
        ],
        _privacyFooter(),
      ],
    ));
    return doc;
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
  final String nome, dataNascita, luogoNascita, nazionalita, cf, indirizzo, telefono, email, posizione;
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
    required this.italianoLevel, this.photo, this.posizione = '',
  });
}
