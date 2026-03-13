import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../models/guida.dart';

class GuideDetailScreen extends StatefulWidget {
  final Guida guida;
  const GuideDetailScreen({super.key, required this.guida});

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final g = widget.guida;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, g)),
          SliverToBoxAdapter(child: _buildInfoCards(g)),
          SliverToBoxAdapter(child: _title('Documenti Necessari')),
          SliverToBoxAdapter(child: _buildDocuments(g)),
          SliverToBoxAdapter(child: _title('Procedura Step by Step')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildStep(g.steps[i], i), childCount: g.steps.length,
            )),
          ),
          if (g.linkUtili.isNotEmpty) ...[
            SliverToBoxAdapter(child: _title('Link Utili')),
            SliverToBoxAdapter(child: _buildLinks(g)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Guida g) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 20, bottom: 20),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(g.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(g.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(g.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 6),
        Text(g.shortDescription, style: const TextStyle(color: AppColors.bannerText, fontSize: 13)),
      ]),
    );
  }

  Widget _buildInfoCards(Guida g) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(child: _InfoCard(icon: Icons.schedule, label: 'Tempi', value: g.tempiStimati, color: AppColors.iconBlue)),
        const SizedBox(width: 12),
        Expanded(child: _InfoCard(icon: Icons.euro, label: 'Costo', value: g.costoStimato, color: AppColors.iconGreen)),
      ]),
    );
  }

  Widget _title(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
    child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
  );

  Widget _buildDocuments(Guida g) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
        ),
        child: Column(
          children: g.documenti.asMap().entries.map((e) {
            final doc = e.value;
            final isLast = e.key == g.documenti.length - 1;
            return Column(children: [
              InkWell(
                onTap: () => setState(() => doc.isChecked = !doc.isChecked),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: doc.isChecked ? AppColors.badge : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: doc.isChecked ? AppColors.badge : const Color(0xFFDDDDDD), width: 2),
                      ),
                      child: doc.isChecked ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(doc.name, style: TextStyle(
                      fontSize: 13, color: doc.isChecked ? AppColors.textLight : AppColors.textDark,
                      decoration: doc.isChecked ? TextDecoration.lineThrough : null,
                    ))),
                  ]),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 52),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStep(GuidaStep step, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(step.description, style: const TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildLinks(Guida g) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: g.linkUtili.map((link) {
        return GestureDetector(
          onTap: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Row(children: [
              const Icon(Icons.link, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(link, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              const Icon(Icons.open_in_new, color: AppColors.navInactive, size: 16),
            ]),
          ),
        );
      }).toList()),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}
