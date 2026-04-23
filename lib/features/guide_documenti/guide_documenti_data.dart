// Catalogo schede "Guida Documenti" per immigrati in Italia.
// Solo metadati statici (titolo, categoria, ente, link, emoji).
// Il contenuto dettagliato (cos'è, requisiti, documenti, procedura, costi,
// tempi, avvertenze, FAQ) viene generato on-demand da Gemini e cachato per
// lingua (vedi GuideAiService).

class GuidaCategoria {
  final String id;
  final String titolo;
  final String emoji;
  final int color;
  const GuidaCategoria({
    required this.id,
    required this.titolo,
    required this.emoji,
    required this.color,
  });
}

class GuidaScheda {
  final String id;
  final String categoriaId;
  final String titolo;
  final String descrizione;
  final String ente;
  final String linkUfficiale;
  final String emoji;
  const GuidaScheda({
    required this.id,
    required this.categoriaId,
    required this.titolo,
    required this.descrizione,
    required this.ente,
    required this.linkUfficiale,
    required this.emoji,
  });
}

const guideCategorie = <GuidaCategoria>[
  GuidaCategoria(id: 'arrivo',       titolo: 'Appena arrivato',        emoji: '🛬', color: 0xFF1565C0),
  GuidaCategoria(id: 'permesso',     titolo: 'Permesso di soggiorno',  emoji: '🪪', color: 0xFF2E7D32),
  GuidaCategoria(id: 'asilo',        titolo: 'Asilo e protezione',     emoji: '🏛️', color: 0xFF6A1B9A),
  GuidaCategoria(id: 'residenza',    titolo: 'Residenza & Anagrafe',   emoji: '🏠', color: 0xFFE65100),
  GuidaCategoria(id: 'fiscale',      titolo: 'Codice fiscale & TS',    emoji: '🔢', color: 0xFFC62828),
  GuidaCategoria(id: 'lavoro',       titolo: 'Lavoro',                 emoji: '💼', color: 0xFF0D47A1),
  GuidaCategoria(id: 'famiglia',     titolo: 'Famiglia',               emoji: '👨‍👩‍👦', color: 0xFFD81B60),
  GuidaCategoria(id: 'studio',       titolo: 'Studio',                 emoji: '📚', color: 0xFF4527A0),
  GuidaCategoria(id: 'patente',      titolo: 'Patente',                emoji: '🚗', color: 0xFF00838F),
  GuidaCategoria(id: 'cittadinanza', titolo: 'Cittadinanza',           emoji: '🇮🇹', color: 0xFF2E7D32),
  GuidaCategoria(id: 'diritti',      titolo: 'Diritti & ricorsi',      emoji: '🛡️', color: 0xFF37474F),
];

const guideSchede = <GuidaScheda>[
  // ─── Appena arrivato ───
  GuidaScheda(
    id: 'visto_ingresso',
    categoriaId: 'arrivo',
    titolo: 'Visto di ingresso in Italia',
    descrizione: 'Tipologie, richiesta al consolato italiano, documenti necessari.',
    ente: 'Consolato italiano',
    linkUfficiale: 'https://vistoperitalia.esteri.it/',
    emoji: '🛂',
  ),
  GuidaScheda(
    id: 'dichiarazione_presenza',
    categoriaId: 'arrivo',
    titolo: 'Dichiarazione di presenza (8 giorni)',
    descrizione: 'Chi arriva con visto turistico deve dichiarare la presenza entro 8 giorni.',
    ente: 'Questura / Polizia di frontiera',
    linkUfficiale: 'https://www.poliziadistato.it/articolo/1088',
    emoji: '⏱️',
  ),
  GuidaScheda(
    id: 'primi_passi',
    categoriaId: 'arrivo',
    titolo: 'Primi 10 passi appena arrivato',
    descrizione: 'Checklist: dichiarazione, codice fiscale, residenza, medico, scuola.',
    ente: 'Vari',
    linkUfficiale: 'https://www.integrazionemigranti.gov.it/',
    emoji: '✅',
  ),

  // ─── Permesso di soggiorno ───
  GuidaScheda(
    id: 'permesso_primo',
    categoriaId: 'permesso',
    titolo: 'Primo rilascio permesso di soggiorno',
    descrizione: 'Come richiederlo dopo l\'ingresso: kit postale, moduli, fototessere.',
    ente: 'Questura',
    linkUfficiale: 'https://www.portaleimmigrazione.it/',
    emoji: '📝',
  ),
  GuidaScheda(
    id: 'permesso_rinnovo',
    categoriaId: 'permesso',
    titolo: 'Rinnovo permesso di soggiorno',
    descrizione: 'Quando e come rinnovarlo. Scadenza, documenti, tempi.',
    ente: 'Questura',
    linkUfficiale: 'https://www.poliziadistato.it/articolo/213',
    emoji: '🔄',
  ),
  GuidaScheda(
    id: 'permesso_conversione',
    categoriaId: 'permesso',
    titolo: 'Conversione permesso (da studio a lavoro)',
    descrizione: 'Passaggio da un tipo di permesso a un altro.',
    ente: 'Questura / SUI',
    linkUfficiale: 'https://nullaostalavoro.dlci.interno.it/',
    emoji: '🔀',
  ),
  GuidaScheda(
    id: 'permesso_ue',
    categoriaId: 'permesso',
    titolo: 'Permesso UE per soggiornanti di lungo periodo',
    descrizione: 'Ex carta di soggiorno. Dopo 5 anni di residenza legale.',
    ente: 'Questura',
    linkUfficiale: 'https://www.poliziadistato.it/articolo/1051',
    emoji: '🇪🇺',
  ),

  // ─── Asilo e protezione ───
  GuidaScheda(
    id: 'asilo_richiesta',
    categoriaId: 'asilo',
    titolo: 'Richiesta di asilo (protezione internazionale)',
    descrizione: 'Come fare domanda di asilo politico in Italia.',
    ente: 'Questura / Commissione Territoriale',
    linkUfficiale: 'https://www.interno.gov.it/it/temi/immigrazione-e-asilo/protezione-internazionale',
    emoji: '🕊️',
  ),
  GuidaScheda(
    id: 'rifugiato',
    categoriaId: 'asilo',
    titolo: 'Status di rifugiato',
    descrizione: 'Chi può essere riconosciuto rifugiato, diritti, permesso 5 anni.',
    ente: 'Commissione Territoriale',
    linkUfficiale: 'https://www.unhcr.org/it/',
    emoji: '🛡️',
  ),
  GuidaScheda(
    id: 'protezione_sussidiaria',
    categoriaId: 'asilo',
    titolo: 'Protezione sussidiaria',
    descrizione: 'Per chi rischia danno grave se rimpatriato. Permesso 5 anni.',
    ente: 'Commissione Territoriale',
    linkUfficiale: 'https://www.interno.gov.it/it/temi/immigrazione-e-asilo/protezione-internazionale',
    emoji: '🛟',
  ),
  GuidaScheda(
    id: 'protezione_speciale',
    categoriaId: 'asilo',
    titolo: 'Protezione speciale e casi umanitari',
    descrizione: 'Permesso per ragioni umanitarie, salute, calamità, vittime tratta.',
    ente: 'Questura',
    linkUfficiale: 'https://www.poliziadistato.it/articolo/2371',
    emoji: '❤️‍🩹',
  ),

  // ─── Residenza & Anagrafe ───
  GuidaScheda(
    id: 'iscrizione_anagrafica',
    categoriaId: 'residenza',
    titolo: 'Iscrizione anagrafica / Residenza',
    descrizione: 'Come registrarsi all\'anagrafe del Comune dove vivi.',
    ente: 'Comune',
    linkUfficiale: 'https://www.anagrafenazionale.interno.gov.it/',
    emoji: '🏠',
  ),
  GuidaScheda(
    id: 'cambio_residenza',
    categoriaId: 'residenza',
    titolo: 'Cambio di residenza',
    descrizione: 'Quando cambi casa devi comunicarlo al Comune entro 20 giorni.',
    ente: 'Comune',
    linkUfficiale: 'https://www.anagrafenazionale.interno.gov.it/',
    emoji: '🚚',
  ),
  GuidaScheda(
    id: 'cie_straniero',
    categoriaId: 'residenza',
    titolo: 'Carta d\'identità (CIE) per stranieri',
    descrizione: 'Come richiedere la carta d\'identità elettronica se sei straniero residente.',
    ente: 'Comune',
    linkUfficiale: 'https://www.cartaidentita.interno.gov.it/',
    emoji: '🪪',
  ),
  GuidaScheda(
    id: 'stato_famiglia',
    categoriaId: 'residenza',
    titolo: 'Stato di famiglia',
    descrizione: 'Certificato della composizione del nucleo familiare. Quando serve.',
    ente: 'Comune',
    linkUfficiale: 'https://www.anagrafenazionale.interno.gov.it/',
    emoji: '👪',
  ),

  // ─── Codice fiscale & Tessera sanitaria ───
  GuidaScheda(
    id: 'codice_fiscale',
    categoriaId: 'fiscale',
    titolo: 'Codice fiscale',
    descrizione: 'Come richiederlo appena arrivato in Italia.',
    ente: 'Agenzia delle Entrate',
    linkUfficiale: 'https://www.agenziaentrate.gov.it/portale/schede/istanze/richiesta-ts_cf/richiesta-tessera-sanitaria-e-codice-fiscale',
    emoji: '🔢',
  ),
  GuidaScheda(
    id: 'ssn_iscrizione',
    categoriaId: 'fiscale',
    titolo: 'Iscrizione al SSN (Servizio Sanitario)',
    descrizione: 'Obbligatoria o volontaria, costi, diritti di cura.',
    ente: 'ASL',
    linkUfficiale: 'https://www.salute.gov.it/portale/temi/p2_6.jsp?lingua=italiano&id=906&area=Assistenza%20sanitaria',
    emoji: '🏥',
  ),
  GuidaScheda(
    id: 'medico_base',
    categoriaId: 'fiscale',
    titolo: 'Scelta del medico di base',
    descrizione: 'Come scegliere il tuo medico di famiglia (gratuito).',
    ente: 'ASL',
    linkUfficiale: 'https://www.salute.gov.it/',
    emoji: '👨‍⚕️',
  ),
  GuidaScheda(
    id: 'tessera_sanitaria',
    categoriaId: 'fiscale',
    titolo: 'Tessera sanitaria',
    descrizione: 'A cosa serve, come riceverla, come sostituirla.',
    ente: 'Agenzia delle Entrate',
    linkUfficiale: 'https://sistemats1.sanita.finanze.it/portale/',
    emoji: '💳',
  ),

  // ─── Lavoro ───
  GuidaScheda(
    id: 'nullaosta_lavoro',
    categoriaId: 'lavoro',
    titolo: 'Nulla osta al lavoro (decreto flussi)',
    descrizione: 'Entrare in Italia regolarmente per lavorare. Quote annuali.',
    ente: 'SUI - Sportello Unico Immigrazione',
    linkUfficiale: 'https://nullaostalavoro.dlci.interno.it/',
    emoji: '📃',
  ),
  GuidaScheda(
    id: 'cpi_iscrizione',
    categoriaId: 'lavoro',
    titolo: 'Iscrizione al Centro per l\'Impiego (CPI)',
    descrizione: 'Come iscriversi per cercare lavoro e accedere ai sussidi.',
    ente: 'Centro per l\'Impiego',
    linkUfficiale: 'https://www.anpal.gov.it/',
    emoji: '🔎',
  ),
  GuidaScheda(
    id: 'did',
    categoriaId: 'lavoro',
    titolo: 'DID - Dichiarazione Immediata Disponibilità',
    descrizione: 'Dichiarazione obbligatoria per chi cerca lavoro (NASpI, SIA...).',
    ente: 'ANPAL / CPI',
    linkUfficiale: 'https://myanpal.anpal.gov.it/',
    emoji: '✅',
  ),
  GuidaScheda(
    id: 'naspi',
    categoriaId: 'lavoro',
    titolo: 'NASpI - Sussidio di disoccupazione',
    descrizione: 'Indennità per chi perde il lavoro involontariamente.',
    ente: 'INPS',
    linkUfficiale: 'https://www.inps.it/it/it/inps-comunica/dossier/la-naspi.html',
    emoji: '💰',
  ),

  // ─── Famiglia ───
  GuidaScheda(
    id: 'ricongiungimento',
    categoriaId: 'famiglia',
    titolo: 'Ricongiungimento familiare',
    descrizione: 'Portare moglie/marito e figli in Italia. Requisiti reddito e alloggio.',
    ente: 'SUI - Sportello Unico',
    linkUfficiale: 'https://nullaostalavoro.dlci.interno.it/',
    emoji: '👨‍👩‍👧',
  ),
  GuidaScheda(
    id: 'permesso_familiari',
    categoriaId: 'famiglia',
    titolo: 'Permesso per motivi familiari',
    descrizione: 'Permesso per coniuge/figli di cittadino italiano o UE.',
    ente: 'Questura',
    linkUfficiale: 'https://www.poliziadistato.it/articolo/213',
    emoji: '❤️',
  ),
  GuidaScheda(
    id: 'matrimonio_italia',
    categoriaId: 'famiglia',
    titolo: 'Matrimonio in Italia (straniero)',
    descrizione: 'Nulla osta al matrimonio, pubblicazioni, documenti tradotti.',
    ente: 'Comune / Consolato',
    linkUfficiale: 'https://www.servizidemografici.interno.it/',
    emoji: '💒',
  ),

  // ─── Studio ───
  GuidaScheda(
    id: 'visto_studio',
    categoriaId: 'studio',
    titolo: 'Visto per studio',
    descrizione: 'Entrare in Italia per studiare. Università, scuole, corsi.',
    ente: 'Consolato / Università',
    linkUfficiale: 'https://www.studiare-in-italia.it/',
    emoji: '🎓',
  ),
  GuidaScheda(
    id: 'riconoscimento_titoli',
    categoriaId: 'studio',
    titolo: 'Riconoscimento titoli di studio esteri',
    descrizione: 'Far valere diploma/laurea presa all\'estero in Italia.',
    ente: 'MIM / Cimea',
    linkUfficiale: 'https://www.cimea.it/',
    emoji: '🏅',
  ),
  GuidaScheda(
    id: 'scuola_figli',
    categoriaId: 'studio',
    titolo: 'Iscrizione a scuola dei figli',
    descrizione: 'Iscrizione scuola pubblica anche senza permesso perfetto.',
    ente: 'MIM / Scuola',
    linkUfficiale: 'https://www.istruzione.it/iscrizionionline/',
    emoji: '🏫',
  ),

  // ─── Patente ───
  GuidaScheda(
    id: 'conversione_patente',
    categoriaId: 'patente',
    titolo: 'Conversione patente estera',
    descrizione: 'Convertire la patente del tuo Paese in patente italiana.',
    ente: 'Motorizzazione',
    linkUfficiale: 'https://www.ilportaledellautomobilista.it/',
    emoji: '🔁',
  ),
  GuidaScheda(
    id: 'patente_rinnovo',
    categoriaId: 'patente',
    titolo: 'Rinnovo patente',
    descrizione: 'Visita medica, costi, dove e quando farlo.',
    ente: 'Motorizzazione / ASL',
    linkUfficiale: 'https://www.ilportaledellautomobilista.it/',
    emoji: '🔄',
  ),

  // ─── Cittadinanza ───
  GuidaScheda(
    id: 'cittadinanza_residenza',
    categoriaId: 'cittadinanza',
    titolo: 'Cittadinanza per residenza (10 anni)',
    descrizione: 'Extra-UE: 10 anni di residenza legale. UE: 4 anni.',
    ente: 'Ministero Interno',
    linkUfficiale: 'https://cittadinanza.dlci.interno.it/',
    emoji: '⏳',
  ),
  GuidaScheda(
    id: 'cittadinanza_matrimonio',
    categoriaId: 'cittadinanza',
    titolo: 'Cittadinanza per matrimonio',
    descrizione: '2 anni se residente in Italia, 3 se all\'estero (dimezzati con figli).',
    ente: 'Ministero Interno',
    linkUfficiale: 'https://cittadinanza.dlci.interno.it/',
    emoji: '💍',
  ),
  GuidaScheda(
    id: 'test_b1',
    categoriaId: 'cittadinanza',
    titolo: 'Test B1 italiano per cittadinanza',
    descrizione: 'Come iscriversi, dove farlo, quanto costa, come prepararsi.',
    ente: 'CILS / CELI / PLIDA',
    linkUfficiale: 'https://cittadinanza.dlci.interno.it/',
    emoji: '📖',
  ),
  GuidaScheda(
    id: 'ius_sanguinis',
    categoriaId: 'cittadinanza',
    titolo: 'Cittadinanza per discendenza (ius sanguinis)',
    descrizione: 'Se hai un antenato italiano puoi richiedere la cittadinanza.',
    ente: 'Consolato italiano',
    linkUfficiale: 'https://www.esteri.it/it/servizi-consolari-e-visti/italiani-all-estero/cittadinanza/',
    emoji: '🌳',
  ),

  // ─── Diritti & ricorsi ───
  GuidaScheda(
    id: 'espulsione_ricorso',
    categoriaId: 'diritti',
    titolo: 'Espulsione e ricorso',
    descrizione: 'Cosa fare se ricevi un ordine di espulsione. Diritti e tempi.',
    ente: 'Giudice di Pace / TAR',
    linkUfficiale: 'https://www.asgi.it/',
    emoji: '⚖️',
  ),
  GuidaScheda(
    id: 'gratuito_patrocinio',
    categoriaId: 'diritti',
    titolo: 'Gratuito patrocinio (avvocato gratis)',
    descrizione: 'Se il reddito è basso puoi avere un avvocato pagato dallo Stato.',
    ente: 'Consiglio dell\'Ordine Avvocati',
    linkUfficiale: 'https://www.giustizia.it/giustizia/it/mg_2_4_3.page',
    emoji: '⚖️',
  ),
  GuidaScheda(
    id: 'discriminazione_lavoro',
    categoriaId: 'diritti',
    titolo: 'Tutela contro discriminazione sul lavoro',
    descrizione: 'Cosa fare se sei discriminato per origine/religione/genere.',
    ente: 'UNAR / Ispettorato',
    linkUfficiale: 'https://unar.it/',
    emoji: '🛡️',
  ),
];

List<GuidaScheda> schedePerCategoria(String categoriaId) =>
    guideSchede.where((s) => s.categoriaId == categoriaId).toList();

GuidaCategoria? categoriaById(String id) {
  for (final c in guideCategorie) {
    if (c.id == id) return c;
  }
  return null;
}

GuidaScheda? schedaById(String id) {
  for (final s in guideSchede) {
    if (s.id == id) return s;
  }
  return null;
}
