import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/services/agevolazioni_service.dart';
import '../../core/services/profilo_utente_service.dart';
import '../simulatore/simulatore_screen.dart';
import '../compilatore/compilatore_screen.dart';
import '../ai_avvocato/ai_chat_screen.dart';
import '../strumenti/strumenti_screen.dart';
import '../ilmiocaso/compila_profilo_screen.dart';
import '../ilmiocaso/risultati_diritti_screen.dart';

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
      // Novità ultime 48h per il banner "del giorno"
      final result = await _agevolazioniService.getNovita48h();
      if (mounted) setState(() { _nuoveAgevolazioni = result; _loading = false; });
      // In background: aggiorna lista completa per i contatori
      _agevolazioniService.getAgevolazioni();
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
        SliverToBoxAdapter(child: _buildIlMioCasoBanner(context)),
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

  // ─── IL MIO CASO BANNER ──────────────────────────────────────────────────
  Widget _buildIlMioCasoBanner(BuildContext context) {
    final profiloService = context.watch<ProfiloUtenteService>();
    final hasProfile = profiloService.hasProfile;

    return GestureDetector(
      onTap: () {
        if (hasProfile) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => RisultatiDirittiScreen(profilo: profiloService.profilo!),
          ));
        } else {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => CompilaProfiloScreen(service: profiloService),
          ));
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasProfile ? 'VEDI I TUOI DIRITTI' : 'SCOPRI I TUOI DIRITTI',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasProfile
                        ? 'Clicca per vedere i bonus a cui hai diritto'
                        : 'Compila il profilo e scopri tutti i bonus e agevolazioni che puoi ottenere!',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ],
        ),
      ),
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

  // ─── ULTIME 48H — NOVITÀ DINAMICA (Gemini + Google Search) ───────────────
  Widget _buildAgevolazioneDelGiorno(BuildContext context) {
    // Loading
    if (_loading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFFE65100).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: const Row(
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
            SizedBox(width: 14),
            Expanded(child: Text('Cerco novità ultime 48h...', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      );
    }

    // Nessuna novità 48h → hide
    if (_nuoveAgevolazioni.isEmpty) {
      return const SizedBox.shrink();
    }

    final a = _nuoveAgevolazioni.first;
    return GestureDetector(
      onTap: widget.onNavigateToAgevolazioni,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFFE65100).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(a.categoriaIcon, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bolt, size: 10, color: Color(0xFFE65100)),
                      SizedBox(width: 2),
                      Text('ULTIME 48H', style: TextStyle(color: Color(0xFFE65100), fontSize: 8, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text(a.titolo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(a.importo.isNotEmpty ? a.importo : a.tempoRelativo, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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
                  gradientColors: const [Color(0xFFE65100)],
                  glowColor: const Color(0xFFE65100),
                  emoji: '🎁',
                  icon: Icons.card_giftcard,
                  badge: 'HOT',
                  badgeColor: const Color(0xFFE65100),
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
                  gradientColors: const [Color(0xFF5E35B1)],
                  glowColor: const Color(0xFF5E35B1),
                  emoji: '🧮',
                  icon: Icons.calculate_rounded,
                  badge: '14',
                  badgeColor: const Color(0xFF5E35B1),
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
                  gradientColors: const [Color(0xFF2E7D32)],
                  glowColor: const Color(0xFF2E7D32),
                  emoji: '🛠',
                  icon: Icons.build_circle_rounded,
                  badge: 'TOOL',
                  badgeColor: const Color(0xFF2E7D32),
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
                  gradientColors: const [Color(0xFF1565C0)],
                  glowColor: const Color(0xFF1565C0),
                  emoji: '💬',
                  icon: Icons.question_answer_rounded,
                  badge: 'AI',
                  badgeColor: const Color(0xFF1565C0),
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
    final accent = glowColor;
    final accentSoft = Color.alphaBlend(accent.withValues(alpha: 0.10), Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFECEFF3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Badge row
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),

            // Subtitle
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF8A92A3),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Divider
            Container(height: 1, color: const Color(0xFFF1F3F5)),
            const SizedBox(height: 10),

            // Items with check icons
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: accent, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF2C3340),
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

            const SizedBox(height: 4),

            // Bottom action — solo testo + freccia
            Row(
              children: [
                Text(
                  'Scopri',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: accent, size: 14),
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
