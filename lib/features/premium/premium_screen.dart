import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/constants.dart';
import '../../core/services/premium_service.dart';

/// Shows the Premium PRO offer as a modal bottom sheet.
/// [reason] is an optional context line (e.g. shown when the AI free quota
/// runs out) displayed above the benefits.
Future<void> showPremiumSheet(BuildContext context, {String? reason}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PremiumSheet(reason: reason),
  );
}

class _PremiumSheet extends StatelessWidget {
  final String? reason;
  const _PremiumSheet({this.reason});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scroll,
          child: PremiumContent(reason: reason),
        ),
      ),
    );
  }
}

/// Full-page version (pushable as a route too).
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Premium PRO', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: const SingleChildScrollView(child: PremiumContent()),
    );
  }
}

class PremiumContent extends StatelessWidget {
  final String? reason;
  const PremiumContent({super.key, this.reason});

  static const _benefits = <(IconData, String, String)>[
    (Icons.block, 'Nessuna pubblicità', 'Niente banner, niente schermate intere, niente video. Mai più.'),
    (Icons.bolt, 'Niente video per usare i calcolatori', 'Apri ISEE, NASpI, stipendio netto… all\'istante, senza attese.'),
    (Icons.smart_toy, 'Assistente AI illimitato', 'Fai tutte le domande che vuoi, senza limite giornaliero.'),
    (Icons.picture_as_pdf, 'PDF e documenti senza interruzioni', 'CV Europass, deleghe e moduli scaricabili al volo.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PremiumService(),
      builder: (context, _) {
        final svc = PremiumService();
        final owned = svc.isPremium;
        final price = svc.priceLabel ?? '—';
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.amber, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Premium PRO',
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          Text('Pagamento unico, tuo per sempre',
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (reason != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.serviceOrangeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AppColors.iconOrange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(reason!,
                        style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 18),
              ..._benefits.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.serviceBlueLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(b.$1, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.$2,
                                  style: GoogleFonts.inter(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                              Text(b.$3,
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: AppColors.textMedium)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              if (owned)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.serviceGreenLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.iconGreen),
                      const SizedBox(width: 8),
                      Text('Sei Premium PRO ✓',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800, color: AppColors.iconGreen, fontSize: 16)),
                    ],
                  ),
                )
              else ...[
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: svc.product == null ? null : () => svc.buy(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      svc.product == null
                          ? 'Non disponibile al momento'
                          : 'Sblocca Premium PRO — $price',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => svc.restore(),
                  child: Text('Ripristina acquisti',
                      style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
                Text(
                  'Pagamento una tantum gestito da Google Play / App Store. Nessun abbonamento.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
