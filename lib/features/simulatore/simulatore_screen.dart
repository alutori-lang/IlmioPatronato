import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/services/ad_service.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/disclaimer_strip.dart';
import 'adi_screen.dart';
import 'isee_screen.dart';
import 'irpef730_screen.dart';
import 'codice_fiscale_screen.dart';
import 'stipendio_netto_screen.dart';
import 'assegno_unico_screen.dart';
import 'naspi_screen.dart';
import 'tfr_screen.dart';
import 'bollo_auto_screen.dart';

class SimulatoreScreen extends StatelessWidget {
  const SimulatoreScreen({super.key});

  void _openCalc(BuildContext context, Widget screen) {
    AdService().showAdEveryOther(
      key: 'simulatore',
      navigate: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const BannerAdWidget(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          const SliverToBoxAdapter(child: DisclaimerStrip()),
          SliverToBoxAdapter(child: _buildSubtitle()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── CON FOTO AI (in cima) ──
                _SimulatoreCard(
                  icon: Icons.payments,
                  color: Colors.green.shade800,
                  title: 'Stipendio Netto',
                  description: 'Da lordo a netto con INPS e IRPEF',
                  onTap: () => _openCalc(context, const StipendioNettoScreen()),
                ),
                const SizedBox(height: 12),
                _SimulatoreCard(
                  icon: Icons.work_off,
                  color: Colors.red.shade700,
                  title: 'Calcolo NASpI',
                  description: 'Indennità di disoccupazione e durata',
                  onTap: () => _openCalc(context, const NaspiScreen()),
                ),
                const SizedBox(height: 12),
                _SimulatoreCard(
                  icon: Icons.savings,
                  color: Colors.amber.shade800,
                  title: 'Calcolo TFR',
                  description: 'Stima la tua liquidazione fine rapporto',
                  onTap: () => _openCalc(context, const TfrScreen()),
                ),
                const SizedBox(height: 12),
                _SimulatoreCard(
                  icon: Icons.directions_car,
                  color: Colors.cyan.shade700,
                  title: 'Bollo Auto',
                  description: 'Calcola la tassa automobilistica',
                  onTap: () => _openCalc(context, const BolloAutoScreen()),
                ),
                const SizedBox(height: 12),
                _SimulatoreCard(
                  icon: Icons.account_balance_wallet,
                  color: Colors.orange.shade700,
                  title: 'Verifica ADI',
                  description:
                      "Scopri se hai diritto all'Assegno di Inclusione",
                  onTap: () => _openCalc(context, const AdiScreen()),
                ),
                const SizedBox(height: 12),
                _SimulatoreCard(
                  icon: Icons.calculate,
                  color: Colors.purple.shade700,
                  title: 'Calcolo ISEE',
                  description: 'Simula il tuo ISEE con la formula ufficiale',
                  onTap: () => _openCalc(context, const IseeScreen()),
                ),
                const SizedBox(height: 12),
                _SimulatoreCard(
                  icon: Icons.receipt_long,
                  color: Colors.teal.shade700,
                  title: 'Calcolo 730 / IRPEF',
                  description: 'Calcola tasse, scaglioni e reddito netto',
                  onTap: () => _openCalc(context, const Irpef730Screen()),
                ),
                const SizedBox(height: 12),
                // ── MANUALI (in basso) ──
                _SimulatoreCard(
                  icon: Icons.child_care,
                  color: Colors.pink.shade600,
                  title: 'Assegno Unico Figli',
                  description: 'Calcola importo mensile per i tuoi figli',
                  onTap: () => _openCalc(context, const AssegnoUnicoScreen()),
                ),
                const SizedBox(height: 12),
                _SimulatoreCard(
                  icon: Icons.badge,
                  color: Colors.indigo,
                  title: 'Codice Fiscale',
                  description: 'Genera il tuo codice fiscale italiano',
                  onTap: () => _openCalc(context, const CodiceFiscaleScreen()),
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
        left: 20,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.calculate_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulatore Pratica',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Calcola tempi, costi e requisiti',
                  style: TextStyle(
                    color: AppColors.textSubtitle,
                    fontSize: 11,
                  ),
                ),
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
        'Calcola tempi, costi e requisiti per le tue pratiche',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textMedium,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SimulatoreCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SimulatoreCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.03),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: color.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
