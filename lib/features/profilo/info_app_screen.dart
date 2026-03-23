import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../core/widgets/disclaimer_widget.dart';

class InfoAppScreen extends StatelessWidget {
  const InfoAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildAppInfo()),
          SliverToBoxAdapter(child: _buildDisclaimerCard()),
          SliverToBoxAdapter(child: _buildSourcesSection(context)),
          SliverToBoxAdapter(child: _buildLegislationSection()),
          SliverToBoxAdapter(child: _buildDataPolicyCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Info App', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 1),
                Text('Disclaimer, fonti e informazioni legali', style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          const Text('Il Mio Patronato', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Il Patronato in Tasca', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
          const SizedBox(height: 4),
          Text('Versione 1.0.1', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text('DISCLAIMER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.red.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Questa app NON è affiliata, approvata, autorizzata o rappresentativa di alcun ente governativo italiano o istituzione pubblica.\n\n'
            'È uno strumento informativo indipendente che raccoglie informazioni pubblicamente disponibili per aiutare gli utenti a orientarsi nei servizi pubblici italiani.\n\n'
            'Questa app:\n'
            '• NON fornisce servizi governativi\n'
            '• NON elabora pratiche o domande ufficiali\n'
            '• NON sostituisce la consulenza di un Patronato, CAF o professionista abilitato\n\n'
            'Tutti i calcoli (ISEE, IRPEF, NASpI, IMU, TFR, ecc.) sono STIME a scopo orientativo. Per i calcoli ufficiali, rivolgersi agli enti competenti.',
            style: TextStyle(fontSize: 13, color: Colors.red.shade900, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.language, size: 20, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Text('TUTTE LE FONTI UFFICIALI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tutte le informazioni contenute nell\'app provengono esclusivamente dalle seguenti fonti pubbliche:',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
          ),
          const SizedBox(height: 12),
          ...DisclaimerBox.officialSources.map((s) => _sourceRow(s['name']!, s['url']!)),
        ],
      ),
    );
  }

  Widget _sourceRow(String name, String url) {
    return InkWell(
      onTap: () async {
        try {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } catch (_) {}
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(url, style: TextStyle(fontSize: 10, color: Colors.blue.shade600)),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 12, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildLegislationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel, size: 20, color: Colors.brown),
              SizedBox(width: 8),
              Text('RIFERIMENTI NORMATIVI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.brown)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'I calcoli e le informazioni si basano sulla seguente legislazione italiana:',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
          ),
          const SizedBox(height: 12),
          ...DisclaimerBox.legislationRefs.map((ref) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6, height: 6, margin: const EdgeInsets.only(top: 5),
                  decoration: const BoxDecoration(color: Colors.brown, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(ref, style: const TextStyle(fontSize: 12, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDataPolicyCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, size: 20, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text('PRIVACY E SICUREZZA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Nessun dato personale viene raccolto o trasmesso\n'
            '• Tutti i calcoli avvengono localmente sul dispositivo\n'
            '• L\'app funziona anche offline\n'
            '• Nessuna registrazione richiesta',
            style: TextStyle(fontSize: 13, color: Colors.green.shade900, height: 1.6),
          ),
        ],
      ),
    );
  }
}
