import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/widgets/disclaimer_widget.dart';

class CostoPermessoScreen extends StatefulWidget {
  const CostoPermessoScreen({super.key});

  @override
  State<CostoPermessoScreen> createState() => _CostoPermessoScreenState();
}

class _CostoPermessoScreenState extends State<CostoPermessoScreen>
    with SingleTickerProviderStateMixin {
  // Form values
  String? _tipoPermesso;
  String _durata = 'fino_1_anno'; // 'fino_1_anno' | '1_2_anni'
  String _motivo = 'rinnovo'; // 'rinnovo' | 'primo_rilascio' | 'conversione'

  // Result
  bool _showResult = false;
  double _kitPostale = 0;
  double _marcaDaBollo = 0;
  double _contributoElettronico = 0;
  double _fotoTessera = 0;
  double _contributoConversione = 0;
  double _totale = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Real 2024-2026 costs
  static const double _costoKit = 30.46;
  static const double _costoMarca = 16.00;
  static const double _costoFoto = 8.00;
  static const double _costoConversione = 30.00;

  final List<String> _tipiPermesso = [
    'Lavoro subordinato',
    'Lavoro autonomo',
    'Famiglia',
    'Studio',
    'CE Lungo Soggiorno',
    'Carta di soggiorno familiare UE',
    'Attesa occupazione',
    'Protezione sussidiaria',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _calcolaContributoElettronico() {
    if (_tipoPermesso == 'CE Lungo Soggiorno' ||
        _tipoPermesso == 'Carta di soggiorno familiare UE') {
      return 100.00;
    }
    if (_durata == 'fino_1_anno') {
      return 40.00;
    }
    return 50.00; // 1-2 anni
  }

  void _calcola() {
    if (_tipoPermesso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona il tipo di permesso'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final contributo = _calcolaContributoElettronico();
    final conversione = _motivo == 'conversione' ? _costoConversione : 0.0;
    final totale = _costoKit + _costoMarca + contributo + _costoFoto + conversione;

    setState(() {
      _showResult = true;
      _kitPostale = _costoKit;
      _marcaDaBollo = _costoMarca;
      _contributoElettronico = contributo;
      _fotoTessera = _costoFoto;
      _contributoConversione = conversione;
      _totale = totale;
    });

    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildTipoPermesso()),
          SliverToBoxAdapter(child: _buildDurata()),
          SliverToBoxAdapter(child: _buildMotivo()),
          SliverToBoxAdapter(child: _buildCalcolaButton()),
          if (_showResult) ...[
            SliverToBoxAdapter(child: _buildReceiptCard()),
            SliverToBoxAdapter(child: _buildNoteCard()),
          ],
          SliverToBoxAdapter(child: CalculatorDisclaimer(specificSource: "tariffe Ministero dell'Interno")),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 6,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
          const Icon(Icons.euro, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Costo Permesso',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildTipoPermesso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tipo permesso'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _tipoPermesso,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Seleziona tipo permesso',
              hintStyle: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
            ),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.primary),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            items: _tipiPermesso
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() {
              _tipoPermesso = v;
              _showResult = false;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDurata() {
    // Hide durata for types that have fixed cost
    final isFixedCost = _tipoPermesso == 'CE Lungo Soggiorno' ||
        _tipoPermesso == 'Carta di soggiorno familiare UE';

    if (isFixedCost) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Durata'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Fino a 1 anno',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Contributo: \u20AC40,00',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textLight)),
                value: 'fino_1_anno',
                groupValue: _durata,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _durata = v!;
                  _showResult = false;
                }),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              RadioListTile<String>(
                title: const Text('1-2 anni',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Contributo: \u20AC50,00',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textLight)),
                value: '1_2_anni',
                groupValue: _durata,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _durata = v!;
                  _showResult = false;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMotivo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Motivo'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Rinnovo',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                value: 'rinnovo',
                groupValue: _motivo,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _motivo = v!;
                  _showResult = false;
                }),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              RadioListTile<String>(
                title: const Text('Primo rilascio',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                value: 'primo_rilascio',
                groupValue: _motivo,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _motivo = v!;
                  _showResult = false;
                }),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              RadioListTile<String>(
                title: const Text('Conversione',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Aggiunge \u20AC30,00',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textLight)),
                value: 'conversione',
                groupValue: _motivo,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _motivo = v!;
                  _showResult = false;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalcolaButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: GestureDetector(
        onTap: _calcola,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'CALCOLA COSTO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Receipt header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long,
                        color: Colors.white, size: 28),
                    const SizedBox(height: 6),
                    const Text(
                      'Riepilogo Costi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tipoPermesso ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Receipt items
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildReceiptRow('Kit Postale', _kitPostale),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Marca da bollo', _marcaDaBollo),
                    const SizedBox(height: 10),
                    _buildReceiptRow(
                        'Contributo elettronico', _contributoElettronico),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Foto tessera (4 pz.)', _fotoTessera),
                    if (_contributoConversione > 0) ...[
                      const SizedBox(height: 10),
                      _buildReceiptRow(
                          'Contributo conversione', _contributoConversione),
                    ],
                    const SizedBox(height: 14),
                    // Dashed separator
                    Row(
                      children: List.generate(
                        30,
                        (i) => Expanded(
                          child: Container(
                            height: 1,
                            color: i.isEven
                                ? AppColors.textLight
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Total with animated count-up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTALE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: _totale),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return Text(
                              '\u20AC${value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
        ),
        Text(
          '\u20AC${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNoteRow(
                Icons.payment,
                'Dove pagare',
                'Bollettino postale premarcato incluso nel Kit',
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildNoteRow(
                Icons.location_on,
                'Dove presentare',
                'Ufficio Postale abilitato',
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildNoteRow(
                Icons.info_outline,
                'Nota',
                'I costi indicati sono riferiti al Kit Postale standard. '
                    'Eventuali costi aggiuntivi per servizi accessori '
                    '(assicurazione sanitaria, traduzione documenti, ecc.) '
                    'non sono inclusi.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
