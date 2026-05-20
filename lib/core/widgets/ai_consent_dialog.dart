import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_links.dart';
import '../services/ai_consent_service.dart';

class AiConsentDialog extends StatefulWidget {
  const AiConsentDialog({super.key});

  static Future<bool> ensureConsent(BuildContext context) async {
    if (await AiConsentService.hasConsented()) return true;
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiConsentDialog(),
    );
    return result == true;
  }

  @override
  State<AiConsentDialog> createState() => _AiConsentDialogState();
}

class _AiConsentDialogState extends State<AiConsentDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.smart_toy_outlined, color: Color(0xFF1976D2)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Consenso uso assistente AI',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
      ]),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Per usare l\'assistente AI devi sapere come funziona:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _row(Icons.send_outlined,
                  'COSA viene inviato: i messaggi che scrivi nella chat e le immagini che alleghi.'),
              _row(Icons.public,
                  'A CHI: Google LLC (servizio Google Gemini, server in USA), attraverso un nostro proxy su Cloudflare Workers.'),
              _row(Icons.history_toggle_off,
                  'PER QUANTO: il provider può conservare i dati come da sua privacy policy.'),
              _row(Icons.lock_outline,
                  'BASE GIURIDICA: consenso esplicito dell\'utente (GDPR art. 6.1.a).'),
              _row(Icons.warning_amber_rounded,
                  'NON inviare MAI dati sensibili: codice fiscale, dati bancari, numeri di documento, password, dati sanitari.'),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse(AppLinks.privacyPolicy),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text(
                  'Leggi la Privacy Policy completa →',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'Ho letto e accetto l\'invio dei miei messaggi al servizio AI di Google.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Rifiuta'),
        ),
        FilledButton(
          onPressed: _agreed
              ? () async {
                  await AiConsentService.setConsented(true);
                  if (context.mounted) Navigator.of(context).pop(true);
                }
              : null,
          child: const Text('Accetta e continua'),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
