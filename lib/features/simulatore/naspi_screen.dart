import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/constants.dart';

class NaspiScreen extends StatefulWidget {
  const NaspiScreen({super.key});

  @override
  State<NaspiScreen> createState() => _NaspiScreenState();
}

class _NaspiScreenState extends State<NaspiScreen>
    with SingleTickerProviderStateMixin {
  // ── Form controllers ──
  final _retribuzioneController = TextEditingController();

  // ── State ──
  int _settimaneContributi = 52; // default 1 anno
  String _motivoCessazione = 'licenziamento';

  // ── Result state ──
  bool _showResult = false;
  double _importoMensile = 0;
  int _durataMesi = 0;
  double _totaleStimato = 0;
  double _retribuzioneRiferimento = 0;
  List<_MeseNaspi> _tabellaMesi = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ────────────────────────────────────────────────
  // PARAMETRI REALI NASpI 2025
  // ────────────────────────────────────────────────
  static const double _sogliaRetribuzione = 1425.21;
  static const double _importoMassimo = 1550.42;
  static const double _percentualeSotto = 0.75;
  static const double _percentualeSopra = 0.25;
  static const double _percentualeDecalage = 0.03; // 3% mensile dal 6° mese (151° giorno)

  static const List<String> _motiviLabels = [
    'Licenziamento',
    'Dimissioni per giusta causa',
    'Scadenza contratto a termine',
  ];
  static const List<String> _motiviValues = [
    'licenziamento',
    'giusta_causa',
    'scadenza_contratto',
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
    _retribuzioneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  double _parseNum(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  void _calcola() {
    final retribuzioneLorda = _parseNum(_retribuzioneController.text);
    if (retribuzioneLorda <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci la retribuzione lorda mensile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Retribuzione di riferimento
    // In formula completa: (imponibile ultimi 4 anni) / settimane * 4.33
    // Semplificato: usiamo la retribuzione lorda mensile come riferimento
    final retribuzioneRif = retribuzioneLorda;

    // Calcolo importo NASpI
    double importo;
    if (retribuzioneRif <= _sogliaRetribuzione) {
      importo = retribuzioneRif * _percentualeSotto;
    } else {
      importo = _sogliaRetribuzione * _percentualeSotto +
          (retribuzioneRif - _sogliaRetribuzione) * _percentualeSopra;
    }

    // Tetto massimo
    if (importo > _importoMassimo) {
      importo = _importoMassimo;
    }

    // Durata: meta delle settimane di contributi, max 24 mesi
    final durataMesi = (_settimaneContributi / 2).floor().clamp(1, 24);

    // Tabella con decalage mensile
    final tabella = <_MeseNaspi>[];
    double totale = 0;
    double importoCorrente = importo;

    for (int mese = 1; mese <= durataMesi; mese++) {
      // Dal 6 mese (151 giorno = inizio mese 6): riduzione 3% al mese
      if (mese >= 6) {
        final mesiDiRiduzione = mese - 5;
        final riduzione = 1.0 - (_percentualeDecalage * mesiDiRiduzione.toDouble());
        importoCorrente = importo * (riduzione > 0 ? riduzione : 0);
        if (importoCorrente < 0) importoCorrente = 0;
      } else {
        importoCorrente = importo;
      }

      tabella.add(_MeseNaspi(
        mese: mese,
        importo: importoCorrente,
        riduzione: mese >= 6
            ? _percentualeDecalage * (mese - 5).toDouble() * 100
            : 0,
      ));

      totale += importoCorrente;
    }

    setState(() {
      _showResult = true;
      _importoMensile = importo;
      _durataMesi = durataMesi;
      _totaleStimato = totale;
      _retribuzioneRiferimento = retribuzioneRif;
      _tabellaMesi = tabella;
    });

    _animController.reset();
    _animController.forward();
  }

  // ────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────
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
            SliverToBoxAdapter(child: _sectionTitle('Retribuzione')),
            SliverToBoxAdapter(child: _buildRetribuzioneSection()),
            SliverToBoxAdapter(child: _sectionTitle('Contributi versati')),
            SliverToBoxAdapter(child: _buildContributiSection()),
            SliverToBoxAdapter(child: _sectionTitle('Motivo cessazione')),
            SliverToBoxAdapter(child: _buildMotivoSection()),
            SliverToBoxAdapter(child: _buildCalcolaButton()),
            if (_showResult) ...[
              SliverToBoxAdapter(child: _buildResultCard()),
              SliverToBoxAdapter(child: _buildDettaglioCalcoloCard()),
              SliverToBoxAdapter(child: _buildDecalageCard()),
              SliverToBoxAdapter(child: _buildInfoCard()),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Header ──
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
          const Icon(Icons.work_off, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calcolo NASpI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Indennita di disoccupazione 2025',
                  style: TextStyle(
                    color: AppColors.textSubtitle,
                    fontSize: 11,
                  ),
                ),
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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFFFA000), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Calcolo indicativo basato sui parametri INPS 2025. '
              'L\'importo effettivo dipende dall\'imponibile previdenziale '
              'degli ultimi 4 anni calcolato dall\'INPS.',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF5D4037), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  // ── Retribuzione section ──
  Widget _buildRetribuzioneSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ultima retribuzione lorda mensile (da busta paga). '
            'Viene utilizzata come retribuzione di riferimento per il calcolo.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textMedium, height: 1.3),
          ),
          const SizedBox(height: 12),
          _buildMoneyField(
              _retribuzioneController, 'Retribuzione lorda mensile'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMedium,
                          height: 1.3),
                      children: [
                        const TextSpan(
                          text: 'Soglia 2025: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              'Se \u2264 \u20AC${_sogliaRetribuzione.toStringAsFixed(2)}: '
                              'NASpI = 75%. Se superiore: 75% di \u20AC${_sogliaRetribuzione.toStringAsFixed(2)} '
                              '+ 25% della parte eccedente. '
                              'Max \u20AC${_importoMassimo.toStringAsFixed(2)}/mese.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Contributi section ──
  Widget _buildContributiSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settimane di contribuzione versati negli ultimi 4 anni. '
            'Servono almeno 13 settimane per avere diritto alla NASpI.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textMedium, height: 1.3),
          ),
          const SizedBox(height: 16),
          _buildCounter(
            'Settimane contributi',
            _settimaneContributi,
            13,
            208,
            (v) => setState(() {
              _settimaneContributi = v;
              _showResult = false;
            }),
          ),
          const SizedBox(height: 12),
          // Quick select buttons
          const Text(
            'Selezione rapida:',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickSelectChip('1 anno', 52),
              _quickSelectChip('2 anni', 104),
              _quickSelectChip('3 anni', 156),
              _quickSelectChip('4 anni', 208),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Durata NASpI stimata: ${(_settimaneContributi / 2).floor().clamp(1, 24)} mesi',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickSelectChip(String label, int settimane) {
    final isSelected = _settimaneContributi == settimane;
    return GestureDetector(
      onTap: () => setState(() {
        _settimaneContributi = settimane;
        _showResult = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ── Motivo cessazione ──
  Widget _buildMotivoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(),
      child: RadioGroup<String>(
        groupValue: _motivoCessazione,
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _motivoCessazione = value;
              _showResult = false;
            });
          }
        },
        child: Column(
          children: List.generate(_motiviValues.length, (i) {
            final isLast = i == _motiviValues.length - 1;
            return Column(
              children: [
                RadioListTile<String>(
                  title: Text(
                    _motiviLabels[i],
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _getMotivoSubtitle(i),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight),
                  ),
                  value: _motiviValues[i],
                  activeColor: AppColors.primary,
                ),
                if (!isLast)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _getMotivoSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Individuale, collettivo, per giustificato motivo';
      case 1:
        return 'Per mancato pagamento, mobbing, ecc.';
      case 2:
        return 'Contratto a tempo determinato scaduto';
      default:
        return '';
    }
  }

  // ── Calcola button ──
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'CALCOLA NASpI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Result card ──
  Widget _buildResultCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'NASpI STIMATA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: _importoMensile),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      '\u20AC${value.toStringAsFixed(2)}/mese',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _resultPill(
                      Icons.timer,
                      '$_durataMesi mesi',
                    ),
                    const SizedBox(width: 12),
                    _resultPill(
                      Icons.savings,
                      'Tot. \u20AC${_totaleStimato.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dettaglio calcolo ──
  Widget _buildDettaglioCalcoloCard() {
    final retLorda = _parseNum(_retribuzioneController.text);
    final sottoSoglia = retLorda <= _sogliaRetribuzione;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dettaglio calcolo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detailRow('Retribuzione di riferimento',
                  '\u20AC${_retribuzioneRiferimento.toStringAsFixed(2)}'),
              _detailRow(
                  'Soglia 2025', '\u20AC${_sogliaRetribuzione.toStringAsFixed(2)}'),
              if (sottoSoglia)
                _detailRow('Calcolo',
                    '75% di \u20AC${retLorda.toStringAsFixed(2)}')
              else ...[
                _detailRow('75% di \u20AC${_sogliaRetribuzione.toStringAsFixed(2)}',
                    '\u20AC${(_sogliaRetribuzione * _percentualeSotto).toStringAsFixed(2)}'),
                _detailRow(
                    '25% di \u20AC${(retLorda - _sogliaRetribuzione).toStringAsFixed(2)}',
                    '\u20AC${((retLorda - _sogliaRetribuzione) * _percentualeSopra).toStringAsFixed(2)}'),
              ],
              if (_importoMensile >= _importoMassimo)
                _detailRow('Tetto massimo applicato',
                    '\u20AC${_importoMassimo.toStringAsFixed(2)}',
                    bold: true),
              const Divider(height: 20),
              _detailRow('Importo mensile iniziale',
                  '\u20AC${_importoMensile.toStringAsFixed(2)}',
                  bold: true),
              _detailRow('Durata', '$_durataMesi mesi', bold: true),
              _detailRow('Settimane contributi', '$_settimaneContributi'),
              _detailRow(
                  'Decalage', 'Dal 6\u00B0 mese: -3% al mese'),
              const Divider(height: 20),
              _detailRow('Totale stimato complessivo',
                  '\u20AC${_totaleStimato.toStringAsFixed(2)}',
                  bold: true),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tabella decalage mensile ──
  Widget _buildDecalageCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_down,
                      color: Color(0xFFFF9800), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tabella importi mensili',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Dal 6\u00B0 mese l\'importo si riduce del 3% ogni mese',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textLight, height: 1.3),
              ),
              const SizedBox(height: 14),
              // Table header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text('Mese',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ),
                    Expanded(
                      child: Text('Importo',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text('Riduzione',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Table rows - show first 6 and last 2 if long
              ..._buildTableRows(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTableRows() {
    final rows = <Widget>[];
    final total = _tabellaMesi.length;

    if (total <= 10) {
      // Show all rows
      for (final m in _tabellaMesi) {
        rows.add(_buildMeseRow(m));
      }
    } else {
      // Show first 6
      for (int i = 0; i < 6; i++) {
        rows.add(_buildMeseRow(_tabellaMesi[i]));
      }
      // Ellipsis
      rows.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Center(
            child: Text(
              '...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
          ),
        ),
      );
      // Show last 3
      for (int i = total - 3; i < total; i++) {
        rows.add(_buildMeseRow(_tabellaMesi[i]));
      }
    }

    return rows;
  }

  Widget _buildMeseRow(_MeseNaspi m) {
    final hasRiduzione = m.riduzione > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '${m.mese}\u00B0',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '\u20AC${m.importo.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasRiduzione
                    ? const Color(0xFFFF9800)
                    : AppColors.textDark,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              hasRiduzione ? '-${m.riduzione.toStringAsFixed(0)}%' : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasRiduzione ? Colors.red.shade400 : AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info card ──
  Widget _buildInfoCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Come fare domanda NASpI',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStep(
                '1',
                'Entro 68 giorni dalla cessazione',
                'La domanda va presentata entro 68 giorni dal licenziamento',
              ),
              _buildStep(
                '2',
                'Accedi a myINPS con SPID/CIE',
                'Sezione "Prestazioni e servizi" > "NASpI"',
              ),
              _buildStep(
                '3',
                'Compila la domanda online',
                'Oppure rivolgiti a un Patronato/CAF',
              ),
              _buildStep(
                '4',
                'Dichiarazione di disponibilita (DID)',
                'Renditi disponibile al lavoro presso il Centro per l\'Impiego',
              ),
              const Divider(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber,
                        color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Requisito minimo: 13 settimane di contributi '
                        'negli ultimi 4 anni e 30 giorni di lavoro '
                        'effettivo nei 12 mesi precedenti.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade700,
                          height: 1.4,
                        ),
                      ),
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

  Widget _buildStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMedium,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // REUSABLE WIDGETS
  // ────────────────────────────────────────────────
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 15,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildCounter(
      String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
        _counterBtn(Icons.remove, value > min, () => onChanged(value - 1)),
        Container(
          width: 50,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        _counterBtn(Icons.add, value < max, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _counterBtn(IconData icon, bool enabled, VoidCallback onTap) {
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
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primary : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildMoneyField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMedium),
        prefixText: '\u20AC  ',
        prefixStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: bold ? AppColors.textDark : AppColors.textMedium,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper data class ──
class _MeseNaspi {
  final int mese;
  final double importo;
  final double riduzione; // percentage

  const _MeseNaspi({
    required this.mese,
    required this.importo,
    required this.riduzione,
  });
}
