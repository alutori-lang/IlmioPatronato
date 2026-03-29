import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared disclaimer box used throughout the app.
/// Shows a compact version by default; tapping "Vedi tutte le fonti" opens the full sources dialog.
class DisclaimerBox extends StatelessWidget {
  const DisclaimerBox({super.key});

  static const List<Map<String, String>> officialSources = [
    {'name': 'INPS (Previdenza Sociale)', 'url': 'https://www.inps.it'},
    {'name': 'Agenzia delle Entrate', 'url': 'https://www.agenziaentrate.gov.it'},
    {'name': 'Ministero dell\'Interno', 'url': 'https://www.interno.gov.it'},
    {'name': 'Portale Immigrazione', 'url': 'https://www.portaleimmigrazione.it'},
    {'name': 'Ministero del Lavoro', 'url': 'https://www.lavoro.gov.it'},
    {'name': 'MEF (Economia e Finanze)', 'url': 'https://www.mef.gov.it'},
    {'name': 'Governo Italiano', 'url': 'https://www.governo.it'},
    {'name': 'Gazzetta Ufficiale', 'url': 'https://www.gazzettaufficiale.it'},
    {'name': 'Normattiva (Leggi e Decreti)', 'url': 'https://www.normattiva.it'},
    {'name': 'INAIL (Assicurazione Lavoro)', 'url': 'https://www.inail.it'},
    {'name': 'Ministero della Salute', 'url': 'https://www.salute.gov.it'},
    {'name': 'MIUR (Istruzione)', 'url': 'https://www.miur.gov.it'},
    {'name': 'MISE (Sviluppo Economico)', 'url': 'https://www.mise.gov.it'},
    {'name': 'ARERA (Energia)', 'url': 'https://www.arera.it'},
    {'name': 'Polizia di Stato', 'url': 'https://www.poliziadistato.it'},
    {'name': 'ACI (Automobile Club)', 'url': 'https://www.aci.it'},
    {'name': 'MIT (Infrastrutture e Trasporti)', 'url': 'https://www.mit.gov.it'},
    {'name': 'ANPAL / Garanzia Giovani', 'url': 'https://garanziagiovani.anpal.gov.it'},
    {'name': 'CONSAP (Prima Casa)', 'url': 'https://www.consap.it'},
    {'name': 'Servizio Civile', 'url': 'https://www.scelgoilserviziocivile.gov.it'},
    {'name': 'SPID (Identità Digitale)', 'url': 'https://www.spid.gov.it'},
    {'name': 'Europass (CV)', 'url': 'https://europass.cedefop.europa.eu'},
  ];

  static const List<String> legislationRefs = [
    'DPCM 159/2013 — Formula ufficiale ISEE',
    'D.Lgs. 286/1998 — Testo Unico Immigrazione',
    'DPR 394/1999 — Regolamento Immigrazione',
    'L. 91/1992 — Legge sulla Cittadinanza',
    'D.Lgs. 150/2015 — NASpI / Disoccupazione',
    'DPR 917/1986 — TUIR (Imposte sui Redditi)',
    'D.Lgs. 196/2003 & GDPR (UE) 2016/679 — Privacy',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DISCLAIMER: Questa app NON è affiliata, approvata o rappresentativa di alcun ente governativo italiano. '
                  'È uno strumento informativo indipendente. Tutte le informazioni provengono da fonti ufficiali pubblicamente accessibili. '
                  'I calcoli sono STIME e non sostituiscono la consulenza di un Patronato o CAF.',
                  style: TextStyle(fontSize: 10, color: Colors.amber.shade900, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => showSourcesDialog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new, size: 12, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  'Vedi tutte le ${officialSources.length} fonti ufficiali →',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void showSourcesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Fonti Ufficiali Utilizzate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tutte le informazioni nell\'app provengono esclusivamente da queste fonti pubbliche.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _sectionHeader('Siti Istituzionali'),
                  ...officialSources.map((s) => _sourceTile(context, s['name']!, s['url']!)),
                  const SizedBox(height: 12),
                  _sectionHeader('Riferimenti Normativi'),
                  ...legislationRefs.map((ref) => Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.gavel, size: 14, color: Colors.brown),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ref, style: const TextStyle(fontSize: 12, height: 1.4))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'ATTENZIONE: Questa app NON è un ente governativo, NON elabora pratiche ufficiali e NON sostituisce la consulenza '
                      'di un Patronato, CAF o professionista abilitato. I calcoli forniti sono stime a scopo orientativo.',
                      style: TextStyle(fontSize: 11, color: Colors.red.shade800, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
    );
  }

  static Widget _sourceTile(BuildContext context, String name, String url) {
    return InkWell(
      onTap: () async {
        try {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } catch (_) {}
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            const Icon(Icons.language, size: 14, color: Color(0xFF1565C0)),
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
}

/// Compact disclaimer for calculator/tool screens.
class CalculatorDisclaimer extends StatelessWidget {
  final String? specificSource;
  const CalculatorDisclaimer({super.key, this.specificSource});

  @override
  Widget build(BuildContext context) {
    final sourceText = specificSource != null
        ? 'Calcolo basato su $specificSource. '
        : '';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber.shade800),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${sourceText}Risultato a scopo orientativo (STIMA). '
              'Per il calcolo ufficiale rivolgersi a INPS, CAF o Patronato. '
              'App non affiliata ad alcun ente governativo.',
              style: TextStyle(fontSize: 9, color: Colors.amber.shade900, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
