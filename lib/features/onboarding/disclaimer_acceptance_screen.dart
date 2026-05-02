import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../core/widgets/disclaimer_widget.dart';

class DisclaimerAcceptanceScreen extends StatefulWidget {
  final VoidCallback onAccepted;
  const DisclaimerAcceptanceScreen({super.key, required this.onAccepted});

  static const prefsKey = 'disclaimer_accepted_v1';

  static Future<bool> alreadyAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  @override
  State<DisclaimerAcceptanceScreen> createState() => _DisclaimerAcceptanceScreenState();
}

class _DisclaimerAcceptanceScreenState extends State<DisclaimerAcceptanceScreen> {
  bool _checkboxAccepted = false;

  Future<void> _accept() async {
    if (!_checkboxAccepted) return;
    await DisclaimerAcceptanceScreen.markAccepted();
    if (!mounted) return;
    widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: 20, bottom: 16, left: 20, right: 20,
              ),
              decoration: const BoxDecoration(gradient: AppColors.headerGradient),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
                  const SizedBox(height: 8),
                  const Text(
                    'INFORMAZIONI IMPORTANTI',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leggi prima di usare l\'app',
                    style: TextStyle(color: Colors.amber.shade200, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBigDisclaimer(),
                    const SizedBox(height: 16),
                    _buildBlock(
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                      title: 'Cosa NON è questa app',
                      bullets: const [
                        'NON è un\'app del Governo italiano',
                        'NON è un Patronato o CAF autorizzato',
                        'NON elabora pratiche ufficiali',
                        'NON invia dati a INPS, Agenzia delle Entrate o altri enti',
                        'NON sostituisce la consulenza di un professionista',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildBlock(
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      title: 'Cosa è questa app',
                      bullets: const [
                        'App informativa indipendente',
                        'Riassume informazioni pubbliche da fonti ufficiali',
                        'Fornisce calcolatori che danno solo STIME',
                        'Aiuta a capire procedure e documenti',
                        'Mostra i link ai siti ufficiali per ogni informazione',
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => DisclaimerBox.showSourcesDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.menu_book, color: Colors.blue.shade700, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vedi tutte le ${DisclaimerBox.officialSources.length} fonti ufficiali',
                                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                  Text(
                                    'INPS, Agenzia Entrate, Ministeri, ecc.',
                                    style: TextStyle(color: Colors.blue.shade700, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.blue.shade700, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _checkboxAccepted,
                          onChanged: (v) => setState(() => _checkboxAccepted = v ?? false),
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _checkboxAccepted = !_checkboxAccepted),
                            child: const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'Ho letto e capito che questa app è solo informativa, '
                                'non è un servizio del Governo italiano e non sostituisce '
                                'la consulenza di un Patronato o CAF.',
                                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _checkboxAccepted ? _accept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('CONTINUA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade400, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.amber.shade800, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'APP INFORMATIVA INDIPENDENTE',
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Questa applicazione NON è affiliata, approvata o sponsorizzata da alcun ente del Governo italiano '
            '(INPS, Agenzia delle Entrate, Ministeri, Patronati, CAF, Comuni). '
            'Le informazioni fornite provengono esclusivamente da fonti pubbliche ufficiali e hanno solo scopo informativo. '
            'I calcoli sono STIME senza valore legale.',
            style: TextStyle(color: Colors.amber.shade900, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> bullets,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ...bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
                Expanded(child: Text(b, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
