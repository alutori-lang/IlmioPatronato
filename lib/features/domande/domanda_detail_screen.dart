import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../models/domanda.dart';

class DomandaDetailScreen extends StatefulWidget {
  final Domanda domanda;
  const DomandaDetailScreen({super.key, required this.domanda});

  @override
  State<DomandaDetailScreen> createState() => _DomandaDetailScreenState();
}

class _DomandaDetailScreenState extends State<DomandaDetailScreen> {
  final _replyController = TextEditingController();

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m fa';
    if (diff.inHours < 24) return '${diff.inHours}h fa';
    return '${diff.inDays}g fa';
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.domanda;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 20, bottom: 14),
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Domanda', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Question card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.titolo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text(d.descrizione, style: const TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5)),
                  const SizedBox(height: 14),
                  Row(children: [
                    CircleAvatar(radius: 16, backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(d.autore[0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    const SizedBox(width: 8),
                    Text(d.autore, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(width: 8),
                    Text(_timeAgo(d.dataCreazione), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    const Spacer(),
                    Icon(Icons.thumb_up_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('${d.voti}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              // Answers header
              Row(children: [
                const Text('Risposte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: Text('${d.risposte.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 12),
              if (d.risposte.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('Nessuna risposta ancora. Sii il primo!', style: TextStyle(fontSize: 14, color: AppColors.textLight))),
                )
              else
                ...d.risposte.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CircleAvatar(radius: 14, backgroundColor: AppColors.iconGreen.withValues(alpha: 0.12),
                        child: Text(r.autore[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.iconGreen))),
                      const SizedBox(width: 8),
                      Text(r.autore, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(_timeAgo(r.data), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                      const Spacer(),
                      Icon(Icons.thumb_up_outlined, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text('${r.voti}', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    ]),
                    const SizedBox(height: 8),
                    Text(r.testo, style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.4)),
                  ]),
                )),
              const SizedBox(height: 20),
            ]),
          ),
        ),
        // Reply input
        Container(
          padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _replyController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Scrivi la tua risposta...', hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
                    border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                if (_replyController.text.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funzione disponibile con Firebase!'), backgroundColor: AppColors.primary),
                  );
                  _replyController.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
