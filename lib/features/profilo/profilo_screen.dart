import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../core/services/ad_service.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/services/language_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/localization/app_strings.dart';
import 'info_app_screen.dart';
import '../strumenti/cv_europass_screen.dart';
import '../strumenti/documento_wallet_screen.dart';
import 'notifiche_screen.dart';
import 'scanner_doc_screen.dart';
import 'tracker_pratica_screen.dart';
import 'translator_screen.dart';

class ProfiloScreen extends StatelessWidget {
  const ProfiloScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, s)),
        SliverToBoxAdapter(child: _buildProfileCard(s)),
        SliverToBoxAdapter(child: _buildStatsRow(s)),
        SliverToBoxAdapter(child: _sectionTitle(context, s.toolsTitleAlt)),
        SliverToBoxAdapter(child: _buildTools(context, s)),
        SliverToBoxAdapter(child: _sectionTitle(context, s.settingsSectionTitle)),
        SliverToBoxAdapter(child: _buildSettings(context, s)),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: BannerAdWidget())),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings s) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 14),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(children: [
        const Icon(Icons.person_rounded, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Text(s.profileTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildProfileCard(AppStrings s) {
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
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.userDefaultName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const Text('utente@email.com', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            _Badge(text: s.planFree, color: Colors.white, textColor: AppColors.primary),
            const SizedBox(width: 8),
            _Badge(text: s.userLevel1, color: AppColors.badge, textColor: Colors.white),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildStatsRow(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(child: _StatCard(icon: Icons.menu_book, label: s.statsGuidesRead, value: '3', color: AppColors.iconBlue)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.check_circle, label: s.statsDocs, value: '7', color: AppColors.iconGreen)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.forum, label: s.statsQuestions, value: '2', color: AppColors.iconOrange)),
      ]),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
    child: Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
  );

  Widget _buildTools(BuildContext context, AppStrings s) {
    final tools = [
      _ToolData(Icons.document_scanner, s.toolScanner, AppColors.iconBlue, false, 'scanner'),
      _ToolData(Icons.translate, s.toolTranslator, AppColors.iconGreen, false, 'translator'),
      _ToolData(Icons.description, 'Curriculum Vitae', AppColors.iconPurple, false, 'cv'),
      _ToolData(Icons.track_changes, s.toolTracker, AppColors.iconOrange, false, 'tracker'),
      _ToolData(Icons.account_balance_wallet, s.toolWallet, AppColors.iconGreen, false, 'wallet'),
      _ToolData(Icons.notifications_active, s.toolNotifications, AppColors.iconOrange, false, 'notif'),
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
              if (t.id == 'scanner') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerDocScreen()));
                return;
              }
              if (t.id == 'translator') {
                AdService().showAdThenNavigate(() {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslatorScreen()));
                });
                return;
              }
              if (t.id == 'cv') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CvEuropassScreen()));
                return;
              }
              if (t.id == 'tracker') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerPraticaScreen()));
                return;
              }
              if (t.id == 'wallet') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentoWalletScreen()));
                return;
              }
              if (t.id == 'notif') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificheScreen()));
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.comingSoon), backgroundColor: t.color),
              );
            },
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14),
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
                Text(t.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.center),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final langService = context.read<LanguageService>();
    final s = AppStrings.forCode(langService.currentCode);
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
            Text(s.chooseLanguageBilingual, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(s.forEducationalContent, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
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

  void _showThemePicker(BuildContext context) {
    final themeSvc = context.read<ThemeService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        final txt = Theme.of(ctx).textTheme.bodyMedium?.color ?? AppColors.textDark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Tema / Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: txt)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.light_mode, color: Color(0xFFFFC107)),
                title: Text('Chiaro / Light', style: TextStyle(color: txt, fontWeight: themeSvc.mode == ThemeMode.light ? FontWeight.w800 : FontWeight.w500)),
                trailing: themeSvc.mode == ThemeMode.light ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  themeSvc.setMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode, color: Color(0xFF455A64)),
                title: Text('Scuro / Dark', style: TextStyle(color: txt, fontWeight: themeSvc.mode == ThemeMode.dark ? FontWeight.w800 : FontWeight.w500)),
                trailing: themeSvc.mode == ThemeMode.dark ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  themeSvc.setMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    const pkg = 'com.docflow.docflow_immigrati';
    final marketUri = Uri.parse('market://details?id=$pkg');
    final webUri = Uri.parse('https://play.google.com/store/apps/details?id=$pkg');
    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire Play Store')),
        );
      }
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    const pkg = 'com.docflow.docflow_immigrati';
    final url = 'https://play.google.com/store/apps/details?id=$pkg';
    final text = 'Scarica IlmioPatronato — Bonus, ISEE, NASpI, permessi e guide per immigrati.\n\n$url';
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      text,
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  Widget _buildSettings(BuildContext context, AppStrings s) {
    final langService = context.watch<LanguageService>();
    final themeService = context.watch<ThemeService>();
    final items = [
      _SettData(Icons.language, s.settingsLang, '${langService.current.flag} ${langService.current.name}', AppColors.iconBlue),
      _SettData(themeService.isDark ? Icons.dark_mode : Icons.light_mode, s.settingsTheme, themeService.isDark ? 'Dark' : 'Light', AppColors.textDark),
      _SettData(Icons.notifications, s.settingsNotifs, s.notifsActive, AppColors.iconOrange),
      _SettData(Icons.info, s.settingsAbout, 'v1.0.11', AppColors.iconGreen),
      _SettData(Icons.star, s.settingsRate, '', const Color(0xFFFFC107)),
      _SettData(Icons.share, s.settingsShare, '', AppColors.iconPurple),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return GestureDetector(
          onTap: () {
            switch (i) {
              case 0:
                _showLanguagePicker(context);
                break;
              case 1:
                _showThemePicker(context);
                break;
              case 3:
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoAppScreen()));
                break;
              case 4:
                _rateApp(context);
                break;
              case 5:
                _shareApp(context);
                break;
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              if (item.value.isNotEmpty) Text(item.value, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _ToolData {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPro;
  final String id;
  const _ToolData(this.icon, this.label, this.color, this.isPro, this.id);
}

class _SettData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SettData(this.icon, this.label, this.value, this.color);
}
