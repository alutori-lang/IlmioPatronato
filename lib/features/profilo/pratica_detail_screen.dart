import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../core/services/pratica_service.dart';
import '../../models/pratica.dart';
import '../sbroglia/sbroglia_chat_screen.dart';

class PraticaDetailScreen extends StatefulWidget {
  final String praticaId;
  const PraticaDetailScreen({super.key, required this.praticaId});

  @override
  State<PraticaDetailScreen> createState() => _PraticaDetailScreenState();
}

class _PraticaDetailScreenState extends State<PraticaDetailScreen> {
  final _noteCtrl = TextEditingController();
  bool _noteInit = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<PraticaService>();
    final pratica = svc.byId(widget.praticaId);

    if (pratica == null) {
      return const Scaffold(
        body: Center(child: Text('Pratica non trovata')),
      );
    }

    if (!_noteInit) {
      _noteCtrl.text = pratica.note;
      _noteInit = true;
    }

    final color = _colorForStato(pratica.stato);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(pratica, color)),
          SliverToBoxAdapter(child: _buildStatoPicker(pratica, color)),
          SliverToBoxAdapter(child: _buildInfoCard(pratica, color)),
          SliverToBoxAdapter(child: _buildChecklistCard(pratica, color)),
          SliverToBoxAdapter(child: _buildNoteCard(pratica)),
          SliverToBoxAdapter(child: _buildActionsCard(pratica, color)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader(Pratica p, Color color) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8, right: 8, bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.95), color],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _confirmDelete(p),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.ente.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(p.titolo,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatoPicker(Pratica p, Color color) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        children: PraticaStato.values.map((s) {
          final selected = s == p.stato;
          final c = _colorForStato(s);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                context.read<PraticaService>().update(p.copyWith(stato: s));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? c : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? c : Colors.grey.shade300),
                  boxShadow: selected
                      ? [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(s.label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppColors.textDark)),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard(Pratica p, Color color) {
    final df = DateFormat('d MMM yyyy', 'it_IT');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(children: [
        _infoRow(
          icon: Icons.event_available,
          label: 'Creata',
          value: df.format(p.dataCreazione),
          color: AppColors.textMedium,
        ),
        const Divider(height: 14),
        InkWell(
          onTap: () => _pickDate(
            initial: p.dataInvio,
            onPicked: (d) => context.read<PraticaService>().update(p.copyWith(dataInvio: d)),
            onCleared: () => context.read<PraticaService>().update(p.copyWith(clearDataInvio: true)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _infoRow(
              icon: Icons.send,
              label: 'Data invio',
              value: p.dataInvio == null ? 'Non impostata' : df.format(p.dataInvio!),
              color: AppColors.primary,
              tappable: true,
            ),
          ),
        ),
        const Divider(height: 14),
        InkWell(
          onTap: () => _pickDate(
            initial: p.scadenza,
            onPicked: (d) => context.read<PraticaService>().update(p.copyWith(scadenza: d)),
            onCleared: () => context.read<PraticaService>().update(p.copyWith(clearScadenza: true)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _infoRow(
              icon: Icons.schedule,
              label: 'Scadenza',
              value: p.scadenza == null ? 'Non impostata' : df.format(p.scadenza!),
              color: Colors.orange.shade700,
              tappable: true,
            ),
          ),
        ),
        if (p.stato == PraticaStato.completata) ...[
          const Divider(height: 14),
          InkWell(
            onTap: () => _editImporto(p),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _infoRow(
                icon: Icons.euro,
                label: 'Importo',
                value: p.importo == null || p.importo!.isEmpty ? 'Aggiungi importo' : p.importo!,
                color: Colors.green.shade700,
                tappable: true,
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool tappable = false,
  }) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
      const Spacer(),
      Text(value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      if (tappable) const SizedBox(width: 6),
      if (tappable) const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
    ]);
  }

  Widget _buildChecklistCard(Pratica p, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.checklist, size: 18, color: color),
            const SizedBox(width: 8),
            const Text('Cosa devo fare',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addChecklistItem(p),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Aggiungi'),
              style: TextButton.styleFrom(foregroundColor: color, padding: EdgeInsets.zero),
            ),
          ]),
          const SizedBox(height: 4),
          if (p.checklist.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Nessuna voce. Aggiungi uno step.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ),
            )
          else
            ...List.generate(p.checklist.length, (i) {
              final item = p.checklist[i];
              return InkWell(
                onTap: () {
                  final updated = [...p.checklist];
                  updated[i] = item.toggle();
                  context.read<PraticaService>().update(p.copyWith(checklist: updated));
                },
                onLongPress: () => _removeChecklistItem(p, i),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  child: Row(children: [
                    Icon(
                      item.done ? Icons.check_box : Icons.check_box_outline_blank,
                      color: item.done ? color : AppColors.textLight,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: item.done ? AppColors.textLight : AppColors.textDark,
                          decoration: item.done ? TextDecoration.lineThrough : null,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Pratica p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.notes, size: 18, color: AppColors.textMedium),
          SizedBox(width: 8),
          Text('Note personali',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: _noteCtrl,
          minLines: 2,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Aggiungi le tue note qui…',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (v) => context.read<PraticaService>().update(p.copyWith(note: v)),
        ),
      ]),
    );
  }

  Widget _buildActionsCard(Pratica p, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(children: [
        if (p.linkUfficiale != null && p.linkUfficiale!.isNotEmpty)
          _bigButton(
            icon: Icons.launch_rounded,
            label: 'Controlla stato sul sito ufficiale',
            color: AppColors.primary,
            onTap: () async {
              try {
                await launchUrl(Uri.parse(p.linkUfficiale!), mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
          ),
        const SizedBox(height: 10),
        _bigButton(
          icon: Icons.auto_awesome,
          label: 'Chiedi al Patronato AI',
          color: const Color(0xFF9C27B0),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SbrogliaScreen(
                  initialCategory: UserCategory.neogenitore,
                  initialQuestion:
                      'Sto seguendo la pratica "${p.titolo}" (${p.ente}). Stato attuale: ${p.stato.label}. '
                      '${p.dataInvio != null ? 'Inviata il ${DateFormat('d MMM yyyy', 'it_IT').format(p.dataInvio!)}. ' : ''}'
                      'Cosa mi conviene fare adesso? Tempi medi di risposta e prossimi passi.',
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _bigButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── Actions ───────────
  Future<void> _pickDate({
    required DateTime? initial,
    required void Function(DateTime) onPicked,
    required VoidCallback onCleared,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('it', 'IT'),
      helpText: 'Scegli data',
      cancelText: 'Annulla',
      confirmText: 'OK',
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _addChecklistItem(Pratica p) async {
    final text = await _askText('Aggiungi step', 'es. Prenota CAF');
    if (text == null || text.isEmpty) return;
    final updated = [...p.checklist, ChecklistItem(text: text)];
    await context.read<PraticaService>().update(p.copyWith(checklist: updated));
  }

  Future<void> _removeChecklistItem(Pratica p, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rimuovi step?'),
        content: Text('"${p.checklist[index].text}"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rimuovi', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = [...p.checklist]..removeAt(index);
    await context.read<PraticaService>().update(p.copyWith(checklist: updated));
  }

  Future<void> _editImporto(Pratica p) async {
    final text = await _askText('Importo', 'es. 800€ al mese', initial: p.importo);
    if (text == null) return;
    await context.read<PraticaService>().update(
          p.copyWith(importo: text.isEmpty ? null : text, clearImporto: text.isEmpty),
        );
  }

  Future<String?> _askText(String title, String hint, {String? initial}) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Pratica p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina pratica?'),
        content: Text('"${p.titolo}" sarà rimossa definitivamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<PraticaService>().delete(p.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
