import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../core/widgets/disclaimer_widget.dart';

class CostoOrarioScreen extends StatefulWidget {
  const CostoOrarioScreen({super.key});

  @override
  State<CostoOrarioScreen> createState() => _CostoOrarioScreenState();
}

class _CostoOrarioScreenState extends State<CostoOrarioScreen>
    with SingleTickerProviderStateMixin {
  // ── Input ──
  final _ralCtrl = TextEditingController();
  String _tipoContratto = 'Tempo indeterminato';
  String _ccnl = 'Commercio';
  int _mensilita = 13;

  // ── Result ──
  bool _showResult = false;
  double _costoAnnuo = 0;
  double _costoMensile = 0;
  double _costoOrario = 0;
  double _contributiInps = 0;
  double _contributoInail = 0;
  double _tfr = 0;
  double _mensilAgg = 0;
  double _ral = 0;
  double _percContributi = 0;
  double _percInail = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');

  static const _tipiContratto = [
    'Tempo indeterminato',
    'Tempo determinato',
    'Apprendistato',
  ];

  static const _ccnlList = [
    'Commercio',
    'Metalmeccanico',
    'Edilizia',
    'Pubblico',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ralCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  double _p(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  // ─────────────────────────────────────────────
  // ALIQUOTE PER CCNL / CONTRATTO
  // ─────────────────────────────────────────────
  double _getAliquotaInps() {
    // Contributi INPS a carico azienda (percentuale sulla RAL)
    switch (_ccnl) {
      case 'Commercio':
        return _tipoContratto == 'Apprendistato' ? 0.1161 : 0.2981;
      case 'Metalmeccanico':
        return _tipoContratto == 'Apprendistato' ? 0.1161 : 0.3068;
      case 'Edilizia':
        return _tipoContratto == 'Apprendistato' ? 0.1161 : 0.3485;
      case 'Pubblico':
        return _tipoContratto == 'Apprendistato' ? 0.1161 : 0.2481;
      default:
        return 0.3000;
    }
  }

  double _getAliquotaInail() {
    // INAIL: varia per settore / rischio
    switch (_ccnl) {
      case 'Commercio':
        return 0.004; // 0.4%
      case 'Metalmeccanico':
        return 0.018; // 1.8%
      case 'Edilizia':
        return 0.050; // 5.0%
      case 'Pubblico':
        return 0.004; // 0.4%
      default:
        return 0.010;
    }
  }

  // ─────────────────────────────────────────────
  // CALCOLO COSTO ORARIO
  // ─────────────────────────────────────────────
  void _calcola() {
    final ral = _p(_ralCtrl.text);
    if (ral <= 0) return;
    _ral = ral;

    // Contributi INPS carico azienda
    _percContributi = _getAliquotaInps();
    _contributiInps = ral * _percContributi;

    // INAIL
    _percInail = _getAliquotaInail();
    _contributoInail = ral * _percInail;

    // TFR = RAL / 13.5
    _tfr = ral / 13.5;

    // Mensilita aggiuntive: la RAL gia include 13esima.
    // Se 14 mensilita, aggiungere 1/14 della RAL come costo aggiuntivo
    if (_mensilita == 14) {
      _mensilAgg = ral / 14.0;
    } else {
      _mensilAgg = 0;
    }

    // Maggiorazione per tempo determinato (+1.4% contributo addizionale NASpI)
    double maggiorazioneDet = 0;
    if (_tipoContratto == 'Tempo determinato') {
      maggiorazioneDet = ral * 0.014;
    }

    // Costo annuo totale
    _costoAnnuo =
        ral + _contributiInps + _contributoInail + _tfr + _mensilAgg + maggiorazioneDet;

    // Costo mensile
    _costoMensile = _costoAnnuo / 12.0;

    // Costo orario (standard 1720 ore/anno = 215 gg x 8 ore)
    _costoOrario = _costoAnnuo / 1720.0;

    setState(() => _showResult = true);
    _animController.forward(from: 0);
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildInfoBanner()),
            SliverToBoxAdapter(child: _sectionTitle('RAL Dipendente')),
            SliverToBoxAdapter(child: _buildRalSection()),
            SliverToBoxAdapter(child: _sectionTitle('Tipo Contratto')),
            SliverToBoxAdapter(child: _buildContrattoSection()),
            SliverToBoxAdapter(child: _sectionTitle('CCNL')),
            SliverToBoxAdapter(child: _buildCcnlSection()),
            SliverToBoxAdapter(child: _sectionTitle('Mensilita')),
            SliverToBoxAdapter(child: _buildMensilitaSection()),
            SliverToBoxAdapter(child: _buildCalcolaButton()),
            if (_showResult) ...[
              SliverToBoxAdapter(child: _buildResultCard()),
              SliverToBoxAdapter(child: _buildBreakdownCard()),
              SliverToBoxAdapter(child: _buildPercentualeCard()),
            ],
            SliverToBoxAdapter(child: CalculatorDisclaimer(specificSource: 'aliquote contributive INPS e INAIL')),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

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
            child: const Icon(Icons.business, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COSTO ORARIO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Costo dipendente per azienda',
                    style: TextStyle(
                        color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          const Icon(Icons.info_outline,
              color: Color(0xFFFFA000), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5D4037),
                    height: 1.4),
                children: [
                  TextSpan(
                      text: 'Per datori di lavoro. ',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                      text:
                          'Calcola il costo reale di un dipendente includendo contributi INPS, INAIL, TFR e mensilita aggiuntive. Ore standard: 1720/anno.'),
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

  // ── RAL ──
  Widget _buildRalSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Retribuzione Annua Lorda del dipendente',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 10),
          _moneyField(_ralCtrl, 'RAL lorda annua'),
        ],
      ),
    );
  }

  // ── Tipo contratto ──
  Widget _buildContrattoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Row(
        children: _tipiContratto
            .map((tipo) => Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _tipoContratto = tipo),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tipoContratto == tipo
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _tipoContratto == tipo
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: _tipoContratto == tipo ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            tipo == 'Tempo indeterminato'
                                ? Icons.all_inclusive
                                : tipo == 'Tempo determinato'
                                    ? Icons.timer
                                    : Icons.school,
                            size: 22,
                            color: _tipoContratto == tipo
                                ? AppColors.primary
                                : AppColors.textLight,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tipo == 'Tempo indeterminato'
                                ? 'Indeter.'
                                : tipo == 'Tempo determinato'
                                    ? 'Determ.'
                                    : 'Apprend.',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _tipoContratto == tipo
                                  ? AppColors.primary
                                  : AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── CCNL ──
  Widget _buildCcnlSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _ccnlList.map((ccnl) {
          final selected = _ccnl == ccnl;
          return GestureDetector(
            onTap: () => setState(() => _ccnl = ccnl),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Text(
                ccnl,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? AppColors.primary : AppColors.textMedium,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Mensilita ──
  Widget _buildMensilitaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Row(
        children: [13, 14].map((m) {
          final selected = _mensilita == m;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mensilita = m),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : Colors.grey.shade200,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$m',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m == 13 ? 'Tredicesima' : 'Quattordicesima',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Calcola ──
  Widget _buildCalcolaButton() {
    return GestureDetector(
      onTap: _calcola,
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
            Icon(Icons.calculate, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('CALCOLA COSTO',
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

  // ── Risultato principale ──
  Widget _buildResultCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Costo orario grande
            const Text('COSTO ORARIO',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('\u20AC ${_fmt.format(_costoOrario)} /ora',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _resultMini(
                    'Annuo', '\u20AC ${_fmt.format(_costoAnnuo)}'),
                Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.3)),
                _resultMini(
                    'Mensile', '\u20AC ${_fmt.format(_costoMensile)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultMini(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── Breakdown ──
  Widget _buildBreakdownCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dettaglio Costo Annuo',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 14),
            _row('RAL dipendente',
                '\u20AC ${_fmt.format(_ral)}'),
            const Divider(height: 16),
            _row(
                'Contributi INPS azienda (${(_percContributi * 100).toStringAsFixed(1)}%)',
                '+ \u20AC ${_fmt.format(_contributiInps)}'),
            _row(
                'INAIL (${(_percInail * 100).toStringAsFixed(1)}%)',
                '+ \u20AC ${_fmt.format(_contributoInail)}'),
            _row('TFR (RAL / 13.5)',
                '+ \u20AC ${_fmt.format(_tfr)}'),
            if (_mensilAgg > 0)
              _row('Quattordicesima',
                  '+ \u20AC ${_fmt.format(_mensilAgg)}'),
            if (_tipoContratto == 'Tempo determinato')
              _row('Maggiorazione NASpI (1.4%)',
                  '+ \u20AC ${_fmt.format(_ral * 0.014)}'),
            const Divider(height: 16),
            _row('COSTO TOTALE ANNUO',
                '\u20AC ${_fmt.format(_costoAnnuo)}',
                bold: true),
            _row('Costo mensile',
                '\u20AC ${_fmt.format(_costoMensile)}'),
            _row('Costo orario (1720 ore/anno)',
                '\u20AC ${_fmt.format(_costoOrario)}',
                bold: true),
          ],
        ),
      ),
    );
  }

  // ── Percentuale breakdown ──
  Widget _buildPercentualeCard() {
    if (_costoAnnuo <= 0) return const SizedBox.shrink();

    final items = <_BarItem>[
      _BarItem(
          'RAL', _ral, const Color(0xFF1565C0)),
      _BarItem('INPS Azienda', _contributiInps,
          const Color(0xFFFF9800)),
      _BarItem(
          'INAIL', _contributoInail, const Color(0xFFF44336)),
      _BarItem('TFR', _tfr, const Color(0xFF4CAF50)),
    ];
    if (_mensilAgg > 0) {
      items.add(_BarItem(
          '14a Mensilita', _mensilAgg, const Color(0xFF9C27B0)));
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Composizione Percentuale',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            // Stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: items.map((item) {
                    final perc = item.value / _costoAnnuo;
                    return Expanded(
                      flex: (perc * 1000).round().clamp(1, 1000),
                      child: Container(color: item.color),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...items.map((item) {
              final perc = (item.value / _costoAnnuo * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.label,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium)),
                    ),
                    Text('${perc.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    const SizedBox(width: 8),
                    Text('\u20AC ${_fmt.format(item.value)}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WIDGETS RIUTILIZZABILI
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

  Widget _moneyField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMedium),
        prefixText: '\u20AC  ',
        prefixStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark),
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

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: bold
                          ? AppColors.textDark
                          : AppColors.textMedium,
                      fontWeight:
                          bold ? FontWeight.w600 : FontWeight.w400))),
          const SizedBox(width: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color ??
                      (bold ? AppColors.primary : AppColors.textDark))),
        ],
      ),
    );
  }
}

class _BarItem {
  final String label;
  final double value;
  final Color color;
  const _BarItem(this.label, this.value, this.color);
}
