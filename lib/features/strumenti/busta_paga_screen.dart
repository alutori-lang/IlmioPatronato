import 'package:flutter/material.dart';

import '../../config/constants.dart';

// ---------------------------------------------------------------------------
// BUSTA PAGA SPIEGATA
// Educational tool: visual representation of an Italian payslip with
// expandable explanations for each line item.
// ---------------------------------------------------------------------------

class BustaPagaScreen extends StatefulWidget {
  const BustaPagaScreen({super.key});

  @override
  State<BustaPagaScreen> createState() => _BustaPagaScreenState();
}

class _BustaPagaScreenState extends State<BustaPagaScreen> {
  // Track which items are expanded
  final Set<String> _expanded = {};

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildInfoBanner()),
          SliverToBoxAdapter(child: _buildBustaPagaTitle()),

          // ── INTESTAZIONE ──
          SliverToBoxAdapter(child: _sectionHeader('INTESTAZIONE', Icons.badge, const Color(0xFF5C6BC0))),
          SliverToBoxAdapter(child: _buildSection(_intestazioneItems)),

          // ── COMPETENZE (guadagni) ──
          SliverToBoxAdapter(child: _sectionHeader('COMPETENZE (quello che guadagni)', Icons.trending_up, const Color(0xFF43A047))),
          SliverToBoxAdapter(child: _buildSection(_competenzeItems)),

          // ── TRATTENUTE (cosa ti tolgono) ──
          SliverToBoxAdapter(child: _sectionHeader('TRATTENUTE (cosa ti tolgono)', Icons.trending_down, const Color(0xFFE53935))),
          SliverToBoxAdapter(child: _buildSection(_trattenutItems)),

          // ── NETTO ──
          SliverToBoxAdapter(child: _sectionHeader('NETTO (quello che ricevi)', Icons.account_balance_wallet, const Color(0xFF1565C0))),
          SliverToBoxAdapter(child: _buildSection(_nettoItems)),

          // ── Footer tip ──
          SliverToBoxAdapter(child: _buildFooterTip()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BUSTA PAGA SPIEGATA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Ogni voce spiegata in modo semplice',
                    style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info banner ──
  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: Color(0xFF1A237E), height: 1.4),
                children: [
                  TextSpan(
                      text: 'Strumento educativo. ',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                      text:
                          'Tocca ogni voce della busta paga per leggere una spiegazione semplice. '
                          'Gli importi mostrati sono esempi indicativi per un contratto Commercio 4\u00b0 livello.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fake busta paga title ──
  Widget _buildBustaPagaTitle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2D5E), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.business, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('AZIENDA ESEMPIO S.R.L.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dipendente:', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text('Mario Rossi', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('CCNL Commercio', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text('4\u00b0 Livello', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION (list of items)
  // ─────────────────────────────────────────────
  Widget _buildSection(List<_BustaItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isExpanded = _expanded.contains(item.id);
          final isLast = idx == items.length - 1;

          return Column(
            children: [
              // ── Tappable row ──
              InkWell(
                onTap: () => _toggle(item.id),
                borderRadius: BorderRadius.vertical(
                  top: idx == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: isLast && !isExpanded
                      ? const Radius.circular(16)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      // Left: title
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 20,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.voce,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isExpanded
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isExpanded
                                      ? AppColors.primary
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: amount
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isNegative
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.importo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: item.isNegative
                                ? const Color(0xFFE53935)
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Expanded explanation ──
              if (isExpanded)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 16,
                              color: AppColors.primary.withValues(alpha: 0.7)),
                          const SizedBox(width: 6),
                          const Text('Spiegazione semplice',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.spiegazione,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A237E),
                          height: 1.5,
                        ),
                      ),
                      if (item.dettaglio != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.dettaglio!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMedium,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Divider between items
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Footer tip ──
  Widget _buildFooterTip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates, color: Color(0xFFFFA000), size: 20),
              SizedBox(width: 8),
              Text('Consiglio',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5D4037))),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 12, color: Color(0xFF5D4037), height: 1.5),
              children: [
                TextSpan(
                    text: 'Controlla sempre la tua busta paga! ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                    text:
                        'Verifica che le ore lavorate siano corrette, che il livello contrattuale sia giusto, '
                        'e che le trattenute corrispondano. Se hai dubbi, chiedi aiuto a un CAF o al sindacato '
                        '(CGIL, CISL, UIL). Il servizio \u00e8 spesso gratuito per i lavoratori.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DATA
  // ─────────────────────────────────────────────

  // ── INTESTAZIONE ──
  static final _intestazioneItems = [
    _BustaItem(
      id: 'periodo',
      voce: 'Periodo di paga',
      importo: 'Gen 2025',
      isNegative: false,
      spiegazione:
          'Il mese a cui si riferisce lo stipendio. La busta paga viene emessa ogni mese e riguarda il lavoro fatto in quel periodo.',
      dettaglio:
          'Di solito il pagamento arriva entro il 10 del mese successivo. Controlla il tuo contratto per la data esatta.',
    ),
    _BustaItem(
      id: 'livello',
      voce: 'Livello / Qualifica',
      importo: '4\u00b0 Liv.',
      isNegative: false,
      spiegazione:
          'Il tuo inquadramento contrattuale. Ogni contratto nazionale (CCNL) ha dei livelli che determinano la paga base. '
          'Pi\u00f9 alto il livello, pi\u00f9 alta la paga.',
      dettaglio:
          'Esempio CCNL Commercio: 1\u00b0 livello (quadro) \u2192 7\u00b0 livello (apprendista). '
          'Il 4\u00b0 livello \u00e8 il pi\u00f9 comune per impiegati.',
    ),
    _BustaItem(
      id: 'ore',
      voce: 'Ore lavorate',
      importo: '168 ore',
      isNegative: false,
      spiegazione:
          'Le ore normali lavorate nel mese, pi\u00f9 eventuali ore di straordinario. '
          'Un mese standard full-time ha circa 168-176 ore (40 ore/settimana).',
      dettaglio:
          'Se lavori part-time, le ore saranno proporzionalmente ridotte. '
          'Esempio: part-time 20 ore/settimana = circa 84 ore/mese.',
    ),
  ];

  // ── COMPETENZE (guadagni) ──
  static final _competenzeItems = [
    _BustaItem(
      id: 'paga_base',
      voce: 'Paga base',
      importo: '\u20ac 1.618,75',
      isNegative: false,
      spiegazione:
          'Lo stipendio minimo stabilito dal tuo contratto nazionale (CCNL) per il tuo livello. '
          'Nessun datore di lavoro pu\u00f2 pagarti meno di questo importo.',
      dettaglio:
          'CCNL Commercio 4\u00b0 livello 2025: \u20ac 1.618,75 lordi/mese. '
          'Questo importo viene aggiornato con i rinnovi contrattuali.',
    ),
    _BustaItem(
      id: 'contingenza',
      voce: 'Contingenza',
      importo: '\u20ac 524,22',
      isNegative: false,
      spiegazione:
          'Un\'indennit\u00e0 fissa storica creata negli anni \'70-\'80 per proteggere lo stipendio dall\'inflazione. '
          'Oggi \u00e8 "congelata": non aumenta pi\u00f9, ma viene sempre pagata.',
      dettaglio:
          'La contingenza \u00e8 stata bloccata nel 1992 ma resta in busta paga come voce fissa. '
          'L\'importo varia in base al livello e al CCNL.',
    ),
    _BustaItem(
      id: 'superminimo',
      voce: 'Superminimo',
      importo: '\u20ac 150,00',
      isNegative: false,
      spiegazione:
          'Una quota aggiuntiva concordata tra te e il datore di lavoro, oltre la paga minima del contratto. '
          'Pu\u00f2 essere "assorbibile" (riducibile con gli aumenti) o "non assorbibile" (resta sempre).',
      dettaglio:
          'Se il CCNL prevede un aumento di \u20ac 50 e il tuo superminimo \u00e8 assorbibile, '
          'il datore pu\u00f2 ridurlo di \u20ac 50. Se non assorbibile, resta intero.',
    ),
    _BustaItem(
      id: 'straordinario',
      voce: 'Straordinario',
      importo: '\u20ac 87,50',
      isNegative: false,
      spiegazione:
          'Le ore lavorate oltre l\'orario normale. Vengono pagate di pi\u00f9: '
          'dal 15% al 30% in pi\u00f9 rispetto alla paga oraria normale, a seconda del tipo.',
      dettaglio:
          'Maggiorazioni tipiche CCNL Commercio:\n'
          '\u2022 Straordinario diurno: +15%\n'
          '\u2022 Straordinario notturno: +30%\n'
          '\u2022 Festivo: +30%\n'
          '\u2022 Notturno festivo: +50%',
    ),
    _BustaItem(
      id: 'scatti',
      voce: 'Scatti anzianit\u00e0',
      importo: '\u20ac 25,46',
      isNegative: false,
      spiegazione:
          'Aumenti automatici che ricevi ogni 2-3 anni per la tua fedelt\u00e0 all\'azienda. '
          'Sono previsti dal CCNL e non possono essere negati dal datore.',
      dettaglio:
          'CCNL Commercio: \u20ac 25,46 ogni 3 anni, fino a un massimo di 10 scatti. '
          'Se cambi azienda, gli scatti ripartono da zero.',
    ),
    _BustaItem(
      id: 'tredicesima',
      voce: 'Tredicesima (rateo)',
      importo: '\u20ac 194,95',
      isNegative: false,
      spiegazione:
          'La tredicesima \u00e8 una mensilit\u00e0 extra pagata a dicembre. Ogni mese ne "maturi" 1/12. '
          'In busta paga vedi il rateo mensile che si accumula.',
      dettaglio:
          'Se guadagni \u20ac 2.339,43 lordi/mese, la tredicesima sar\u00e0:\n'
          '\u20ac 2.339,43 / 12 = \u20ac 194,95 al mese che maturi.\n'
          'A dicembre ricevi l\'importo intero accumulato.',
    ),
    _BustaItem(
      id: 'quattordicesima',
      voce: 'Quattordicesima (rateo)',
      importo: '\u20ac 194,95',
      isNegative: false,
      spiegazione:
          'Una seconda mensilit\u00e0 extra, pagata di solito a giugno/luglio. '
          'Non tutti i contratti la prevedono: \u00e8 comune nel Commercio, Turismo e alcuni altri.',
      dettaglio:
          'Contratti con quattordicesima: Commercio, Turismo, Pubblici Esercizi, Chimico.\n'
          'Contratti SENZA quattordicesima: Metalmeccanico, Edilizia, Trasporti.',
    ),
  ];

  // ── TRATTENUTE ──
  static final _trattenutItems = [
    _BustaItem(
      id: 'inps',
      voce: 'INPS (9,19%)',
      importo: '- \u20ac 214,99',
      isNegative: true,
      spiegazione:
          'I contributi pensionistici obbligatori. Tu paghi il 9,19% dello stipendio lordo, '
          'e il datore paga un altro ~24% (che non vedi in busta). Questi soldi vanno alla tua pensione futura.',
      dettaglio:
          'Il 9,19% si calcola sullo stipendio lordo:\n'
          '\u20ac 2.339,43 \u00d7 9,19% = \u20ac 214,99\n'
          'Contributo totale (tuo + datore): circa 33% del lordo.',
    ),
    _BustaItem(
      id: 'irpef',
      voce: 'IRPEF',
      importo: '- \u20ac 356,00',
      isNegative: true,
      spiegazione:
          'L\'imposta sul reddito delle persone fisiche. Si calcola a scaglioni: '
          'pi\u00f9 guadagni, pi\u00f9 paghi in percentuale.',
      dettaglio:
          'Scaglioni IRPEF 2025:\n'
          '\u2022 Fino a \u20ac 28.000: 23%\n'
          '\u2022 Da \u20ac 28.001 a \u20ac 50.000: 35%\n'
          '\u2022 Oltre \u20ac 50.000: 43%\n\n'
          'L\'IRPEF si calcola sul reddito imponibile (lordo - INPS).',
    ),
    _BustaItem(
      id: 'addizionale_reg',
      voce: 'Addizionale regionale',
      importo: '- \u20ac 35,00',
      isNegative: true,
      spiegazione:
          'Una tassa aggiuntiva che va alla tua Regione. L\'importo dipende da dove hai la residenza fiscale. '
          'Varia dallo 0,9% al 3,33% a seconda della Regione.',
      dettaglio:
          'Regioni pi\u00f9 "care": Lazio (3,33%), Campania (2,03%), Piemonte (1,62%).\n'
          'Regioni pi\u00f9 "economiche": Trento, Bolzano, Sardegna.\n'
          'Viene trattenuta in 11 rate da gennaio a novembre.',
    ),
    _BustaItem(
      id: 'addizionale_com',
      voce: 'Addizionale comunale',
      importo: '- \u20ac 15,00',
      isNegative: true,
      spiegazione:
          'Una tassa aggiuntiva che va al tuo Comune di residenza. '
          'L\'importo varia da Comune a Comune, dallo 0% allo 0,8%.',
      dettaglio:
          'Ogni Comune decide la propria aliquota. Le grandi citt\u00e0 (Roma, Milano, Napoli) '
          'di solito applicano l\'aliquota massima dello 0,8%.',
    ),
    _BustaItem(
      id: 'detrazioni',
      voce: 'Detrazioni lavoro dipendente',
      importo: '+ \u20ac 155,00',
      isNegative: false,
      spiegazione:
          'Uno "sconto" sulle tasse che lo Stato ti riconosce perch\u00e9 sei un lavoratore dipendente. '
          'Riduce l\'IRPEF che devi pagare. Pi\u00f9 guadagni, meno detrai.',
      dettaglio:
          'Detrazioni 2025 per redditi da lavoro dipendente:\n'
          '\u2022 Fino a \u20ac 15.000: \u20ac 1.955\n'
          '\u2022 Da \u20ac 15.001 a \u20ac 28.000: \u20ac 1.910 (decresce)\n'
          '\u2022 Da \u20ac 28.001 a \u20ac 50.000: \u20ac 1.910 (decresce)\n'
          '\u2022 Oltre \u20ac 50.000: nessuna detrazione\n\n'
          'In busta paga vedi la quota mensile (annuale / 12).',
    ),
  ];

  // ── NETTO ──
  static final _nettoItems = [
    _BustaItem(
      id: 'netto',
      voce: 'Netto in busta',
      importo: '\u20ac 1.680,38',
      isNegative: false,
      spiegazione:
          'Questo \u00e8 l\'importo che ricevi davvero sul conto corrente. '
          '\u00c8 il lordo meno tutte le trattenute (INPS + IRPEF + addizionali) pi\u00f9 le detrazioni.',
      dettaglio:
          'Calcolo semplificato:\n'
          'Lordo: \u20ac 2.339,43\n'
          '- INPS (9,19%): - \u20ac 214,99\n'
          '= Imponibile IRPEF: \u20ac 2.124,44\n'
          '- IRPEF: - \u20ac 356,00\n'
          '- Add. regionale: - \u20ac 35,00\n'
          '- Add. comunale: - \u20ac 15,00\n'
          '+ Detrazioni: + \u20ac 155,00\n'
          '= NETTO: \u20ac 1.673,44\n\n'
          '(Importi arrotondati a scopo didattico)',
    ),
    _BustaItem(
      id: 'tfr',
      voce: 'TFR maturato',
      importo: '\u20ac 173,29',
      isNegative: false,
      spiegazione:
          'Il Trattamento di Fine Rapporto, cio\u00e8 la tua "liquidazione". '
          'Ogni mese il datore accantona circa 1/13,5 del tuo stipendio lordo. '
          'Lo ricevi quando lasci il lavoro.',
      dettaglio:
          'Calcolo TFR annuale: stipendio annuo lordo / 13,5\n'
          '\u20ac 2.339,43 \u00d7 12 / 13,5 = \u20ac 2.079,49 all\'anno\n'
          'Mensile: \u20ac 2.079,49 / 12 = \u20ac 173,29\n\n'
          'Puoi scegliere di:\n'
          '\u2022 Lasciarlo in azienda (rendimento ~1,5% + 75% inflazione)\n'
          '\u2022 Versarlo in un fondo pensione (spesso pi\u00f9 conveniente)\n'
          '\u2022 Chiedere un anticipo del 70% dopo 8 anni di lavoro',
    ),
  ];
}

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────

class _BustaItem {
  final String id;
  final String voce;
  final String importo;
  final bool isNegative;
  final String spiegazione;
  final String? dettaglio;

  const _BustaItem({
    required this.id,
    required this.voce,
    required this.importo,
    required this.isNegative,
    required this.spiegazione,
    this.dettaglio,
  });
}
