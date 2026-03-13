import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

class DelegaScreen extends StatefulWidget {
  const DelegaScreen({super.key});

  @override
  State<DelegaScreen> createState() => _DelegaScreenState();
}

class _DelegaScreenState extends State<DelegaScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Delegante ──
  final _delNomeCtrl = TextEditingController();
  final _delCognomeCtrl = TextEditingController();
  final _delNatoACtrl = TextEditingController();
  final _delDataNascitaCtrl = TextEditingController();
  final _delResidenteCtrl = TextEditingController();
  final _delCfCtrl = TextEditingController();
  String _delDocTipo = 'Carta d\'identità';
  final _delDocNumeroCtrl = TextEditingController();

  // ── Delegato ──
  final _datoNomeCtrl = TextEditingController();
  final _datoCognomeCtrl = TextEditingController();
  final _datoNatoACtrl = TextEditingController();
  final _datoDataNascitaCtrl = TextEditingController();
  final _datoCfCtrl = TextEditingController();
  String _datoDocTipo = 'Carta d\'identità';
  final _datoDocNumeroCtrl = TextEditingController();

  // ── Delega ──
  String _tipoDelega = 'Delega Generica';
  final _oggettoCtrl = TextEditingController();
  final _ufficioCtrl = TextEditingController();
  final _dataDelegaCtrl = TextEditingController();
  final _validitaCtrl = TextEditingController();

  static const _tipiDelega = [
    'Delega Generica',
    'Delega Ritiro Documenti',
    'Delega Pratica Immigrazione',
    'Delega CAF/Patronato',
    'Delega Posta',
  ];

  static const _tipiDocumento = [
    'Carta d\'identità',
    'Passaporto',
    'Patente di guida',
    'Permesso di soggiorno',
  ];

  @override
  void initState() {
    super.initState();
    _loadDelegante();
    _dataDelegaCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _validitaCtrl.text = DateFormat('dd/MM/yyyy').format(
      DateTime.now().add(const Duration(days: 30)),
    );
  }

  Future<void> _loadDelegante() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _delNomeCtrl.text = prefs.getString('profilo_nome') ?? '';
      _delCognomeCtrl.text = prefs.getString('profilo_cognome') ?? '';
      _delNatoACtrl.text = prefs.getString('profilo_nato_a') ?? '';
      _delDataNascitaCtrl.text = prefs.getString('profilo_data_nascita') ?? '';
      _delResidenteCtrl.text = prefs.getString('profilo_residente') ?? '';
      _delCfCtrl.text = prefs.getString('profilo_codice_fiscale') ?? '';
      _delDocTipo = prefs.getString('profilo_doc_tipo') ?? 'Carta d\'identità';
      _delDocNumeroCtrl.text = prefs.getString('profilo_doc_numero') ?? '';
    });
  }

  @override
  void dispose() {
    _delNomeCtrl.dispose();
    _delCognomeCtrl.dispose();
    _delNatoACtrl.dispose();
    _delDataNascitaCtrl.dispose();
    _delResidenteCtrl.dispose();
    _delCfCtrl.dispose();
    _delDocNumeroCtrl.dispose();
    _datoNomeCtrl.dispose();
    _datoCognomeCtrl.dispose();
    _datoNatoACtrl.dispose();
    _datoDataNascitaCtrl.dispose();
    _datoCfCtrl.dispose();
    _datoDocNumeroCtrl.dispose();
    _oggettoCtrl.dispose();
    _ufficioCtrl.dispose();
    _dataDelegaCtrl.dispose();
    _validitaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1940),
      lastDate: DateTime(2030),
      locale: const Locale('it', 'IT'),
    );
    if (picked != null) {
      ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // ─────────────────────────────────────────────
  // PDF GENERATION
  // ─────────────────────────────────────────────
  Future<void> _generaPdf() async {
    if (!_formKey.currentState!.validate()) return;

    final pdf = pw.Document();

    const bluScuro = PdfColor.fromInt(0xFF0D2D5E);
    const grigio = PdfColor.fromInt(0xFF666666);

    final nomeDelgante = '${_delNomeCtrl.text} ${_delCognomeCtrl.text}';
    final nomeDelegato = '${_datoNomeCtrl.text} ${_datoCognomeCtrl.text}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Center(
                child: pw.Text(
                  'DELEGA',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: bluScuro,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  _tipoDelega.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: grigio,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Delegante paragraph
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 6),
                  children: [
                    const pw.TextSpan(text: 'Il/La sottoscritto/a '),
                    pw.TextSpan(
                      text: nomeDelgante,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ', nato/a a '),
                    pw.TextSpan(
                      text: _delNatoACtrl.text,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ' il '),
                    pw.TextSpan(
                      text: _delDataNascitaCtrl.text,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ', residente a '),
                    pw.TextSpan(
                      text: _delResidenteCtrl.text,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ', codice fiscale '),
                    pw.TextSpan(
                      text: _delCfCtrl.text.toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ', documento '),
                    pw.TextSpan(
                      text: '$_delDocTipo n. ${_delDocNumeroCtrl.text}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // DELEGA centered bold
              pw.Center(
                child: pw.Text(
                  'DELEGA',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: bluScuro,
                  ),
                ),
              ),
              pw.SizedBox(height: 24),

              // Delegato paragraph
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 6),
                  children: [
                    const pw.TextSpan(text: 'Il/La Sig./Sig.ra '),
                    pw.TextSpan(
                      text: nomeDelegato,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ', nato/a a '),
                    pw.TextSpan(
                      text: _datoNatoACtrl.text,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ' il '),
                    pw.TextSpan(
                      text: _datoDataNascitaCtrl.text,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ', codice fiscale '),
                    pw.TextSpan(
                      text: _datoCfCtrl.text.toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ', documento '),
                    pw.TextSpan(
                      text: '$_datoDocTipo n. ${_datoDocNumeroCtrl.text}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Object
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 6),
                  children: [
                    const pw.TextSpan(text: 'a '),
                    pw.TextSpan(
                      text: _oggettoCtrl.text,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ' presso '),
                    pw.TextSpan(
                      text: _ufficioCtrl.text,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: '.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Validity
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 6),
                  children: [
                    const pw.TextSpan(
                        text: 'La presente delega ha validit\u00E0 fino al '),
                    pw.TextSpan(
                      text: _validitaCtrl.text,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: '.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Attachment note
              pw.Text(
                'Si allega copia del documento di identit\u00E0 del delegante e del delegato.',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                  color: grigio,
                ),
              ),
              pw.SizedBox(height: 50),

              // Place and date + Signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Luogo e data',
                        style: const pw.TextStyle(
                            fontSize: 10, color: grigio),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        width: 180,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                                color: PdfColors.grey400, width: 0.5),
                          ),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          _dataDelegaCtrl.text,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Firma del delegante',
                        style: const pw.TextStyle(
                            fontSize: 10, color: grigio),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 200,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                                color: PdfColors.grey400, width: 0.5),
                          ),
                        ),
                        child: pw.SizedBox(height: 1),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),

              // Legal footer
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 6),
              pw.Text(
                'Ai sensi dell\'art. 1387 e ss. del Codice Civile e dell\'art. 38 del D.P.R. 445/2000',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: grigio,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Documento generato da DocFlow Immigrati',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontStyle: pw.FontStyle.italic,
                  color: grigio,
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    if (!mounted) return;

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'delega_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
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
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildInfoBanner()),
              SliverToBoxAdapter(child: _sectionTitle('Tipo di Delega')),
              SliverToBoxAdapter(child: _buildTipoDelegaSection()),
              SliverToBoxAdapter(child: _sectionTitle('Delegante (chi delega)')),
              SliverToBoxAdapter(child: _buildDeleganteSection()),
              SliverToBoxAdapter(
                  child: _sectionTitle('Delegato (chi riceve la delega)')),
              SliverToBoxAdapter(child: _buildDelegatoSection()),
              SliverToBoxAdapter(child: _sectionTitle('Oggetto della Delega')),
              SliverToBoxAdapter(child: _buildOggettoSection()),
              SliverToBoxAdapter(child: _sectionTitle('Date e Validit\u00E0')),
              SliverToBoxAdapter(child: _buildDateSection()),
              SliverToBoxAdapter(child: _buildGeneraButton()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
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
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
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
            child: const Icon(Icons.description, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GENERATORE DELEGA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Crea delega in formato PDF',
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
                      text: 'Delega valida. ',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                      text:
                          'Genera una delega conforme alla normativa italiana. Ricorda di allegare copia dei documenti di identit\u00E0 del delegante e del delegato.'),
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

  // ── Tipo delega ──
  Widget _buildTipoDelegaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _tipiDelega.map((tipo) {
          final selected = _tipoDelega == tipo;
          IconData icon;
          switch (tipo) {
            case 'Delega Generica':
              icon = Icons.article;
              break;
            case 'Delega Ritiro Documenti':
              icon = Icons.folder_open;
              break;
            case 'Delega Pratica Immigrazione':
              icon = Icons.flight_land;
              break;
            case 'Delega CAF/Patronato':
              icon = Icons.account_balance;
              break;
            case 'Delega Posta':
              icon = Icons.mail;
              break;
            default:
              icon = Icons.article;
          }
          return GestureDetector(
            onTap: () => setState(() {
              _tipoDelega = tipo;
              _oggettoCtrl.text = _oggettoDefault(tipo);
            }),
            child: Container(
              width: (MediaQuery.of(context).size.width - 56) / 2,
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 18,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textLight),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(tipo,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMedium)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _oggettoDefault(String tipo) {
    switch (tipo) {
      case 'Delega Ritiro Documenti':
        return 'ritirare i documenti';
      case 'Delega Pratica Immigrazione':
        return 'presentare/ritirare la pratica di immigrazione';
      case 'Delega CAF/Patronato':
        return 'presentare la documentazione fiscale e previdenziale';
      case 'Delega Posta':
        return 'ritirare la corrispondenza e i pacchi postali';
      default:
        return '';
    }
  }

  // ── Delegante ──
  Widget _buildDeleganteSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _textField(_delNomeCtrl, 'Nome', required: true)),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _textField(_delCognomeCtrl, 'Cognome', required: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child:
                      _textField(_delNatoACtrl, 'Nato/a a', required: true)),
              const SizedBox(width: 12),
              Expanded(
                child: _dateField(_delDataNascitaCtrl, 'Data di nascita'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _textField(_delResidenteCtrl, 'Residente a (indirizzo completo)',
              required: true),
          const SizedBox(height: 12),
          _textField(_delCfCtrl, 'Codice Fiscale', required: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dropdownField(
                  'Tipo documento',
                  _delDocTipo,
                  _tipiDocumento,
                  (v) => setState(() => _delDocTipo = v ?? _delDocTipo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: _textField(_delDocNumeroCtrl, 'N. Documento',
                      required: true)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Delegato ──
  Widget _buildDelegatoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _textField(_datoNomeCtrl, 'Nome', required: true)),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _textField(_datoCognomeCtrl, 'Cognome', required: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child:
                      _textField(_datoNatoACtrl, 'Nato/a a', required: true)),
              const SizedBox(width: 12),
              Expanded(
                child: _dateField(_datoDataNascitaCtrl, 'Data di nascita'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _textField(_datoCfCtrl, 'Codice Fiscale', required: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dropdownField(
                  'Tipo documento',
                  _datoDocTipo,
                  _tipiDocumento,
                  (v) => setState(() => _datoDocTipo = v ?? _datoDocTipo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: _textField(_datoDocNumeroCtrl, 'N. Documento',
                      required: true)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Oggetto ──
  Widget _buildOggettoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textField(_oggettoCtrl, 'Oggetto specifico della delega',
              required: true, maxLines: 3),
          const SizedBox(height: 12),
          _textField(_ufficioCtrl, 'Ufficio destinatario', required: true),
        ],
      ),
    );
  }

  // ── Date ──
  Widget _buildDateSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Row(
        children: [
          Expanded(child: _dateField(_dataDelegaCtrl, 'Data delega')),
          const SizedBox(width: 12),
          Expanded(child: _dateField(_validitaCtrl, 'Valida fino al')),
        ],
      ),
    );
  }

  // ── Generate button ──
  Widget _buildGeneraButton() {
    return GestureDetector(
      onTap: _generaPdf,
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
            Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('GENERA DELEGA PDF',
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

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMedium),
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
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dateField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: () => _pickDate(ctrl),
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMedium),
        suffixIcon: const Icon(Icons.calendar_today,
            size: 18, color: AppColors.textLight),
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

  Widget _dropdownField(
    String label,
    String currentValue,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMedium),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: onChanged,
    );
  }
}
