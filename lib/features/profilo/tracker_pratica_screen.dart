import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../core/services/pratica_service.dart';
import '../../models/pratica.dart';
import 'nuova_pratica_screen.dart';
import 'pratica_detail_screen.dart';

class TrackerPraticaScreen extends StatefulWidget {
  const TrackerPraticaScreen({super.key});

  @override
  State<TrackerPraticaScreen> createState() => _TrackerPraticaScreenState();
}

class _TrackerPraticaScreenState extends State<TrackerPraticaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<PraticaService>();
      if (!svc.isLoaded) svc.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<PraticaService>();
    final pratiche = svc.pratiche;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(pratiche.length),
          Expanded(
            child: pratiche.isEmpty ? _buildEmpty() : _buildList(pratiche),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNuova,
        backgroundColor: AppColors.iconOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuova pratica', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Icon(Icons.track_changes, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        const Text('Tracker Pratica',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                color: AppColors.iconOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.track_changes, color: AppColors.iconOrange, size: 56),
            ),
            const SizedBox(height: 22),
            const Text('Nessuna pratica',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text(
              'Tieni traccia di NASpI, ISEE, Bonus, Permesso Soggiorno — checklist, scadenze e note, tutto in un posto.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openNuova,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi la prima pratica',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Pratica> pratiche) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: pratiche.length,
      itemBuilder: (_, i) => _PraticaCard(
        pratica: pratiche[i],
        onTap: () => _openDetail(pratiche[i]),
      ),
    );
  }

  Future<void> _openNuova() async {
    final result = await Navigator.push<Pratica>(
      context,
      MaterialPageRoute(builder: (_) => const NuovaPraticaScreen()),
    );
    if (result != null && mounted) {
      _openDetail(result);
    }
  }

  void _openDetail(Pratica p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PraticaDetailScreen(praticaId: p.id)),
    );
  }
}

class _PraticaCard extends StatelessWidget {
  final Pratica pratica;
  final VoidCallback onTap;

  const _PraticaCard({required this.pratica, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForStato(pratica.stato);
    final df = DateFormat('d MMM yyyy', 'it_IT');
    final checklistDone = pratica.checklist.where((c) => c.done).length;
    final checklistTotal = pratica.checklist.length;
    final hasChecklist = checklistTotal > 0;
    final progress = hasChecklist ? checklistDone / checklistTotal : 0.0;

    String? subtitle;
    IconData subIcon = Icons.info_outline;
    Color subColor = AppColors.textLight;

    if (pratica.scadenza != null) {
      final now = DateTime.now();
      final days = pratica.scadenza!.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (days < 0) {
        subtitle = 'Scaduta il ${df.format(pratica.scadenza!)}';
        subIcon = Icons.warning;
        subColor = Colors.red.shade700;
      } else if (days == 0) {
        subtitle = 'Scade oggi!';
        subIcon = Icons.warning_amber;
        subColor = Colors.red.shade700;
      } else if (days <= 7) {
        subtitle = 'Scade tra $days giorn${days == 1 ? 'o' : 'i'}';
        subIcon = Icons.schedule;
        subColor = Colors.orange.shade700;
      } else {
        subtitle = 'Scadenza ${df.format(pratica.scadenza!)}';
        subIcon = Icons.calendar_today;
      }
    } else if (pratica.dataInvio != null) {
      subtitle = 'Inviata il ${df.format(pratica.dataInvio!)}';
      subIcon = Icons.send;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(pratica.stato.emoji, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(pratica.stato.label,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                    ]),
                  ),
                  const Spacer(),
                  Text(pratica.ente,
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 10),
                Text(pratica.titolo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(subIcon, size: 13, color: subColor),
                    const SizedBox(width: 4),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w600)),
                  ]),
                ],
                if (hasChecklist) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$checklistDone/$checklistTotal',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMedium)),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _colorForStato(PraticaStato s) {
  switch (s) {
    case PraticaStato.daFare:     return const Color(0xFFF9A825);
    case PraticaStato.inCorso:    return const Color(0xFFE65100);
    case PraticaStato.inAttesa:   return const Color(0xFF5E35B1);
    case PraticaStato.completata: return const Color(0xFF2E7D32);
    case PraticaStato.rifiutata:  return const Color(0xFFC62828);
  }
}
