import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';

class ImuScreen extends StatefulWidget {
  const ImuScreen({super.key});

  @override
  State<ImuScreen> createState() => _ImuScreenState();
}

class _ImuScreenState extends State<ImuScreen> with SingleTickerProviderStateMixin {
  // ── Tipo immobile ──
  String _tipoImmobile = 'seconda_casa'; // seconda_casa, pertinenza, terreno, commerciale

  // ── Dati catastali ──
  final _renditaCtrl = TextEditingController();
  String _categoriaSelected = 'A/2'; // Categoria catastale

  // ── Quota possesso ──
  double _quotaPossesso = 100;
  int _mesiPossesso = 12;

  // ── Aliquota ──
  final _aliquotaCtrl = TextEditingController(text: '10.6');

  // ── Risultato ──
  bool _showResult = false;
  double _baseImponibile = 0;
  double _imuAnnuale = 0;
  double _imuDovuta = 0;
  double _acconto = 0;
  double _saldo = 0;
  double _coefficiente = 0;
  double _rivalutazione = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final _fmt = NumberFormat('#,##0.00', 'it_IT');

  static const _categorie = {
    'A/1': 'Abitazione signorile',
    'A/2': 'Abitazione civile',
    'A/3': 'Abitazione economica',
    'A/4': 'Abitazione popolare',
    'A/5': 'Abitazione ultrapopolare',
    'A/6': 'Abitazione rurale',
    'A/7': 'Abitazione villini',
    'A/8': 'Abitazione in ville',
    'A/9': 'Castelli/palazzi',
    'A/10': 'Uffici/studi privati',
    'C/1': 'Negozio/bottega',
    'C/2': 'Magazzino/deposito',
    'C/3': 'Laboratorio',
    'C/6': 'Box/garage',
    'C/7': 'Tettoie chiuse',
    'D/1': 'Opificio',
    'D/2': 'Albergo/pensione',
    'D/5': 'Istituto di credito',
    'D/7': 'Fabbricato industriale',
    'D/8': 'Fabbricato commerciale',
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _renditaCtrl.dispose();
    _aliquotaCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  double _p(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  // ─────────────────────────────────────────────
  // CALCOLO IMU (formula ufficiale)
  // Base imponibile = Rendita × 1.05 (rivalutazione 5%) × coefficiente
  // IMU = Base imponibile × aliquota / 1000 × quota possesso × mesi / 12
  // ─────────────────────────────────────────────
  void _calcola() {
    final rendita = _p(_renditaCtrl.text);
    final aliquotaPermille = _p(_aliquotaCtrl.text);

    if (rendita <= 0) return;

    // Coefficiente moltiplicatore per categoria
    _coefficiente = _getCoefficient();
    _rivalutazione = rendita * 1.05;
    _baseImponibile = _rivalutazione * _coefficiente;

    _imuAnnuale = _baseImponibile * aliquotaPermille / 1000;
    _imuDovuta = _imuAnnuale * (_quotaPossesso / 100) * (_mesiPossesso / 12);

    _acconto = _imuDovuta / 2; // Scadenza 16 giugno
    _saldo = _imuDovuta - _acconto; // Scadenza 16 dicembre

    setState(() => _showResult = true);
    _animCtrl.forward(from: 0);
  }

  double _getCoefficient() {
    if (_categoriaSelected.startsWith('A/') && _categoriaSelected != 'A/10') {
      return 160;
    } else if (_categoriaSelected == 'A/10') {
      return 80;
    } else if (_categoriaSelected == 'C/1') {
      return 55;
    } else if (_categoriaSelected == 'C/2' || _categoriaSelected == 'C/6' || _categoriaSelected == 'C/7') {
      return 160;
    } else if (_categoriaSelected == 'C/3') {
      return 140;
    } else if (_categoriaSelected.startsWith('D/')) {
      return 65;
    }
    return 160;
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
            SliverToBoxAdapter(child: _buildInfoBanner()),
            SliverToBoxAdapter(child: _sectionTitle('Tipo Immobile')),
            SliverToBoxAdapter(child: _buildTipoImmobile()),
            SliverToBoxAdapter(child: _sectionTitle('Dati Catastali')),
            SliverToBoxAdapter(child: _buildDatiCatastali()),
            SliverToBoxAdapter(child: _sectionTitle('Possesso')),
            SliverToBoxAdapter(child: _buildPossesso()),
            SliverToBoxAdapter(child: _sectionTitle('Aliquota Comunale')),
            SliverToBoxAdapter(child: _buildAliquota()),
            SliverToBoxAdapter(child: _buildCalcolaButton()),
            if (_showResult) ...[
              SliverToBoxAdapter(child: _buildResultCard()),
              SliverToBoxAdapter(child: _buildDettaglioCard()),
              SliverToBoxAdapter(child: _buildScadenzeCard()),
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
            child: const Icon(Icons.home_work, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CALCOLATORE IMU', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Imposta Municipale Unica', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
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
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF388E3C), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'L\'abitazione principale (prima casa) con categorie A/2-A/7 è ESENTE da IMU. '
              'L\'IMU si paga su seconde case, negozi, uffici, terreni, etc.',
              style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    );
  }

  Widget _buildTipoImmobile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Column(
        children: [
          Row(
            children: [
              _chip('seconda_casa', 'Seconda Casa', Icons.home),
              const SizedBox(width: 8),
              _chip('pertinenza', 'Box/Garage', Icons.garage),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip('commerciale', 'Commerciale', Icons.store),
              const SizedBox(width: 8),
              _chip('terreno', 'Terreno', Icons.landscape),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label, IconData icon) {
    final sel = _tipoImmobile == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _tipoImmobile = value;
          if (value == 'seconda_casa') _categoriaSelected = 'A/2';
          if (value == 'pertinenza') _categoriaSelected = 'C/6';
          if (value == 'commerciale') _categoriaSelected = 'C/1';
          if (value == 'terreno') _categoriaSelected = 'D/1';
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade200, width: sel ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: sel ? AppColors.primary : AppColors.textLight),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? AppColors.primary : AppColors.textMedium)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatiCatastali() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('La rendita catastale si trova nella visura catastale o nell\'atto di compravendita',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3)),
          const SizedBox(height: 12),
          _moneyField(_renditaCtrl, 'Rendita catastale'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categoriaSelected,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Categoria catastale',
              labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMedium),
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _categorie.entries.map((e) => DropdownMenuItem(
              value: e.key,
              child: Text('${e.key} - ${e.value}', style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) => setState(() => _categoriaSelected = v ?? 'A/2'),
          ),
        ],
      ),
    );
  }

  Widget _buildPossesso() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('Quota possesso', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark))),
              Text('${_quotaPossesso.toInt()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          Slider(
            value: _quotaPossesso, min: 10, max: 100, divisions: 9,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _quotaPossesso = v),
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Expanded(child: Text('Mesi di possesso', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark))),
              _cBtn(Icons.remove, _mesiPossesso > 1, () => setState(() => _mesiPossesso--)),
              Container(width: 40, alignment: Alignment.center, child: Text('$_mesiPossesso', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark))),
              _cBtn(Icons.add, _mesiPossesso < 12, () => setState(() => _mesiPossesso++)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAliquota() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aliquota del tuo Comune (per mille). L\'aliquota base è 8.6‰, la massima 10.6‰.',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3)),
          const SizedBox(height: 12),
          TextField(
            controller: _aliquotaCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
            decoration: InputDecoration(
              labelText: 'Aliquota (‰)',
              labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMedium),
              suffixText: '‰',
              suffixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMedium),
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

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
            Icon(Icons.home_work, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('CALCOLA IMU', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('IMU DOVUTA', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('€ ${_fmt.format(_imuDovuta)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(
                'Categoria $_categoriaSelected · Coefficiente ${_coefficiente.toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            const Text('Formula di Calcolo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            _row('Rendita catastale', '€ ${_fmt.format(_p(_renditaCtrl.text))}'),
            _row('Rivalutazione (+5%)', '€ ${_fmt.format(_rivalutazione)}'),
            _row('× Coefficiente', '${_coefficiente.toInt()}'),
            const Divider(height: 16),
            _row('= Base imponibile', '€ ${_fmt.format(_baseImponibile)}', bold: true),
            _row('× Aliquota', '${_aliquotaCtrl.text}‰'),
            _row('= IMU annuale', '€ ${_fmt.format(_imuAnnuale)}'),
            const Divider(height: 16),
            _row('Quota possesso', '${_quotaPossesso.toInt()}%'),
            _row('Mesi possesso', '$_mesiPossesso / 12'),
            const Divider(height: 16),
            _row('IMU DOVUTA', '€ ${_fmt.format(_imuDovuta)}', bold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildScadenzeCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFFFF9800).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event, color: Color(0xFFFF9800), size: 22),
                SizedBox(width: 10),
                Text('Scadenze Pagamento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 16),
            _scadenzaRow('ACCONTO', '16 Giugno 2026', _acconto, const Color(0xFFFF9800)),
            const SizedBox(height: 12),
            _scadenzaRow('SALDO', '16 Dicembre 2026', _saldo, const Color(0xFFF44336)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Pagamento tramite modello F24 con codice tributo 3918 (seconde case). '
                'Codice catastale del Comune reperibile sul sito dell\'Agenzia delle Entrate.',
                style: TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scadenzaRow(String tipo, String data, double importo, Color color) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.calendar_today, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tipo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
              Text(data, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
            ],
          ),
        ),
        Text('€ ${_fmt.format(importo)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ],
    );
  }

  // ── Widgets riutilizzabili ──
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
        prefixText: '€  ',
        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
        filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
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

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: bold ? AppColors.textDark : AppColors.textMedium, fontWeight: bold ? FontWeight.w600 : FontWeight.w400))),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? AppColors.primary : AppColors.textDark)),
        ],
      ),
    );
  }
}
