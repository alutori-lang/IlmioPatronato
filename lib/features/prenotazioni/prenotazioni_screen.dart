import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';

// ---------------------------------------------------------------------------
// Data model for a government office
// ---------------------------------------------------------------------------
class _Ufficio {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String note;
  final String detailTips;
  final String Function(String city) urlBuilder;
  final bool usesSpid;

  const _Ufficio({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.note,
    required this.detailTips,
    required this.urlBuilder,
    this.usesSpid = false,
  });
}

// ---------------------------------------------------------------------------
// PrenotazioniScreen
// ---------------------------------------------------------------------------
class PrenotazioniScreen extends StatefulWidget {
  const PrenotazioniScreen({super.key});

  @override
  State<PrenotazioniScreen> createState() => _PrenotazioniScreenState();
}

class _PrenotazioniScreenState extends State<PrenotazioniScreen> {
  // -----------------------------------------------------------------------
  // City state
  // -----------------------------------------------------------------------
  String _selectedCity = '';
  final TextEditingController _cityController = TextEditingController();
  final FocusNode _cityFocus = FocusNode();
  bool _showCityDropdown = false;

  static const List<String> _cities = [
    'Roma',
    'Milano',
    'Napoli',
    'Torino',
    'Bologna',
    'Firenze',
    'Genova',
    'Palermo',
    'Bari',
    'Catania',
    'Venezia',
    'Verona',
    'Padova',
    'Brescia',
    'Bergamo',
    'Modena',
    'Parma',
    'Reggio Emilia',
    'Perugia',
    'Cagliari',
    'Sassari',
    'Messina',
    'Taranto',
    'Lecce',
    'Prato',
    'Vicenza',
    'Livorno',
  ];

  List<String> _filteredCities = [];

  // -----------------------------------------------------------------------
  // Offices
  // -----------------------------------------------------------------------
  late final List<_Ufficio> _uffici;

  @override
  void initState() {
    super.initState();
    _filteredCities = List.from(_cities);

    _uffici = [
      _Ufficio(
        icon: Icons.local_police,
        color: Colors.blue.shade700,
        title: 'Questura - Permesso di Soggiorno',
        description: 'Prenota appuntamento per ritiro/rilascio permesso di soggiorno',
        note: 'Il Kit Postale va presentato all\'Ufficio Postale',
        detailTips:
            'Per il primo rilascio del permesso di soggiorno, devi acquistare il Kit Postale '
            'presso qualsiasi Ufficio Postale e compilare il modulo. Dopo la spedizione riceverai '
            'una convocazione dalla Questura per le impronte digitali.\n\n'
            'Documenti necessari:\n'
            '- Passaporto in corso di validit\u00e0\n'
            '- 4 foto formato tessera\n'
            '- Marca da bollo da \u20ac16,00\n'
            '- Ricevuta del bollettino postale',
        urlBuilder: (_) => 'https://portaleservizi.dlci.interno.it/AliSportello/ali/home.htm',
        usesSpid: true,
      ),
      _Ufficio(
        icon: Icons.account_balance,
        color: Colors.red.shade700,
        title: 'Agenzia delle Entrate',
        description: 'Codice fiscale, CU, dichiarazioni',
        note: 'Accesso diretto con SPID per prenotare',
        detailTips:
            'Puoi prenotare online un appuntamento per:\n'
            '- Richiesta codice fiscale\n'
            '- Rilascio CU (Certificazione Unica)\n'
            '- Dichiarazione dei redditi\n'
            '- Variazione dati anagrafici\n\n'
            'Documenti necessari:\n'
            '- Passaporto o carta d\'identit\u00e0\n'
            '- Permesso di soggiorno\n'
            '- Eventuale delega se agisci per conto terzi',
        urlBuilder: (_) => 'https://prenotazioneweb.agenziaentrate.gov.it/PrenotazioneWeb/prenotazione.action',
      ),
      _Ufficio(
        icon: Icons.security,
        color: Colors.teal.shade700,
        title: 'INPS - Servizi Previdenziali',
        description: 'ADI, NASpI, assegni familiari, pensioni',
        note: 'Login diretto con SPID / CIE / CNS',
        detailTips:
            'L\'INPS gestisce le prestazioni previdenziali e sociali:\n'
            '- ADI (Assegno di Inclusione)\n'
            '- NASpI (indennit\u00e0 di disoccupazione)\n'
            '- Assegno Unico per figli a carico\n'
            '- Pensioni\n\n'
            'Cliccando PRENOTA vai direttamente alla pagina di login SPID.\n'
            'In alternativa puoi rivolgerti a un Patronato/CAF.',
        urlBuilder: (_) => 'https://serviziweb2.inps.it/PassiWeb/jsp/spid/loginSPID.jsp',
        usesSpid: true,
      ),
      _Ufficio(
        icon: Icons.location_city,
        color: Colors.green.shade700,
        title: 'Comune / Anagrafe',
        description: 'Residenza, stato di famiglia, CIE',
        note: 'Accesso ANPR con SPID per certificati online',
        detailTips:
            'Presso l\'ufficio anagrafe del Comune puoi:\n'
            '- Registrare la residenza\n'
            '- Richiedere certificati anagrafici\n'
            '- Ottenere lo stato di famiglia\n'
            '- Richiedere la Carta d\'Identit\u00e0 Elettronica (CIE)\n\n'
            'Per la CIE \u00e8 obbligatorio prenotare online.\n\n'
            'Documenti per residenza:\n'
            '- Permesso di soggiorno valido\n'
            '- Codice fiscale\n'
            '- Contratto di affitto registrato',
        urlBuilder: (city) {
          return 'https://www.anagrafenazionale.interno.it/servizi-al-cittadino/';
        },
        usesSpid: true,
      ),
      _Ufficio(
        icon: Icons.flag,
        color: Colors.amber.shade800,
        title: 'Prefettura / Cittadinanza',
        description: 'Domanda di cittadinanza italiana',
        note: 'Contributo di \u20ac250 richiesto',
        detailTips:
            'La domanda di cittadinanza italiana si presenta online '
            'tramite il portale del Ministero dell\'Interno.\n\n'
            'Requisiti principali:\n'
            '- 10 anni di residenza legale in Italia (4 per cittadini UE)\n'
            '- Reddito minimo richiesto\n'
            '- Nessun precedente penale ostativo\n\n'
            'Costi:\n'
            '- Contributo di \u20ac250,00 (bollettino postale)\n'
            '- Marca da bollo da \u20ac16,00\n\n'
            'Tempi: fino a 24 mesi dalla domanda (prorogabili di 6 mesi).',
        urlBuilder: (_) => 'https://portaleservizi.dlci.interno.it/AliCittadinanza/ali/home.htm',
        usesSpid: true,
      ),
      _Ufficio(
        icon: Icons.local_hospital,
        color: Colors.pink.shade700,
        title: 'ASL / Tessera Sanitaria',
        description: 'Iscrizione SSN, scelta medico di base',
        note: 'Porta permesso di soggiorno, codice fiscale, autocertificazione residenza',
        detailTips:
            'L\'iscrizione al Servizio Sanitario Nazionale (SSN) \u00e8 obbligatoria '
            'per i cittadini stranieri con permesso di soggiorno.\n\n'
            'Documenti necessari:\n'
            '- Permesso di soggiorno (o ricevuta)\n'
            '- Codice fiscale\n'
            '- Autocertificazione di residenza\n'
            '- Eventuale certificato di lavoro\n\n'
            'Dopo l\'iscrizione potrai scegliere il medico di base.\n'
            'Il sito della tua ASL locale varia per regione.',
        urlBuilder: (_) =>
            'https://www.salute.gov.it/portale/lea/dettaglioContenutiLea.jsp?lingua=italiano&id=4917&area=Lea&menu=vuoto',
      ),
      _Ufficio(
        icon: Icons.business,
        color: Colors.indigo,
        title: 'Sportello Unico Immigrazione',
        description: 'Ricongiungimento familiare, nulla osta lavoro',
        note: 'Per ricongiungimento serve certificato idoneit\u00e0 alloggiativa',
        detailTips:
            'Lo Sportello Unico per l\'Immigrazione gestisce:\n'
            '- Ricongiungimento familiare\n'
            '- Nulla osta al lavoro subordinato\n'
            '- Conversione permesso di soggiorno\n\n'
            'Per il ricongiungimento familiare servono:\n'
            '- Certificato di idoneit\u00e0 alloggiativa\n'
            '- Reddito minimo (assegno sociale annuo)\n'
            '- Documenti familiari tradotti e legalizzati\n\n'
            'La pratica si avvia online sul Portale Immigrazione.',
        urlBuilder: (_) => 'https://portaleservizi.dlci.interno.it/AliSportello/ali/home.htm',
      ),
      _Ufficio(
        icon: Icons.people,
        color: Colors.brown.shade600,
        title: 'CAF / Patronato',
        description: 'ISEE, 730, RED, bonus, pratiche',
        note: 'Servizio gratuito per ISEE e pratiche base',
        detailTips:
            'I CAF e i Patronati offrono assistenza gratuita per:\n'
            '- Compilazione ISEE\n'
            '- Dichiarazione 730\n'
            '- Modello RED\n'
            '- Richiesta bonus e agevolazioni\n'
            '- Pratiche previdenziali INPS\n\n'
            'Il servizio per ISEE e pratiche di base \u00e8 completamente gratuito.\n'
            'Porta tutti i documenti di reddito e patrimonio.',
        urlBuilder: (_) => 'https://www.cafcisl.it/sedi/',
      ),
    ];
  }

  @override
  void dispose() {
    _cityController.dispose();
    _cityFocus.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------
  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = List.from(_cities);
      } else {
        _filteredCities = _cities
            .where((c) => c.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _showCityDropdown = true;
    });
  }

  void _selectCity(String city) {
    setState(() {
      _selectedCity = city;
      _cityController.text = city;
      _showCityDropdown = false;
    });
    _cityFocus.unfocus();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showOfficeDetails(BuildContext context, _Ufficio ufficio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfficeDetailSheet(
        ufficio: ufficio,
        city: _selectedCity,
        onOpenUrl: _openUrl,
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () {
          _cityFocus.unfocus();
          setState(() => _showCityDropdown = false);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildCitySelector()),
            if (_selectedCity.isNotEmpty)
              SliverToBoxAdapter(child: _buildSelectedCityChip()),
            SliverToBoxAdapter(child: _buildSectionTitle('Uffici e Prenotazioni')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildOfficeCard(_uffici[index]),
                childCount: _uffici.length,
              ),
            ),
            SliverToBoxAdapter(child: _buildSectionTitle('Suggerimenti')),
            SliverToBoxAdapter(child: _buildTipsCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Header
  // -----------------------------------------------------------------------
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
            child: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRENOTA APPUNTAMENTO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Uffici pubblici italiani',
                  style: TextStyle(color: AppColors.textSubtitle, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // City Selector
  // -----------------------------------------------------------------------
  Widget _buildCitySelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _cityController,
              focusNode: _cityFocus,
              onChanged: _filterCities,
              onTap: () => _filterCities(_cityController.text),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Cerca la tua citt\u00e0...',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                prefixIcon: Icon(Icons.location_on, color: AppColors.primary, size: 22),
                suffixIcon: _cityController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textLight),
                        onPressed: () {
                          _cityController.clear();
                          setState(() {
                            _selectedCity = '';
                            _filteredCities = List.from(_cities);
                            _showCityDropdown = false;
                          });
                        },
                      )
                    : const Icon(Icons.search, color: AppColors.textLight, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          if (_showCityDropdown && _filteredCities.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _filteredCities.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (_, index) {
                    final city = _filteredCities[index];
                    final isSelected = city == _selectedCity;
                    return InkWell(
                      onTap: () => _selectCity(city),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_city,
                              size: 18,
                              color: isSelected ? AppColors.primary : AppColors.textLight,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              city,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.textDark,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Selected city chip
  // -----------------------------------------------------------------------
  Widget _buildSelectedCityChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _selectedCity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Section title
  // -----------------------------------------------------------------------
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Office card
  // -----------------------------------------------------------------------
  Widget _buildOfficeCard(_Ufficio ufficio) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ufficio.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(ufficio.icon, color: ufficio.color, size: 28),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ufficio.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ufficio.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 12, color: AppColors.primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ufficio.note,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.primary.withValues(alpha: 0.7),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // PRENOTA button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openUrl(ufficio.urlBuilder(_selectedCity)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              gradient: ufficio.usesSpid
                                  ? const LinearGradient(colors: [Color(0xFF0066CC), Color(0xFF004A99)])
                                  : AppColors.buttonGradient,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  ufficio.usesSpid ? Icons.login : Icons.open_in_new,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ufficio.usesSpid ? 'ACCEDI SPID' : 'PRENOTA',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Info button
                      GestureDetector(
                        onTap: () => _showOfficeDetails(context, ufficio),
                        child: Container(
                          width: 40,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ufficio.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.info_outline, color: ufficio.color, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Tips card
  // -----------------------------------------------------------------------
  Widget _buildTipsCard() {
    const tips = [
      'Porta sempre: documento d\'identit\u00e0, codice fiscale, permesso di soggiorno',
      'Fai le fotocopie di TUTTI i documenti prima dell\'appuntamento',
      'Arriva almeno 15 minuti in anticipo',
      'Se hai bisogno di traduttore, chiedi al momento della prenotazione',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFC107).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC107).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, color: Color(0xFFFFC107), size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Suggerimenti Utili',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC107),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet for office details
// ---------------------------------------------------------------------------
class _OfficeDetailSheet extends StatelessWidget {
  final _Ufficio ufficio;
  final String city;
  final Future<void> Function(String url) onOpenUrl;

  const _OfficeDetailSheet({
    required this.ufficio,
    required this.city,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = ufficio.urlBuilder(city);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: ufficio.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(ufficio.icon, color: ufficio.color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ufficio.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ufficio.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade100,
                  ),
                  const SizedBox(height: 18),
                  // Details
                  const Text(
                    'Informazioni e Consigli',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ufficio.detailTips,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ufficio.color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ufficio.color.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ufficio.color,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ufficio.note,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: ufficio.color,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // URL display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link, size: 16, color: AppColors.textLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            url,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMedium,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Prenota button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenUrl(url);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'PRENOTA ORA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
