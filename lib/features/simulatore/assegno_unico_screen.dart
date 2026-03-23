import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/constants.dart';
import '../../core/widgets/disclaimer_widget.dart';

class AssegnoUnicoScreen extends StatefulWidget {
  const AssegnoUnicoScreen({super.key});

  @override
  State<AssegnoUnicoScreen> createState() => _AssegnoUnicoScreenState();
}

class _AssegnoUnicoScreenState extends State<AssegnoUnicoScreen>
    with SingleTickerProviderStateMixin {
  // ── Form controllers ──
  final _iseeController = TextEditingController();

  // ── Children state ──
  int _numFigli = 1;
  // Age category for each child: 0 = 0-1, 1 = 1-3, 2 = 3-18, 3 = 18-21
  List<int> _etaCategorie = [2]; // default: first child 3-18

  bool _genitoreSolo = false;
  int _figliDisabili = 0;
  String _tipoDisabilita = 'medio'; // 'medio', 'grave', 'non_autosufficiente'
  bool _entrambiLavorano = false;

  // ── Result state ──
  bool _showResult = false;
  double _totaleMensile = 0;
  double _totaleAnnuale = 0;
  List<_DettaglioFiglio> _dettagliFigli = [];
  double _maggiorazione3Figli = 0;
  double _maggiorazioneLavoro = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ────────────────────────────────────────────────
  // IMPORTI REALI ASSEGNO UNICO 2025
  // ────────────────────────────────────────────────
  static const double _iseeMinSoglia = 17090.61;
  static const double _iseeMaxSoglia = 45574.96;

  // 0-17 anni
  static const double _importoMax017 = 199.40;
  static const double _importoMin017 = 57.00;

  // 18-21 anni
  static const double _importoMax1821 = 96.90;
  static const double _importoMin1821 = 28.50;

  // Maggiorazioni
  static const double _maggiorazioneSotto1 = 114.40;
  static const double _maggiorazione1_3con3figli = 99.80;
  static const double _maggiorazioneDisabileNonAuto = 119.60;
  static const double _maggiorazioneDisabileGrave = 108.50;
  static const double _maggiorazioneDisabileMedio = 97.50;
  static const double _maggiorazioneLavoroMax = 37.40;
  static const double _maggiorazioneLavoroMin = 0.0;
  static const double _maggiorazione3FigliMax = 97.40;
  static const double _maggiorazione3FigliMin = 0.0;

  static const List<String> _etaLabels = [
    '0-1 anno',
    '1-3 anni',
    '3-18 anni',
    '18-21 anni',
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
    _iseeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _updateNumFigli(int newVal) {
    setState(() {
      _numFigli = newVal;
      // Adjust age categories list
      if (_etaCategorie.length < newVal) {
        while (_etaCategorie.length < newVal) {
          _etaCategorie.add(2); // default 3-18
        }
      } else if (_etaCategorie.length > newVal) {
        _etaCategorie = _etaCategorie.sublist(0, newVal);
      }
      // Ensure disabled count does not exceed children count
      if (_figliDisabili > _numFigli) {
        _figliDisabili = _numFigli;
      }
      _showResult = false;
    });
  }

  double _parseNum(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  /// Linear interpolation between max and min based on ISEE
  double _interpolaImporto(double maxVal, double minVal, double isee) {
    if (isee <= _iseeMinSoglia) return maxVal;
    if (isee >= _iseeMaxSoglia) return minVal;
    final rapporto = (isee - _iseeMinSoglia) / (_iseeMaxSoglia - _iseeMinSoglia);
    return maxVal - (maxVal - minVal) * rapporto;
  }

  void _calcola() {
    final isee = _parseNum(_iseeController.text);

    final dettagli = <_DettaglioFiglio>[];
    double somma = 0;

    for (int i = 0; i < _numFigli; i++) {
      final cat = _etaCategorie[i];
      double importoBase;
      String fascia;

      if (cat == 3) {
        // 18-21 anni
        importoBase = _interpolaImporto(_importoMax1821, _importoMin1821, isee);
        fascia = '18-21 anni';
      } else {
        // 0-17 anni
        importoBase = _interpolaImporto(_importoMax017, _importoMin017, isee);
        fascia = _etaLabels[cat];
      }

      double maggiorazioneEta = 0;
      String? notaMaggiorazione;

      // Maggiorazione figlio < 1 anno
      if (cat == 0) {
        maggiorazioneEta = _maggiorazioneSotto1;
        notaMaggiorazione = 'Maggiorazione < 1 anno';
      }

      // Maggiorazione 1-3 anni con 3+ figli
      if (cat == 1 && _numFigli >= 3) {
        maggiorazioneEta = _maggiorazione1_3con3figli;
        notaMaggiorazione = 'Maggiorazione 1-3 anni (3+ figli)';
      }

      final totaleFiglio = importoBase + maggiorazioneEta;

      dettagli.add(_DettaglioFiglio(
        numero: i + 1,
        fascia: fascia,
        importoBase: importoBase,
        maggiorazioneEta: maggiorazioneEta,
        notaMaggiorazione: notaMaggiorazione,
        totaleFiglio: totaleFiglio,
      ));

      somma += totaleFiglio;
    }

    // Maggiorazione disabilita
    double totDisabilita = 0;
    if (_figliDisabili > 0) {
      double maggiorazionePerFiglio;
      switch (_tipoDisabilita) {
        case 'non_autosufficiente':
          maggiorazionePerFiglio = _maggiorazioneDisabileNonAuto;
          break;
        case 'grave':
          maggiorazionePerFiglio = _maggiorazioneDisabileGrave;
          break;
        default:
          maggiorazionePerFiglio = _maggiorazioneDisabileMedio;
      }
      totDisabilita = maggiorazionePerFiglio * _figliDisabili.toDouble();
      somma += totDisabilita;
    }

    // Maggiorazione entrambi genitori lavorano
    double maggiorazioneLavoro = 0;
    if (_entrambiLavorano) {
      maggiorazioneLavoro =
          _interpolaImporto(_maggiorazioneLavoroMax, _maggiorazioneLavoroMin, isee);
      somma += maggiorazioneLavoro;
    }

    // Maggiorazione 3+ figli
    double maggiorazione3figli = 0;
    if (_numFigli >= 3) {
      maggiorazione3figli =
          _interpolaImporto(_maggiorazione3FigliMax, _maggiorazione3FigliMin, isee);
      somma += maggiorazione3figli;
    }

    // Genitore solo: importo raddoppiato (si aggiunge la stessa somma come quota altro genitore)
    if (_genitoreSolo) {
      somma *= 2;
    }

    setState(() {
      _showResult = true;
      _totaleMensile = somma;
      _totaleAnnuale = somma * 12;
      _dettagliFigli = dettagli;
      _maggiorazione3Figli = maggiorazione3figli;
      _maggiorazioneLavoro = maggiorazioneLavoro;
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
            SliverToBoxAdapter(child: _sectionTitle('Dati ISEE')),
            SliverToBoxAdapter(child: _buildIseeSection()),
            SliverToBoxAdapter(child: _sectionTitle('Figli a carico')),
            SliverToBoxAdapter(child: _buildFigliSection()),
            SliverToBoxAdapter(child: _sectionTitle('Situazione familiare')),
            SliverToBoxAdapter(child: _buildSituazioneSection()),
            if (_figliDisabili > 0) ...[
              SliverToBoxAdapter(child: _sectionTitle('Tipo disabilita')),
              SliverToBoxAdapter(child: _buildDisabilitaSection()),
            ],
            SliverToBoxAdapter(child: _buildCalcolaButton()),
            if (_showResult) ...[
              SliverToBoxAdapter(child: _buildResultCard()),
              SliverToBoxAdapter(child: _buildDettaglioFigliCard()),
              SliverToBoxAdapter(child: _buildMaggiorazioniCard()),
              SliverToBoxAdapter(child: _buildInfoCard()),
            ],
            SliverToBoxAdapter(child: CalculatorDisclaimer(specificSource: 'D.Lgs. 230/2021 e tabelle INPS')),
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
          const Icon(Icons.child_care, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assegno Unico Figli',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Importi aggiornati 2025',
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
              'Calcolo indicativo basato sugli importi INPS 2025. '
              'L\'importo effettivo viene determinato dall\'INPS in base '
              'alla DSU/ISEE presentata.',
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

  // ── ISEE section ──
  Widget _buildIseeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inserisci il valore ISEE del tuo nucleo familiare. '
            'Senza ISEE o con ISEE > \u20AC45.574,96 si applica l\'importo minimo.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textMedium, height: 1.3),
          ),
          const SizedBox(height: 12),
          _buildMoneyField(_iseeController, 'Valore ISEE'),
        ],
      ),
    );
  }

  // ── Figli section ──
  Widget _buildFigliSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildCounter(
            'Numero figli',
            _numFigli,
            1,
            10,
            _updateNumFigli,
          ),
          const Divider(height: 24),
          // Age categories for each child
          ...List.generate(_numFigli, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
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
                        '${i + 1}',
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _etaCategorie[i],
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.primary, size: 20),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          items: List.generate(4, (idx) {
                            return DropdownMenuItem<int>(
                              value: idx,
                              child: Text(_etaLabels[idx]),
                            );
                          }),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _etaCategorie[i] = v;
                                _showResult = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Situazione familiare ──
  Widget _buildSituazioneSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSwitch(
            'Genitore solo (vedovo/a, affido esclusivo)',
            _genitoreSolo,
            (v) => setState(() {
              _genitoreSolo = v;
              _showResult = false;
            }),
          ),
          const Divider(height: 16),
          _buildSwitch(
            'Entrambi i genitori lavorano',
            _entrambiLavorano,
            (v) => setState(() {
              _entrambiLavorano = v;
              _showResult = false;
            }),
          ),
          const Divider(height: 16),
          _buildCounter(
            'Figli con disabilita',
            _figliDisabili,
            0,
            _numFigli,
            (v) => setState(() {
              _figliDisabili = v;
              _showResult = false;
            }),
          ),
        ],
      ),
    );
  }

  // ── Tipo disabilita ──
  Widget _buildDisabilitaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(),
      child: RadioGroup<String>(
        groupValue: _tipoDisabilita,
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _tipoDisabilita = value;
              _showResult = false;
            });
          }
        },
        child: Column(
          children: [
            RadioListTile<String>(
              title: const Text('Non autosufficiente',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                  'Maggiorazione: +\u20AC${_maggiorazioneDisabileNonAuto.toStringAsFixed(2)}/figlio',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight)),
              value: 'non_autosufficiente',
              activeColor: AppColors.primary,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            RadioListTile<String>(
              title: const Text('Grave',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                  'Maggiorazione: +\u20AC${_maggiorazioneDisabileGrave.toStringAsFixed(2)}/figlio',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight)),
              value: 'grave',
              activeColor: AppColors.primary,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            RadioListTile<String>(
              title: const Text('Medio',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                  'Maggiorazione: +\u20AC${_maggiorazioneDisabileMedio.toStringAsFixed(2)}/figlio',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight)),
              value: 'medio',
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
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
              'CALCOLA ASSEGNO',
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
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.child_care, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'ASSEGNO UNICO STIMATO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: _totaleMensile),
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
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: _totaleAnnuale),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Text(
                        'Totale annuale: \u20AC${value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                if (_genitoreSolo) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Importo raddoppiato (genitore solo)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Dettaglio per figlio ──
  Widget _buildDettaglioFigliCard() {
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
                  Icon(Icons.people, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dettaglio per figlio',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._dettagliFigli.map((d) => _buildFiglioRow(d)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiglioRow(_DettaglioFiglio d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        '${d.numero}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Figlio ${d.numero} (${d.fascia})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Text(
                '\u20AC${d.totaleFiglio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _miniRow('Importo base', '\u20AC${d.importoBase.toStringAsFixed(2)}'),
          if (d.maggiorazioneEta > 0) ...[
            _miniRow(
              d.notaMaggiorazione ?? 'Maggiorazione eta',
              '+\u20AC${d.maggiorazioneEta.toStringAsFixed(2)}',
              isGreen: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isGreen ? const Color(0xFF4CAF50) : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Maggiorazioni card ──
  Widget _buildMaggiorazioniCard() {
    final hasAnyMaggiorazione = _figliDisabili > 0 ||
        _entrambiLavorano ||
        _numFigli >= 3 ||
        _genitoreSolo;

    if (!hasAnyMaggiorazione) return const SizedBox.shrink();

    double maggiorazioneDisab = 0;
    String tipoDisabLabel = '';
    if (_figliDisabili > 0) {
      switch (_tipoDisabilita) {
        case 'non_autosufficiente':
          maggiorazioneDisab =
              _maggiorazioneDisabileNonAuto * _figliDisabili.toDouble();
          tipoDisabLabel = 'non autosufficiente';
          break;
        case 'grave':
          maggiorazioneDisab =
              _maggiorazioneDisabileGrave * _figliDisabili.toDouble();
          tipoDisabLabel = 'grave';
          break;
        default:
          maggiorazioneDisab =
              _maggiorazioneDisabileMedio * _figliDisabili.toDouble();
          tipoDisabLabel = 'medio';
      }
    }

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
                  Icon(Icons.add_circle_outline,
                      color: Color(0xFF4CAF50), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Maggiorazioni applicate',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_figliDisabili > 0)
                _buildMaggiorazioneRow(
                  Icons.accessible,
                  'Disabilita ($tipoDisabLabel) x $_figliDisabili',
                  maggiorazioneDisab,
                ),
              if (_entrambiLavorano)
                _buildMaggiorazioneRow(
                  Icons.work,
                  'Entrambi genitori lavorano',
                  _maggiorazioneLavoro,
                ),
              if (_numFigli >= 3)
                _buildMaggiorazioneRow(
                  Icons.family_restroom,
                  'Nucleo con 3+ figli',
                  _maggiorazione3Figli,
                ),
              if (_genitoreSolo)
                _buildMaggiorazioneRow(
                  Icons.person,
                  'Genitore solo (importo raddoppiato)',
                  _totaleMensile / 2,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaggiorazioneRow(
      IconData icon, String label, double importo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            '+\u20AC${importo.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4CAF50),
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
                    'Come fare domanda',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStep('1', 'Presenta ISEE aggiornato',
                  'Tramite CAF o DSU precompilata su INPS'),
              _buildStep('2', 'Accedi a myINPS',
                  'Con SPID o CIE, sezione "Assegno Unico"'),
              _buildStep('3', 'Compila la domanda online',
                  'Inserisci dati figli e nucleo familiare'),
              _buildStep('4', 'Pagamento mensile',
                  'L\'INPS eroga l\'assegno ogni mese sul conto indicato'),
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
          width: 40,
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

  Widget _buildSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
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
}

// ── Helper data class ──
class _DettaglioFiglio {
  final int numero;
  final String fascia;
  final double importoBase;
  final double maggiorazioneEta;
  final String? notaMaggiorazione;
  final double totaleFiglio;

  const _DettaglioFiglio({
    required this.numero,
    required this.fascia,
    required this.importoBase,
    required this.maggiorazioneEta,
    this.notaMaggiorazione,
    required this.totaleFiglio,
  });
}
