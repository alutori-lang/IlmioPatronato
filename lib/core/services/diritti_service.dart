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
  final String categoria; // 'famiglia', 'lavoro', 'casa', 'salute', 'giovani', 'disabilita'
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

  // Helper condivisi
  static bool _haPermessoValido(ProfiloUtente p) =>
      p.isItaliano || p.isUE || (p.isExtraUE && p.anniInItalia > 0);

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
      comeRichiederlo: 'Domanda online su INPS.it (sezione "Assegno Unico"), App INPS Mobile, o tramite Patronato. Serve ISEE in corso di validità per ottenere importi sopra il minimo.',
      documentiNecessari: 'ISEE in corso di validità (minorenni), codici fiscali figli, IBAN intestato/cointestato al richiedente',
      check: (p) => p.numeriFigli > 0 && p.etaFigli.any((e) => e < 21) && _haPermessoValido(p),
    ),

    Diritto(
      titolo: 'Bonus Nuovi Nati 2026',
      descrizione: 'Contributo di €1.000 una tantum per ogni figlio nato o adottato dal 1° gennaio 2025.',
      importo: '€1.000 una tantum',
      categoria: 'famiglia',
      icona: '🍼',
      comeRichiederlo: 'Domanda online su INPS.it entro 120 giorni dalla nascita o dall\'ingresso in famiglia del minore.',
      documentiNecessari: 'ISEE minorenni non superiore a €40.000, certificato di nascita/adozione, codice fiscale del neonato, IBAN',
      check: (p) => p.numeriFigli > 0 && p.etaFigli.any((e) => e == 0) && p.isee > 0 && p.isee <= 40000 && _haPermessoValido(p),
    ),

    Diritto(
      titolo: 'Bonus Asilo Nido',
      descrizione: 'Contributo per pagare le rette di asilo nido pubblico o privato autorizzato (o supporto domiciliare per bimbi con gravi patologie).',
      importo: 'Da €1.500 a €3.600/anno (in base a ISEE)',
      categoria: 'famiglia',
      icona: '🏫',
      comeRichiederlo: 'Domanda online su INPS.it allegando le ricevute di pagamento delle rette.',
      documentiNecessari: 'ISEE minorenni, ricevute pagamento rette asilo, codice fiscale figlio',
      check: (p) => p.numeriFigli > 0 && p.etaFigli.any((e) => e <= 3) && _haPermessoValido(p),
    ),

    Diritto(
      titolo: 'Bonus Mamme Lavoratrici',
      descrizione: 'Esonero contributivo INPS per madri lavoratrici con 2 o più figli (tempo indeterminato o determinato dal 2026).',
      importo: 'Fino a €3.000/anno (€250/mese max)',
      categoria: 'famiglia',
      icona: '👩',
      comeRichiederlo: 'Automatico in busta paga dopo aver comunicato al datore di lavoro i codici fiscali dei figli.',
      documentiNecessari: 'Codici fiscali dei figli',
      check: (p) => p.sesso == 'F' && p.numeriFigli >= 2 && (p.situazioneLavoro == 'dipendente' || p.situazioneLavoro == 'cococo'),
    ),

    Diritto(
      titolo: 'Assegno di Maternità del Comune',
      descrizione: 'Assegno del Comune per madri che NON lavorano (o senza altra indennità di maternità) con ISEE basso.',
      importo: '€2.091,62 totali (5 mensilità)',
      categoria: 'famiglia',
      icona: '🤱',
      comeRichiederlo: 'Domanda al Comune di residenza entro 6 mesi dalla nascita o dall\'ingresso in famiglia del minore.',
      documentiNecessari: 'ISEE sotto €20.221,13, certificato di nascita, documento d\'identità, permesso di soggiorno (se extraUE)',
      check: (p) => p.sesso == 'F' &&
          p.numeriFigli > 0 &&
          p.etaFigli.any((e) => e == 0) &&
          p.isee > 0 &&
          p.isee < 20221 &&
          (p.situazioneLavoro == 'disoccupato' || p.situazioneLavoro == 'studente'),
    ),

    Diritto(
      titolo: 'Carta Acquisti (Social Card)',
      descrizione: 'Carta prepagata da €80 bimestrali per acquisti alimentari, farmaceutici e bollette luce/gas. Per over 65 o genitori di bimbi under 3.',
      importo: '€480/anno (€80 ogni 2 mesi)',
      categoria: 'famiglia',
      icona: '🛒',
      comeRichiederlo: 'Domanda presso un ufficio postale abilitato con modulo ministeriale.',
      documentiNecessari: 'ISEE sotto €8.117,87, documento d\'identità, codice fiscale',
      check: (p) => p.isee > 0 && p.isee < 8117 && (p.eta >= 65 || (p.numeriFigli > 0 && p.etaFigli.any((e) => e < 3))),
    ),

    Diritto(
      titolo: 'Assegno di Inclusione (ADI)',
      descrizione: 'Sostegno economico per famiglie in difficoltà con componenti fragili: minori, over 60, persone con disabilità, o in percorsi di cura sociosanitari.',
      importo: 'Da €500 a €800/mese + fino a €280/mese per affitto',
      categoria: 'famiglia',
      icona: '🤝',
      comeRichiederlo: 'Domanda online su INPS.it o tramite Patronato/CAF. Obbligo di sottoscrivere il Patto per l\'Inclusione al Servizio Sociale del Comune.',
      documentiNecessari: 'ISEE sotto €10.140, documento d\'identità, permesso di soggiorno (min. 5 anni in Italia se extraUE, di cui 2 continuativi), IBAN',
      check: (p) => p.isee > 0 &&
          p.isee < 10140 &&
          p.haComponentiFragili &&
          (p.isItaliano || p.isUE || (p.isExtraUE && p.anniInItalia >= 5)),
    ),

    // ═══════════════════════════════════════════════════════════════════
    // LAVORO
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'NASpI (Nuova Assicurazione Sociale per l\'Impiego)',
      descrizione: 'Indennità mensile di disoccupazione per lavoratori dipendenti che hanno perso il lavoro involontariamente (richiede almeno 13 settimane di contributi nei 4 anni precedenti).',
      importo: 'Fino a €1.562,82/mese (durata max 24 mesi, riduzione 3% mensile dal 6° mese)',
      categoria: 'lavoro',
      icona: '💼',
      comeRichiederlo: 'Domanda online su INPS.it entro 68 giorni dal licenziamento. Registrazione obbligatoria al Centro per l\'Impiego.',
      documentiNecessari: 'Lettera di licenziamento/dimissioni per giusta causa, ultime buste paga, documento d\'identità, IBAN',
      check: (p) => p.situazioneLavoro == 'disoccupato',
    ),

    Diritto(
      titolo: 'DIS-COLL',
      descrizione: 'Indennità di disoccupazione specifica per collaboratori coordinati e continuativi (co.co.co.) iscritti alla Gestione Separata INPS, che hanno perso il contratto.',
      importo: 'Fino a €1.562,82/mese',
      categoria: 'lavoro',
      icona: '📋',
      comeRichiederlo: 'Domanda online su INPS.it entro 68 giorni dalla fine del contratto di collaborazione.',
      documentiNecessari: 'Contratto scaduto, certificazione unica, documento d\'identità, IBAN',
      // DIS-COLL si applica a co.co.co. che hanno perso il lavoro — qui approssimiamo: disoccupato che però ha avuto co.co.co. prima
      check: (p) => p.situazioneLavoro == 'disoccupato',
    ),

    Diritto(
      titolo: 'Supporto per la Formazione e il Lavoro (SFL)',
      descrizione: 'Misura per adulti 18-59 anni, attivabili al lavoro, con ISEE basso e SENZA componenti fragili nel nucleo (chi ha minori/disabili/over 60 va sull\'ADI). Obbligo di iscrizione al Centro per l\'Impiego e partecipazione a corsi di formazione.',
      importo: '€500/mese per 12 mesi (estendibili a 24 se si frequenta formazione)',
      categoria: 'lavoro',
      icona: '📚',
      comeRichiederlo: 'Domanda online su INPS.it + firma del Patto di Attivazione Digitale (PAD) e iscrizione a un corso.',
      documentiNecessari: 'ISEE sotto €10.140, documento d\'identità, permesso di soggiorno valido, IBAN',
      check: (p) => p.isee > 0 &&
          p.isee < 10140 &&
          p.eta >= 18 &&
          p.eta < 60 &&
          p.situazioneLavoro == 'disoccupato' &&
          !p.haComponentiFragili,
    ),

    Diritto(
      titolo: 'Trattamento Integrativo (ex Bonus IRPEF)',
      descrizione: 'Credito IRPEF in busta paga per lavoratori dipendenti con reddito complessivo fino a €15.000 (fino a €28.000 in casi di capienza fiscale).',
      importo: 'Fino a €1.200/anno (€100/mese)',
      categoria: 'lavoro',
      icona: '💰',
      comeRichiederlo: 'Automatico in busta paga se si ha capienza fiscale. Verificare sulla CU o chiedere al datore di lavoro.',
      documentiNecessari: 'Nessuno — erogazione automatica',
      check: (p) => p.situazioneLavoro == 'dipendente' &&
          (p.fasciaReddito == '8-15k' || p.fasciaReddito == '15-28k'),
    ),

    // ═══════════════════════════════════════════════════════════════════
    // CASA
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Bonus Sociale Luce, Gas e Idrico',
      descrizione: 'Sconto automatico applicato sulle bollette di luce, gas e acqua per famiglie con ISEE basso.',
      importo: 'Stimato da €150 a €600/anno a seconda del nucleo e consumi',
      categoria: 'casa',
      icona: '💡',
      comeRichiederlo: 'Automatico con ISEE in corso di validità: basta presentare la DSU ogni anno al CAF. Nessuna domanda aggiuntiva.',
      documentiNecessari: 'ISEE in corso di validità (sotto €9.530, oppure sotto €20.000 con 4+ figli a carico)',
      check: (p) => p.isee > 0 && (p.isee < 9530 || (p.isee < 20000 && p.numeriFigli >= 4)),
    ),

    Diritto(
      titolo: 'Detrazione Affitto Giovani',
      descrizione: 'Detrazione IRPEF per giovani tra 20 e 31 anni che vivono in affitto (contratto registrato, anche stanza singola) con reddito complessivo fino a €15.493,71.',
      importo: 'Detrazione di €991,60 o 20% del canone (max €2.000/anno)',
      categoria: 'casa',
      icona: '🏠',
      comeRichiederlo: 'Indicare il contratto di affitto registrato nella dichiarazione dei redditi (modello 730 o Redditi PF). Valida per i primi 4 anni del contratto.',
      documentiNecessari: 'Contratto di affitto registrato, ricevute pagamento canone, dichiarazione dei redditi',
      check: (p) => p.eta >= 20 &&
          p.eta <= 31 &&
          p.inAffitto &&
          (p.fasciaReddito == '<8k' || p.fasciaReddito == '8-15k'),
    ),

    // ═══════════════════════════════════════════════════════════════════
    // SALUTE
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Esenzione Ticket Sanitario per Reddito (E02)',
      descrizione: 'Esenzione dal pagamento del ticket per visite specialistiche ed esami diagnostici per famiglie con reddito sotto €8.263,31 + bonus €516,46 per coniuge e per ogni figlio a carico.',
      importo: 'Risparmio su tutte le prestazioni SSN',
      categoria: 'salute',
      icona: '🏥',
      comeRichiederlo: 'Richiesta alla ASL di residenza con autocertificazione reddito. Codice esenzione E02 stampato sulla ricetta.',
      documentiNecessari: 'Autocertificazione reddito familiare (sotto €8.263,31 + maggiorazioni)',
      check: (p) => p.fasciaReddito == '<8k',
    ),

    Diritto(
      titolo: 'Esenzione Ticket per Età (E01/E03/E04)',
      descrizione: 'Esenzione dal ticket sanitario automatica per minori di 6 anni e over 65 con reddito basso, o per specifiche categorie (disoccupati, pensionati sociali).',
      importo: 'Risparmio su tutte le prestazioni SSN',
      categoria: 'salute',
      icona: '🏥',
      comeRichiederlo: 'Automatica per età. Per over 65 serve anche autocertificazione reddito alla ASL.',
      documentiNecessari: 'Documento d\'identità, per over 65 anche autocertificazione reddito',
      check: (p) => p.eta < 6 || (p.eta >= 65 && (p.fasciaReddito == '<8k' || p.fasciaReddito == '8-15k')),
    ),

    // ═══════════════════════════════════════════════════════════════════
    // GIOVANI / CULTURA
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Carta Cultura Giovani',
      descrizione: 'Bonus €500 per acquistare libri, musei, cinema, teatro, concerti, corsi musicali, abbonamenti a quotidiani. Riservata ai 18enni di famiglie con ISEE sotto €35.000.',
      importo: '€500 spendibili entro l\'anno',
      categoria: 'giovani',
      icona: '🎓',
      comeRichiederlo: 'Registrazione sul portale cartegiovani.cultura.gov.it con SPID/CIE tra i 18 e i 19 anni.',
      documentiNecessari: 'SPID o CIE, ISEE del nucleo familiare sotto €35.000',
      check: (p) => p.eta == 18 && p.isee > 0 && p.isee < 35000,
    ),

    Diritto(
      titolo: 'Carta del Merito',
      descrizione: 'Bonus €500 per cultura riservato a chi consegue il diploma con 100/100 entro i 19 anni. Cumulabile con Carta Cultura Giovani. Nessun limite ISEE.',
      importo: '€500 spendibili entro l\'anno',
      categoria: 'giovani',
      icona: '🏆',
      comeRichiederlo: 'Registrazione sul portale cartegiovani.cultura.gov.it con SPID/CIE. Il voto viene verificato automaticamente dal MIUR.',
      documentiNecessari: 'SPID o CIE, diploma di maturità con voto 100/100',
      check: (p) => (p.eta == 18 || p.eta == 19) && p.merito100,
    ),

    // ═══════════════════════════════════════════════════════════════════
    // DISABILITÀ
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Indennità di Accompagnamento',
      descrizione: 'Prestazione economica per persone con invalidità civile al 100% riconosciuta con impossibilità a deambulare senza aiuto o a compiere atti quotidiani della vita. Non dipende da reddito né ISEE.',
      importo: '€542,02/mese per 12 mensilità',
      categoria: 'disabilita',
      icona: '♿',
      comeRichiederlo: 'Certificato medico telematico → domanda INPS online o tramite Patronato → visita commissione medica ASL/INPS.',
      documentiNecessari: 'Certificato di invalidità civile al 100% con indicazione di impossibilità a deambulare/compiere atti quotidiani',
      check: (p) => p.disabilita,
    ),

    Diritto(
      titolo: 'Pensione di Invalidità Civile',
      descrizione: 'Assegno mensile per invalidi civili parziali (74-99%) di età 18-67 anni, con reddito personale sotto la soglia.',
      importo: '€336,14/mese per 13 mensilità',
      categoria: 'disabilita',
      icona: '🩺',
      comeRichiederlo: 'Domanda INPS online o tramite Patronato con certificato medico di invalidità civile 74-99%.',
      documentiNecessari: 'Certificato di invalidità civile 74-99%, autocertificazione reddito personale sotto €5.725,46/anno',
      check: (p) => p.disabilita && p.eta >= 18 && p.eta < 67 && p.fasciaReddito == '<8k',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // IMMIGRAZIONE / PERMESSO DI SOGGIORNO
    // ═══════════════════════════════════════════════════════════════════

    Diritto(
      titolo: 'Cittadinanza Italiana per Residenza',
      descrizione: 'Puoi richiedere la cittadinanza italiana per naturalizzazione dopo 10 anni di residenza legale continuativa (4 anni per cittadini UE, 5 per rifugiati e apolidi).',
      importo: 'Diritto permanente (passaporto italiano e UE)',
      categoria: 'giovani',
      icona: '🇮🇹',
      comeRichiederlo: 'Domanda online sul portale del Ministero dell\'Interno (portaleservizi.dlci.interno.it) con SPID. Contributo €250.',
      documentiNecessari: 'Atto di nascita apostillato e tradotto, certificato penale del paese d\'origine, redditi ultimi 3 anni, certificato italiano B1, marca da bollo €16 + €250',
      check: (p) => !p.isItaliano &&
          ((p.isExtraUE && p.anniInItalia >= 10) || (p.cittadinanza == 'ue' && p.anniInItalia >= 4)),
    ),

    Diritto(
      titolo: 'Permesso di Soggiorno UE per Soggiornanti di Lungo Periodo',
      descrizione: 'Permesso di soggiorno a tempo indeterminato (ex "carta di soggiorno") rilasciato agli extracomunitari dopo 5 anni di residenza legale continuativa in Italia.',
      importo: 'Permesso permanente',
      categoria: 'giovani',
      icona: '📄',
      comeRichiederlo: 'Domanda tramite kit postale presso gli sportelli di Poste Italiane → appuntamento in Questura per il rilascio.',
      documentiNecessari: 'Permesso di soggiorno valido da almeno 5 anni, reddito minimo (assegno sociale = €6.947,33/anno per un componente), alloggio idoneo, attestato italiano A2',
      check: (p) => p.isExtraUE && p.anniInItalia >= 5,
    ),
  ];
}
