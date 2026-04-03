import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/services/profilo_utente_service.dart';
import '../../core/services/diritti_service.dart';

class RisultatiDirittiScreen extends StatelessWidget {
  final ProfiloUtente profilo;
  const RisultatiDirittiScreen({super.key, required this.profilo});

  @override
  Widget build(BuildContext context) {
    final diritti = DirittiService.getDiritti(profilo);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('I Tuoi Diritti', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF1B5E20),
          ),

          // ── Header risultato ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    diritti.isEmpty
                        ? 'Nessun bonus trovato'
                        : 'HAI DIRITTO A ${diritti.length} BONUS!',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    diritti.isEmpty
                        ? 'Prova ad aggiornare il tuo ISEE o il profilo.'
                        : 'Ecco tutti i bonus e agevolazioni a cui puoi accedere.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // ── Lista diritti ──
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final d = diritti[index];
                return _DirittoCard(diritto: d);
              },
              childCount: diritti.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _DirittoCard extends StatefulWidget {
  final Diritto diritto;
  const _DirittoCard({required this.diritto});

  @override
  State<_DirittoCard> createState() => _DirittoCardState();
}

class _DirittoCardState extends State<_DirittoCard> {
  bool _expanded = false;

  Color get _categoryColor {
    switch (widget.diritto.categoria) {
      case 'famiglia': return const Color(0xFFE91E63);
      case 'lavoro': return const Color(0xFF1565C0);
      case 'casa': return const Color(0xFFFF6F00);
      case 'salute': return const Color(0xFF00897B);
      case 'giovani': return const Color(0xFF6A1B9A);
      case 'disabilita': return const Color(0xFF0277BD);
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diritto;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(d.icona, style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.titolo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        const SizedBox(height: 2),
                        Text(d.importo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _categoryColor)),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textLight),
                ],
              ),
            ),
            if (_expanded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.descrizione, style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4)),
                    const SizedBox(height: 12),
                    _infoRow(Icons.how_to_reg, 'Come richiederlo', d.comeRichiederlo),
                    const SizedBox(height: 8),
                    _infoRow(Icons.folder, 'Documenti necessari', d.documentiNecessari),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _categoryColor),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _categoryColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3)),
        ],
      ),
    );
  }
}
