import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_links.dart';
import '../../config/constants.dart';
import '../../core/services/ai_consent_service.dart';
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
          SliverToBoxAdapter(child: _buildDataPolicyCard(context)),
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
          Text(
            Platform.isIOS ? 'Smart Bonus Italia' : 'Bonus Italia',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text('App informativa indipendente', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
          const SizedBox(height: 4),
          Text('Versione 1.0.13', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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

  Widget _buildDataPolicyCard(BuildContext context) {
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
              Text('PRIVACY E DATI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'COSA NON FACCIAMO:\n'
            '• Nessuna registrazione, login o account\n'
            '• Nessuna raccolta automatica di dati personali\n'
            '• I tuoi dati di compilazione moduli restano sul dispositivo\n'
            '• Calcolatori (ISEE, IRPEF, NASpI, IMU…) funzionano localmente\n\n'
            'COSA SUCCEDE QUANDO USI L\'AI:\n'
            '• Quando usi la chat AI o l\'analisi documenti, il testo o i file '
            'che invii vengono trasmessi a Google Gemini (Google LLC, USA) '
            'tramite il nostro proxy su Cloudflare Workers.\n'
            '• I dati sono inviati SOLO quando tu lo richiedi, mai automaticamente.\n'
            '• Non inviare mai codice fiscale, dati bancari, password o numeri di documento.',
            style: TextStyle(fontSize: 13, color: Colors.green.shade900, height: 1.6),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse(AppLinks.privacyPolicy),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Leggi la Privacy Policy completa',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.open_in_new, size: 14, color: Colors.green.shade700),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _confirmRevokeAiConsent(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.smart_toy_outlined, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Revoca consenso uso AI',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: Colors.green.shade700),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse('mailto:${AppLinks.supportEmail}?subject=Supporto%20Smart%20Bonus%20Italia'),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Contatta il supporto (${AppLinks.supportEmail})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.open_in_new, size: 14, color: Colors.green.shade700),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRevokeAiConsent(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revocare consenso AI?'),
        content: const Text(
          'Se revochi il consenso, dovrai accettarlo di nuovo la prossima volta '
          'che usi la chat AI. Vuoi continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoca'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AiConsentService.revoke();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consenso AI revocato.')),
      );
    }
  }
}
