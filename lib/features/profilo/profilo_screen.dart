import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../core/services/language_service.dart';
import 'info_app_screen.dart';
import 'scanner_doc_screen.dart';
import 'tracker_pratica_screen.dart';
import 'translator_screen.dart';

class ProfiloScreen extends StatelessWidget {
  const ProfiloScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildProfileCard()),
        SliverToBoxAdapter(child: _buildStatsRow()),
        SliverToBoxAdapter(child: _buildUpgradeBanner()),
        SliverToBoxAdapter(child: _sectionTitle('Strumenti')),
        SliverToBoxAdapter(child: _buildTools(context)),
        SliverToBoxAdapter(child: _sectionTitle('Impostazioni')),
        SliverToBoxAdapter(child: _buildSettings(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 14),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: const Row(children: [
        Icon(Icons.person_rounded, color: Colors.white, size: 24),
        SizedBox(width: 12),
        Text('Profilo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Utente', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          Text('utente@email.com', style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 6),
          Row(children: [
            _Badge(text: 'FREE', color: Colors.white, textColor: AppColors.primary),
            SizedBox(width: 8),
            _Badge(text: 'LV.1', color: AppColors.badge, textColor: Colors.white),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: const [
        Expanded(child: _StatCard(icon: Icons.menu_book, label: 'Guide lette', value: '3', color: AppColors.iconBlue)),
        SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.check_circle, label: 'Documenti', value: '7', color: AppColors.iconGreen)),
        SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.forum, label: 'Domande', value: '2', color: AppColors.iconOrange)),
      ]),
    );
  }

  Widget _buildUpgradeBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8F62)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Diventa PRO!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('AI Illimitato • Scanner DOC • Zero ADS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const Text('€4.99/m', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFF6B35))),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
    child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
  );

  Widget _buildTools(BuildContext context) {
    final tools = [
      _ToolData(Icons.document_scanner, 'Scanner DOC', AppColors.iconBlue, false),
      _ToolData(Icons.translate, 'Traduttore', AppColors.iconGreen, false),
      _ToolData(Icons.track_changes, 'Tracker Pratica', AppColors.iconOrange, false),
      _ToolData(Icons.calculate, 'Simulatore ISEE', AppColors.iconPurple, false),
      _ToolData(Icons.map, 'Mappa Uffici', AppColors.primary, false),
      _ToolData(Icons.notifications_active, 'Notifiche', AppColors.iconOrange, true),
      _ToolData(Icons.people, 'Community', AppColors.iconPurple, false),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9),
        itemCount: tools.length,
        itemBuilder: (_, i) {
          final t = tools[i];
          return GestureDetector(
            onTap: () {
              if (t.label == 'Scanner DOC') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerDocScreen()));
                return;
              }
              if (t.label == 'Traduttore') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslatorScreen()));
                return;
              }
              if (t.label == 'Tracker Pratica') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerPraticaScreen()));
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.isPro ? 'Funzione PRO - Coming Soon!' : 'Coming Soon!'), backgroundColor: t.color),
              );
            },
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: t.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(t.icon, color: t.color, size: 22),
                  ),
                  if (t.isPro) Positioned(top: -4, right: -8, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(4)),
                    child: const Text('PRO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                  )),
                ]),
                const SizedBox(height: 8),
                Text(t.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark), textAlign: TextAlign.center),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final langService = context.read<LanguageService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Scegli Lingua / Choose Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 4),
            const Text('Per contenuti educativi', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: supportedLanguages.length,
                itemBuilder: (ctx, i) {
                  final lang = supportedLanguages[i];
                  final isSelected = lang.code == langService.currentCode;
                  return ListTile(
                    leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(lang.name, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textDark)),
                    subtitle: Text(lang.nameEn, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22) : null,
                    onTap: () {
                      langService.setLanguage(lang.code);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final langService = context.watch<LanguageService>();
    final items = [
      _SettData(Icons.language, 'Lingua', '${langService.current.flag} ${langService.current.name}', AppColors.iconBlue),
      _SettData(Icons.dark_mode, 'Tema', 'Chiaro', AppColors.textDark),
      _SettData(Icons.notifications, 'Notifiche', 'Attive', AppColors.iconOrange),
      _SettData(Icons.info, 'Info App', 'v1.0.0', AppColors.iconGreen),
      _SettData(Icons.star, 'Valuta App', '', const Color(0xFFFFC107)),
      _SettData(Icons.share, 'Condividi', '', AppColors.iconPurple),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return GestureDetector(
          onTap: i == 0
              ? () => _showLanguagePicker(context)
              : i == 3
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoAppScreen()))
                  : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: s.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(s.icon, color: s.color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(s.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const Spacer(),
              if (s.value.isNotEmpty) Text(s.value, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.navInactive, size: 20),
            ]),
          ),
        );
      }).toList()),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _Badge({required this.text, required this.color, required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textLight), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _ToolData {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPro;
  const _ToolData(this.icon, this.label, this.color, this.isPro);
}

class _SettData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SettData(this.icon, this.label, this.value, this.color);
}
