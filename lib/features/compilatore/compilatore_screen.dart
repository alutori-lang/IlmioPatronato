import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/constants.dart';
import 'moduli_data.dart';
import 'wizard_screen.dart';

// ---------------------------------------------------------------------------
// Schermata principale del Compilatore Moduli
// ---------------------------------------------------------------------------
class CompilatoreScreen extends StatelessWidget {
  const CompilatoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final moduli = ModuliDatabase.tutti;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildSubtitle()),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildModuloCard(context, moduli[index]),
              childCount: moduli.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Header con gradiente
  // -----------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          const Icon(Icons.edit_document, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(
            'Compilatore Moduli',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Sottotitolo descrittivo
  // -----------------------------------------------------------------------
  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Text(
        'Compila i moduli ufficiali e genera il PDF pronto da stampare',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textMedium,
          height: 1.4,
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Card di ogni modulo
  // -----------------------------------------------------------------------
  Widget _buildModuloCard(BuildContext context, Modulo modulo) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WizardScreen(modulo: modulo)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icona colorata
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: modulo.colore.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(modulo.icona, color: modulo.colore, size: 24),
            ),
            const SizedBox(width: 14),
            // Testi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modulo.titolo,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    modulo.descrizione,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF888888),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    modulo.nomeUfficiale,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.navInactive, size: 20),
          ],
        ),
      ),
    );
  }
}
