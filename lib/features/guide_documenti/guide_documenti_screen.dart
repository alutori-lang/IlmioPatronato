import 'package:flutter/material.dart';
import '../../config/constants.dart';
import 'guide_documenti_data.dart';
import 'guida_categoria_screen.dart';

class GuideDocumentiScreen extends StatelessWidget {
  const GuideDocumentiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildIntro(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: guideCategorie.length,
                itemBuilder: (_, i) {
                  final cat = guideCategorie[i];
                  final count = schedePerCategoria(cat.id).length;
                  return _CategoriaCard(
                    categoria: cat,
                    schedeCount: count,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuidaCategoriaScreen(categoriaId: cat.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Text('🇮🇹', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        const Text('Guida Documenti',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dalla richiesta di asilo alla cittadinanza. Ogni scheda ti spiega requisiti, documenti, procedura e costi. Disponibile in 14 lingue.',
              style: TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final GuidaCategoria categoria;
  final int schedeCount;
  final VoidCallback onTap;

  const _CategoriaCard({
    required this.categoria,
    required this.schedeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(categoria.color);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 2))],
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(categoria.emoji, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(height: 10),
              Text(
                categoria.titolo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$schedeCount sched${schedeCount == 1 ? 'a' : 'e'}',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
