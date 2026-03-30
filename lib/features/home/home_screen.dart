import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/services/agevolazioni_service.dart';
import '../agevolazioni/agevolazioni_data.dart' as data;
import '../agevolazioni/agevolazione_detail_screen.dart';
import '../simulatore/simulatore_screen.dart';
import '../compilatore/compilatore_screen.dart';
import '../ai_avvocato/ai_chat_screen.dart';
import '../strumenti/strumenti_screen.dart';

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
    final a = data.agevolazioneDellaSettimana();
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
                    child: const Text('AGEVOLAZIONE DELLA SETTIMANA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
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

          // ── ROW 1 ──
          Row(
            children: [
              Expanded(
                child: _WowCard(
                  gradientColors: const [Color(0xFFFF6B35), Color(0xFFFF3D00), Color(0xFFD50000)],
                  glowColor: const Color(0xFFFF6B35),
                  emoji: '🎁',
                  icon: Icons.card_giftcard,
                  badge: 'HOT',
                  badgeColor: const Color(0xFFFFD600),
                  title: 'Agevolazioni',
                  subtitle: '$bonusCount bonus disponibili',
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
                child: _WowCard(
                  gradientColors: const [Color(0xFF7C4DFF), Color(0xFF651FFF), Color(0xFF6200EA)],
                  glowColor: const Color(0xFF7C4DFF),
                  emoji: '🧮',
                  icon: Icons.calculate_rounded,
                  badge: '14',
                  badgeColor: const Color(0xFFB388FF),
                  title: 'Calcolatori',
                  subtitle: 'Simula & calcola tutto',
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

          // ── ROW 2 ──
          Row(
            children: [
              Expanded(
                child: _WowCard(
                  gradientColors: const [Color(0xFF00C853), Color(0xFF00B248), Color(0xFF009624)],
                  glowColor: const Color(0xFF00C853),
                  emoji: '🛠',
                  icon: Icons.build_circle_rounded,
                  badge: 'TOOL',
                  badgeColor: const Color(0xFF69F0AE),
                  title: 'Strumenti',
                  subtitle: '6 tools professionali',
                  items: const [
                    'Wallet Documenti',
                    'Quiz Cittadinanza',
                    'CV Europass',
                    'Busta Paga Spiegata',
                  ],
                  onTap: () => _push(const StrumentiScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WowCard(
                  gradientColors: const [Color(0xFF00B0FF), Color(0xFF0091EA), Color(0xFF0277BD)],
                  glowColor: const Color(0xFF00B0FF),
                  emoji: '💬',
                  icon: Icons.question_answer_rounded,
                  badge: 'AI',
                  badgeColor: const Color(0xFF80D8FF),
                  title: 'Chiedi del Patronato?',
                  subtitle: 'Chiedi qualsiasi cosa',
                  items: const [
                    'Immigrazione',
                    'Documenti & Pratiche',
                    'Bonus & Diritti',
                    'Lavoro & Contratti',
                  ],
                  onTap: () => _push(const AiChatScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── WOW CARD ─────────────────────────────────────────────────────────────

class _WowCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Color glowColor;
  final String emoji;
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final List<String> items;
  final VoidCallback onTap;

  const _WowCard({
    required this.gradientColors,
    required this.glowColor,
    required this.emoji,
    required this.icon,
    required this.badge,
    required this.badgeColor,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            // Main glow shadow
            BoxShadow(
              color: glowColor.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
            // Subtle inner light
            BoxShadow(
              color: glowColor.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: -5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decorative circle (subtle)
            Positioned(
              top: -15,
              right: -15,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -10,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji + Badge row
                Row(
                  children: [
                    // Big emoji with glow background
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const Spacer(),
                    // Animated badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title - bold white
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Subtitle with accent color
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                // Glowing divider
                Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Items with checkmark icons
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 8),

                // Bottom action button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Scopri',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                    ],
                  ),
                ),
              ],
            ),
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
