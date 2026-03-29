import 'package:flutter/material.dart';
import '../../config/constants.dart';
import 'documento_wallet_screen.dart';
import 'quiz_cittadinanza_screen.dart';
import 'cv_europass_screen.dart';
import 'busta_paga_screen.dart';
import 'delega_screen.dart';
import 'confronto_lavoro_screen.dart';

class StrumentiScreen extends StatelessWidget {
  const StrumentiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildSubtitle()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StrumentoCard(
                  icon: Icons.folder_special,
                  color: Colors.blue.shade700,
                  title: 'Documento Wallet',
                  description: 'Salva documenti con alert scadenza',
                  badge: 'NUOVO',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentoWalletScreen())),
                ),
                const SizedBox(height: 12),
                _StrumentoCard(
                  icon: Icons.quiz,
                  color: Colors.green.shade700,
                  title: 'Quiz Cittadinanza',
                  description: '218 domande per il test B1 + cultura',
                  badge: '218 Q',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizCittadinanzaScreen())),
                ),
                const SizedBox(height: 12),
                _StrumentoCard(
                  icon: Icons.description,
                  color: Colors.purple.shade700,
                  title: 'Generatore CV Europass',
                  description: 'Carica CV + foto, AI suggerisce esperienze',
                  badge: 'AI',
                  badgeColor: const Color(0xFF4CAF50),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CvEuropassScreen())),
                ),
                const SizedBox(height: 12),
                _StrumentoCard(
                  icon: Icons.receipt,
                  color: Colors.orange.shade700,
                  title: 'Busta Paga Spiegata',
                  description: 'Carica foto busta paga, AI analizza tutto',
                  badge: 'AI',
                  badgeColor: const Color(0xFF4CAF50),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BustaPagaScreen())),
                ),
                const SizedBox(height: 12),
                _StrumentoCard(
                  icon: Icons.assignment,
                  color: Colors.teal.shade700,
                  title: 'Generatore Delega',
                  description: 'Scansiona documento, AI compila la delega',
                  badge: 'AI',
                  badgeColor: const Color(0xFF4CAF50),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DelegaScreen())),
                ),
                const SizedBox(height: 12),
                _StrumentoCard(
                  icon: Icons.compare_arrows,
                  color: Colors.red.shade700,
                  title: 'Confronto Offerte Lavoro',
                  description: 'Carica contratti, AI confronta le offerte',
                  badge: 'AI',
                  badgeColor: const Color(0xFF4CAF50),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfrontoLavoroScreen())),
                ),
              ]),
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
                Text('Tools e utilità avanzate', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        'Strumenti esclusivi per la vita in Italia',
        style: TextStyle(fontSize: 14, color: AppColors.textMedium, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _StrumentoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _StrumentoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? color).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(badge!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: badgeColor ?? color)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textMedium), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }
}
