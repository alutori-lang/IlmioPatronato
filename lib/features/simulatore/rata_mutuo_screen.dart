import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';

class RataMutuoScreen extends StatefulWidget {
  const RataMutuoScreen({super.key});

  @override
  State<RataMutuoScreen> createState() => _RataMutuoScreenState();
}

class _RataMutuoScreenState extends State<RataMutuoScreen>
    with SingleTickerProviderStateMixin {
  // ── Input ──
  final _importoCtrl = TextEditingController();
  int _durataAnni = 20;
  final _tassoCtrl = TextEditingController(text: '3.5');
  String _tipoTasso = 'Fisso';

  // ── Result ──
  bool _showResult = false;
  double _rataMensile = 0;
  double _totaleInteressi = 0;
  double _totaleRestituito = 0;
  double _importo = 0;
  List<_RataDetail> _pianoFirst12 = [];
  List<_RataDetail> _pianoLast12 = [];
  int _totaleMesi = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');

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
    _importoCtrl.dispose();
    _tassoCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  double _p(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  // ─────────────────────────────────────────────
  // CALCOLO MUTUO - Ammortamento alla francese
  // Rata = C * r / (1 - (1 + r)^(-n))
  // C = capitale, r = tasso mensile, n = numero rate
  // ─────────────────────────────────────────────
  void _calcola() {
    final capitale = _p(_importoCtrl.text);
    final tassoAnnuo = _p(_tassoCtrl.text);
    if (capitale <= 0 || tassoAnnuo <= 0) return;

    _importo = capitale;
    _totaleMesi = _durataAnni * 12;
    final double r = tassoAnnuo / 100.0 / 12.0; // tasso mensile
    final int n = _totaleMesi;

    // Formula ammortamento francese
    _rataMensile = capitale * r / (1.0 - pow(1.0 + r, -n).toDouble());

    _totaleRestituito = _rataMensile * n.toDouble();
    _totaleInteressi = _totaleRestituito - capitale;

    // Genera piano ammortamento completo per estrarre primi e ultimi 12 mesi
    final List<_RataDetail> pianoCompleto = [];
    double debitoResiduo = capitale;

    for (int mese = 1; mese <= n; mese++) {
      final quotaInteressi = debitoResiduo * r;
      final quotaCapitale = _rataMensile - quotaInteressi;
      debitoResiduo -= quotaCapitale;
      if (debitoResiduo < 0) debitoResiduo = 0;

      pianoCompleto.add(_RataDetail(
        mese: mese,
        rata: _rataMensile,
        quotaCapitale: quotaCapitale,
        quotaInteressi: quotaInteressi,
        debitoResiduo: debitoResiduo,
      ));
    }

    // Primi 12 mesi
    _pianoFirst12 = pianoCompleto.take(12).toList();

    // Ultimi 12 mesi
    if (n > 24) {
      _pianoLast12 = pianoCompleto.skip(n - 12).toList();
    } else if (n > 12) {
      _pianoLast12 = pianoCompleto.skip(12).toList();
    } else {
      _pianoLast12 = [];
    }

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
            SliverToBoxAdapter(child: _sectionTitle('Importo Mutuo')),
            SliverToBoxAdapter(child: _buildImportoSection()),
            SliverToBoxAdapter(child: _sectionTitle('Durata')),
            SliverToBoxAdapter(child: _buildDurataSection()),
            SliverToBoxAdapter(child: _sectionTitle('Tasso di Interesse')),
            SliverToBoxAdapter(child: _buildTassoSection()),
            SliverToBoxAdapter(child: _sectionTitle('Tipo Tasso')),
            SliverToBoxAdapter(child: _buildTipoTassoSection()),
            SliverToBoxAdapter(child: _buildCalcolaButton()),
            if (_showResult) ...[
              SliverToBoxAdapter(child: _buildResultCard()),
              SliverToBoxAdapter(child: _buildProgressCard()),
              SliverToBoxAdapter(child: _buildDettaglioCard()),
              SliverToBoxAdapter(
                  child: _buildPianoCard(
                      'Prime 12 Rate', _pianoFirst12)),
              if (_pianoLast12.isNotEmpty)
                SliverToBoxAdapter(
                    child: _buildPianoCard(
                        'Ultime 12 Rate', _pianoLast12)),
            ],
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
            child: const Icon(Icons.home, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RATA MUTUO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Ammortamento alla francese',
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
                      text: 'Calcolo indicativo. ',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                      text:
                          'Ammortamento alla francese (rata costante). Non include spese notarili, perizia, assicurazione obbligatoria. Consulta sempre la banca per un preventivo ufficiale.'),
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

  // ── Importo ──
  Widget _buildImportoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Importo del mutuo richiesto alla banca',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 10),
          _moneyField(_importoCtrl, 'Importo mutuo'),
        ],
      ),
    );
  }

  // ── Durata ──
  Widget _buildDurataSection() {
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
                child: Text(
                  'Durata: $_durataAnni anni ($_totaleMesiLabel)',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                ),
              ),
              Text(
                '${_durataAnni * 12} rate',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor:
                  AppColors.primary.withValues(alpha: 0.15),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              valueIndicatorColor: AppColors.primary,
              valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            child: Slider(
              value: _durataAnni.toDouble(),
              min: 5,
              max: 30,
              divisions: 25,
              label: '$_durataAnni anni',
              onChanged: (v) =>
                  setState(() => _durataAnni = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5 anni',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
              Text('30 anni',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  String get _totaleMesiLabel {
    final mesi = _durataAnni * 12;
    return '$mesi mesi';
  }

  // ── Tasso ──
  Widget _buildTassoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tasso Annuo Nominale (TAN)',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Il tasso medio attuale per mutui a tasso fisso e\' circa 3.0% - 4.0%',
            style: TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tassoCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark),
            decoration: InputDecoration(
              labelText: 'Tasso interesse annuo',
              labelStyle: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium),
              suffixText: '%',
              suffixStyle: const TextStyle(
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
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tipo tasso ──
  Widget _buildTipoTassoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Row(
        children: ['Fisso', 'Variabile'].map((tipo) {
          final selected = _tipoTasso == tipo;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tipoTasso = tipo),
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
                    Icon(
                      tipo == 'Fisso' ? Icons.lock : Icons.trending_up,
                      size: 24,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textLight,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tasso $tipo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tipo == 'Fisso'
                          ? 'Rata costante'
                          : 'Rata variabile',
                      style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.7)
                            : AppColors.textLight,
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
            Text('CALCOLA RATA',
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
            const Text('RATA MENSILE',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('\u20AC ${_fmt.format(_rataMensile)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Tasso $_tipoTasso ${_tassoCtrl.text}% - $_durataAnni anni',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _resultMini('Totale Interessi',
                    '\u20AC ${_fmt.format(_totaleInteressi)}'),
                Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.3)),
                _resultMini('Totale Restituito',
                    '\u20AC ${_fmt.format(_totaleRestituito)}'),
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
                fontSize: 10,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── Grafico progress bar capitale vs interessi ──
  Widget _buildProgressCard() {
    if (_totaleRestituito <= 0) return const SizedBox.shrink();

    final percCapitale = _importo / _totaleRestituito;
    final percInteressi = _totaleInteressi / _totaleRestituito;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Capitale vs Interessi',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            // Stacked progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Expanded(
                      flex: (percCapitale * 1000).round().clamp(1, 999),
                      child: Container(
                        color: const Color(0xFF4CAF50),
                        alignment: Alignment.center,
                        child: Text(
                          '${(percCapitale * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: (percInteressi * 1000).round().clamp(1, 999),
                      child: Container(
                        color: const Color(0xFFFF9800),
                        alignment: Alignment.center,
                        child: Text(
                          '${(percInteressi * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Capitale: \u20AC ${_fmt.format(_importo)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMedium)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Interessi: \u20AC ${_fmt.format(_totaleInteressi)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMedium)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Dettaglio ──
  Widget _buildDettaglioCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riepilogo',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 14),
            _row('Importo mutuo',
                '\u20AC ${_fmt.format(_importo)}'),
            _row('Durata', '$_durataAnni anni ($_totaleMesi rate)'),
            _row('Tasso annuo (TAN)', '${_tassoCtrl.text}%'),
            _row('Tipo tasso', _tipoTasso),
            const Divider(height: 16),
            _row('Rata mensile',
                '\u20AC ${_fmt.format(_rataMensile)}',
                bold: true),
            _row('Totale interessi',
                '\u20AC ${_fmt.format(_totaleInteressi)}',
                color: const Color(0xFFFF9800)),
            _row('Totale restituito',
                '\u20AC ${_fmt.format(_totaleRestituito)}',
                bold: true),
            const Divider(height: 16),
            _row(
                'Incidenza interessi',
                '${(_totaleInteressi / _totaleRestituito * 100).toStringAsFixed(1)}% del totale'),
            if (_tipoTasso == 'Variabile') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFF9800)
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Color(0xFFFF9800), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Con tasso variabile la rata puo\' cambiare nel tempo in base all\'andamento dell\'Euribor.',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.brown.shade700,
                            height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Piano ammortamento (tabella) ──
  Widget _buildPianoCard(String title, List<_RataDetail> rate) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 14),
            // Table header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                      width: 34,
                      child: Text('N.',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary))),
                  Expanded(
                      child: Text('Rata',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                          textAlign: TextAlign.right)),
                  Expanded(
                      child: Text('Capitale',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                          textAlign: TextAlign.right)),
                  Expanded(
                      child: Text('Interessi',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                          textAlign: TextAlign.right)),
                  Expanded(
                      flex: 2,
                      child: Text('Debito Residuo',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                          textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...rate.map((d) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 34,
                          child: Text('${d.mese}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark))),
                      Expanded(
                          child: Text(
                              '\u20AC ${_fmt.format(d.rata)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMedium),
                              textAlign: TextAlign.right)),
                      Expanded(
                          child: Text(
                              '\u20AC ${_fmt.format(d.quotaCapitale)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF4CAF50)),
                              textAlign: TextAlign.right)),
                      Expanded(
                          child: Text(
                              '\u20AC ${_fmt.format(d.quotaInteressi)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFFF9800)),
                              textAlign: TextAlign.right)),
                      Expanded(
                          flex: 2,
                          child: Text(
                              '\u20AC ${_fmt.format(d.debitoResiduo)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark),
                              textAlign: TextAlign.right)),
                    ],
                  ),
                )),
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

class _RataDetail {
  final int mese;
  final double rata;
  final double quotaCapitale;
  final double quotaInteressi;
  final double debitoResiduo;
  const _RataDetail({
    required this.mese,
    required this.rata,
    required this.quotaCapitale,
    required this.quotaInteressi,
    required this.debitoResiduo,
  });
}
