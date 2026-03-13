import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/widgets/service_card.dart';
import '../compilatore/compilatore_screen.dart';
import '../simulatore/isee_screen.dart';
import '../agevolazioni/agevolazioni_data.dart';
import '../agevolazioni/agevolazione_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToGuide;
  final VoidCallback onNavigateToAgevolazioni;
  final VoidCallback onNavigateToStrumenti;

  const HomeScreen({
    super.key,
    required this.onNavigateToGuide,
    required this.onNavigateToAgevolazioni,
    required this.onNavigateToStrumenti,
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
        SliverToBoxAdapter(child: _buildAgevolazioneDelGiorno(context)),
        SliverToBoxAdapter(child: _sectionTitle('Cosa vuoi fare?')),
        SliverToBoxAdapter(child: _buildServicesGrid(context)),
        SliverToBoxAdapter(child: _buildStats()),
        SliverToBoxAdapter(child: _sectionTitle('Novità Agevolazioni 2025')),
        SliverToBoxAdapter(child: _buildNovitaAgevolazioni(context)),
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
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _push(context, const CompilatoreScreen()),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        height: 160,
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
                    const Text('Pratiche, Bonus e Servizi per Immigrati', style: TextStyle(color: AppColors.bannerText, fontSize: 13)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rocket_launch, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Compila Moduli', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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

  Widget _buildAgevolazioneDelGiorno(BuildContext context) {
    final a = agevolazioneDelGiorno();
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AgevolazioneDetailScreen(
            agevolazione: a,
            icon: Icons.card_giftcard,
            color: const Color(0xFF1565C0),
          ),
        ));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(4)),
                    child: const Text('AGEVOLAZIONE DEL GIORNO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 4),
                  Text(a.titolo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(a.importo, style: TextStyle(color: Colors.amber.shade300, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15,
        children: [
          ServiceCard(
            icon: Icons.card_giftcard, title: 'Agevolazioni', subtitle: '53 bonus & diritti',
            iconGradient: const [Color(0xFFFFF3E0), Color(0xFFFFE0B2)], iconColor: const Color(0xFFE65100),
            onTap: onNavigateToAgevolazioni,
          ),
          ServiceCard(
            icon: Icons.menu_book_rounded, title: 'Guide', subtitle: '18 guide step-by-step',
            iconGradient: const [AppColors.servicePurpleLight, AppColors.servicePurpleMed], iconColor: AppColors.iconPurple,
            onTap: onNavigateToGuide,
          ),
          ServiceCard(
            icon: Icons.build_circle, title: 'Strumenti', subtitle: '20+ calcolatori & tools',
            iconGradient: const [AppColors.serviceGreenLight, AppColors.serviceGreenMed], iconColor: AppColors.iconGreen,
            onTap: onNavigateToStrumenti,
          ),
          ServiceCard(
            icon: Icons.calculate, title: 'Calcola ISEE', subtitle: 'Formula ufficiale',
            iconGradient: const [AppColors.serviceBlueLight, AppColors.serviceBlueMed], iconColor: AppColors.iconBlue,
            onTap: () => _push(context, const IseeScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 2))],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '53', label: 'BONUS'),
          _StatItem(value: '18', label: 'GUIDE'),
          _StatItem(value: '14', label: 'CALCOLATORI'),
          _StatItem(value: '6', label: 'PDF'),
        ],
      ),
    );
  }

  Widget _buildNovitaAgevolazioni(BuildContext context) {
    final nuove = novita().take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...nuove.map((a) => GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AgevolazioneDetailScreen(agevolazione: a, icon: Icons.card_giftcard, color: const Color(0xFFE65100)),
            )),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 2))],
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.fiber_new, color: Colors.red.shade600, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.titolo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(a.importo, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                ],
              ),
            ),
          )),
          GestureDetector(
            onTap: onNavigateToAgevolazioni,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Vedi tutte le 53 Agevolazioni →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
              ),
            ),
          ),
        ],
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
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textLight, letterSpacing: 0.5)),
    ]);
  }
}
