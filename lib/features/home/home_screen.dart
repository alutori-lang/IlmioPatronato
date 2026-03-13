import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/widgets/service_card.dart';
import '../../core/widgets/news_card.dart';
import '../../core/widgets/quick_action_item.dart';
import '../compilatore/compilatore_screen.dart';
import '../simulatore/simulatore_screen.dart';
import '../prenotazioni/prenotazioni_screen.dart';
import '../simulatore/isee_screen.dart';
import '../strumenti/strumenti_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToGuide;
  final VoidCallback onNavigateToDomande;
  final VoidCallback onNavigateToAI;

  const HomeScreen({
    super.key,
    required this.onNavigateToGuide,
    required this.onNavigateToDomande,
    required this.onNavigateToAI,
  });

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildBanner(context)),
        SliverToBoxAdapter(child: _sectionTitle('I Nostri Servizi')),
        SliverToBoxAdapter(child: _buildServicesGrid(context)),
        SliverToBoxAdapter(child: _buildStats()),
        SliverToBoxAdapter(child: _sectionTitle('Novità & Avvisi')),
        SliverToBoxAdapter(child: _buildNews()),
        SliverToBoxAdapter(child: _sectionTitle('Azioni Rapide')),
        SliverToBoxAdapter(child: _buildQuickActions(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF1976D2).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IL MIO PATRONATO', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Assistenza Immigrazione', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
          _HeaderBtn(icon: Icons.search, onTap: () {}),
          const SizedBox(width: 10),
          _HeaderBtn(icon: Icons.notifications_outlined, showDot: true, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _push(context, const CompilatoreScreen()),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/banner.png', fit: BoxFit.cover),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.bannerOverlayStart, AppColors.bannerOverlayEnd],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Benvenuto su\nIl Mio Patronato', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 6),
                    const Text('Pratiche di Immigrazione e Servizi CAF', style: TextStyle(color: AppColors.bannerText, fontSize: 13)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rocket_launch, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Inizia Ora', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.92,
        children: [
          ServiceCard(
            icon: Icons.edit_document, title: 'Compila Moduli', subtitle: 'Genera PDF pronti',
            iconGradient: const [AppColors.serviceBlueLight, AppColors.serviceBlueMed], iconColor: AppColors.iconBlue,
            onTap: () => _push(context, const CompilatoreScreen()),
          ),
          ServiceCard(
            icon: Icons.calculate_rounded, title: 'Simulatore', subtitle: '14 calcolatori reali',
            iconGradient: const [AppColors.serviceGreenLight, AppColors.serviceGreenMed], iconColor: AppColors.iconGreen,
            onTap: () => _push(context, const SimulatoreScreen()),
          ),
          ServiceCard(
            icon: Icons.build_circle, title: 'Strumenti', subtitle: 'CV, Quiz, Wallet +',
            iconGradient: const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], iconColor: Color(0xFF1565C0),
            onTap: () => _push(context, const StrumentiScreen()),
          ),
          ServiceCard(
            icon: Icons.calendar_month_rounded, title: 'Prenotazioni', subtitle: 'Prenota appuntamento',
            iconGradient: const [AppColors.serviceOrangeLight, AppColors.serviceOrangeMed], iconColor: AppColors.iconOrange,
            onTap: () => _push(context, const PrenotazioniScreen()),
          ),
          ServiceCard(
            icon: Icons.menu_book_rounded, title: 'Guide Complete', subtitle: '18 guide step-by-step',
            iconGradient: const [AppColors.servicePurpleLight, AppColors.servicePurpleMed], iconColor: AppColors.iconPurple,
            onTap: onNavigateToGuide,
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 2))],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '6', label: 'MODULI'),
          _StatItem(value: '14', label: 'SIMULATORI'),
          _StatItem(value: '6', label: 'STRUMENTI'),
        ],
      ),
    );
  }

  Widget _buildNews() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        NewsCard(title: 'Rinnovo Permesso 2026', description: 'Scopri le nuove regole per il rinnovo del permesso di soggiorno.', onTap: onNavigateToGuide),
        NewsCard(title: 'Bonus Famiglia', description: 'Agevolazioni per le famiglie, scopri come fare domanda.', onTap: onNavigateToGuide),
        NewsCard(title: 'Cittadinanza Italiana', description: 'Nuove procedure per la richiesta di cittadinanza.', onTap: onNavigateToGuide),
      ]),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 4, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9,
        children: [
          QuickActionItem(icon: Icons.edit_document, label: 'Moduli', onTap: () => _push(context, const CompilatoreScreen())),
          QuickActionItem(icon: Icons.euro, label: 'Costi', onTap: () => _push(context, const SimulatoreScreen())),
          QuickActionItem(icon: Icons.chat_bubble_outline, label: 'Chat AI', onTap: onNavigateToAI),
          QuickActionItem(icon: Icons.calendar_month, label: 'Prenota', onTap: () => _push(context, const PrenotazioniScreen())),
          QuickActionItem(icon: Icons.build_circle, label: 'Strumenti', onTap: () => _push(context, const StrumentiScreen())),
          QuickActionItem(icon: Icons.calculate_outlined, label: 'ISEE', onTap: () => _push(context, const IseeScreen())),
          QuickActionItem(icon: Icons.menu_book, label: 'Guide', onTap: onNavigateToGuide),
          QuickActionItem(icon: Icons.question_answer, label: 'Domande', onTap: onNavigateToDomande),
        ],
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, this.showDot = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (showDot) Positioned(
              top: 7, right: 8,
              child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.notification, shape: BoxShape.circle, border: Border.all(color: AppColors.headerMid, width: 2))),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, letterSpacing: 0.5)),
    ]);
  }
}
