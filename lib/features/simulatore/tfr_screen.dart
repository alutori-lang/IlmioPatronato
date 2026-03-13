import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';

class TfrScreen extends StatefulWidget {
  const TfrScreen({super.key});

  @override
  State<TfrScreen> createState() => _TfrScreenState();
}

class _TfrScreenState extends State<TfrScreen>
    with SingleTickerProviderStateMixin {
  // ── Input ──
  final _ralCtrl = TextEditingController();
  int _anniLavoro = 5;
  final _rivalutazioneCtrl = TextEditingController(text: '3.0');
  bool _anticipazione = false;
  final _anticipazionePercentCtrl = TextEditingController(text: '70');

  // ── Result ──
  bool _showResult = false;
  double _tfrLordo = 0;
  double _tfrNetto = 0;
  double _tassazioneSeparata = 0;
  double _aliquotaMedia = 0;
  List<_TfrAnnuale> _dettaglioAnnuale = [];
  double _anticipazioneImporto = 0;

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
    _ralCtrl.dispose();
    _rivalutazioneCtrl.dispose();
    _anticipazionePercentCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  double _p(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  // ─────────────────────────────────────────────
  // CALCOLO TFR
  // ─────────────────────────────────────────────
  void _calcola() {
    final ral = _p(_ralCtrl.text);
    if (ral <= 0) return;

    final rivalutazioneAnnua = _p(_rivalutazioneCtrl.text) / 100.0;

    _dettaglioAnnuale = [];
    double tfrAccumulato = 0;

    for (int anno = 1; anno <= _anniLavoro; anno++) {
      // TFR annuo lordo = RAL / 13.5
      final tfrAnnuoLordo = ral / 13.5;

      // Contributo INPS 0.5% della RAL
      final contributoInps = ral * 0.005;

      // TFR annuo netto INPS
      final tfrAnnuoNetto = tfrAnnuoLordo - contributoInps;

      // Rivalutazione sul TFR accumulato (dall'anno 2 in poi)
      double rivalutazione = 0;
      if (anno > 1 && tfrAccumulato > 0) {
        // Rivalutazione = 1.5% fisso + 75% dell'indice ISTAT
        // Semplificato: usiamo il tasso input (default ~3%)
        rivalutazione = tfrAccumulato * rivalutazioneAnnua;
      }

      tfrAccumulato += tfrAnnuoNetto + rivalutazione;

      _dettaglioAnnuale.add(_TfrAnnuale(
        anno: anno,
        tfrAnnuo: tfrAnnuoNetto,
        rivalutazione: rivalutazione,
        tfrCumulato: tfrAccumulato,
      ));
    }

    _tfrLordo = tfrAccumulato;

    // ── Tassazione separata ──
    // Aliquota media = TFR lordo / anni * 12 → reddito di riferimento
    // Poi si applica IRPEF su quel reddito di riferimento → aliquota media ultimi 5 anni
    final redditoRiferimento = (_tfrLordo / _anniLavoro.toDouble()) * 12.0;
    _aliquotaMedia = _calcolaAliquotaMediaIrpef(redditoRiferimento);
    _tassazioneSeparata = _tfrLordo * _aliquotaMedia;
    _tfrNetto = _tfrLordo - _tassazioneSeparata;

    // ── Anticipazione ──
    if (_anticipazione) {
      final perc = _p(_anticipazionePercentCtrl.text).clamp(0, 70.0) / 100.0;
      _anticipazioneImporto = _tfrNetto * perc;
    } else {
      _anticipazioneImporto = 0;
    }

    setState(() => _showResult = true);
    _animController.forward(from: 0);
  }

  // Calcolo aliquota media IRPEF semplificata (scaglioni 2025)
  double _calcolaAliquotaMediaIrpef(double reddito) {
    if (reddito <= 0) return 0;
    double imposta = 0;
    double residuo = reddito;

    if (residuo > 0) {
      final base1 = residuo.clamp(0.0, 28000.0);
      imposta += base1 * 0.23;
      residuo -= base1;
    }
    if (residuo > 0) {
      final base2 = residuo.clamp(0.0, 22000.0);
      imposta += base2 * 0.35;
      residuo -= base2;
    }
    if (residuo > 0) {
      imposta += residuo * 0.43;
    }

    return imposta / reddito;
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
            SliverToBoxAdapter(child: _sectionTitle('Dati Retributivi')),
            SliverToBoxAdapter(child: _buildRetribuzioneSection()),
            SliverToBoxAdapter(child: _sectionTitle('Anni di Lavoro')),
            SliverToBoxAdapter(child: _buildAnniSection()),
            SliverToBoxAdapter(child: _sectionTitle('Rivalutazione')),
            SliverToBoxAdapter(child: _buildRivalutazioneSection()),
            SliverToBoxAdapter(child: _sectionTitle('Anticipazione TFR')),
            SliverToBoxAdapter(child: _buildAnticipazioneSection()),
            SliverToBoxAdapter(child: _buildCalcolaButton()),
            if (_showResult) ...[
              SliverToBoxAdapter(child: _buildResultCard()),
              SliverToBoxAdapter(child: _buildDettaglioCard()),
              SliverToBoxAdapter(child: _buildAnnualeCard()),
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
            child: const Icon(Icons.savings, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CALCOLO TFR',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Trattamento di Fine Rapporto',
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
                          'Il TFR viene calcolato con la formula RAL/13.5 meno contributo INPS 0.5%. La rivalutazione si applica dal secondo anno. Tassazione separata semplificata.'),
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

  // ── Retribuzione ──
  Widget _buildRetribuzioneSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RAL - Retribuzione Annua Lorda',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 10),
          _moneyField(_ralCtrl, 'RAL lorda annua'),
        ],
      ),
    );
  }

  // ── Anni di lavoro ──
  Widget _buildAnniSection() {
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
                  'Anni di lavoro: $_anniLavoro',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                ),
              ),
              _cBtn(Icons.remove, _anniLavoro > 1,
                  () => setState(() => _anniLavoro--)),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  '$_anniLavoro',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
              ),
              _cBtn(Icons.add, _anniLavoro < 40,
                  () => setState(() => _anniLavoro++)),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _anniLavoro.toDouble(),
              min: 1,
              max: 40,
              divisions: 39,
              label: '$_anniLavoro anni',
              onChanged: (v) => setState(() => _anniLavoro = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 anno',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
              Text('40 anni',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Rivalutazione ──
  Widget _buildRivalutazioneSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rivalutazione annua media',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Formula: 1.5% fisso + 75% indice ISTAT. Media storica ~3%',
            style: TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rivalutazioneCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark),
            decoration: InputDecoration(
              labelText: 'Tasso rivalutazione annuo',
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
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Anticipazione ──
  Widget _buildAnticipazioneSection() {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Richiesta anticipazione TFR',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(
                      'Max 70% dopo 8 anni di servizio',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _anticipazione,
                onChanged: (v) => setState(() => _anticipazione = v),
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          if (_anticipazione) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _anticipazionePercentCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
              decoration: InputDecoration(
                labelText: 'Percentuale anticipazione',
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
        ],
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
            Icon(Icons.savings, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('CALCOLA TFR',
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
            const Text('TFR NETTO STIMATO',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('\u20AC ${_fmt.format(_tfrNetto)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
                'TFR lordo: \u20AC ${_fmt.format(_tfrLordo)}',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                'Tassazione separata (${(_aliquotaMedia * 100).toStringAsFixed(1)}%): \u20AC ${_fmt.format(_tassazioneSeparata)}',
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12)),
            if (_anticipazione && _anticipazioneImporto > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'Anticipazione: \u20AC ${_fmt.format(_anticipazioneImporto)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Dettaglio calcolo ──
  Widget _buildDettaglioCard() {
    final ral = _p(_ralCtrl.text);
    final tfrAnnuoLordo = ral / 13.5;
    final contributoInps = ral * 0.005;
    final tfrAnnuoNetto = tfrAnnuoLordo - contributoInps;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dettaglio Calcolo',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 14),
            _row('RAL annua',
                '\u20AC ${_fmt.format(ral)}'),
            _row('TFR annuo lordo (RAL / 13.5)',
                '\u20AC ${_fmt.format(tfrAnnuoLordo)}'),
            _row('Contributo INPS 0.5%',
                '- \u20AC ${_fmt.format(contributoInps)}',
                color: const Color(0xFFF44336)),
            _row('TFR annuo netto INPS',
                '\u20AC ${_fmt.format(tfrAnnuoNetto)}'),
            const Divider(height: 16),
            _row('Anni di lavoro', '$_anniLavoro'),
            _row('TFR lordo accumulato',
                '\u20AC ${_fmt.format(_tfrLordo)}',
                bold: true),
            const Divider(height: 16),
            _row('Aliquota tassazione separata',
                '${(_aliquotaMedia * 100).toStringAsFixed(1)}%'),
            _row('Tassazione separata',
                '- \u20AC ${_fmt.format(_tassazioneSeparata)}',
                color: const Color(0xFFF44336)),
            _row('TFR NETTO',
                '\u20AC ${_fmt.format(_tfrNetto)}',
                bold: true),
            if (_anticipazione && _anticipazioneImporto > 0) ...[
              const Divider(height: 16),
              _row('Anticipazione TFR',
                  '\u20AC ${_fmt.format(_anticipazioneImporto)}',
                  bold: true,
                  color: const Color(0xFFFF9800)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Piano annuale ──
  Widget _buildAnnualeCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dettaglio Annuale',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 14),
            // Table header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                      width: 40,
                      child: Text('Anno',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary))),
                  Expanded(
                      child: Text('TFR Annuo',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                          textAlign: TextAlign.right)),
                  Expanded(
                      child: Text('Rivalut.',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                          textAlign: TextAlign.right)),
                  Expanded(
                      child: Text('Cumulato',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                          textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ..._dettaglioAnnuale.map((d) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 40,
                          child: Text('${d.anno}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark))),
                      Expanded(
                          child: Text(
                              '\u20AC ${_fmt.format(d.tfrAnnuo)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMedium),
                              textAlign: TextAlign.right)),
                      Expanded(
                          child: Text(
                              d.rivalutazione > 0
                                  ? '\u20AC ${_fmt.format(d.rivalutazione)}'
                                  : '-',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: d.rivalutazione > 0
                                      ? const Color(0xFF4CAF50)
                                      : AppColors.textLight),
                              textAlign: TextAlign.right)),
                      Expanded(
                          child: Text(
                              '\u20AC ${_fmt.format(d.tfrCumulato)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
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

  Widget _cBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? AppColors.primary : Colors.grey.shade400),
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

class _TfrAnnuale {
  final int anno;
  final double tfrAnnuo;
  final double rivalutazione;
  final double tfrCumulato;
  const _TfrAnnuale({
    required this.anno,
    required this.tfrAnnuo,
    required this.rivalutazione,
    required this.tfrCumulato,
  });
}
