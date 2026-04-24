import 'profilo_utente_service.dart';

// ---------------------------------------------------------------------------
// Diritti e Bonus — matching con profilo utente
// Importi e soglie aggiornati alla normativa 2026 (Legge di Bilancio 2026,
// circolari INPS 2026, rivalutazioni ISTAT).
// ---------------------------------------------------------------------------

class Diritto {
  final String titolo;
  final String descrizione;
  final String importo;
  final String categoria; // 'famiglia','lavoro','casa','salute','giovani','disabilita','anziani','immigrazione'
  final String icona; // emoji
  final String comeRichiederlo;
  final String documentiNecessari;
  final bool Function(ProfiloUtente p) check;

  const Diritto({
    required this.titolo,
    required this.descrizione,
    required this.importo,
    required this.categoria,
    required this.icona,
    required this.comeRichiederlo,
    required this.documentiNecessari,
    required this.check,
  });
}

class DirittiService {
  static List<Diritto> getDiritti(ProfiloUtente profilo) {
    return _tuttiDiritti.where((d) => d.check(profilo)).toList();
  }

  // ── Helper ──────────────────────────────────────────────────────────
  static bool _haPermessoValido(ProfiloUtente p) =>
      p.isItaliano || p.cittadinanza == 'ue' || (p.isExtraUE && p.anniInItalia > 0);

  static bool _redditoBasso(ProfiloUtente p) =>
      p.fasciaReddito == '<8k' || p.fasciaReddito == '8-15k';

  static final List<Diritto> _tuttiDiritti = [

    // ═══════════════════════════════════════════════════════════════════
    // FAMIGLIA
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Assegno Unico Universale Figli',
      descrizione: 'Assegno mensile per ogni figlio a carico fino a 21 anni (senza limiti se con disabilità). L\'importo varia in base all\'ISEE.',
      importo: 'Da €57,50 a €201,00/mese per figlio (ISEE fino a €17.227,33 = importo pieno)',
      categoria: 'famiglia',
      icona: '👶',
      comeRichiederlo: 'Domanda online su INPS.it (sezione "Assegno Unico"), App INPS Mobile, o tramite Patronato.',
      documentiNecessari: 'ISEE minorenni, codici fiscali figli, IBAN intestato/cointestato al richiedente',
      check: (p) => p.numeriFigli > 0 && p.etaFigli.any((e) => e < 21) && _haPermessoValido(p),
    ),

    Diritto(
      titolo: 'Bonus Nuovi Nati 2026',
      descrizione: 'Contributo di €1.000 una tantum per ogni figlio nato o adottato dal 1° gennaio 2025.',
      importo: '€1.000 una tantum',
      categoria: 'famiglia',
      icona: '🍼',
      comeRichiederlo: 'Domanda online su INPS.it entro 120 giorni dalla nascita o dall\'ingresso in famiglia del minore.',
      documentiNecessari: 'ISEE minorenni ≤ €40.000, certificato di nascita/adozione, codice fiscale del neonato, IBAN',
      check: (p) => p.numeriFigli > 0 && p.etaFigli.any((e) => e == 0) && p.isee > 0 && p.isee <= 40000 && _haPermessoValido(p),
    ),

    Diritto(
      titolo: 'Bonus Asilo Nido',
      descrizione: 'Contributo per rette asilo nido pubblico/privato autorizzato, o supporto domiciliare per bimbi con gravi patologie.',
      importo: 'Da €1.500 a €3.600/anno (in base a ISEE)',
      categoria: 'famiglia',
      icona: '🏫',
      comeRichiederlo: 'Domanda online su INPS.it allegando ricevute di pagamento delle rette.',
      documentiNecessari: 'ISEE minorenni, ricevute rette asilo, codice fiscale figlio',
      check: (p) => p.numeriFigli > 0 && p.etaFigli.any((e) => e <= 3) && _haPermessoValido(p),
    ),

    Diritto(
      titolo: 'Bonus Mamme Lavoratrici 2026',
      descrizione: 'Integrazione al reddito INPS di €60/mese per madri lavoratrici con 2 o più figli (la decontribuzione piena è rinviata al 2027).',
      importo: '€60/mese × 12 = €720/anno',
      categoria: 'famiglia',
      icona: '👩',
      comeRichiederlo: 'Automatico in busta paga dopo comunicazione al datore dei codici fiscali dei figli, oppure via INPS.',
      documentiNecessari: 'Codici fiscali figli',
      check: (p) => p.sesso == 'F' && p.numeriFigli >= 2 && (p.situazioneLavoro == 'dipendente' || p.situazioneLavoro == 'cococo'),
    ),

    Diritto(
      titolo: 'Carta Dedicata a Te 2026',
      descrizione: 'Social card prepagata per spesa alimentare, carburanti e abbonamenti trasporti. Riservata a famiglie con almeno 3 componenti e ISEE basso. Graduatoria automatica INPS+Comune.',
      importo: '€500 una tantum',
      categoria: 'famiglia',
      icona: '🛒',
      comeRichiederlo: 'Automatico: graduatoria INPS+Comune; raccomandata da Poste con PIN attivazione.',
      documentiNecessari: 'ISEE ordinario valido, residenza in Italia, non percepire ADI/NASpI/altri sussidi',
      check: (p) => p.isee > 0 && p.isee < 15000 && (p.numeriFigli + 1) >= 3 && p.situazioneLavoro != 'disoccupato',
    ),

    Diritto(
      titolo: 'Reddito Alimentare',
      descrizione: 'Pacchi alimentari gratuiti con invenduto della GDO per persone in povertà assoluta. Sperimentale nelle Città Metropolitane di Genova, Firenze, Napoli, Palermo.',
      importo: 'Pacchi alimentari gratuiti (in natura)',
      categoria: 'famiglia',
      icona: '🥖',
      comeRichiederlo: 'Iscrizione tramite Servizi Sociali del Comune o organizzazioni del Terzo Settore convenzionate.',
      documentiNecessari: 'Segnalazione Servizi Sociali, ISEE, residenza nelle città indicate',
      check: (p) => p.isee > 0 && p.isee < 6000,
    ),

    Diritto(
      titolo: 'Assegno di Maternità del Comune',
      descrizione: 'Assegno del Comune per madri che NON lavorano (o senza altra indennità di maternità) con ISEE basso.',
      importo: '€2.091,62 totali (5 mensilità)',
      categoria: 'famiglia',
      icona: '🤱',
      comeRichiederlo: 'Domanda al Comune di residenza entro 6 mesi dalla nascita/ingresso in famiglia.',
      documentiNecessari: 'ISEE < €20.221,13, certificato di nascita, documento identità, permesso di soggiorno (se extraUE)',
      check: (p) => p.sesso == 'F' && p.numeriFigli > 0 && p.etaFigli.any((e) => e == 0) && p.isee > 0 && p.isee < 20221 && (p.situazioneLavoro == 'disoccupato' || p.situazioneLavoro == 'studente'),
    ),

    Diritto(
      titolo: 'Indennità Maternità Obbligatoria INPS',
      descrizione: 'Indennità pari all\'80% della retribuzione per 5 mesi (2 prima + 3 dopo il parto) per lavoratrici dipendenti, co.co.co. e autonome.',
      importo: '80% retribuzione × 5 mesi',
      categoria: 'famiglia',
      icona: '🤰',
      comeRichiederlo: 'Domanda online INPS prima del periodo di astensione + certificato medico di gravidanza.',
      documentiNecessari: 'Certificato medico di gravidanza, documento identità',
      check: (p) => p.sesso == 'F' && (p.situazioneLavoro == 'dipendente' || p.situazioneLavoro == 'cococo' || p.situazioneLavoro == 'partita_iva') && p.numeriFigli > 0 && p.etaFigli.any((e) => e == 0),
    ),

    Diritto(
      titolo: 'Congedo Paternità Obbligatoria',
      descrizione: '10 giorni lavorativi obbligatori al 100% della retribuzione per padri lavoratori dipendenti, da fruire entro 5 mesi dalla nascita.',
      importo: '100% retribuzione × 10 giorni',
      categoria: 'famiglia',
      icona: '👨‍👶',
      comeRichiederlo: 'Comunicazione al datore di lavoro con preavviso di 5 giorni; pagato dall\'INPS.',
      documentiNecessari: 'Atto di nascita, comunicazione scritta al datore',
      check: (p) => p.sesso == 'M' && p.situazioneLavoro == 'dipendente' && p.numeriFigli > 0 && p.etaFigli.any((e) => e == 0),
    ),

    Diritto(
      titolo: 'Congedo Parentale all\'80%',
      descrizione: 'Indennità INPS per genitori dipendenti durante congedo parentale: 3 mesi all\'80% (invece del 30%) entro i primi 6 anni del bambino. Diritto fino ai 14 anni del figlio.',
      importo: '80% retribuzione × 3 mesi',
      categoria: 'famiglia',
      icona: '👨‍👩‍👧',
      comeRichiederlo: 'Domanda INPS via portale online prima del periodo di congedo + comunicazione al datore.',
      documentiNecessari: 'Documenti del figlio, SPID, lettera al datore',
      check: (p) => p.situazioneLavoro == 'dipendente' && p.numeriFigli >= 1 && p.etaFigli.any((e) => e < 14),
    ),

    Diritto(
      titolo: 'Carta Acquisti (Social Card)',
      descrizione: 'Carta prepagata da €80 bimestrali per acquisti alimentari, farmaceutici e bollette. Per over 65 o genitori di bimbi under 3.',
      importo: '€480/anno (€80 ogni 2 mesi)',
      categoria: 'famiglia',
      icona: '💳',
      comeRichiederlo: 'Domanda presso un ufficio postale abilitato con modulo ministeriale.',
      documentiNecessari: 'ISEE < €8.117,87, documento d\'identità, codice fiscale',
      check: (p) => p.isee > 0 && p.isee < 8117 && (p.eta >= 65 || (p.numeriFigli > 0 && p.etaFigli.any((e) => e < 3))),
    ),

    Diritto(
      titolo: 'Assegno di Inclusione (ADI)',
      descrizione: 'Sostegno economico per famiglie in difficoltà con componenti fragili: minori, over 60, persone con disabilità, o in percorsi di cura sociosanitari.',
      importo: 'Da €500 a €800/mese + fino a €280/mese per affitto',
      categoria: 'famiglia',
      icona: '🤝',
      comeRichiederlo: 'Domanda online su INPS.it o tramite Patronato/CAF + firma Patto per l\'Inclusione al Servizio Sociale del Comune.',
      documentiNecessari: 'ISEE < €10.140, documento identità, permesso (min. 5 anni in Italia se extraUE, di cui 2 continuativi), IBAN',
      check: (p) => p.isee > 0 && p.isee < 10140 && p.haComponentiFragili && (p.isItaliano || p.cittadinanza == 'ue' || (p.isExtraUE && p.anniInItalia >= 5)),
    ),

    Diritto(
      titolo: 'Reddito di Libertà',
      descrizione: 'Contributo INPS per donne vittime di violenza in povertà, seguite da un centro antiviolenza riconosciuto.',
      importo: '€530/mese × 12 mesi = €6.360/anno',
      categoria: 'famiglia',
      icona: '🦋',
      comeRichiederlo: 'Domanda tramite Comune di residenza (i Comuni la trasmettono a INPS).',
      documentiNecessari: 'Attestazione Centro Antiviolenza, Servizi Sociali, ISEE',
      check: (p) => p.sesso == 'F' && p.fasciaReddito == '<8k',
    ),

    Diritto(
      titolo: 'Detrazione Spese Funebri',
      descrizione: 'Detrazione IRPEF del 19% per spese funebri sostenute per il decesso di familiari.',
      importo: '19% su max €1.550 per decesso → max €294,50',
      categoria: 'famiglia',
      icona: '🕊️',
      comeRichiederlo: 'Inserimento in dichiarazione 730/Redditi PF.',
      documentiNecessari: 'Fattura intestata al dichiarante, pagamenti tracciabili',
      check: (p) => p.fasciaReddito != '<8k', // con <8k non c'è capienza IRPEF
    ),

    // ═══════════════════════════════════════════════════════════════════
    // LAVORO
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'NASpI (Nuova Assicurazione Sociale per l\'Impiego)',
      descrizione: 'Indennità mensile di disoccupazione per lavoratori dipendenti che hanno perso il lavoro involontariamente. Serve almeno 13 settimane di contributi nei 4 anni precedenti.',
      importo: 'Fino a €1.584,70/mese (durata max 24 mesi; -3% mensile dal 6° mese)',
      categoria: 'lavoro',
      icona: '💼',
      comeRichiederlo: 'Domanda online su INPS.it entro 68 giorni dal licenziamento. Registrazione obbligatoria al Centro per l\'Impiego.',
      documentiNecessari: 'Lettera licenziamento, ultime buste paga, documento identità, IBAN',
      check: (p) => p.situazioneLavoro == 'disoccupato',
    ),

    Diritto(
      titolo: 'NASpI Anticipata in unica soluzione',
      descrizione: 'Liquidazione in un\'unica soluzione del residuo NASpI per chi avvia attività di lavoro autonomo, P.IVA o sottoscrive quote di cooperativa.',
      importo: 'Totale NASpI residuo non ancora percepito',
      categoria: 'lavoro',
      icona: '🚀',
      comeRichiederlo: 'Domanda INPS online entro 30 giorni dall\'inizio attività + modulo SR163.',
      documentiNecessari: 'Apertura P.IVA, business plan',
      check: (p) => p.situazioneLavoro == 'disoccupato',
    ),

    Diritto(
      titolo: 'DIS-COLL',
      descrizione: 'Indennità di disoccupazione specifica per collaboratori coordinati e continuativi (co.co.co.) iscritti alla Gestione Separata INPS.',
      importo: 'Fino a €1.584,70/mese',
      categoria: 'lavoro',
      icona: '📋',
      comeRichiederlo: 'Domanda online su INPS.it entro 68 giorni dalla fine del contratto.',
      documentiNecessari: 'Contratto scaduto, certificazione unica, documento identità, IBAN',
      check: (p) => p.situazioneLavoro == 'disoccupato',
    ),

    Diritto(
      titolo: 'ISCRO – Indennità Continuità Reddituale',
      descrizione: 'Indennità INPS per partite IVA iscritte alla Gestione Separata che hanno avuto un calo di reddito superiore al 30% rispetto alla media biennale precedente.',
      importo: 'Da €255,53 a €817,69/mese × 6 mesi (25% del reddito medio)',
      categoria: 'lavoro',
      icona: '💼',
      comeRichiederlo: 'Domanda INPS online entro 31 ottobre; max 1 volta ogni 5 anni.',
      documentiNecessari: 'Autocertificazione redditi, iscrizione Gestione Separata da almeno 3 anni',
      check: (p) => p.situazioneLavoro == 'partita_iva' && (p.fasciaReddito == '<8k' || p.fasciaReddito == '8-15k'),
    ),

    Diritto(
      titolo: 'Supporto Formazione e Lavoro (SFL)',
      descrizione: 'Misura per adulti 18-59 anni, attivabili al lavoro, con ISEE basso e senza componenti fragili nel nucleo. Obbligo iscrizione CPI e partecipazione corsi di formazione.',
      importo: '€500/mese per 12 mesi (estendibili a 24 con formazione)',
      categoria: 'lavoro',
      icona: '📚',
      comeRichiederlo: 'Domanda online su INPS.it + Patto Attivazione Digitale + iscrizione a corso.',
      documentiNecessari: 'ISEE < €10.140, documento identità, permesso di soggiorno valido, IBAN',
      check: (p) => p.isee > 0 && p.isee < 10140 && p.eta >= 18 && p.eta < 60 && p.situazioneLavoro == 'disoccupato' && !p.haComponentiFragili,
    ),

    Diritto(
      titolo: 'Trattamento Integrativo (ex Bonus IRPEF)',
      descrizione: 'Credito IRPEF in busta paga per lavoratori dipendenti con reddito complessivo fino a €15.000 (fino a €28.000 in casi di capienza fiscale).',
      importo: 'Fino a €1.200/anno (€100/mese)',
      categoria: 'lavoro',
      icona: '💰',
      comeRichiederlo: 'Automatico in busta paga. Verificare sulla CU o chiedere al datore di lavoro.',
      documentiNecessari: 'Nessuno — erogazione automatica',
      check: (p) => p.situazioneLavoro == 'dipendente' && (p.fasciaReddito == '8-15k' || p.fasciaReddito == '15-28k'),
    ),

    Diritto(
      titolo: 'Bonus Assunzione Giovani Under 35',
      descrizione: 'Esonero contributivo per datori di lavoro privati che assumono under 35 a tempo indeterminato. Beneficio indiretto sul lavoratore tramite costo del lavoro più basso.',
      importo: '100% contributi (€500/mese; €650 al Sud) per 24 mesi',
      categoria: 'lavoro',
      icona: '🧑‍💼',
      comeRichiederlo: 'A carico del datore di lavoro tramite Portale Agevolazioni INPS.',
      documentiNecessari: 'Mai stato dipendente a tempo indeterminato prima',
      check: (p) => p.eta < 35 && p.situazioneLavoro == 'dipendente',
    ),

    Diritto(
      titolo: 'Cassa Integrazione Guadagni (CIG/CIGS)',
      descrizione: 'Integrazione salariale INPS per lavoratori dipendenti in caso di sospensione/riduzione attività per crisi aziendale, ristrutturazione o eventi straordinari.',
      importo: 'Max €1.423,69/mese lordi (Circ. INPS 4/2026)',
      categoria: 'lavoro',
      icona: '🏭',
      comeRichiederlo: 'Domanda presentata dal datore di lavoro all\'INPS; il lavoratore non deve fare nulla.',
      documentiNecessari: 'Nessuno per il lavoratore (azienda in crisi / ristrutturazione)',
      check: (p) => p.situazioneLavoro == 'dipendente',
    ),

    Diritto(
      titolo: 'Assegno Ordinario di Invalidità (AOI)',
      descrizione: 'Assegno previdenziale INPS per chi ha riduzione di capacità lavorativa permanente superiore ai 2/3 e almeno 5 anni di contributi (3 negli ultimi 5).',
      importo: 'Calcolo contributivo, integrabile al minimo (€603,40/mese 2026)',
      categoria: 'lavoro',
      icona: '⚕️',
      comeRichiederlo: 'Domanda INPS online + certificato medico SS3 introduttivo.',
      documentiNecessari: 'Certificazione medica, estratto contributivo con almeno 5 anni di contributi',
      check: (p) => p.disabilita && p.eta >= 18 && p.eta < 67,
    ),

    // ═══════════════════════════════════════════════════════════════════
    // CASA
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Bonus Sociale Luce, Gas e Idrico',
      descrizione: 'Sconto automatico applicato sulle bollette di luce, gas e acqua per famiglie con ISEE basso.',
      importo: 'Da €150 a €600/anno a seconda di nucleo e consumi',
      categoria: 'casa',
      icona: '💡',
      comeRichiederlo: 'Automatico con ISEE in corso di validità. Basta presentare la DSU ogni anno al CAF.',
      documentiNecessari: 'ISEE valido (< €9.796, oppure < €20.000 con 4+ figli)',
      check: (p) => p.isee > 0 && (p.isee < 9796 || (p.isee < 20000 && p.numeriFigli >= 4)),
    ),

    Diritto(
      titolo: 'Detrazione Affitto Giovani',
      descrizione: 'Detrazione IRPEF per giovani tra 20 e 31 anni che vivono in affitto (contratto registrato, anche stanza singola) con reddito fino a €15.493,71.',
      importo: '€991,60 fisso o 20% canone (max €2.000/anno)',
      categoria: 'casa',
      icona: '🏠',
      comeRichiederlo: 'Indicare il contratto di affitto registrato in dichiarazione 730/Redditi PF.',
      documentiNecessari: 'Contratto di affitto registrato, ricevute canone, dichiarazione dei redditi',
      check: (p) => p.eta >= 20 && p.eta <= 31 && p.inAffitto && (p.fasciaReddito == '<8k' || p.fasciaReddito == '8-15k'),
    ),

    Diritto(
      titolo: 'Contributo Affitto Comunale (Fondo Morosi Incolpevoli)',
      descrizione: 'Contributo dei Comuni per inquilini con sfratto per morosità incolpevole o difficoltà economica temporanea.',
      importo: 'Variabile: in genere €3.000–€8.000 una tantum',
      categoria: 'casa',
      icona: '🏘️',
      comeRichiederlo: 'Bando comunale (verificare sul sito del Comune di residenza).',
      documentiNecessari: 'ISEE, contratto di locazione registrato, documentazione difficoltà',
      check: (p) => p.inAffitto && p.isee > 0 && p.isee < 27000,
    ),

    Diritto(
      titolo: 'Garanzia Mutuo Prima Casa Under 36',
      descrizione: 'Fondo Consap garantisce fino all\'80% del mutuo per acquisto prima casa per giovani under 36 con ISEE basso. Prorogato fino al 31/12/2027.',
      importo: 'Garanzia statale 80% del mutuo',
      categoria: 'casa',
      icona: '🔑',
      comeRichiederlo: 'Tramite banca convenzionata + modulo MEF al momento del mutuo.',
      documentiNecessari: 'ISEE valido ≤ €40.000, età < 36, preliminare di acquisto',
      check: (p) => p.eta < 36 && p.isee > 0 && p.isee <= 40000,
    ),

    Diritto(
      titolo: 'Detrazione Interessi Mutuo Prima Casa',
      descrizione: 'Detrazione IRPEF del 19% sugli interessi passivi del mutuo per acquisto abitazione principale.',
      importo: '19% su max €4.000 → max €760/anno',
      categoria: 'casa',
      icona: '🏦',
      comeRichiederlo: 'Inserimento spese in dichiarazione 730/Redditi PF.',
      documentiNecessari: 'Quietanze interessi banca, contratto mutuo, rogito',
      check: (p) => p.fasciaReddito != '<8k' && !p.inAffitto,
    ),

    Diritto(
      titolo: 'Bonus Ristrutturazioni 50%',
      descrizione: 'Detrazione IRPEF del 50% sulle spese di ristrutturazione edilizia ordinaria per abitazione principale (36% per altri immobili). Tetto €96.000.',
      importo: '50% detrazione fino a €48.000 (10 rate annuali)',
      categoria: 'casa',
      icona: '🔨',
      comeRichiederlo: 'Pagamento con bonifico parlante; detrazione in dichiarazione 730/Redditi PF.',
      documentiNecessari: 'CILA o pratica edilizia, bonifici tracciabili, fatture',
      check: (p) => p.fasciaReddito != '<8k' && !p.inAffitto,
    ),

    Diritto(
      titolo: 'Bonus Mobili ed Elettrodomestici',
      descrizione: 'Detrazione IRPEF del 50% per acquisto mobili ed elettrodomestici (classe A o superiore) per arredare casa oggetto di ristrutturazione iniziata dal 1° gennaio dell\'anno precedente.',
      importo: '50% su max €5.000 (€2.500 detrazione in 10 anni)',
      categoria: 'casa',
      icona: '🛋️',
      comeRichiederlo: 'Bonifico/carta; detrazione in dichiarazione 730/Redditi PF.',
      documentiNecessari: 'Fatture mobili, documentazione ristrutturazione collegata, pagamenti tracciabili',
      check: (p) => p.fasciaReddito != '<8k' && !p.inAffitto,
    ),

    Diritto(
      titolo: 'Ecobonus Riqualificazione Energetica',
      descrizione: 'Detrazione IRPEF del 50% (prima casa) o 36% (altro) per interventi di efficienza energetica: cappotto termico, infissi, caldaie, pompe di calore.',
      importo: '50%/36% detrazione (10 rate annuali)',
      categoria: 'casa',
      icona: '🌿',
      comeRichiederlo: 'Comunicazione ENEA entro 90 gg fine lavori; detrazione in dichiarazione.',
      documentiNecessari: 'Asseverazione tecnica, APE, pagamenti tracciabili',
      check: (p) => p.fasciaReddito != '<8k' && !p.inAffitto,
    ),

    Diritto(
      titolo: 'Bonus Barriere Architettoniche 75%',
      descrizione: 'Detrazione IRPEF del 75% per eliminazione barriere architettoniche (scale, rampe, ascensori, montascale, citofoni). Confermato fino al 2028.',
      importo: '75% detrazione in 10 rate annuali',
      categoria: 'casa',
      icona: '🦽',
      comeRichiederlo: 'Pagamento con bonifico parlante, conformità DM 236/89.',
      documentiNecessari: 'Asseverazione tecnica, fatture, certificazione conformità. Se in affitto: consenso scritto del proprietario',
      check: (p) => p.disabilita || p.eta >= 65,
    ),

    Diritto(
      titolo: 'Sismabonus',
      descrizione: 'Detrazione IRPEF per interventi di riduzione del rischio sismico in zone 1, 2 o 3. Confermato anche nel 2026.',
      importo: '50%/36% (incrementi con passaggio classi sismiche)',
      categoria: 'casa',
      icona: '🏚️',
      comeRichiederlo: 'Asseverazione struttura prima dei lavori; detrazione in dichiarazione.',
      documentiNecessari: 'Modulo Allegato B, asseverazione, bonifici parlanti',
      check: (p) => p.fasciaReddito != '<8k' && !p.inAffitto,
    ),

    // ═══════════════════════════════════════════════════════════════════
    // SALUTE
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Esenzione Ticket Sanitario per Reddito (E02)',
      descrizione: 'Esenzione dal ticket per visite ed esami per famiglie con reddito < €8.263,31 + bonus €516,46 per coniuge e ogni figlio.',
      importo: 'Risparmio su tutte le prestazioni SSN',
      categoria: 'salute',
      icona: '🏥',
      comeRichiederlo: 'Richiesta alla ASL di residenza con autocertificazione reddito. Codice E02 stampato sulla ricetta.',
      documentiNecessari: 'Autocertificazione reddito familiare < €8.263,31 + maggiorazioni',
      check: (p) => p.fasciaReddito == '<8k',
    ),

    Diritto(
      titolo: 'Esenzione Ticket per Età (E01/E03/E04)',
      descrizione: 'Esenzione ticket sanitario automatica per minori di 6 anni e over 65 con reddito basso, o per categorie specifiche.',
      importo: 'Risparmio su tutte le prestazioni SSN',
      categoria: 'salute',
      icona: '🏥',
      comeRichiederlo: 'Automatica per età. Per over 65 serve autocertificazione reddito alla ASL.',
      documentiNecessari: 'Documento identità; per over 65 anche autocertificazione reddito',
      check: (p) => p.eta < 6 || (p.eta >= 65 && (p.fasciaReddito == '<8k' || p.fasciaReddito == '8-15k')),
    ),

    Diritto(
      titolo: 'Bonus Psicologo 2026',
      descrizione: 'Contributo INPS per spese di psicoterapia con psicologi privati iscritti all\'albo. Voucher fino a €50/seduta.',
      importo: '€500 / €1.000 / €1.500 (in base a ISEE)',
      categoria: 'salute',
      icona: '🧠',
      comeRichiederlo: 'Domanda online INPS (servizio "Contributo sessioni psicoterapia") con SPID/CIE.',
      documentiNecessari: 'ISEE valido, SPID/CIE',
      check: (p) => p.isee > 0 && p.isee < 50000,
    ),

    Diritto(
      titolo: 'Bonus Occhiali e Lenti',
      descrizione: 'Voucher €50 erogato dal Ministero della Salute per acquisto occhiali da vista o lenti a contatto correttive in ottici convenzionati.',
      importo: '€50 una tantum',
      categoria: 'salute',
      icona: '👓',
      comeRichiederlo: 'Domanda online piattaforma bonusvista.it con SPID; voucher applicato in ottica convenzionata.',
      documentiNecessari: 'ISEE < €10.000, ricetta oculista (consigliata)',
      check: (p) => p.isee > 0 && p.isee < 10000,
    ),

    Diritto(
      titolo: 'Detrazione Spese Mediche 19%',
      descrizione: 'Detrazione IRPEF del 19% per spese sanitarie (ticket, visite, esami, dispositivi medici CE, farmaci) eccedenti la franchigia di €129,11.',
      importo: '19% su (spesa - €129,11)',
      categoria: 'salute',
      icona: '💊',
      comeRichiederlo: 'Inserimento spese in dichiarazione 730/Redditi PF (precompilato dal Sistema TS).',
      documentiNecessari: 'Scontrini farmacia con CF, fatture sanitarie tracciabili',
      check: (p) => p.fasciaReddito != '<8k',
    ),

    Diritto(
      titolo: 'Detrazione Spese Veterinarie 19%',
      descrizione: 'Detrazione IRPEF del 19% delle spese veterinarie (visite, chirurgia, esami, farmaci) eccedenti la franchigia di €129,11.',
      importo: '19% su max €550 - franchigia €129,11',
      categoria: 'salute',
      icona: '🐾',
      comeRichiederlo: 'Inserimento in dichiarazione 730/Redditi PF.',
      documentiNecessari: 'Fatture veterinarie con CF dell\'intestatario, pagamenti tracciabili',
      check: (p) => p.fasciaReddito != '<8k',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // GIOVANI / CULTURA / STUDENTI
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Carta Cultura Giovani',
      descrizione: 'Bonus €500 per libri, musei, cinema, teatro, concerti, corsi, abbonamenti. Riservata ai 18enni di famiglie con ISEE sotto €35.000.',
      importo: '€500 spendibili entro l\'anno',
      categoria: 'giovani',
      icona: '🎓',
      comeRichiederlo: 'Registrazione su cartegiovani.cultura.gov.it con SPID/CIE tra 18 e 19 anni.',
      documentiNecessari: 'SPID/CIE, ISEE nucleo < €35.000',
      check: (p) => p.eta == 18 && p.isee > 0 && p.isee < 35000,
    ),

    Diritto(
      titolo: 'Carta del Merito',
      descrizione: 'Bonus €500 per cultura riservato a chi consegue il diploma con 100/100 entro i 19 anni. Cumulabile con Carta Cultura Giovani. Nessun limite ISEE.',
      importo: '€500 spendibili entro l\'anno',
      categoria: 'giovani',
      icona: '🏆',
      comeRichiederlo: 'Registrazione su cartegiovani.cultura.gov.it con SPID/CIE. Voto verificato dal MIUR.',
      documentiNecessari: 'SPID/CIE, diploma con 100/100',
      check: (p) => (p.eta == 18 || p.eta == 19) && p.merito100,
    ),

    Diritto(
      titolo: 'Carta Giovani Nazionale',
      descrizione: 'Tessera digitale gratuita nell\'app IO per giovani 18-35 anni: sconti 5%-50% su trasporti, cultura, tecnologia, sport, formazione, psicoterapia online. EYCA per under 30.',
      importo: 'Sconti variabili (tessera gratuita)',
      categoria: 'giovani',
      icona: '🎫',
      comeRichiederlo: 'App IO + autenticazione con SPID/CIE.',
      documentiNecessari: 'SPID/CIE, età 18-35',
      check: (p) => p.eta >= 18 && p.eta <= 35,
    ),

    Diritto(
      titolo: 'Borse di Studio INPS Università',
      descrizione: 'Borse di studio annuali da €2.000 INPS per studenti universitari figli di iscritti a Gestione Unitaria (dipendenti pubblici, pensionati pubblici).',
      importo: '€2.000/anno',
      categoria: 'giovani',
      icona: '🎓',
      comeRichiederlo: 'Bando annuale Portale Prestazioni Welfare INPS (gennaio-marzo).',
      documentiNecessari: 'ISEE, iscrizione università, libretto esami (media min 24/30, no fuori corso)',
      check: (p) => p.situazioneLavoro == 'studente' && p.eta >= 18 && p.eta <= 30,
    ),

    Diritto(
      titolo: 'Detrazione Affitto Studenti Fuori Sede',
      descrizione: 'Detrazione IRPEF del 19% del canone di affitto per studenti universitari che frequentano un ateneo a oltre 100 km dalla residenza, in altra provincia.',
      importo: '19% su max €2.633 → max €500/anno',
      categoria: 'giovani',
      icona: '📚',
      comeRichiederlo: 'Inserimento in dichiarazione 730/Redditi PF (anche dei genitori se a carico).',
      documentiNecessari: 'Contratto registrato, ricevute pagamento, certificato iscrizione università',
      check: (p) => p.situazioneLavoro == 'studente' && p.inAffitto,
    ),

    Diritto(
      titolo: 'Detrazione Spese Universitarie',
      descrizione: 'Detrazione IRPEF del 19% per tasse e contributi universitari (atenei statali e non statali entro tetti regionali MUR).',
      importo: '19% sulle tasse pagate (limite MUR per area)',
      categoria: 'giovani',
      icona: '🎒',
      comeRichiederlo: 'Inserimento in dichiarazione 730/Redditi PF.',
      documentiNecessari: 'Ricevute pagamento tasse, iscrizione regolare',
      check: (p) => p.situazioneLavoro == 'studente' || (p.numeriFigli >= 1 && p.etaFigli.any((e) => e >= 18 && e <= 28)),
    ),

    Diritto(
      titolo: 'Detrazione Spese Scolastiche',
      descrizione: 'Detrazione IRPEF del 19% per tasse di iscrizione, mensa, gite e contributi volontari di scuole dell\'infanzia, primaria e secondaria.',
      importo: '19% su max €800 per figlio → €152/anno per figlio',
      categoria: 'giovani',
      icona: '🏫',
      comeRichiederlo: 'Inserimento ricevute in dichiarazione 730/Redditi PF.',
      documentiNecessari: 'Ricevute scuola, bonifici tracciabili',
      check: (p) => p.numeriFigli >= 1 && p.etaFigli.any((e) => e >= 3 && e <= 18) && p.fasciaReddito != '<8k',
    ),

    Diritto(
      titolo: 'Detrazione Spese Sportive Figli 5-18',
      descrizione: 'Detrazione IRPEF del 19% per iscrizione e abbonamenti a palestre, piscine e associazioni sportive dilettantistiche per ragazzi tra 5 e 18 anni.',
      importo: '19% su max €210 per figlio → max €40/anno per figlio',
      categoria: 'giovani',
      icona: '⚽',
      comeRichiederlo: 'Inserimento ricevute in dichiarazione 730/Redditi PF.',
      documentiNecessari: 'Ricevute con dati associazione sportiva e CF del ragazzo',
      check: (p) => p.numeriFigli >= 1 && p.etaFigli.any((e) => e >= 5 && e <= 18) && p.fasciaReddito != '<8k',
    ),

    Diritto(
      titolo: 'Fondo Dote per la Famiglia (Sport Minori)',
      descrizione: 'Contributo Dipartimento Sport per attività sportive e ricreative di figli 6-14 anni, per famiglie con ISEE basso non beneficiarie di altri sussidi sportivi.',
      importo: 'Variabile (voucher per attività)',
      categoria: 'giovani',
      icona: '🏅',
      comeRichiederlo: 'Domanda online portale Dipartimento Sport (bando annuale).',
      documentiNecessari: 'ISEE minorenni < €15.000, iscrizione a società sportiva ASD/SSD',
      check: (p) => p.isee > 0 && p.isee < 15000 && p.numeriFigli >= 1 && p.etaFigli.any((e) => e >= 6 && e <= 14),
    ),

    // ═══════════════════════════════════════════════════════════════════
    // DISABILITÀ
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Indennità di Accompagnamento',
      descrizione: 'Prestazione economica per invalidità civile al 100% riconosciuta con impossibilità a deambulare senza aiuto o a compiere atti quotidiani. Non dipende da reddito né ISEE.',
      importo: '€552,57/mese × 12 mensilità',
      categoria: 'disabilita',
      icona: '♿',
      comeRichiederlo: 'Certificato medico telematico → domanda INPS → visita commissione medica ASL/INPS.',
      documentiNecessari: 'Certificato di invalidità civile 100% con impossibilità a deambulare/compiere atti quotidiani',
      check: (p) => p.disabilita,
    ),

    Diritto(
      titolo: 'Pensione di Invalidità Civile',
      descrizione: 'Assegno mensile per invalidi civili parziali (74-99%), età 18-67 anni, con reddito personale sotto la soglia.',
      importo: '€340,71/mese × 13 mensilità',
      categoria: 'disabilita',
      icona: '🩺',
      comeRichiederlo: 'Domanda INPS online o tramite Patronato con certificato medico di invalidità.',
      documentiNecessari: 'Certificato invalidità 74-99%, reddito personale < €5.725,46/anno',
      check: (p) => p.disabilita && p.eta >= 18 && p.eta < 67 && p.fasciaReddito == '<8k',
    ),

    Diritto(
      titolo: 'Pensione di Inabilità Civile (Invalidi 100%)',
      descrizione: 'Prestazione assistenziale INPS per invalidi civili totali (100%) tra 18 e 67 anni, con limite di reddito personale.',
      importo: '€340,71/mese × 13 mensilità + maggiorazioni',
      categoria: 'disabilita',
      icona: '♿',
      comeRichiederlo: 'Certificato medico SS3 + domanda INPS online + visita Commissione.',
      documentiNecessari: 'Certificato medico, verbale invalidità 100%',
      check: (p) => p.disabilita && p.eta >= 18 && p.eta < 67 && (p.fasciaReddito == '<8k' || p.fasciaReddito == '8-15k'),
    ),

    Diritto(
      titolo: 'Permessi Legge 104',
      descrizione: 'Permessi lavorativi retribuiti per lavoratore disabile grave o per chi assiste familiare disabile grave. Dal 2026: 3 giorni mensili + 10 ore annuali per visite/terapie.',
      importo: '3 giorni/mese + 10 ore/anno (100% retribuzione)',
      categoria: 'disabilita',
      icona: '🤝',
      comeRichiederlo: 'Domanda INPS online + comunicazione al datore di lavoro.',
      documentiNecessari: 'Verbale Commissione ASL/INPS attestante handicap grave (art. 3 c. 3)',
      check: (p) => p.disabilita && (p.situazioneLavoro == 'dipendente' || p.situazioneLavoro == 'cococo'),
    ),

    Diritto(
      titolo: 'Agevolazioni Auto Disabili (IVA 4% + Bollo + IRPEF)',
      descrizione: 'Pacchetto: IVA 4% anziché 22%, esenzione permanente bollo auto, esenzione imposta trascrizione PRA, detrazione IRPEF 19% fino a €18.075,99.',
      importo: 'Risparmio fiscale fino a €5.000+ totali',
      categoria: 'disabilita',
      icona: '🚙',
      comeRichiederlo: 'IVA 4%: in concessionaria. Bollo: Regione/ACI prima volta. Detrazione: in dichiarazione.',
      documentiNecessari: 'Verbale L.104 con ridotta capacità motoria, libretto auto, eventuale patente speciale',
      check: (p) => p.disabilita,
    ),

    Diritto(
      titolo: 'Home Care Premium (Dipendenti Pubblici)',
      descrizione: 'Contributo INPS per assistenza domiciliare a dipendenti/pensionati pubblici e loro familiari non autosufficienti (anche minori).',
      importo: 'Fino a €1.380/mese (in base a ISEE)',
      categoria: 'disabilita',
      icona: '🏡',
      comeRichiederlo: 'Domanda INPS online ("Welfare Richieste in un click").',
      documentiNecessari: 'Iscrizione Gestione Unitaria INPS, ISEE sociosanitario, verbale non autosufficienza',
      check: (p) => p.disabilita && (p.situazioneLavoro == 'dipendente' || p.situazioneLavoro == 'pensionato'),
    ),

    // ═══════════════════════════════════════════════════════════════════
    // ANZIANI
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Pensione di Vecchiaia',
      descrizione: 'Pensione INPS al raggiungimento di 67 anni di età con almeno 20 anni di contributi.',
      importo: 'Calcolo contributivo (min 1,5× assegno sociale per contributivo puro)',
      categoria: 'anziani',
      icona: '👴',
      comeRichiederlo: 'Domanda INPS online tramite SPID/CIE/CNS o patronato.',
      documentiNecessari: 'Estratto contributivo con almeno 20 anni di contributi, documenti identità',
      check: (p) => p.eta >= 67,
    ),

    Diritto(
      titolo: 'Assegno Sociale',
      descrizione: 'Prestazione assistenziale INPS per cittadini over 67 senza pensione contributiva e con redditi minimi. 13 mensilità.',
      importo: '€546,24/mese (€7.101,12/anno)',
      categoria: 'anziani',
      icona: '🧓',
      comeRichiederlo: 'Domanda INPS online o tramite Patronato.',
      documentiNecessari: 'Redditi bassi, residenza Italia ≥ 10 anni, permesso UE per extra-UE',
      check: (p) => p.eta >= 67 && p.fasciaReddito == '<8k' && (p.isItaliano || p.cittadinanza == 'ue' || (p.isExtraUE && p.anniInItalia >= 10)),
    ),

    Diritto(
      titolo: 'Quattordicesima Pensionati',
      descrizione: 'Somma aggiuntiva annuale erogata d\'ufficio dall\'INPS a luglio ai pensionati con reddito basso e almeno 64 anni. Esente IRPEF.',
      importo: '€336–€655/anno (in base a reddito e anni contribuzione)',
      categoria: 'anziani',
      icona: '💸',
      comeRichiederlo: 'Automatica — INPS la accredita con cedolino di luglio.',
      documentiNecessari: 'Nessuno',
      check: (p) => p.eta >= 64 && p.situazioneLavoro == 'pensionato' && (p.fasciaReddito == '<8k' || p.fasciaReddito == '8-15k'),
    ),

    Diritto(
      titolo: 'Integrazione al Trattamento Minimo',
      descrizione: 'Maggiorazione INPS per pensioni che non raggiungono il trattamento minimo (€603,40/mese × 13 mensilità nel 2026).',
      importo: 'Differenza fino a €603,40/mese',
      categoria: 'anziani',
      icona: '💰',
      comeRichiederlo: 'Automatico — INPS verifica all\'erogazione della pensione.',
      documentiNecessari: 'Reddito personale e coniugale entro soglie',
      check: (p) => p.situazioneLavoro == 'pensionato' && (p.fasciaReddito == '<8k' || p.fasciaReddito == '8-15k'),
    ),

    Diritto(
      titolo: 'APE Sociale 2026',
      descrizione: 'Indennità ponte fino alla pensione di vecchiaia per: disoccupati post-NASpI, caregiver, invalidi, lavoratori gravosi.',
      importo: 'Pari alla pensione maturata (max €1.500/mese × 12)',
      categoria: 'anziani',
      icona: '⏳',
      comeRichiederlo: 'Domanda verifica requisiti INPS entro 31 marzo, 15 luglio o 30 novembre.',
      documentiNecessari: 'Documentazione categoria di appartenenza, estratto contributivo',
      check: (p) => p.eta >= 63 && p.eta < 67 && (p.situazioneLavoro == 'disoccupato' || p.disabilita),
    ),

    Diritto(
      titolo: 'Prestazione Universale Anziani Non Autosufficienti',
      descrizione: 'Misura sperimentale INPS (fino al 31/12/2026) per ultraottantenni non autosufficienti gravissimi con ISEE basso. Si somma all\'Indennità di Accompagnamento.',
      importo: '€552,57 (accompagnamento) + €850 quota integrativa = max €1.402,57/mese',
      categoria: 'anziani',
      icona: '🏥',
      comeRichiederlo: 'Domanda INPS online (sezione "Decreto Anziani — Prestazione Universale").',
      documentiNecessari: 'ISEE sociosanitario < €6.000, valutazione fabbisogno gravissimo',
      check: (p) => p.eta >= 80 && p.isee > 0 && p.isee < 6000 && p.disabilita,
    ),

    Diritto(
      titolo: 'Esenzione Canone RAI Over 75',
      descrizione: 'Esenzione totale canone RAI (€90/anno) per ultrasettantacinquenni con reddito proprio + coniuge ≤ €8.000.',
      importo: '€90/anno risparmio',
      categoria: 'anziani',
      icona: '📺',
      comeRichiederlo: 'Modulo dichiarazione sostitutiva Agenzia Entrate (online o cartaceo) entro 30 aprile.',
      documentiNecessari: 'Dichiarazione redditi, documento d\'identità',
      check: (p) => p.eta >= 75 && p.fasciaReddito == '<8k',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // IMMIGRAZIONE
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Cittadinanza Italiana per Residenza',
      descrizione: 'Naturalizzazione dopo 10 anni di residenza legale continuativa (4 anni per cittadini UE, 5 per rifugiati e apolidi).',
      importo: 'Diritto permanente (passaporto italiano e UE)',
      categoria: 'immigrazione',
      icona: '🇮🇹',
      comeRichiederlo: 'Domanda online portaleservizi.dlci.interno.it con SPID. Contributo €250.',
      documentiNecessari: 'Atto di nascita apostillato e tradotto, penale paese origine, redditi ultimi 3 anni, B1 italiano, bolli €16 + €250',
      check: (p) => !p.isItaliano && ((p.isExtraUE && p.anniInItalia >= 10) || (p.cittadinanza == 'ue' && p.anniInItalia >= 4)),
    ),

    Diritto(
      titolo: 'Permesso UE Soggiornanti Lungo Periodo',
      descrizione: 'Permesso di soggiorno a tempo indeterminato (ex "carta di soggiorno") dopo 5 anni di residenza legale continuativa per extracomunitari.',
      importo: 'Permesso permanente',
      categoria: 'immigrazione',
      icona: '📄',
      comeRichiederlo: 'Kit postale Poste Italiane → appuntamento Questura.',
      documentiNecessari: 'Permesso valido da almeno 5 anni, reddito min (€6.947,33/anno = assegno sociale), alloggio idoneo, attestato A2',
      check: (p) => p.isExtraUE && p.anniInItalia >= 5,
    ),

    Diritto(
      titolo: 'Ricongiungimento Familiare',
      descrizione: 'Procedura per cittadino non-UE di portare in Italia coniuge, figli minori, figli maggiorenni a carico, genitori over 65 a carico.',
      importo: 'Diritto al permesso di soggiorno per i familiari',
      categoria: 'immigrazione',
      icona: '👨‍👩‍👧‍👦',
      comeRichiederlo: 'Nulla osta allo Sportello Unico Immigrazione (SUI) della Prefettura.',
      documentiNecessari: 'Reddito ≥ €7.101,12 + 50% per ogni familiare, alloggio idoneo, permesso > 1 anno',
      check: (p) => p.isExtraUE && p.anniInItalia >= 1,
    ),

    Diritto(
      titolo: 'Conversione Permesso Studio → Lavoro',
      descrizione: 'Conversione semplificata dal 2026: senza limiti numerici e in qualsiasi momento dell\'anno, anche prima della laurea per corsi universitari.',
      importo: 'Passaggio al permesso di lavoro',
      categoria: 'immigrazione',
      icona: '🔄',
      comeRichiederlo: 'Domanda Questura + contratto di lavoro firmato.',
      documentiNecessari: 'Contratto lavoro, permesso studio valido, passaporto',
      check: (p) => p.isExtraUE && p.situazioneLavoro == 'studente',
    ),
  ];
}
