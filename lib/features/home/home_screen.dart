import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/widgets/service_card.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/services/agevolazioni_service.dart';
import '../agevolazioni/agevolazioni_data.dart' as data;
import '../agevolazioni/agevolazione_detail_screen.dart';
import '../agevolazioni/agevolazione_ai_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToGuide;
  final VoidCallback onNavigateToAgevolazioni;
  final VoidCallback onNavigateToStrumenti;
  final VoidCallback onNavigateToSbroglia;

  const HomeScreen({
    super.key,
    required this.onNavigateToGuide,
    required this.onNavigateToAgevolazioni,
    required this.onNavigateToStrumenti,
    required this.onNavigateToSbroglia,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _agevolazioniService = AgevolazioniService();
  List<Agevolazione> _nuoveAgevolazioni = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAgevolazioni();
  }

  Future<void> _loadAgevolazioni() async {
    try {
      final result = await _agevolazioniService.getAgevolazioni();
      if (mounted) setState(() { _nuoveAgevolazioni = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
        SliverToBoxAdapter(child: _sectionTitle('Agevolazioni Nuove Questa Settimana')),
        SliverToBoxAdapter(child: _buildNovitaAgevolazioni(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        const SliverToBoxAdapter(child: _DisclaimerBox()),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: BannerAdWidget(),
          ),
        ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      height: 150,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Il Mio Patronato', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 4),
                  const Text('Pratiche, Bonus e Servizi per Immigrati', style: TextStyle(color: AppColors.bannerText, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgevolazioneDelGiorno(BuildContext context) {
    final a = data.agevolazioneDelGiorno();
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
    final bonusCount = 53 + _nuoveAgevolazioni.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78,
        children: [
          ServiceCard(
            icon: Icons.card_giftcard, title: 'Agevolazioni', subtitle: '$bonusCount bonus & diritti',
            iconGradient: const [Color(0xFFFFF3E0), Color(0xFFFFE0B2)], iconColor: const Color(0xFFE65100),
            onTap: widget.onNavigateToAgevolazioni,
          ),
          ServiceCard(
            icon: Icons.build_circle, title: 'Strumenti', subtitle: '20+ tools',
            iconGradient: const [AppColors.serviceGreenLight, AppColors.serviceGreenMed], iconColor: AppColors.iconGreen,
            onTap: widget.onNavigateToStrumenti,
          ),
          ServiceCard(
            icon: Icons.psychology_rounded, title: 'Chiedi AI', subtitle: 'Patronato AI',
            iconGradient: const [Color(0xFFEDE7F6), Color(0xFFD1C4E9)], iconColor: Color(0xFF6A1B9A),
            onTap: widget.onNavigateToSbroglia,
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final bonusCount = 53 + _nuoveAgevolazioni.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '$bonusCount', label: 'BONUS'),
          const _StatItem(value: '18', label: 'GUIDE'),
          const _StatItem(value: '14', label: 'CALCOLATORI'),
          const _StatItem(value: '6', label: 'PDF'),
        ],
      ),
    );
  }

  Widget _buildNovitaAgevolazioni(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(child: Column(
          children: [
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFE65100))),
            SizedBox(height: 10),
            Text('Cerco agevolazioni reali...', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        )),
      );
    }

    if (_nuoveAgevolazioni.isEmpty) {
      // Fallback: mostra 3 agevolazioni statiche come prima
      final nuove = data.novita().take(3).toList();
      return _buildStaticNovita(context, nuove);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ..._nuoveAgevolazioni.take(4).map((a) => _buildAgevolazioneCard(context, a)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: widget.onNavigateToAgevolazioni,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Vedi tutte le ${53 + _nuoveAgevolazioni.length} Agevolazioni →',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgevolazioneCard(BuildContext context, Agevolazione a) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AgevolazioneAiDetailScreen(agevolazione: a),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 2))],
          border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(a.categoriaIcon, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.titolo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(a.descrizione, style: const TextStyle(fontSize: 11, color: AppColors.textLight), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    if (a.importo.isNotEmpty) ...[
                      Text(a.importo, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.access_time, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(a.tempoRelativo, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    if (a.fonte.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.source, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Flexible(child: Text(a.fonte, style: TextStyle(fontSize: 10, color: Colors.grey.shade400), overflow: TextOverflow.ellipsis)),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticNovita(BuildContext context, List<dynamic> nuove) {
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
            onTap: widget.onNavigateToAgevolazioni,
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

// ─── StatItem ──────────────────────────────────────────────────────────────

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

class _DisclaimerBox extends StatelessWidget {
  const _DisclaimerBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 15, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Questa app non è un ente governativo né è affiliata ad esso. '
              'Le informazioni fornite sono a scopo orientativo e si basano su fonti ufficiali '
              '(INPS, Agenzia delle Entrate, Ministeri). '
              'Verifica sempre i dettagli sui siti ufficiali (.gov.it) prima di presentare domanda.',
              style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
