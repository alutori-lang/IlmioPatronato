import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../compilatore/compilatore_screen.dart';
import '../prenotazioni/prenotazioni_screen.dart';
import '../simulatore/simulatore_screen.dart';
import '../simulatore/cittadinanza_screen.dart';
import '../simulatore/costo_permesso_screen.dart';
import '../simulatore/isee_screen.dart';
import '../simulatore/irpef730_screen.dart';
import '../simulatore/codice_fiscale_screen.dart';
import '../simulatore/stipendio_netto_screen.dart';
import '../simulatore/naspi_screen.dart';
import 'documento_wallet_screen.dart';
import 'quiz_cittadinanza_screen.dart';
import 'cv_europass_screen.dart';
import 'busta_paga_screen.dart';
import 'delega_screen.dart';
import 'confronto_lavoro_screen.dart';

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

        // ── TOP TOOLS (più usati) ──
        SliverToBoxAdapter(child: _sectionTitle('Più Usati')),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _TopTool(icon: Icons.calculate, label: 'ISEE', color: Colors.purple.shade700, onTap: () => _push(context, const IseeScreen())),
                _TopTool(icon: Icons.receipt_long, label: '730', color: Colors.teal.shade700, onTap: () => _push(context, const Irpef730Screen())),
                _TopTool(icon: Icons.badge, label: 'Cod. Fiscale', color: Colors.indigo, onTap: () => _push(context, const CodiceFiscaleScreen())),
                _TopTool(icon: Icons.payments, label: 'Stipendio', color: Colors.green.shade800, onTap: () => _push(context, const StipendioNettoScreen())),
                _TopTool(icon: Icons.edit_document, label: 'Moduli', color: AppColors.iconBlue, onTap: () => _push(context, const CompilatoreScreen())),
                _TopTool(icon: Icons.calendar_month, label: 'Prenota', color: AppColors.iconOrange, onTap: () => _push(context, const PrenotazioniScreen())),
              ],
            ),
          ),
        ),

        // ── CALCOLATORI ──
        SliverToBoxAdapter(child: _sectionWithAction('Calcolatori', '14 totali', () => _push(context, const SimulatoreScreen()))),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9,
            ),
            delegate: SliverChildListDelegate([
              _GridTool(icon: Icons.flag, label: 'Cittadinanza', color: Colors.green.shade700, onTap: () => _push(context, const CittadinanzaScreen())),
              _GridTool(icon: Icons.euro, label: 'Costo Permesso', color: AppColors.primary, onTap: () => _push(context, const CostoPermessoScreen())),
              _GridTool(icon: Icons.calculate, label: 'ISEE', color: Colors.purple.shade700, onTap: () => _push(context, const IseeScreen())),
              _GridTool(icon: Icons.receipt_long, label: '730 / IRPEF', color: Colors.teal.shade700, onTap: () => _push(context, const Irpef730Screen())),
              _GridTool(icon: Icons.badge, label: 'Cod. Fiscale', color: Colors.indigo, onTap: () => _push(context, const CodiceFiscaleScreen())),
              _GridTool(icon: Icons.payments, label: 'Stipendio', color: Colors.green.shade800, onTap: () => _push(context, const StipendioNettoScreen())),
              _GridTool(icon: Icons.work_off, label: 'NASpI', color: Colors.red.shade700, onTap: () => _push(context, const NaspiScreen())),
              _GridTool(icon: Icons.more_horiz, label: 'Tutti (14)', color: Colors.grey.shade600, onTap: () => _push(context, const SimulatoreScreen())),
            ]),
          ),
        ),

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
                icon: Icons.receipt, color: Colors.orange.shade700,
                title: 'Busta Paga Spiegata', desc: 'Ogni voce spiegata in modo semplice',
                onTap: () => _push(context, const BustaPagaScreen()),
              ),
              _ToolCard(
                icon: Icons.assignment, color: Colors.teal.shade700,
                title: 'Generatore Delega', desc: 'Crea delega formale in PDF',
                badge: 'PDF',
                onTap: () => _push(context, const DelegaScreen()),
              ),
              _ToolCard(
                icon: Icons.compare_arrows, color: Colors.red.shade700,
                title: 'Confronto Offerte', desc: 'Confronta 2 RAL e scopri quale conviene',
                onTap: () => _push(context, const ConfrontoLavoroScreen()),
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
                icon: Icons.edit_document, color: AppColors.iconBlue,
                title: 'Compila Moduli', desc: '6 moduli PDF pronti per la pratica',
                badge: '6 PDF',
                onTap: () => _push(context, const CompilatoreScreen()),
              ),
              _ToolCard(
                icon: Icons.calendar_month, color: AppColors.iconOrange,
                title: 'Prenotazioni Uffici', desc: '8 uffici - Questura, INPS, Comune...',
                badge: '8',
                onTap: () => _push(context, const PrenotazioniScreen()),
              ),
            ]),
          ),
        ),
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
                Text('Calcolatori, generatori e servizi', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
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

  Widget _sectionWithAction(String title, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Text(action, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── TOP TOOL (horizontal scroll) ──
class _TopTool extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TopTool({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── GRID TOOL (3 columns) ──
class _GridTool extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GridTool({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
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
