import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/services/agevolazioni_service.dart';
import '../agevolazioni/agevolazioni_data.dart' as data;
import '../agevolazioni/agevolazione_detail_screen.dart';
import '../simulatore/simulatore_screen.dart';
import '../compilatore/compilatore_screen.dart';

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

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildBanner(context)),
        SliverToBoxAdapter(child: _buildAgevolazioneDelGiorno(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _buildCardsSection(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
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

  // ─── HEADER ──────────────────────────────────────────────────────────────
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
          const SizedBox(width: 8),
          // ── Icona Assistente AI ──
          GestureDetector(
            onTap: widget.onNavigateToSbroglia,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BANNER ──────────────────────────────────────────────────────────────
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Il Mio Patronato', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                  SizedBox(height: 4),
                  Text('Pratiche, Bonus e Servizi per Immigrati', style: TextStyle(color: AppColors.bannerText, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AGEVOLAZIONE DEL GIORNO ─────────────────────────────────────────────
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

  // ─── MAIN CARDS SECTION ──────────────────────────────────────────────────
  Widget _buildCardsSection(BuildContext context) {
    final bonusCount = 53 + _nuoveAgevolazioni.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('I Tuoi Servizi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text('Tutto quello che ti serve, in un posto', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 14),

          // ── ROW 1: Agevolazioni + Calcolatori ──
          Row(
            children: [
              Expanded(
                child: _HomeCard(
                  gradient: const [Color(0xFFFF6F00), Color(0xFFE65100)],
                  icon: Icons.card_giftcard,
                  title: 'Agevolazioni',
                  subtitle: '$bonusCount bonus & diritti',
                  items: _loading
                    ? ['Caricamento...']
                    : [
                        'Assegno Unico',
                        'NASpI & ADI',
                        'Bonus Bollette',
                        if (_nuoveAgevolazioni.isNotEmpty) '+${_nuoveAgevolazioni.length} nuovi',
                      ],
                  onTap: widget.onNavigateToAgevolazioni,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomeCard(
                  gradient: const [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                  icon: Icons.calculate,
                  title: 'Calcolatori',
                  subtitle: '14 simulatori',
                  items: const [
                    'ISEE & 730',
                    'Stipendio Netto',
                    'NASpI & TFR',
                    'IMU & Mutuo',
                  ],
                  onTap: () => _push(const SimulatoreScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── ROW 2: Strumenti & Guide + Moduli PDF ──
          Row(
            children: [
              Expanded(
                child: _HomeCard(
                  gradient: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  icon: Icons.build_circle,
                  title: 'Strumenti & Guide',
                  subtitle: '18 guide + 6 tools',
                  items: const [
                    '18 Guide Pratiche',
                    'Wallet Documenti',
                    'Quiz Cittadinanza',
                    'CV Europass',
                  ],
                  onTap: widget.onNavigateToStrumenti,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomeCard(
                  gradient: const [Color(0xFFC62828), Color(0xFFB71C1C)],
                  icon: Icons.description,
                  title: 'Moduli & PDF',
                  subtitle: '6 moduli + generatori',
                  items: const [
                    'Compila Moduli',
                    'Generatore Delega',
                    'Confronto Offerte',
                    'Prenotazioni',
                  ],
                  onTap: () => _push(const CompilatoreScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── HOME CARD ─────────────────────────────────────────────────────────────

class _HomeCard extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> items;
  final VoidCallback onTap;

  const _HomeCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Arrow
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Divider
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 10),

            // Items list
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ─── DISCLAIMER ────────────────────────────────────────────────────────────

class _DisclaimerBox extends StatelessWidget {
  const _DisclaimerBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
