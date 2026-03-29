import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/document_upload_widget.dart';

class DelegaScreen extends StatefulWidget {
  const DelegaScreen({super.key});

  @override
  State<DelegaScreen> createState() => _DelegaScreenState();
}

class _DelegaScreenState extends State<DelegaScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──
  bool _isAnalyzingDelegante = false;
  bool _isAnalyzingDelegato = false;
  bool _deleganteOk = false;
  bool _delegatoOk = false;
  bool _showResult = false;

  // ── Delegante data (from AI) ──
  String _delNome = '';
  String _delCognome = '';
  String _delNatoA = '';
  String _delDataNascita = '';
  String _delResidente = '';
  String _delCf = '';
  String _delDocTipo = '';
  String _delDocNumero = '';

  // ── Delegato data (from AI) ──
  String _datoNome = '';
  String _datoCognome = '';
  String _datoNatoA = '';
  String _datoDataNascita = '';
  String _datoCf = '';
  String _datoDocTipo = '';
  String _datoDocNumero = '';

  // ── Motivo (user input) ──
  final _motivoCtrl = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyze(ImageSource source, {required bool isDelegante}) async {
    final file = await pickImage(source);
    if (file == null) return;

    setState(() {
      if (isDelegante) {
        _isAnalyzingDelegante = true;
      } else {
        _isAnalyzingDelegato = true;
      }
    });

    final response = await GeminiService().analyzeDocument(
      imageFile: file,
      prompt: 'Analizza questo documento d\'identita italiano (CI, passaporto, permesso di soggiorno, patente). '
          'Estrai TUTTI i dati e restituisci SOLO un JSON valido (senza markdown): '
          '{"nome": "", "cognome": "", "data_nascita": "gg/mm/aaaa", "luogo_nascita": "", '
          '"codice_fiscale": "", "tipo_documento": "", "numero_documento": "", "residenza": ""}. '
          'Se un campo non e\' leggibile, metti null.',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final parsed = response.tryParseJson();
      if (parsed != null) {
        setState(() {
          if (isDelegante) {
            _delNome = parsed['nome']?.toString() ?? '';
            _delCognome = parsed['cognome']?.toString() ?? '';
            _delNatoA = parsed['luogo_nascita']?.toString() ?? '';
            _delDataNascita = parsed['data_nascita']?.toString() ?? '';
            _delResidente = parsed['residenza']?.toString() ?? '';
            _delCf = parsed['codice_fiscale']?.toString() ?? '';
            _delDocNumero = parsed['numero_documento']?.toString() ?? '';
            final tipo = parsed['tipo_documento']?.toString().toLowerCase() ?? '';
            if (tipo.contains('passaporto')) {
              _delDocTipo = 'Passaporto';
            } else if (tipo.contains('patente')) {
              _delDocTipo = 'Patente di guida';
            } else if (tipo.contains('permesso') || tipo.contains('soggiorno')) {
              _delDocTipo = 'Permesso di soggiorno';
            } else {
              _delDocTipo = 'Carta d\'identita';
            }
            _isAnalyzingDelegante = false;
            _deleganteOk = _delNome.isNotEmpty && _delCognome.isNotEmpty;
          } else {
            _datoNome = parsed['nome']?.toString() ?? '';
            _datoCognome = parsed['cognome']?.toString() ?? '';
            _datoNatoA = parsed['luogo_nascita']?.toString() ?? '';
            _datoDataNascita = parsed['data_nascita']?.toString() ?? '';
            _datoCf = parsed['codice_fiscale']?.toString() ?? '';
            _datoDocNumero = parsed['numero_documento']?.toString() ?? '';
            final tipo = parsed['tipo_documento']?.toString().toLowerCase() ?? '';
            if (tipo.contains('passaporto')) {
              _datoDocTipo = 'Passaporto';
            } else if (tipo.contains('patente')) {
              _datoDocTipo = 'Patente di guida';
            } else if (tipo.contains('permesso') || tipo.contains('soggiorno')) {
              _datoDocTipo = 'Permesso di soggiorno';
            } else {
              _datoDocTipo = 'Carta d\'identita';
            }
            _isAnalyzingDelegato = false;
            _delegatoOk = _datoNome.isNotEmpty && _datoCognome.isNotEmpty;
          }
        });

        // Auto-show result if both docs are ready and motivo is filled
        if (_deleganteOk && _delegatoOk && _motivoCtrl.text.isNotEmpty) {
          _mostraRisultato();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Documento ${isDelegante ? "delegante" : "delegato"} analizzato!'),
            backgroundColor: const Color(0xFF4CAF50),
          ));
        }
      } else {
        setState(() {
          if (isDelegante) {
            _isAnalyzingDelegante = false;
          } else {
            _isAnalyzingDelegato = false;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impossibile leggere i dati. Riprova con una foto piu nitida.'),
            backgroundColor: Color(0xFFF44336),
          ));
        }
      }
    } else {
      setState(() {
        if (isDelegante) {
          _isAnalyzingDelegante = false;
        } else {
          _isAnalyzingDelegato = false;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.errorMessage ?? 'Errore'),
          backgroundColor: const Color(0xFFF44336),
        ));
      }
    }
  }

  void _mostraRisultato() {
    setState(() => _showResult = true);
    _animController.forward(from: 0);
  }

  void _generaDelega() {
    if (!_deleganteOk) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Carica il documento del delegante'),
        backgroundColor: Color(0xFFFF9800),
      ));
      return;
    }
    if (!_delegatoOk) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Carica il documento del delegato'),
        backgroundColor: Color(0xFFFF9800),
      ));
      return;
    }
    if (_motivoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Inserisci il motivo della delega'),
        backgroundColor: Color(0xFFFF9800),
      ));
      return;
    }
    _mostraRisultato();
  }

  Future<void> _generaPdf() async {
    final pdf = pw.Document();
    final dataOggi = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final validita = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 30)));
    final nomeDelgante = '$_delNome $_delCognome';
    final nomeDelegato = '$_datoNome $_datoCognome';

    const bluScuro = PdfColor.fromInt(0xFF0D2D5E);
    const grigio = PdfColor.fromInt(0xFF666666);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('DELEGA', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: bluScuro))),
              pw.SizedBox(height: 30),
              // Delegante
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 6),
                  children: [
                    const pw.TextSpan(text: 'Il/La sottoscritto/a '),
                    pw.TextSpan(text: nomeDelgante, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    if (_delNatoA.isNotEmpty) ...[
                      const pw.TextSpan(text: ', nato/a a '),
                      pw.TextSpan(text: _delNatoA, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                    if (_delDataNascita.isNotEmpty) ...[
                      const pw.TextSpan(text: ' il '),
                      pw.TextSpan(text: _delDataNascita, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                    if (_delResidente.isNotEmpty) ...[
                      const pw.TextSpan(text: ', residente a '),
                      pw.TextSpan(text: _delResidente, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                    if (_delCf.isNotEmpty) ...[
                      const pw.TextSpan(text: ', codice fiscale '),
                      pw.TextSpan(text: _delCf.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                    if (_delDocTipo.isNotEmpty && _delDocNumero.isNotEmpty) ...[
                      const pw.TextSpan(text: ', documento '),
                      pw.TextSpan(text: '$_delDocTipo n. $_delDocNumero', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Center(child: pw.Text('DELEGA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: bluScuro))),
              pw.SizedBox(height: 24),
              // Delegato
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 6),
                  children: [
                    const pw.TextSpan(text: 'Il/La Sig./Sig.ra '),
                    pw.TextSpan(text: nomeDelegato, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    if (_datoNatoA.isNotEmpty) ...[
                      const pw.TextSpan(text: ', nato/a a '),
                      pw.TextSpan(text: _datoNatoA, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                    if (_datoDataNascita.isNotEmpty) ...[
                      const pw.TextSpan(text: ' il '),
                      pw.TextSpan(text: _datoDataNascita, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                    if (_datoCf.isNotEmpty) ...[
                      const pw.TextSpan(text: ', codice fiscale '),
                      pw.TextSpan(text: _datoCf.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                    if (_datoDocTipo.isNotEmpty && _datoDocNumero.isNotEmpty) ...[
                      const pw.TextSpan(text: ', documento '),
                      pw.TextSpan(text: '$_datoDocTipo n. $_datoDocNumero', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Motivo
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 6),
                  children: [
                    const pw.TextSpan(text: 'a '),
                    pw.TextSpan(text: _motivoCtrl.text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(text: '.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 6),
                  children: [
                    const pw.TextSpan(text: 'La presente delega ha validita fino al '),
                    pw.TextSpan(text: validita, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(text: '.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Si allega copia del documento di identita del delegante e del delegato.',
                style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: grigio),
              ),
              pw.SizedBox(height: 50),
              // Firma
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Luogo e data', style: const pw.TextStyle(fontSize: 10, color: grigio)),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        width: 180,
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5))),
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(dataOggi, style: const pw.TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Firma del delegante', style: const pw.TextStyle(fontSize: 10, color: grigio)),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 200,
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5))),
                        child: pw.SizedBox(height: 1),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 6),
              pw.Text(
                'Ai sensi dell\'art. 1387 e ss. del Codice Civile e dell\'art. 38 del D.P.R. 445/2000',
                style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: grigio),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Documento generato da Il Mio Patronato',
                style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: grigio),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'delega_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // ── Step 1: Documento Delegante ──
            SliverToBoxAdapter(child: _buildStepLabel('1', 'Documento del Delegante', 'Chi da la delega', _deleganteOk)),
            SliverToBoxAdapter(
              child: _deleganteOk
                  ? _buildPersonCard(true, _delNome, _delCognome, _delCf, _delDocTipo, _delDocNumero)
                  : DocumentUploadWidget(
                      label: 'Carica Documento Delegante',
                      subtitle: 'Foto della carta d\'identita, passaporto o permesso',
                      icon: Icons.person,
                      isLoading: _isAnalyzingDelegante,
                      onPickCamera: () => _pickAndAnalyze(ImageSource.camera, isDelegante: true),
                      onPickGallery: () => _pickAndAnalyze(ImageSource.gallery, isDelegante: true),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // ── Step 2: Documento Delegato ──
            SliverToBoxAdapter(child: _buildStepLabel('2', 'Documento del Delegato', 'Chi riceve la delega', _delegatoOk)),
            SliverToBoxAdapter(
              child: _delegatoOk
                  ? _buildPersonCard(false, _datoNome, _datoCognome, _datoCf, _datoDocTipo, _datoDocNumero)
                  : DocumentUploadWidget(
                      label: 'Carica Documento Delegato',
                      subtitle: 'Foto della carta d\'identita, passaporto o permesso',
                      icon: Icons.person_outline,
                      isLoading: _isAnalyzingDelegato,
                      onPickCamera: () => _pickAndAnalyze(ImageSource.camera, isDelegante: false),
                      onPickGallery: () => _pickAndAnalyze(ImageSource.gallery, isDelegante: false),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // ── Step 3: Motivo ──
            SliverToBoxAdapter(child: _buildStepLabel('3', 'Motivo della Delega', 'Per quale motivo si fa la delega', false)),
            SliverToBoxAdapter(child: _buildMotivoSection()),
            // ── Genera button ──
            if (!_showResult)
              SliverToBoxAdapter(child: _buildGeneraButton()),
            // ── Risultato ──
            if (_showResult) ...[
              SliverToBoxAdapter(child: _buildPreviewCard()),
              SliverToBoxAdapter(child: _buildActionButtons()),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 14),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GENERATORE DELEGA', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Carica documenti e genera PDF', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String number, String title, String subtitle, bool done) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: done ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)]) : AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(number, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(bool isDelegante, String nome, String cognome, String cf, String docTipo, String docNumero) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$nome $cognome', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                if (cf.isNotEmpty) Text('CF: ${cf.toUpperCase()}', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                if (docTipo.isNotEmpty && docNumero.isNotEmpty) Text('$docTipo n. $docNumero', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showResult = false;
                if (isDelegante) {
                  _deleganteOk = false;
                  _delNome = '';
                  _delCognome = '';
                } else {
                  _delegatoOk = false;
                  _datoNome = '';
                  _datoCognome = '';
                }
              });
            },
            child: const Icon(Icons.refresh, color: AppColors.textLight, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scrivi il motivo della delega', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 10),
          TextField(
            controller: _motivoCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Es: ritirare il permesso di soggiorno presso la Questura di Roma',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textLight),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneraButton() {
    return GestureDetector(
      onTap: _generaDelega,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('GENERA DELEGA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final dataOggi = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final validita = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 30)));

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text('ANTEPRIMA DELEGA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5))),
            const SizedBox(height: 16),
            const Text('DELEGANTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            _previewRow('Nome', '$_delNome $_delCognome'),
            if (_delNatoA.isNotEmpty) _previewRow('Nato/a a', '$_delNatoA${_delDataNascita.isNotEmpty ? " il $_delDataNascita" : ""}'),
            if (_delResidente.isNotEmpty) _previewRow('Residente', _delResidente),
            if (_delCf.isNotEmpty) _previewRow('C.F.', _delCf.toUpperCase()),
            if (_delDocTipo.isNotEmpty) _previewRow('Documento', '$_delDocTipo${_delDocNumero.isNotEmpty ? " n. $_delDocNumero" : ""}'),
            const Divider(height: 20),
            const Text('DELEGATO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            _previewRow('Nome', '$_datoNome $_datoCognome'),
            if (_datoNatoA.isNotEmpty) _previewRow('Nato/a a', '$_datoNatoA${_datoDataNascita.isNotEmpty ? " il $_datoDataNascita" : ""}'),
            if (_datoCf.isNotEmpty) _previewRow('C.F.', _datoCf.toUpperCase()),
            if (_datoDocTipo.isNotEmpty) _previewRow('Documento', '$_datoDocTipo${_datoDocNumero.isNotEmpty ? " n. $_datoDocNumero" : ""}'),
            const Divider(height: 20),
            const Text('MOTIVO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(_motivoCtrl.text, style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4)),
            const Divider(height: 20),
            _previewRow('Data', dataOggi),
            _previewRow('Validita', 'fino al $validita'),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark))),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _generaPdf,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('PDF & Condividi', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() {
                _showResult = false;
                _deleganteOk = false;
                _delegatoOk = false;
                _delNome = '';
                _delCognome = '';
                _datoNome = '';
                _datoCognome = '';
                _motivoCtrl.clear();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.refresh, color: AppColors.primary, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
