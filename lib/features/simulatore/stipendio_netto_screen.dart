import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';

class StipendioNettoScreen extends StatefulWidget {
  const StipendioNettoScreen({super.key});

  @override
  State<StipendioNettoScreen> createState() => _StipendioNettoScreenState();
}

class _StipendioNettoScreenState extends State<StipendioNettoScreen>
    with SingleTickerProviderStateMixin {
  // -- Input fields --
  final _ralCtrl = TextEditingController();
  String _tipoContratto = 'dipendente'; // dipendente, apprendista, cococo
  String _settore = 'Commercio';
  String _regione = 'Lazio';
  int _figliACarico = 0;
  bool _coniugeACarico = false;

  // -- Result --
  bool _showResult = false;
  double _ral = 0;
  double _contributiInps = 0;
  double _imponibileIrpef = 0;
  double _irpefLorda = 0;
  double _detrazioniLavoro = 0;
  double _detrazioniFigli = 0;
  double _detrazioneConiuge = 0;
  double _detrazioniTotali = 0;
  double _irpefNetta = 0;
  double _addizionaleRegionale = 0;
  double _addizionaleComunale = 0;
  double _nettoAnnuo = 0;
  double _nettoMensile12 = 0;
  double _nettoMensile13 = 0;
  double _nettoMensile14 = 0;
  double _aliquotaInps = 0;
  List<_ScaglioneDetail> _scaglioni = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');

  static const _settori = ['Commercio', 'Industria', 'Artigianato', 'Pubblico'];

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
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
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

  // -----------------------------------------------
  // CALCOLO STIPENDIO NETTO (busta paga italiana 2025)
  // -----------------------------------------------
  void _calcola() {
    _ral = _p(_ralCtrl.text);
    if (_ral <= 0) return;

    // 1. Contributi INPS a carico del lavoratore
    switch (_tipoContratto) {
      case 'apprendista':
        _aliquotaInps = 5.84;
        break;
      case 'cococo':
        // Co.Co.Co: aliquota 1/3 del 33.72% (quota lavoratore)
        _aliquotaInps = 11.24;
        break;
      default:
        // Dipendente: 9.19% standard
        // con riduzione per RAL fino a 35.000 (esonero 2024-2025 prorogato)
        if (_ral <= 25000) {
          _aliquotaInps = 2.19; // 9.19% - 7% esonero
        } else if (_ral <= 35000) {
          _aliquotaInps = 3.19; // 9.19% - 6% esonero
        } else {
          _aliquotaInps = 9.19;
        }
    }
    _contributiInps = _ral * (_aliquotaInps / 100);

    // 2. Imponibile IRPEF
    _imponibileIrpef = (_ral - _contributiInps).clamp(0.0, double.infinity);

    // 3. IRPEF Lorda (scaglioni 2025)
    _scaglioni = [];
    double imposta = 0;
    double residuo = _imponibileIrpef;

    if (residuo > 0) {
      final double base1 = residuo.clamp(0.0, 28000.0).toDouble();
      final tax1 = base1 * 0.23;
      imposta += tax1;
      residuo -= base1;
      _scaglioni.add(_ScaglioneDetail('Fino a \u20AC28.000', '23%', base1, tax1));
    }
    if (residuo > 0) {
      final double base2 = residuo.clamp(0.0, 22000.0).toDouble();
      final tax2 = base2 * 0.35;
      imposta += tax2;
      residuo -= base2;
      _scaglioni.add(_ScaglioneDetail('\u20AC28.001 - \u20AC50.000', '35%', base2, tax2));
    }
    if (residuo > 0) {
      final tax3 = residuo * 0.43;
      imposta += tax3;
      _scaglioni.add(_ScaglioneDetail('Oltre \u20AC50.000', '43%', residuo, tax3));
    }

    _irpefLorda = imposta;

    // 4. Detrazioni lavoro dipendente (formula reale 2025)
    if (_tipoContratto == 'cococo') {
      // Co.Co.Co assimilati ai dipendenti per detrazioni
      _detrazioniLavoro = _detrazioneLavoroDipendente(_imponibileIrpef);
    } else {
      _detrazioniLavoro = _detrazioneLavoroDipendente(_imponibileIrpef);
    }

    // 5. Detrazioni figli a carico (>21 anni)
    _detrazioniFigli = 0;
    if (_figliACarico > 0) {
      _detrazioniFigli = _calcolaDetrazioneFigli(_imponibileIrpef, _figliACarico);
    }

    // 6. Detrazione coniuge a carico
    _detrazioneConiuge = 0;
    if (_coniugeACarico) {
      _detrazioneConiuge = _calcolaDetrazioneConiuge(_imponibileIrpef);
    }

    _detrazioniTotali = _detrazioniLavoro + _detrazioniFigli + _detrazioneConiuge;

    // 5. IRPEF Netta
    _irpefNetta = (_irpefLorda - _detrazioniTotali).clamp(0.0, double.infinity);

    // 6. Addizionale regionale
    _addizionaleRegionale = _calcolaAddizionaleRegionale(_imponibileIrpef, _regione);

    // 7. Addizionale comunale (media 0.8%)
    _addizionaleComunale = _imponibileIrpef * 0.008;

    // 8. Netto annuo
    _nettoAnnuo = _ral - _contributiInps - _irpefNetta - _addizionaleRegionale - _addizionaleComunale;
    _nettoAnnuo = _nettoAnnuo.clamp(0.0, double.infinity);

    // 9. Netto mensile
    _nettoMensile12 = _nettoAnnuo / 12;
    _nettoMensile13 = _nettoAnnuo / 13;
    _nettoMensile14 = _nettoAnnuo / 14;

    setState(() => _showResult = true);
    _animController.forward(from: 0);
  }

  // -- Detrazione lavoro dipendente (2025) --
  double _detrazioneLavoroDipendente(double reddito) {
    if (reddito <= 15000) {
      return 1955.0;
    } else if (reddito <= 28000) {
      return 1910.0 + 1190.0 * ((28000 - reddito) / 13000);
    } else if (reddito <= 50000) {
      return 1910.0 * ((50000 - reddito) / 22000);
    }
    return 0;
  }

  // -- Detrazione figli a carico (>21 anni, 950 per figlio) --
  double _calcolaDetrazioneFigli(double reddito, int figli) {
    if (reddito > 95000) return 0;
    final base = 950.0 * figli;
    return base * ((95000 - reddito) / 95000);
  }

  // -- Detrazione coniuge a carico --
  double _calcolaDetrazioneConiuge(double reddito) {
    if (reddito <= 15000) {
      return 800.0 - 110.0 * (reddito / 15000);
    } else if (reddito <= 29000) {
      return 690.0;
    } else if (reddito <= 29200) {
      return 700.0;
    } else if (reddito <= 34700) {
      return 710.0;
    } else if (reddito <= 35000) {
      return 720.0;
    } else if (reddito <= 35100) {
      return 710.0;
    } else if (reddito <= 35200) {
      return 700.0;
    } else if (reddito <= 40000) {
      return 690.0;
    } else if (reddito <= 80000) {
      return 690.0 * ((80000 - reddito) / 40000);
    }
    return 0;
  }

  // -- Addizionale regionale (aliquote medie 2025) --
  double _calcolaAddizionaleRegionale(double imponibile, String regione) {
    final aliquote = <String, double>{
      'Abruzzo': 0.0173, 'Basilicata': 0.0123, 'Calabria': 0.0203,
      'Campania': 0.0203, 'Emilia-Romagna': 0.0173, 'Friuli Venezia Giulia': 0.0123,
      'Lazio': 0.0173, 'Liguria': 0.0173, 'Lombardia': 0.0173,
      'Marche': 0.0173, 'Molise': 0.0203, 'Piemonte': 0.0173,
      'Puglia': 0.0173, 'Sardegna': 0.0173, 'Sicilia': 0.0173,
      'Toscana': 0.0162, 'Trentino-Alto Adige': 0.0123, 'Umbria': 0.0173,
      "Valle d'Aosta": 0.0123, 'Veneto': 0.0173,
    };
    final aliquota = aliquote[regione] ?? 0.0173;
    return imponibile * aliquota;
  }

  // -----------------------------------------------
  // BUILD
  // -----------------------------------------------
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
            SliverToBoxAdapter(child: _sectionTitle('RAL - Reddito Annuo Lordo')),
            SliverToBoxAdapter(child: _buildRalSection()),
            SliverToBoxAdapter(child: _sectionTitle('Tipo Contratto')),
            SliverToBoxAdapter(child: _buildTipoContratto()),
            SliverToBoxAdapter(child: _sectionTitle('Settore')),
            SliverToBoxAdapter(child: _buildSettoreSection()),
            SliverToBoxAdapter(child: _sectionTitle('Regione di Residenza')),
            SliverToBoxAdapter(child: _buildRegioneSection()),
            SliverToBoxAdapter(child: _sectionTitle('Carichi Familiari')),
            SliverToBoxAdapter(child: _buildCarichiFamiliari()),
            SliverToBoxAdapter(child: _buildCalcolaButton()),
            if (_showResult) ...[
              SliverToBoxAdapter(child: _buildNettoResultCard()),
              SliverToBoxAdapter(child: _buildSplitBarsCard()),
              SliverToBoxAdapter(child: _buildScaglioniCard()),
              SliverToBoxAdapter(child: _buildDettaglioCard()),
              SliverToBoxAdapter(child: _buildMensileCard()),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // -- Header --
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
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
            child: const Icon(Icons.payments, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STIPENDIO NETTO', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Da lordo a netto - Busta paga 2025', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Info banner --
  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFFA000), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: Color(0xFF5D4037), height: 1.4),
                children: [
                  TextSpan(text: 'Calcolo indicativo. ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: 'Include esonero contributivo 2025 per RAL fino a \u20AC35.000. Per il cedolino ufficiale rivolgiti al consulente del lavoro.'),
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
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    );
  }

  // -- RAL input --
  Widget _buildRalSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inserisci la tua Retribuzione Annua Lorda (RAL) prevista dal contratto',
              style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3)),
          const SizedBox(height: 12),
          _moneyField(_ralCtrl, 'RAL - Reddito Annuo Lordo'),
        ],
      ),
    );
  }

  // -- Tipo contratto --
  Widget _buildTipoContratto() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Row(
        children: [
          _tipoChip('dipendente', 'Dipendente', Icons.work),
          const SizedBox(width: 8),
          _tipoChip('apprendista', 'Apprendista', Icons.school),
          const SizedBox(width: 8),
          _tipoChip('cococo', 'Co.Co.Co', Icons.handshake),
        ],
      ),
    );
  }

  Widget _tipoChip(String value, String label, IconData icon) {
    final selected = _tipoContratto == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipoContratto = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.textLight),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textMedium)),
            ],
          ),
        ),
      ),
    );
  }

  // -- Settore --
  Widget _buildSettoreSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _settori.map((s) {
          final selected = _settore == s;
          final IconData icon;
          switch (s) {
            case 'Commercio':
              icon = Icons.storefront;
              break;
            case 'Industria':
              icon = Icons.factory;
              break;
            case 'Artigianato':
              icon = Icons.construction;
              break;
            case 'Pubblico':
              icon = Icons.account_balance;
              break;
            default:
              icon = Icons.business;
          }
          return GestureDetector(
            onTap: () => setState(() => _settore = s),
            child: Container(
              width: (MediaQuery.of(context).size.width - 72) / 2,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textLight),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textMedium)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // -- Regione --
  Widget _buildRegioneSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: DropdownButtonFormField<String>(
        initialValue: _regione,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Regione (per addizionale regionale)',
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMedium),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: _regioni.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: (v) => setState(() => _regione = v ?? 'Lazio'),
      ),
    );
  }

  // -- Carichi familiari --
  Widget _buildCarichiFamiliari() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        children: [
          _buildCounter('Figli a carico (>21 anni)', _figliACarico, 0, 10, (v) => setState(() => _figliACarico = v)),
          const Divider(height: 20),
          _buildSwitch('Coniuge a carico', _coniugeACarico, (v) => setState(() => _coniugeACarico = v)),
        ],
      ),
    );
  }

  // -- Calcola button --
  Widget _buildCalcolaButton() {
    return GestureDetector(
      onTap: _calcola,
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
            Icon(Icons.payments, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('CALCOLA NETTO', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  // -- Green netto result card --
  Widget _buildNettoResultCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 28),
            const SizedBox(height: 6),
            const Text('NETTO MENSILE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('\u20AC ${_fmt.format(_nettoMensile13)}', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('su 13 mensilit\u00E0', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _nettoMiniCol('x12', _nettoMensile12),
                  Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                  _nettoMiniCol('x13', _nettoMensile13),
                  Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                  _nettoMiniCol('x14', _nettoMensile14),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('Netto annuo: \u20AC ${_fmt.format(_nettoAnnuo)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _nettoMiniCol(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('\u20AC ${_fmt.format(value)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // -- Split bars (visual pie-chart like) --
  Widget _buildSplitBarsCard() {
    final totaleTrattenute = _contributiInps + _irpefNetta + _addizionaleRegionale + _addizionaleComunale;
    if (_ral <= 0) return const SizedBox.shrink();

    final percNetto = (_nettoAnnuo / _ral * 100).clamp(0.0, 100.0);
    final percInps = (_contributiInps / _ral * 100).clamp(0.0, 100.0);
    final percIrpef = (_irpefNetta / _ral * 100).clamp(0.0, 100.0);
    final percAddiz = ((_addizionaleRegionale + _addizionaleComunale) / _ral * 100).clamp(0.0, 100.0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Composizione RAL', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('Totale trattenute: \u20AC ${_fmt.format(totaleTrattenute)} (${(totaleTrattenute / _ral * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 16),
            // Stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Flexible(
                      flex: (percNetto * 10).round().clamp(1, 1000),
                      child: Container(color: const Color(0xFF4CAF50)),
                    ),
                    Flexible(
                      flex: (percInps * 10).round().clamp(1, 1000),
                      child: Container(color: const Color(0xFFFF9800)),
                    ),
                    Flexible(
                      flex: (percIrpef * 10).round().clamp(1, 1000),
                      child: Container(color: const Color(0xFFF44336)),
                    ),
                    Flexible(
                      flex: (percAddiz * 10).round().clamp(1, 1000),
                      child: Container(color: const Color(0xFF9C27B0)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _legendRow(const Color(0xFF4CAF50), 'Netto in tasca', percNetto, _nettoAnnuo),
            const SizedBox(height: 8),
            _legendRow(const Color(0xFFFF9800), 'Contributi INPS (${_aliquotaInps.toStringAsFixed(2)}%)', percInps, _contributiInps),
            const SizedBox(height: 8),
            _legendRow(const Color(0xFFF44336), 'IRPEF netta', percIrpef, _irpefNetta),
            const SizedBox(height: 8),
            _legendRow(const Color(0xFF9C27B0), 'Addizionali reg. + com.', percAddiz, _addizionaleRegionale + _addizionaleComunale),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, double perc, double amount) {
    return Row(
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        ),
        Text('${perc.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMedium)),
        const SizedBox(width: 8),
        Text('\u20AC ${_fmt.format(amount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ],
    );
  }

  // -- Scaglioni IRPEF card --
  Widget _buildScaglioniCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scaglioni IRPEF 2025', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            ..._scaglioni.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(s.aliquota, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.fascia, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        Text('Imponibile: \u20AC ${_fmt.format(s.imponibile)}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                  Text('\u20AC ${_fmt.format(s.imposta)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IRPEF Lorda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                Text('\u20AC ${_fmt.format(_irpefLorda)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -- Dettaglio calcolo step-by-step --
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
            const Text('Dettaglio Calcolo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            _row('1. RAL (lordo annuo)', '\u20AC ${_fmt.format(_ral)}', bold: true),
            const SizedBox(height: 4),
            _row('2. Contributi INPS (${_aliquotaInps.toStringAsFixed(2)}%)', '- \u20AC ${_fmt.format(_contributiInps)}', color: const Color(0xFFFF9800)),
            _row('3. Imponibile IRPEF', '\u20AC ${_fmt.format(_imponibileIrpef)}'),
            const Divider(height: 16),
            _row('4. IRPEF Lorda', '\u20AC ${_fmt.format(_irpefLorda)}'),
            if (_detrazioniLavoro > 0)
              _row('   Detraz. lavoro dipendente', '- \u20AC ${_fmt.format(_detrazioniLavoro)}', color: const Color(0xFF4CAF50)),
            if (_detrazioniFigli > 0)
              _row('   Detraz. figli a carico', '- \u20AC ${_fmt.format(_detrazioniFigli)}', color: const Color(0xFF4CAF50)),
            if (_detrazioneConiuge > 0)
              _row('   Detraz. coniuge a carico', '- \u20AC ${_fmt.format(_detrazioneConiuge)}', color: const Color(0xFF4CAF50)),
            _row('   Detrazioni totali', '- \u20AC ${_fmt.format(_detrazioniTotali)}', color: const Color(0xFF4CAF50)),
            _row('5. IRPEF Netta', '\u20AC ${_fmt.format(_irpefNetta)}', bold: true),
            const Divider(height: 16),
            _row('6. Addizionale regionale ($_regione)', '- \u20AC ${_fmt.format(_addizionaleRegionale)}'),
            _row('7. Addizionale comunale (0,8%)', '- \u20AC ${_fmt.format(_addizionaleComunale)}'),
            const Divider(height: 16),
            _row('NETTO ANNUO', '\u20AC ${_fmt.format(_nettoAnnuo)}', bold: true, color: const Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }

  // -- Mensile breakdown card --
  Widget _buildMensileCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Text('NETTO MENSILE PER MENSILITA\'', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.3)),
            const SizedBox(height: 16),
            Row(
              children: [
                _mensileBox('12 mensilit\u00E0', _nettoMensile12, 'Senza tredicesima'),
                const SizedBox(width: 10),
                _mensileBox('13 mensilit\u00E0', _nettoMensile13, 'Standard'),
                const SizedBox(width: 10),
                _mensileBox('14 mensilit\u00E0', _nettoMensile14, 'Commercio/CCNL'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF7B1FA2), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _settore == 'Commercio'
                          ? 'Il CCNL Commercio prevede 14 mensilit\u00E0.'
                          : _settore == 'Pubblico'
                              ? 'Il settore pubblico prevede 13 mensilit\u00E0.'
                              : 'Le mensilit\u00E0 dipendono dal CCNL applicato. Verifica il tuo contratto.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF4A148C), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mensileBox(String label, double value, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('\u20AC ${_fmt.format(value)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
            ),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 9, color: AppColors.textLight), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------
  // REUSABLE WIDGETS
  // -----------------------------------------------
  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 3))],
    );
  }

  Widget _moneyField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        prefixText: '\u20AC  ',
        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildCounter(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark))),
        _cBtn(Icons.remove, value > min, () => onChanged(value - 1)),
        Container(width: 40, alignment: Alignment.center, child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark))),
        _cBtn(Icons.add, value < max, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _cBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: enabled ? AppColors.primary : Colors.grey.shade400),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
        Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: AppColors.primary),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: bold ? AppColors.textDark : AppColors.textMedium, fontWeight: bold ? FontWeight.w600 : FontWeight.w400))),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? (bold ? AppColors.primary : AppColors.textDark))),
        ],
      ),
    );
  }
}

class _ScaglioneDetail {
  final String fascia;
  final String aliquota;
  final double imponibile;
  final double imposta;
  const _ScaglioneDetail(this.fascia, this.aliquota, this.imponibile, this.imposta);
}
