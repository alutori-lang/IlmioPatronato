import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../core/services/language_service.dart';
import 'busta_paga_translations.dart';

// ---------------------------------------------------------------------------
// BUSTA PAGA SPIEGATA - Multi-language educational payslip viewer
// ---------------------------------------------------------------------------

class BustaPagaScreen extends StatefulWidget {
  const BustaPagaScreen({super.key});

  @override
  State<BustaPagaScreen> createState() => _BustaPagaScreenState();
}

class _BustaPagaScreenState extends State<BustaPagaScreen> {
  final Set<String> _expanded = {};

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>().currentCode;
    final t = getBustaTranslation(lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, t)),
          SliverToBoxAdapter(child: _buildInfoBanner(t)),
          SliverToBoxAdapter(child: _buildBustaPagaTitle(t)),

          SliverToBoxAdapter(child: _sectionHeader(t.sectionHeader, Icons.badge, const Color(0xFF5C6BC0))),
          SliverToBoxAdapter(child: _buildSection(_intestazioneIds, t)),

          SliverToBoxAdapter(child: _sectionHeader(t.sectionEarnings, Icons.trending_up, const Color(0xFF43A047))),
          SliverToBoxAdapter(child: _buildSection(_competenzeIds, t)),

          SliverToBoxAdapter(child: _sectionHeader(t.sectionDeductions, Icons.trending_down, const Color(0xFFE53935))),
          SliverToBoxAdapter(child: _buildSection(_trattenutIds, t)),

          SliverToBoxAdapter(child: _sectionHeader(t.sectionNet, Icons.account_balance_wallet, const Color(0xFF1565C0))),
          SliverToBoxAdapter(child: _buildSection(_nettoIds, t)),

          SliverToBoxAdapter(child: _buildFooterTip(t)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, BustaT t) {
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
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 1),
                Text(t.subtitle, style: const TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(BustaT t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.school, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A237E), height: 1.4),
                children: [
                  TextSpan(text: '${t.infoBold} ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: t.infoText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBustaPagaTitle(BustaT t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D2D5E), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Row(children: [
            Icon(Icons.business, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text('AZIENDA ESEMPIO S.R.L.', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.employee, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  const Text('Mario Rossi', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('CCNL Commercio', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text('4\u00b0 Livello', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(List<_BustaItemData> items, BustaT t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final translated = t.items[item.id];
          final voce = translated?.voce ?? item.id;
          final spiegazione = translated?.spiegazione ?? '';
          final isExp = _expanded.contains(item.id);
          final isLast = idx == items.length - 1;

          return Column(children: [
            InkWell(
              onTap: () => _toggle(item.id),
              borderRadius: BorderRadius.vertical(
                top: idx == 0 ? const Radius.circular(16) : Radius.zero,
                bottom: isLast && !isExp ? const Radius.circular(16) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Expanded(child: Row(children: [
                    Icon(isExp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: AppColors.textLight),
                    const SizedBox(width: 8),
                    Expanded(child: Text(voce, style: TextStyle(fontSize: 13, fontWeight: isExp ? FontWeight.w700 : FontWeight.w500, color: isExp ? AppColors.primary : AppColors.textDark))),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: item.isNeg ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: Text(item.importo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: item.isNeg ? const Color(0xFFE53935) : const Color(0xFF2E7D32))),
                  ),
                ]),
              ),
            ),
            if (isExp)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(t.explanationLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 8),
                  Text(spiegazione, style: const TextStyle(fontSize: 13, color: Color(0xFF1A237E), height: 1.5)),
                ]),
              ),
            if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildFooterTip(BustaT t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.tips_and_updates, color: Color(0xFFFFA000), size: 20),
          const SizedBox(width: 8),
          Text(t.tipTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF5D4037))),
        ]),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037), height: 1.5),
            children: [
              TextSpan(text: '${t.tipBold} ', style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: t.tipText),
            ],
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  // DATA - item IDs with amounts (amounts are universal, not translated)
  // ─────────────────────────────────────────────

  static const _intestazioneIds = [
    _BustaItemData('periodo', 'Gen 2025', false),
    _BustaItemData('livello', '4\u00b0 Liv.', false),
    _BustaItemData('ore', '168 ore', false),
  ];

  static const _competenzeIds = [
    _BustaItemData('paga_base', '\u20ac 1.618,75', false),
    _BustaItemData('contingenza', '\u20ac 524,22', false),
    _BustaItemData('superminimo', '\u20ac 150,00', false),
    _BustaItemData('straordinario', '\u20ac 87,50', false),
    _BustaItemData('scatti', '\u20ac 25,46', false),
    _BustaItemData('tredicesima', '\u20ac 194,95', false),
    _BustaItemData('quattordicesima', '\u20ac 194,95', false),
  ];

  static const _trattenutIds = [
    _BustaItemData('inps', '- \u20ac 214,99', true),
    _BustaItemData('irpef', '- \u20ac 356,00', true),
    _BustaItemData('addizionale_reg', '- \u20ac 35,00', true),
    _BustaItemData('addizionale_com', '- \u20ac 15,00', true),
    _BustaItemData('detrazioni', '+ \u20ac 155,00', false),
  ];

  static const _nettoIds = [
    _BustaItemData('netto', '\u20ac 1.680,38', false),
    _BustaItemData('tfr', '\u20ac 173,29', false),
  ];
}

class _BustaItemData {
  final String id;
  final String importo;
  final bool isNeg;
  const _BustaItemData(this.id, this.importo, this.isNeg);
}
