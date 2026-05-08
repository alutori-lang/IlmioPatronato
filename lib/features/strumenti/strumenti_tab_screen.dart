import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../prenotazioni/prenotazioni_screen.dart';
import 'documento_wallet_screen.dart';
import 'quiz_cittadinanza_screen.dart';
import 'cv_europass_screen.dart';
import 'delega_screen.dart';

class StrumentiTabScreen extends StatelessWidget {
  const StrumentiTabScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),

        // ── GENERATORI & TOOLS ──
        SliverToBoxAdapter(child: _sectionTitle('Generatori & Tools')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ToolCard(
                icon: Icons.folder_special, color: Colors.blue.shade700,
                title: 'Documento Wallet', desc: 'Salva documenti con alert scadenza',
                badge: 'NUOVO',
                onTap: () => _push(context, const DocumentoWalletScreen()),
              ),
              _ToolCard(
                icon: Icons.quiz, color: Colors.green.shade700,
                title: 'Quiz Cittadinanza', desc: '218 domande per il test B1 + cultura',
                badge: '218 Q',
                onTap: () => _push(context, const QuizCittadinanzaScreen()),
              ),
              _ToolCard(
                icon: Icons.description, color: Colors.purple.shade700,
                title: 'CV Europass', desc: 'Crea CV professionale in PDF',
                badge: 'PDF',
                onTap: () => _push(context, const CvEuropassScreen()),
              ),
              _ToolCard(
                icon: Icons.assignment, color: Colors.teal.shade700,
                title: 'Generatore Delega', desc: 'Carica documenti e genera delega PDF',
                badge: 'AI',
                onTap: () => _push(context, const DelegaScreen()),
              ),
            ]),
          ),
        ),

        // ── SERVIZI ──
        SliverToBoxAdapter(child: _sectionTitle('Servizi')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ToolCard(
                icon: Icons.calendar_month, color: AppColors.iconOrange,
                title: 'Prenotazioni Uffici', desc: '8 uffici - Questura, INPS, Comune...',
                badge: '8',
                onTap: () => _push(context, const PrenotazioniScreen()),
              ),
            ]),
          ),
        ),

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
            child: const Icon(Icons.build_circle, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STRUMENTI', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 1),
                Text('Generatori, tools e servizi', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    );
  }
}

// ── TOOL CARD (list item) ──
class _ToolCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final String? badge;
  final VoidCallback onTap;

  const _ToolCard({required this.icon, required this.color, required this.title, required this.desc, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(badge!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textMedium), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}
