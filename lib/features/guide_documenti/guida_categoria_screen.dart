import 'package:flutter/material.dart';
import '../../config/constants.dart';
import 'guida_dettaglio_screen.dart';
import 'guide_documenti_data.dart';

class GuidaCategoriaScreen extends StatelessWidget {
  final String categoriaId;
  const GuidaCategoriaScreen({super.key, required this.categoriaId});

  @override
  Widget build(BuildContext context) {
    final categoria = categoriaById(categoriaId);
    if (categoria == null) {
      return const Scaffold(body: Center(child: Text('Categoria non trovata')));
    }
    final color = Color(categoria.color);
    final schede = schedePerCategoria(categoriaId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, categoria, color),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: schede.length,
              itemBuilder: (_, i) => _SchedaCard(
                scheda: schede[i],
                color: color,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuidaDettaglioScreen(schedaId: schede[i].id),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GuidaCategoria cat, Color color) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8, right: 20, bottom: 20,
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
            Text(cat.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(cat.titolo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SchedaCard extends StatelessWidget {
  final GuidaScheda scheda;
  final Color color;
  final VoidCallback onTap;

  const _SchedaCard({
    required this.scheda,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(scheda.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scheda.titolo,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(scheda.descrizione,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(scheda.ente,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ]),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
            ]),
          ),
        ),
      ),
    );
  }
}
