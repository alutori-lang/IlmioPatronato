import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/agevolazioni_service.dart' as ai;
import 'agevolazioni_data.dart';
import 'agevolazione_detail_screen.dart';
import 'agevolazione_ai_detail_screen.dart';

class AgevolazioniScreen extends StatefulWidget {
  const AgevolazioniScreen({super.key});

  @override
  State<AgevolazioniScreen> createState() => _AgevolazioniScreenState();
}

class _AgevolazioniScreenState extends State<AgevolazioniScreen> {
  final _searchController = TextEditingController();
  String _selectedCategoria = '';
  List<Agevolazione> _risultati = [];
  bool _mostraNovita = true;

  // AI agevolazioni settimanali
  final _aiService = ai.AgevolazioniService();
  List<ai.Agevolazione> _aiNuove = [];
  bool _aiLoading = true;

  @override
  void initState() {
    super.initState();
    _risultati = allAgevolazioni;
    _loadAiAgevolazioni();
  }

  Future<void> _loadAiAgevolazioni() async {
    try {
      // Ultime 48h (refresh ogni 48h, fallback su ultime caricate)
      final result = await _aiService.getNovita48h();
      if (mounted) setState(() { _aiNuove = result; _aiLoading = false; });
      // In background: aggiorna anche lista completa per filtri/categorie
      _aiService.getAgevolazioni();
    } catch (_) {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _mostraNovita = query.isEmpty && _selectedCategoria.isEmpty;
      if (_selectedCategoria.isNotEmpty && query.isEmpty) {
        _risultati = perCategoria(_selectedCategoria);
      } else if (query.isNotEmpty) {
        var res = cerca(query);
        if (_selectedCategoria.isNotEmpty) {
          res = res.where((a) => a.categoria == _selectedCategoria).toList();
        }
        _risultati = res;
      } else {
        _risultati = allAgevolazioni;
      }
    });
  }

  void _selectCategoria(String cat) {
    setState(() {
      if (_selectedCategoria == cat) {
        _selectedCategoria = '';
      } else {
        _selectedCategoria = cat;
      }
      _onSearch(_searchController.text);
    });
  }

  IconData _getIconForName(String name) {
    switch (name) {
      case 'work': return Icons.work;
      case 'home': return Icons.home;
      case 'family_restroom': return Icons.family_restroom;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'school': return Icons.school;
      case 'flight_land': return Icons.flight_land;
      case 'euro': return Icons.euro;
      case 'accessible': return Icons.accessible;
      case 'emoji_people': return Icons.emoji_people;
      case 'elderly': return Icons.elderly;
      default: return Icons.star;
    }
  }

  IconData _getAgevolazioneIcon(String name) {
    switch (name) {
      case 'work_off': return Icons.work_off;
      case 'badge': return Icons.badge;
      case 'person_add': return Icons.person_add;
      case 'woman': return Icons.woman;
      case 'south': return Icons.south;
      case 'rocket_launch': return Icons.rocket_launch;
      case 'menu_book': return Icons.menu_book;
      case 'apartment': return Icons.apartment;
      case 'house': return Icons.house;
      case 'solar_power': return Icons.solar_power;
      case 'chair': return Icons.chair;
      case 'construction': return Icons.construction;
      case 'accessible': return Icons.accessible;
      case 'real_estate_agent': return Icons.real_estate_agent;
      case 'shield': return Icons.shield;
      case 'child_care': return Icons.child_care;
      case 'child_friendly': return Icons.child_friendly;
      case 'pregnant_woman': return Icons.pregnant_woman;
      case 'family_restroom': return Icons.family_restroom;
      case 'credit_card': return Icons.credit_card;
      case 'cake': return Icons.cake;
      case 'local_hospital': return Icons.local_hospital;
      case 'psychology': return Icons.psychology;
      case 'visibility': return Icons.visibility;
      case 'auto_stories': return Icons.auto_stories;
      case 'school': return Icons.school;
      case 'directions_bus': return Icons.directions_bus;
      case 'emoji_events': return Icons.emoji_events;
      case 'military_tech': return Icons.military_tech;
      case 'flight_land': return Icons.flight_land;
      case 'flight_takeoff': return Icons.flight_takeoff;
      case 'card_membership': return Icons.card_membership;
      case 'phone_android': return Icons.phone_android;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'bolt': return Icons.bolt;
      case 'tv': return Icons.tv;
      case 'fastfood': return Icons.fastfood;
      case 'medical_services': return Icons.medical_services;
      case 'wheelchair_pickup': return Icons.wheelchair_pickup;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'work': return Icons.work;
      case 'diversity_3': return Icons.diversity_3;
      case 'trending_up': return Icons.trending_up;
      case 'store': return Icons.store;
      case 'payments': return Icons.payments;
      case 'elderly': return Icons.elderly;
      case 'elderly_woman': return Icons.elderly_woman;
      case 'account_balance': return Icons.account_balance;
      default: return Icons.star;
    }
  }

  Color _getCategoriaColor(String cat) {
    final c = categorie.firstWhere((e) => e['nome'] == cat, orElse: () => {'color': 0xFF1565C0});
    return Color(c['color'] as int);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
        slivers: [
          // ── HEADER ──
          SliverToBoxAdapter(child: _buildHeader(context)),

          // ── SEARCH BAR ──
          SliverToBoxAdapter(child: _buildSearchBar()),

          // ── ULTIME 48H (AI) ──
          if (_mostraNovita)
            SliverToBoxAdapter(child: _buildAiNuoveSection()),

          // ── CATEGORIE ──
          SliverToBoxAdapter(child: _buildCategorie()),

          // Sezione NOVITÀ statica rimossa: sostituita da ULTIME 48H dinamica sopra

          // ── RISULTATI / TUTTE ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(
                    _searchController.text.isNotEmpty ? Icons.search : Icons.list_alt,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _searchController.text.isNotEmpty
                          ? '${_risultati.length} risultati trovati'
                          : _selectedCategoria.isNotEmpty
                              ? _selectedCategoria
                              : 'Tutte le Agevolazioni (${_risultati.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── LISTA RISULTATI ──
          _risultati.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final a = _risultati[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AgevolazioneCard(
                            agevolazione: a,
                            icon: _getAgevolazioneIcon(a.iconName),
                            color: _getCategoriaColor(a.categoria),
                            onTap: () => _openDetail(a),
                          ),
                        );
                      },
                      childCount: _risultati.length,
                    ),
                  ),
                ),
        ],
      ),
      ),
    );
  }

  void _openDetail(Agevolazione a) {
    AdService().onNavigateToDetail();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgevolazioneDetailScreen(
          agevolazione: a,
          icon: _getAgevolazioneIcon(a.iconName),
          color: _getCategoriaColor(a.categoria),
        ),
      ),
    );
  }

  Widget _buildAiNuoveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE65100), borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bolt, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('ULTIME 48H', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(width: 8),
            if (!_aiLoading) Flexible(child: Text('${_aiNuove.length} novità', style: const TextStyle(fontSize: 12, color: AppColors.textMedium), overflow: TextOverflow.ellipsis)),
          ]),
        ),
        if (_aiLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE65100))),
              SizedBox(width: 10),
              Text('Cerco novità ultime 48h...', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            ])),
          )
        else if (_aiNuove.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFFE65100), size: 18),
                SizedBox(width: 8),
                Flexible(child: Text('Nessuna novità nelle ultime 48h', style: TextStyle(fontSize: 12, color: AppColors.textMedium))),
              ]),
            ),
          )
        else
          ...List.generate(_aiNuove.length, (i) {
            final a = _aiNuove[i];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AgevolazioneAiDetailScreen(agevolazione: a),
              )),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6D00), Color(0xFFFF9800)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
                        blurRadius: 18, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(child: Text(a.categoriaIcon, style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.bolt, size: 10, color: Color(0xFFFF6D00)),
                                  SizedBox(width: 2),
                                  Text('NUOVO', style: TextStyle(color: Color(0xFFFF6D00), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                ]),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.access_time, size: 11, color: Colors.white.withValues(alpha: 0.85)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  a.tempoRelativo,
                                  style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Text(
                              a.titolo,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.descrizione,
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.92), height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (a.importo.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  a.importo,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.85), size: 14),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          if (canPop) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF8F00)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFFE65100).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.card_giftcard, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AGEVOLAZIONI', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 1),
                Text('Bonus e diritti del Governo', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${allAgevolazioni.length}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Cerca agevolazione... (es. affitto, figli, lavoro)',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDelGiorno(Agevolazione a) {
    return GestureDetector(
      onTap: () => _openDetail(a),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getAgevolazioneIcon(a.iconName), color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('AGEVOLAZIONE DEL GIORNO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 6),
                  Text(a.titolo, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(a.descrizione, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.euro, color: Colors.amber.shade300, size: 13),
                      const SizedBox(width: 4),
                      Flexible(child: Text(a.importo, style: TextStyle(color: Colors.amber.shade300, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text('Scopri →', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorie() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        itemCount: categorie.length,
        itemBuilder: (context, index) {
          final cat = categorie[index];
          final nome = cat['nome'] as String;
          final isSelected = _selectedCategoria == nome;
          final color = Color(cat['color'] as int);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _selectCategoria(nome),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? color : Colors.grey.shade300),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getIconForName(cat['icon'] as String), size: 16, color: isSelected ? Colors.white : color),
                    const SizedBox(width: 6),
                    Text(
                      nome,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Nessuna agevolazione trovata',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Al momento non esistono agevolazioni per questa ricerca.\nProva con parole diverse.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── CARD AGEVOLAZIONE ──
class _AgevolazioneCard extends StatelessWidget {
  final Agevolazione agevolazione;
  final IconData icon;
  final Color color;
  final bool isNew;
  final VoidCallback onTap;

  const _AgevolazioneCard({
    required this.agevolazione,
    required this.icon,
    required this.color,
    this.isNew = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 3))],
          border: isNew
              ? Border.all(color: Colors.red.shade200, width: 1.5)
              : Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          agevolazione.titolo,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      agevolazione.descrizione,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          agevolazione.categoria,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.euro, size: 11, color: Colors.green.shade600),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          agevolazione.importo,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }
}
