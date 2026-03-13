import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../models/domanda.dart';
import 'domanda_detail_screen.dart';

class DomandeScreen extends StatefulWidget {
  const DomandeScreen({super.key});

  @override
  State<DomandeScreen> createState() => _DomandeScreenState();
}

class _DomandeScreenState extends State<DomandeScreen> {
  String _selectedCategory = 'Tutti';
  String _searchQuery = '';

  final List<String> _categories = ['Tutti', 'Permesso', 'Cittadinanza', 'Lavoro', 'SPID', 'Sanità', 'ISEE', 'Altro'];

  final List<Domanda> _domande = [
    Domanda(id: '1', titolo: 'Quanto tempo ci vuole per il rinnovo del permesso?', descrizione: 'Ho fatto domanda di rinnovo 3 mesi fa tramite Poste Italiane. Il mio permesso scade tra 2 settimane. Qualcuno sa quanto tempo ci vuole in media?', autore: 'Marco R.', categoria: 'Permesso', dataCreazione: DateTime.now().subtract(const Duration(hours: 2)), voti: 15, risposteCount: 8, isNew: true, risposte: [
      Risposta(id: 'r1', autore: 'Anna B.', testo: 'Io ho aspettato circa 60 giorni per la convocazione. Il cedolino postale ti copre nel frattempo.', data: DateTime.now().subtract(const Duration(hours: 1)), voti: 12),
      Risposta(id: 'r2', autore: 'Said K.', testo: 'Dipende dalla Questura. A Milano ci vogliono 3-4 mesi, a Roma anche 6 mesi.', data: DateTime.now().subtract(const Duration(minutes: 45)), voti: 8),
      Risposta(id: 'r3', autore: 'Luigi P.', testo: 'Controlla sul portale immigrazione con il tuo numero di pratica.', data: DateTime.now().subtract(const Duration(minutes: 30)), voti: 5),
    ]),
    Domanda(id: '2', titolo: 'Documenti per cittadinanza per matrimonio?', descrizione: 'Sono sposata con un italiano da 2 anni e viviamo in Italia. Quali documenti devo preparare?', autore: 'Fatima A.', categoria: 'Cittadinanza', dataCreazione: DateTime.now().subtract(const Duration(hours: 5)), voti: 22, risposteCount: 12, isNew: true, risposte: [
      Risposta(id: 'r4', autore: 'Avv. Rossi', testo: 'Servono: certificato di matrimonio, B1 italiano, casellario giudiziario del paese di origine, marca da bollo €16, contributo €250.', data: DateTime.now().subtract(const Duration(hours: 4)), voti: 20),
    ]),
    Domanda(id: '3', titolo: 'Come creare SPID senza carta d\'identità italiana?', descrizione: 'Sono extracomunitario con permesso di soggiorno. Posso creare SPID usando solo il permesso e il passaporto?', autore: 'Ahmed M.', categoria: 'SPID', dataCreazione: DateTime.now().subtract(const Duration(days: 1)), voti: 34, risposteCount: 15, risposte: [
      Risposta(id: 'r6', autore: 'Paolo V.', testo: 'Sì! Con Poste Italiane puoi usare il permesso di soggiorno.', data: DateTime.now().subtract(const Duration(hours: 20)), voti: 30),
    ]),
    Domanda(id: '4', titolo: 'Iscrizione ASL per neoarrivati?', descrizione: 'Sono arrivato in Italia da 1 mese con visto lavoro. Come faccio a iscrivermi alla ASL?', autore: 'Chen W.', categoria: 'Sanità', dataCreazione: DateTime.now().subtract(const Duration(days: 1, hours: 6)), voti: 18, risposteCount: 6, risposte: []),
    Domanda(id: '5', titolo: 'ISEE per stranieri: serve il reddito del paese di origine?', descrizione: 'Devo fare l\'ISEE per richiedere l\'ADI. Devo dichiarare anche i redditi del mio paese di origine?', autore: 'Priya S.', categoria: 'ISEE', dataCreazione: DateTime.now().subtract(const Duration(days: 2)), voti: 27, risposteCount: 9, risposte: []),
    Domanda(id: '6', titolo: 'Nulla osta lavoro: quanto costa?', descrizione: 'Il mio datore di lavoro deve richiedere il nulla osta. Quanto costa il contributo?', autore: 'Omar H.', categoria: 'Lavoro', dataCreazione: DateTime.now().subtract(const Duration(days: 3)), voti: 11, risposteCount: 4, risposte: []),
    Domanda(id: '7', titolo: 'Ricongiungimento familiare: reddito minimo?', descrizione: 'Voglio far venire mia moglie e mio figlio. Qual è il reddito minimo?', autore: 'Ali D.', categoria: 'Permesso', dataCreazione: DateTime.now().subtract(const Duration(days: 4)), voti: 19, risposteCount: 7, risposte: []),
  ];

  List<Domanda> get _filtered {
    return _domande.where((d) {
      final matchCat = _selectedCategory == 'Tutti' || d.categoria == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty || d.titolo.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m fa';
    if (diff.inHours < 24) return '${diff.inHours}h fa';
    return '${diff.inDays}g fa';
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Permesso': return AppColors.iconBlue;
      case 'Cittadinanza': return AppColors.iconOrange;
      case 'Lavoro': return AppColors.iconGreen;
      case 'SPID': return AppColors.primary;
      case 'Sanità': return const Color(0xFFE91E63);
      case 'ISEE': return AppColors.iconPurple;
      default: return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 14),
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.forum_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            const Text('Domande', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.badge, borderRadius: BorderRadius.circular(12)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, size: 6, color: Colors.white),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          // Search
          Container(
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Cerca una domanda...', hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.white54), border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ]),
      ),
      // Category chips
      SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final sel = cat == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE0E0E0)),
                ),
                child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textMedium)),
              ),
            );
          },
        ),
      ),
      // List
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filtered.length,
          itemBuilder: (_, i) {
            final d = _filtered[i];
            return _buildDomandaCard(d);
          },
        ),
      ),
    ]);
  }

  Widget _buildDomandaCard(Domanda d) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DomandaDetailScreen(domanda: d))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 2))],
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _catColor(d.categoria).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(d.categoria, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _catColor(d.categoria))),
            ),
            const SizedBox(width: 8),
            Text(_timeAgo(d.dataCreazione), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            const Spacer(),
            if (d.isNew) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.badge, borderRadius: BorderRadius.circular(6)),
              child: const Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(d.titolo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(d.descrizione, style: const TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(children: [
            CircleAvatar(radius: 14, backgroundColor: _catColor(d.categoria).withValues(alpha: 0.15),
              child: Text(d.autore[0], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _catColor(d.categoria)))),
            const SizedBox(width: 8),
            Text(d.autore, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const Spacer(),
            Icon(Icons.thumb_up_outlined, size: 14, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text('${d.voti}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
            const SizedBox(width: 12),
            Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text('${d.risposteCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
          ]),
        ]),
      ),
    );
  }
}
