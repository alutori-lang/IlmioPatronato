import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/services/agevolazioni_service.dart';
import '../../core/services/profilo_utente_service.dart';
import '../simulatore/simulatore_screen.dart';
import '../compilatore/compilatore_screen.dart';
import '../strumenti/strumenti_screen.dart';
import '../ilmiocaso/compila_profilo_screen.dart';
import '../ilmiocaso/risultati_diritti_screen.dart';
import '../guide_documenti/guide_documenti_screen.dart';

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
  bool _isRecent48h = true;

  @override
  void initState() {
    super.initState();
    _loadAgevolazioni();
  }

  Future<void> _loadAgevolazioni() async {
    try {
      final result = await _agevolazioniService.getNovitaOrLatest();
      if (mounted) setState(() {
        _nuoveAgevolazioni = result.items;
        _isRecent48h = result.isRecent;
        _loading = false;
      });
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
        SliverToBoxAdapter(child: _buildGuideDocumentiCard(context)),
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

  // ─── GUIDA DOCUMENTI CARD ────────────────────────────────────────────────
  Widget _buildGuideDocumentiCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GuideDocumentiScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00838F), Color(0xFF00ACC1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF00838F).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Text('🇮🇹', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.verified, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text('GUIDA COMPLETA',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  ]),
                  SizedBox(height: 6),
                  Text('Documenti per stranieri',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
                  SizedBox(height: 4),
                  Text('Dal visto alla cittadinanza • 14 lingue',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 26),
          ]),
        ),
      ),
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

  // ─── ULTIMO BONUS — LIVE PULSE (news-style professionale) ────────────────
  Widget _buildAgevolazioneDelGiorno(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE4E8EF)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0xFF0D2A4A).withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(width: 3, height: 36, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E4A8A), Color(0xFF3B82F6)], begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E4A8A))),
            const SizedBox(width: 12),
            const Expanded(child: Text('Cerco ultime novità...', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500))),
          ],
        ),
      );
    }

    if (_nuoveAgevolazioni.isEmpty) {
      return const SizedBox.shrink();
    }

    final a = _nuoveAgevolazioni.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onNavigateToAgevolazioni,
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE4E8EF)),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color(0xFF0D2A4A).withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
              ),
              child: Stack(
                children: [
                  Positioned(left: 0, top: 0, bottom: 0, width: 3, child: Container(color: const Color(0xFF1E4A8A))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(17, 13, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          _LivePulseDot(animated: _isRecent48h),
                          const SizedBox(width: 7),
                          Text(
                            _isRecent48h ? 'ULTIME 48H · INFO LIVE' : 'ULTIMO BONUS ATTIVO',
                            style: const TextStyle(color: Color(0xFF1E4A8A), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                          ),
                        ]),
                        const SizedBox(height: 9),
                        Text(a.titolo, style: const TextStyle(color: Color(0xFF0D2A4A), fontSize: 15, fontWeight: FontWeight.w700, height: 1.25), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(a.importo.isNotEmpty ? a.importo : a.tempoRelativo, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        Container(height: 1, color: const Color(0xFFF1F3F7)),
                        const SizedBox(height: 9),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                a.fonte.isNotEmpty ? 'Fonte: ${a.fonte}' : 'Fonte ufficiale',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('Leggi', style: TextStyle(color: Color(0xFF1E4A8A), fontSize: 12, fontWeight: FontWeight.w600)),
                              SizedBox(width: 3),
                              Icon(Icons.arrow_forward, color: Color(0xFF1E4A8A), size: 14),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                  onTap: widget.onNavigateToSbroglia,
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

// ─── LIVE PULSE DOT ────────────────────────────────────────────────────────
// Pallino con ring espansivo: verde se animated (novità live 48h), grigio
// statico altrimenti (fallback su ultimo bonus attivo).

class _LivePulseDot extends StatefulWidget {
  final bool animated;
  const _LivePulseDot({required this.animated});

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.animated) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _LivePulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.animated && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.animated ? const Color(0xFF10B981) : const Color(0xFF94A3B8);
    return SizedBox(
      width: 14, height: 14,
      child: Stack(alignment: Alignment.center, children: [
        if (widget.animated)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value;
              return Container(
                width: 7 + t * 9,
                height: 7 + t * 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor.withValues(alpha: 0.35 * (1 - t)),
                ),
              );
            },
          ),
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
      ]),
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
