import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../core/widgets/disclaimer_widget.dart';

class BolloAutoScreen extends StatefulWidget {
  const BolloAutoScreen({super.key});

  @override
  State<BolloAutoScreen> createState() => _BolloAutoScreenState();
}

class _BolloAutoScreenState extends State<BolloAutoScreen>
    with SingleTickerProviderStateMixin {
  // ── Input ──
  final _kwCtrl = TextEditingController();
  int _classeEuro = 6;
  String _regione = 'Lazio';

  // ── Result ──
  bool _showResult = false;
  double _bolloAnnuale = 0;
  double _tariffaBase = 0;
  double _tariffaOltre = 0;
  double _kwValue = 0;
  String _scadenza = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');

  static const _regioni = [
    'Abruzzo', 'Basilicata', 'Calabria', 'Campania', 'Emilia-Romagna',
    'Friuli Venezia Giulia', 'Lazio', 'Liguria', 'Lombardia', 'Marche',
    'Molise', 'Piemonte', 'Puglia', 'Sardegna', 'Sicilia', 'Toscana',
    'Trentino-Alto Adige', 'Umbria', "Valle d'Aosta", 'Veneto',
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
    _kwCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  double _p(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  // ─────────────────────────────────────────────
  // TARIFFE BOLLO AUTO 2025
  // ─────────────────────────────────────────────
  // Returns (tariffa fino 100kW, tariffa oltre 100kW)
  ({double base, double oltre}) _getTariffe() {
    // Lombardia e Piemonte hanno tariffe leggermente diverse
    final isLombardia = _regione == 'Lombardia';
    final isPiemonte = _regione == 'Piemonte';

    switch (_classeEuro) {
      case 0:
        if (isLombardia) return (base: 3.12, oltre: 4.69);
        if (isPiemonte) return (base: 3.06, oltre: 4.59);
        return (base: 3.00, oltre: 4.50);
      case 1:
        if (isLombardia) return (base: 3.02, oltre: 4.53);
        if (isPiemonte) return (base: 2.96, oltre: 4.44);
        return (base: 2.90, oltre: 4.35);
      case 2:
        if (isLombardia) return (base: 2.91, oltre: 4.37);
        if (isPiemonte) return (base: 2.86, oltre: 4.29);
        return (base: 2.80, oltre: 4.20);
      case 3:
        if (isLombardia) return (base: 2.81, oltre: 4.21);
        if (isPiemonte) return (base: 2.76, oltre: 4.13);
        return (base: 2.70, oltre: 4.05);
      case 4:
      case 5:
      case 6:
      default:
        if (isLombardia) return (base: 2.68, oltre: 4.02);
        if (isPiemonte) return (base: 2.63, oltre: 3.95);
        return (base: 2.58, oltre: 3.87);
    }
  }

  String _calcolaScadenza() {
    // Il bollo auto si paga entro l'ultimo giorno del mese successivo
    // alla scadenza. In genere: Gennaio, Maggio, Settembre
    final now = DateTime.now();
    final month = now.month;

    if (month >= 1 && month <= 4) {
      return 'Aprile ${now.year} (veicoli con scadenza Dicembre ${now.year - 1})';
    } else if (month >= 5 && month <= 8) {
      return 'Agosto ${now.year} (veicoli con scadenza Aprile ${now.year})';
    } else {
      return 'Dicembre ${now.year} (veicoli con scadenza Agosto ${now.year})';
    }
  }

  // ─────────────────────────────────────────────
  // CALCOLO
  // ─────────────────────────────────────────────
  void _calcola() {
    final kw = _p(_kwCtrl.text);
    if (kw <= 0) return;
    _kwValue = kw;

    final tariffe = _getTariffe();
    _tariffaBase = tariffe.base;
    _tariffaOltre = tariffe.oltre;

    if (kw <= 100) {
      _bolloAnnuale = kw * tariffe.base;
    } else {
      _bolloAnnuale = (100 * tariffe.base) + ((kw - 100) * tariffe.oltre);
    }

    _scadenza = _calcolaScadenza();

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
            SliverToBoxAdapter(child: _sectionTitle('Potenza Veicolo')),
            SliverToBoxAdapter(child: _buildPotenzaSection()),
            SliverToBoxAdapter(child: _sectionTitle('Classe Euro')),
            SliverToBoxAdapter(child: _buildClasseEuroSection()),
            SliverToBoxAdapter(child: _sectionTitle('Regione')),
            SliverToBoxAdapter(child: _buildRegioneSection()),
            SliverToBoxAdapter(child: _buildCalcolaButton()),
            if (_showResult) ...[
              SliverToBoxAdapter(child: _buildResultCard()),
              SliverToBoxAdapter(child: _buildDettaglioCard()),
              SliverToBoxAdapter(child: _buildScadenzaCard()),
              SliverToBoxAdapter(child: _buildDovePagareCard()),
            ],
            SliverToBoxAdapter(child: CalculatorDisclaimer(specificSource: 'tariffe ACI regionali')),
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
            child: const Icon(Icons.directions_car,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BOLLO AUTO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Tassa automobilistica 2025',
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
                          'Le tariffe sono aggiornate al 2025. Lombardia e Piemonte hanno tariffe regionali leggermente diverse. Verifica sempre con ACI.'),
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

  // ── Potenza ──
  Widget _buildPotenzaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inserisci la potenza del veicolo in kW (dal libretto)',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _kwCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark),
            decoration: InputDecoration(
              labelText: 'Potenza',
              labelStyle: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium),
              suffixText: 'kW',
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

  // ── Classe Euro ──
  Widget _buildClasseEuroSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(7, (index) {
          final euro = index; // Euro 0 to Euro 6
          final selected = _classeEuro == euro;
          return GestureDetector(
            onTap: () => setState(() => _classeEuro = euro),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? _getEuroColor(euro).withValues(alpha: 0.15)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? _getEuroColor(euro)
                      : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Text(
                'Euro $euro',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? _getEuroColor(euro)
                      : AppColors.textMedium,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getEuroColor(int euro) {
    switch (euro) {
      case 6:
        return const Color(0xFF4CAF50);
      case 5:
        return const Color(0xFF8BC34A);
      case 4:
        return const Color(0xFF2196F3);
      case 3:
        return const Color(0xFFFF9800);
      case 2:
        return const Color(0xFFFF5722);
      case 1:
        return const Color(0xFFF44336);
      case 0:
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF2196F3);
    }
  }

  // ── Regione ──
  Widget _buildRegioneSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: DropdownButtonFormField<String>(
        initialValue: _regione,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Regione di residenza',
          labelStyle: const TextStyle(
              fontSize: 13, color: AppColors.textMedium),
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
        items: _regioni
            .map((r) => DropdownMenuItem(
                value: r,
                child: Text(r, style: const TextStyle(fontSize: 14))))
            .toList(),
        onChanged: (v) => setState(() => _regione = v ?? 'Lazio'),
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
            Icon(Icons.directions_car, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('CALCOLA BOLLO',
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
    final euroColor = _getEuroColor(_classeEuro);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [euroColor, euroColor.withValues(alpha: 0.7)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: euroColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('BOLLO AUTO ANNUALE',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('\u20AC ${_fmt.format(_bolloAnnuale)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
                '${_kwValue.toStringAsFixed(0)} kW - Euro $_classeEuro - $_regione',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                '\u20AC ${(_bolloAnnuale / 12).toStringAsFixed(2)} / mese',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
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
            const Text('Dettaglio Calcolo',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 14),
            _row('Potenza veicolo',
                '${_kwValue.toStringAsFixed(0)} kW'),
            _row('Classe emissioni', 'Euro $_classeEuro'),
            _row('Regione', _regione),
            const Divider(height: 16),
            _row('Tariffa fino a 100 kW',
                '\u20AC ${_tariffaBase.toStringAsFixed(2)} / kW'),
            _row('Tariffa oltre 100 kW',
                '\u20AC ${_tariffaOltre.toStringAsFixed(2)} / kW'),
            const Divider(height: 16),
            if (_kwValue <= 100) ...[
              _row(
                  'Calcolo',
                  '${_kwValue.toStringAsFixed(0)} kW x \u20AC ${_tariffaBase.toStringAsFixed(2)}'),
            ] else ...[
              _row('Primi 100 kW',
                  '100 x \u20AC ${_tariffaBase.toStringAsFixed(2)} = \u20AC ${_fmt.format(100 * _tariffaBase)}'),
              _row(
                  'kW eccedenti (${(_kwValue - 100).toStringAsFixed(0)})',
                  '${(_kwValue - 100).toStringAsFixed(0)} x \u20AC ${_tariffaOltre.toStringAsFixed(2)} = \u20AC ${_fmt.format((_kwValue - 100) * _tariffaOltre)}'),
            ],
            const Divider(height: 16),
            _row('BOLLO ANNUALE',
                '\u20AC ${_fmt.format(_bolloAnnuale)}',
                bold: true),
          ],
        ),
      ),
    );
  }

  // ── Scadenza ──
  Widget _buildScadenzaCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
              width: 2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today,
                      color: Color(0xFFFF9800), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Scadenza Pagamento',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 12),
            Text(_scadenza,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9800))),
            const SizedBox(height: 8),
            const Text(
              'Il bollo si paga entro l\'ultimo giorno del mese successivo alla scadenza. Le scadenze principali sono: Gennaio, Maggio e Settembre.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                  height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dove pagare ──
  Widget _buildDovePagareCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dove Pagare',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 14),
            _pagamentoItem(
              Icons.language,
              'ACI Online',
              'www.aci.it - Pagamento con carta',
              const Color(0xFF1565C0),
            ),
            _pagamentoItem(
              Icons.store,
              'Tabaccheria / Ricevitoria',
              'Presso i punti abilitati Lottomatica',
              const Color(0xFF4CAF50),
            ),
            _pagamentoItem(
              Icons.account_balance,
              'PagoPA',
              'Tramite home banking o app IO',
              const Color(0xFF9C27B0),
            ),
            _pagamentoItem(
              Icons.local_post_office,
              'Poste Italiane',
              'Ufficio postale o app Postepay',
              const Color(0xFFFF9800),
            ),
            _pagamentoItem(
              Icons.account_balance_wallet,
              'Banca / Home Banking',
              'Servizio CBILL / PagoPA',
              const Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pagamentoItem(
      IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
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
