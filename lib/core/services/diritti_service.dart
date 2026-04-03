import 'profilo_utente_service.dart';

// ---------------------------------------------------------------------------
// Diritti e Bonus — matching con profilo utente
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

  static final List<Diritto> _tuttiDiritti = [
    // ── FAMIGLIA ──
    Diritto(
      titolo: 'Assegno Unico Figli',
      descrizione: 'Assegno mensile per ogni figlio a carico fino a 21 anni. Importo varia in base all\'ISEE.',
      importo: 'Da €57 a €199,40/mese per figlio',
      categoria: 'famiglia',
      icona: '👶',
      comeRichiederlo: 'Domanda online su sito INPS o tramite patronato. Serve ISEE in corso di validità.',
      documentiNecessari: 'ISEE in corso di validità, codice fiscale figli, IBAN',
      check: (p) => p.numeriFigli > 0 && p.etaFigli.any((e) => e < 21),
    ),
    Diritto(
      titolo: 'Bonus Asilo Nido',
      descrizione: 'Contributo per pagare le rette dell\'asilo nido, pubblico o privato.',
      importo: 'Da €1.500 a €3.600/anno',
      categoria: 'famiglia',
      icona: '🏫',
      comeRichiederlo: 'Domanda online su sito INPS. Allegare ricevute di pagamento rette.',
      documentiNecessari: 'ISEE, ricevute rette asilo, codice fiscale figlio',
      check: (p) => p.numeriFigli > 0 && p.etaFigli.any((e) => e <= 3),
    ),
    Diritto(
      titolo: 'Bonus Mamme Lavoratrici',
      descrizione: 'Esonero contributi INPS per madri lavoratrici con 2+ figli.',
      importo: 'Fino a €3.000/anno',
      categoria: 'famiglia',
      icona: '👩',
      comeRichiederlo: 'Automatico in busta paga. Comunicare al datore di lavoro i codici fiscali dei figli.',
      documentiNecessari: 'Codice fiscale figli',
      check: (p) => p.numeriFigli >= 2 && p.lavora,
    ),
    Diritto(
      titolo: 'Assegno di Maternità del Comune',
      descrizione: 'Assegno per madri che NON lavorano o con ISEE basso.',
      importo: '€1.917,30 (5 mensilità)',
      categoria: 'famiglia',
      icona: '🤱',
      comeRichiederlo: 'Domanda al Comune di residenza entro 6 mesi dalla nascita.',
      documentiNecessari: 'ISEE sotto €19.185,13, certificato nascita, documento identità',
      check: (p) => p.numeriFigli > 0 && p.etaFigli.any((e) => e == 0) && p.isee < 19185,
    ),

    // ── LAVORO ──
    Diritto(
      titolo: 'NASpI (disoccupazione)',
      descrizione: 'Indennità mensile di disoccupazione per chi perde il lavoro involontariamente.',
      importo: 'Fino a €1.550,42/mese',
      categoria: 'lavoro',
      icona: '💼',
      comeRichiederlo: 'Domanda online su sito INPS entro 68 giorni dal licenziamento.',
      documentiNecessari: 'Lettera di licenziamento, ultime buste paga, IBAN, documento identità',
      check: (p) => !p.lavora || p.tipoContratto == 'disoccupato',
    ),
    Diritto(
      titolo: 'DIS-COLL',
      descrizione: 'Indennità di disoccupazione per collaboratori coordinati e continuativi.',
      importo: 'Fino a €1.550,42/mese',
      categoria: 'lavoro',
      icona: '📋',
      comeRichiederlo: 'Domanda online su sito INPS entro 68 giorni dalla fine del contratto.',
      documentiNecessari: 'Contratto scaduto, documento identità, IBAN',
      check: (p) => !p.lavora,
    ),
    Diritto(
      titolo: 'Trattamento Integrativo (ex Bonus Renzi)',
      descrizione: 'Credito IRPEF per lavoratori dipendenti con reddito fino a €28.000.',
      importo: '€100/mese (€1.200/anno)',
      categoria: 'lavoro',
      icona: '💰',
      comeRichiederlo: 'Automatico in busta paga. Verificare che sia applicato.',
      documentiNecessari: 'Nessuno, è automatico',
      check: (p) => p.lavora && p.isee < 28000 && p.isee > 0,
    ),

    // ── CASA ──
    Diritto(
      titolo: 'Bonus Bollette Luce e Gas',
      descrizione: 'Sconto automatico sulle bollette di luce e gas per famiglie con ISEE basso.',
      importo: 'Da €150 a €600/anno',
      categoria: 'casa',
      icona: '💡',
      comeRichiederlo: 'Automatico con ISEE sotto la soglia. Basta avere ISEE aggiornato.',
      documentiNecessari: 'ISEE in corso di validità (sotto €9.530 o €20.000 con 4+ figli)',
      check: (p) => p.isee > 0 && (p.isee < 9530 || (p.isee < 20000 && p.numeriFigli >= 4)),
    ),
    Diritto(
      titolo: 'Bonus Affitto Giovani',
      descrizione: 'Detrazione per giovani tra 20 e 31 anni che vivono in affitto.',
      importo: 'Fino a €2.000/anno',
      categoria: 'casa',
      icona: '🏠',
      comeRichiederlo: 'Indicare nel 730 il contratto di affitto registrato.',
      documentiNecessari: 'Contratto di affitto registrato, dichiarazione dei redditi',
      check: (p) => p.eta >= 20 && p.eta <= 31,
    ),

    // ── INCLUSIONE SOCIALE ──
    Diritto(
      titolo: 'Assegno di Inclusione (ADI)',
      descrizione: 'Sostegno economico per famiglie in difficoltà con componenti fragili (over 60, minori, disabili).',
      importo: 'Da €480 a €780/mese + contributo affitto',
      categoria: 'famiglia',
      icona: '🤝',
      comeRichiederlo: 'Domanda online su sito INPS. Serve ISEE sotto €9.360.',
      documentiNecessari: 'ISEE sotto €9.360, documento identità, permesso di soggiorno (se extracomunitario), IBAN',
      check: (p) => p.isee > 0 && p.isee < 9360 && (p.numeriFigli > 0 && p.etaFigli.any((e) => e < 18) || p.eta >= 60 || p.disabilita),
    ),
    Diritto(
      titolo: 'Supporto Formazione e Lavoro (SFL)',
      descrizione: 'Per chi ha 18-59 anni, abile al lavoro, con ISEE basso. Partecipazione a corsi di formazione.',
      importo: '€350/mese durante la formazione',
      categoria: 'lavoro',
      icona: '📚',
      comeRichiederlo: 'Domanda online su sito INPS. Iscriversi a un corso di formazione.',
      documentiNecessari: 'ISEE sotto €6.000, documento identità, permesso di soggiorno',
      check: (p) => p.isee > 0 && p.isee < 6000 && p.eta >= 18 && p.eta < 60 && !p.lavora,
    ),

    // ── SALUTE ──
    Diritto(
      titolo: 'Esenzione Ticket Sanitario',
      descrizione: 'Esenzione dal pagamento del ticket per visite ed esami medici.',
      importo: 'Risparmio su tutte le visite',
      categoria: 'salute',
      icona: '🏥',
      comeRichiederlo: 'Richiesta alla ASL con ISEE o certificato medico.',
      documentiNecessari: 'ISEE oppure certificato medico di patologia cronica',
      check: (p) => p.isee > 0 && p.isee < 8263 || p.eta < 6 || p.eta >= 65 || p.disabilita,
    ),
    Diritto(
      titolo: 'Carta Acquisti (Social Card)',
      descrizione: 'Carta prepagata da €80 bimestrali per acquisti alimentari e bollette.',
      importo: '€480/anno',
      categoria: 'famiglia',
      icona: '🛒',
      comeRichiederlo: 'Domanda all\'ufficio postale.',
      documentiNecessari: 'ISEE sotto €7.640,18, documento identità. Per over 65 o genitori di bimbi under 3.',
      check: (p) => p.isee > 0 && p.isee < 7640 && (p.eta >= 65 || (p.numeriFigli > 0 && p.etaFigli.any((e) => e < 3))),
    ),

    // ── GIOVANI ──
    Diritto(
      titolo: 'Bonus Cultura 18enni',
      descrizione: 'Carta cultura e carta del merito per i giovani di 18 anni.',
      importo: 'Fino a €500',
      categoria: 'giovani',
      icona: '🎓',
      comeRichiederlo: 'Registrarsi su 18app.italia.it con SPID.',
      documentiNecessari: 'SPID, ISEE sotto €35.000',
      check: (p) => p.eta == 18 && p.isee < 35000,
    ),

    // ── DISABILITÀ ──
    Diritto(
      titolo: 'Indennità di Accompagnamento',
      descrizione: 'Per persone con invalidità civile al 100% che necessitano di assistenza.',
      importo: '€531,76/mese',
      categoria: 'disabilita',
      icona: '♿',
      comeRichiederlo: 'Domanda INPS con certificato medico di invalidità civile.',
      documentiNecessari: 'Certificato invalidità 100%, verbale commissione medica',
      check: (p) => p.disabilita,
    ),
    Diritto(
      titolo: 'Assegno di Invalidità Civile',
      descrizione: 'Assegno mensile per invalidità civile parziale (74-99%).',
      importo: '€316,98/mese',
      categoria: 'disabilita',
      icona: '🩺',
      comeRichiederlo: 'Domanda INPS con certificato medico.',
      documentiNecessari: 'Certificato invalidità, ISEE, documento identità',
      check: (p) => p.disabilita && p.isee < 5500,
    ),

    // ── PERMESSO DI SOGGIORNO ──
    Diritto(
      titolo: 'Cittadinanza Italiana',
      descrizione: 'Puoi richiedere la cittadinanza italiana se risiedi da almeno 10 anni (UE: 4 anni).',
      importo: 'Diritto permanente',
      categoria: 'giovani',
      icona: '🇮🇹',
      comeRichiederlo: 'Domanda online su sito del Ministero dell\'Interno.',
      documentiNecessari: 'Certificato nascita apostillato e tradotto, certificato penale del paese di origine, ISEE, B1 italiano',
      check: (p) => p.tipoPermesso != 'cittadino_italiano' && p.anniInItalia >= 10,
    ),
    Diritto(
      titolo: 'Permesso Lungo Soggiornante',
      descrizione: 'Permesso di soggiorno illimitato dopo 5 anni di residenza legale.',
      importo: 'Permesso permanente',
      categoria: 'giovani',
      icona: '📄',
      comeRichiederlo: 'Domanda alla Questura tramite kit postale.',
      documentiNecessari: 'Permesso di soggiorno valido, reddito minimo, alloggio, test italiano A2',
      check: (p) => p.tipoPermesso != 'cittadino_italiano' && p.tipoPermesso != 'lungo_soggiornante' && p.tipoPermesso != 'cittadino_ue' && p.anniInItalia >= 5,
    ),
  ];
}
