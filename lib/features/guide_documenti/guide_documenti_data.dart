// Catalogo schede "Guida Documenti" per immigrati in Italia.
// Solo metadati statici (titolo, categoria, ente, link, icona).
// Il contenuto dettagliato (cos'è, requisiti, documenti, procedura, costi,
// tempi, avvertenze, FAQ) viene generato on-demand da Gemini e cachato per
// lingua (vedi GuideAiService).

import 'package:flutter/material.dart';

class GuidaCategoria {
  final String id;
  final String titolo;
  final String emoji;
  final IconData icon;
  final int color;
  const GuidaCategoria({
    required this.id,
    required this.titolo,
    required this.emoji,
    required this.icon,
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
  final IconData icon;
  const GuidaScheda({
    required this.id,
    required this.categoriaId,
    required this.titolo,
    required this.descrizione,
    required this.ente,
    required this.linkUfficiale,
    required this.emoji,
    required this.icon,
  });
}

const guideCategorie = <GuidaCategoria>[
  GuidaCategoria(id: 'arrivo',       titolo: 'Appena arrivato',        emoji: '🛬', icon: Icons.flight_land,          color: 0xFF1565C0),
  GuidaCategoria(id: 'permesso',     titolo: 'Permesso di soggiorno',  emoji: '🪪', icon: Icons.contact_page,         color: 0xFF2E7D32),
  GuidaCategoria(id: 'asilo',        titolo: 'Asilo e protezione',     emoji: '🏛️', icon: Icons.account_balance,      color: 0xFF6A1B9A),
  GuidaCategoria(id: 'residenza',    titolo: 'Residenza & Anagrafe',   emoji: '🏠', icon: Icons.home_work,            color: 0xFFE65100),
  GuidaCategoria(id: 'fiscale',      titolo: 'Codice fiscale & TS',    emoji: '🔢', icon: Icons.credit_card,          color: 0xFFC62828),
  GuidaCategoria(id: 'lavoro',       titolo: 'Lavoro',                 emoji: '💼', icon: Icons.work,                 color: 0xFF0D47A1),
  GuidaCategoria(id: 'famiglia',     titolo: 'Famiglia',               emoji: '👨‍👩‍👦', icon: Icons.family_restroom,      color: 0xFFD81B60),
  GuidaCategoria(id: 'studio',       titolo: 'Studio',                 emoji: '📚', icon: Icons.school,               color: 0xFF4527A0),
  GuidaCategoria(id: 'patente',      titolo: 'Patente',                emoji: '🚗', icon: Icons.directions_car_filled, color: 0xFF00838F),
  GuidaCategoria(id: 'cittadinanza', titolo: 'Cittadinanza',           emoji: '🇮🇹', icon: Icons.flag,                 color: 0xFF2E7D32),
  GuidaCategoria(id: 'diritti',      titolo: 'Diritti & ricorsi',      emoji: '🛡️', icon: Icons.gavel,                color: 0xFF37474F),
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
    icon: Icons.airplane_ticket,
  ),
  GuidaScheda(
    id: 'dichiarazione_presenza',
    categoriaId: 'arrivo',
    titolo: 'Dichiarazione di presenza (8 giorni)',
    descrizione: 'Chi arriva con visto turistico deve dichiarare la presenza entro 8 giorni.',
    ente: 'Questura / Polizia di frontiera',
    linkUfficiale: 'https://www.poliziadistato.it/articolo/1088',
    emoji: '⏱️',
    icon: Icons.timer_outlined,
  ),
  GuidaScheda(
    id: 'primi_passi',
    categoriaId: 'arrivo',
    titolo: 'Primi 10 passi appena arrivato',
    descrizione: 'Checklist: dichiarazione, codice fiscale, residenza, medico, scuola.',
    ente: 'Vari',
    linkUfficiale: 'https://www.integrazionemigranti.gov.it/',
    emoji: '✅',
    icon: Icons.checklist_rounded,
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
    icon: Icons.edit_document,
  ),
  GuidaScheda(
    id: 'permesso_rinnovo',
    categoriaId: 'permesso',
    titolo: 'Rinnovo permesso di soggiorno',
    descrizione: 'Quando e come rinnovarlo. Scadenza, documenti, tempi.',
    ente: 'Questura',
    linkUfficiale: 'https://www.poliziadistato.it/articolo/213',
    emoji: '🔄',
    icon: Icons.autorenew,
  ),
  GuidaScheda(
    id: 'permesso_conversione',
    categoriaId: 'permesso',
    titolo: 'Conversione permesso (da studio a lavoro)',
    descrizione: 'Passaggio da un tipo di permesso a un altro.',
    ente: 'Questura / SUI',
    linkUfficiale: 'https://nullaostalavoro.dlci.interno.it/',
    emoji: '🔀',
    icon: Icons.swap_horiz,
  ),
  GuidaScheda(
    id: 'permesso_ue',
    categoriaId: 'permesso',
    titolo: 'Permesso UE per soggiornanti di lungo periodo',
    descrizione: 'Ex carta di soggiorno. Dopo 5 anni di residenza legale.',
    ente: 'Questura',
    linkUfficiale: 'https://www.poliziadistato.it/articolo/1051',
    emoji: '🇪🇺',
    icon: Icons.public,
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
    icon: Icons.support,
  ),
  GuidaScheda(
    id: 'rifugiato',
    categoriaId: 'asilo',
    titolo: 'Status di rifugiato',
    descrizione: 'Chi può essere riconosciuto rifugiato, diritti, permesso 5 anni.',
    ente: 'Commissione Territoriale',
    linkUfficiale: 'https://www.unhcr.org/it/',
    emoji: '🛡️',
    icon: Icons.shield_outlined,
  ),
  GuidaScheda(
    id: 'protezione_sussidiaria',
    categoriaId: 'asilo',
    titolo: 'Protezione sussidiaria',
    descrizione: 'Per chi rischia danno grave se rimpatriato. Permesso 5 anni.',
    ente: 'Commissione Territoriale',
    linkUfficiale: 'https://www.interno.gov.it/it/temi/immigrazione-e-asilo/protezione-internazionale',
    emoji: '🛟',
    icon: Icons.health_and_safety,
  ),
  GuidaScheda(
    id: 'protezione_speciale',
    categoriaId: 'asilo',
    titolo: 'Protezione speciale e casi umanitari',
    descrizione: 'Permesso per ragioni umanitarie, salute, calamità, vittime tratta.',
    ente: 'Questura',
    linkUfficiale: 'https://www.poliziadistato.it/articolo/2371',
    emoji: '❤️‍🩹',
    icon: Icons.healing,
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
    icon: Icons.home,
  ),
  GuidaScheda(
    id: 'cambio_residenza',
    categoriaId: 'residenza',
    titolo: 'Cambio di residenza',
    descrizione: 'Quando cambi casa devi comunicarlo al Comune entro 20 giorni.',
    ente: 'Comune',
    linkUfficiale: 'https://www.anagrafenazionale.interno.gov.it/',
    emoji: '🚚',
    icon: Icons.local_shipping,
  ),
  GuidaScheda(
    id: 'cie_straniero',
    categoriaId: 'residenza',
    titolo: 'Carta d\'identità (CIE) per stranieri',
    descrizione: 'Come richiedere la carta d\'identità elettronica se sei straniero residente.',
    ente: 'Comune',
    linkUfficiale: 'https://www.cartaidentita.interno.gov.it/',
    emoji: '🪪',
    icon: Icons.badge,
  ),
  GuidaScheda(
    id: 'stato_famiglia',
    categoriaId: 'residenza',
    titolo: 'Stato di famiglia',
    descrizione: 'Certificato della composizione del nucleo familiare. Quando serve.',
    ente: 'Comune',
    linkUfficiale: 'https://www.anagrafenazionale.interno.gov.it/',
    emoji: '👪',
    icon: Icons.people_alt,
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
    icon: Icons.numbers,
  ),
  GuidaScheda(
    id: 'ssn_iscrizione',
    categoriaId: 'fiscale',
    titolo: 'Iscrizione al SSN (Servizio Sanitario)',
    descrizione: 'Obbligatoria o volontaria, costi, diritti di cura.',
    ente: 'ASL',
    linkUfficiale: 'https://www.salute.gov.it/portale/temi/p2_6.jsp?lingua=italiano&id=906&area=Assistenza%20sanitaria',
    emoji: '🏥',
    icon: Icons.local_hospital,
  ),
  GuidaScheda(
    id: 'medico_base',
    categoriaId: 'fiscale',
    titolo: 'Scelta del medico di base',
    descrizione: 'Come scegliere il tuo medico di famiglia (gratuito).',
    ente: 'ASL',
    linkUfficiale: 'https://www.salute.gov.it/',
    emoji: '👨‍⚕️',
    icon: Icons.medical_services,
  ),
  GuidaScheda(
    id: 'tessera_sanitaria',
    categoriaId: 'fiscale',
    titolo: 'Tessera sanitaria',
    descrizione: 'A cosa serve, come riceverla, come sostituirla.',
    ente: 'Agenzia delle Entrate',
    linkUfficiale: 'https://sistemats1.sanita.finanze.it/portale/',
    emoji: '💳',
    icon: Icons.medical_information,
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
    icon: Icons.description,
  ),
  GuidaScheda(
    id: 'cpi_iscrizione',
    categoriaId: 'lavoro',
    titolo: 'Iscrizione al Centro per l\'Impiego (CPI)',
    descrizione: 'Come iscriversi per cercare lavoro e accedere ai sussidi.',
    ente: 'Centro per l\'Impiego',
    linkUfficiale: 'https://www.anpal.gov.it/',
    emoji: '🔎',
    icon: Icons.business_center,
  ),
  GuidaScheda(
    id: 'did',
    categoriaId: 'lavoro',
    titolo: 'DID - Dichiarazione Immediata Disponibilità',
    descrizione: 'Dichiarazione obbligatoria per chi cerca lavoro (NASpI, SIA...).',
    ente: 'ANPAL / CPI',
    linkUfficiale: 'https://myanpal.anpal.gov.it/',
    emoji: '✅',
    icon: Icons.task_alt,
  ),
  GuidaScheda(
    id: 'naspi',
    categoriaId: 'lavoro',
    titolo: 'NASpI - Sussidio di disoccupazione',
    descrizione: 'Indennità per chi perde il lavoro involontariamente.',
    ente: 'INPS',
    linkUfficiale: 'https://www.inps.it/it/it/inps-comunica/dossier/la-naspi.html',
    emoji: '💰',
    icon: Icons.payments,
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
    icon: Icons.groups,
  ),
  GuidaScheda(
    id: 'permesso_familiari',
    categoriaId: 'famiglia',
    titolo: 'Permesso per motivi familiari',
    descrizione: 'Permesso per coniuge/figli di cittadino italiano o UE.',
    ente: 'Questura',
    linkUfficiale: 'https://www.poliziadistato.it/articolo/213',
    emoji: '❤️',
    icon: Icons.favorite,
  ),
  GuidaScheda(
    id: 'matrimonio_italia',
    categoriaId: 'famiglia',
    titolo: 'Matrimonio in Italia (straniero)',
    descrizione: 'Nulla osta al matrimonio, pubblicazioni, documenti tradotti.',
    ente: 'Comune / Consolato',
    linkUfficiale: 'https://www.servizidemografici.interno.it/',
    emoji: '💒',
    icon: Icons.celebration,
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
    icon: Icons.school,
  ),
  GuidaScheda(
    id: 'riconoscimento_titoli',
    categoriaId: 'studio',
    titolo: 'Riconoscimento titoli di studio esteri',
    descrizione: 'Far valere diploma/laurea presa all\'estero in Italia.',
    ente: 'MIM / Cimea',
    linkUfficiale: 'https://www.cimea.it/',
    emoji: '🏅',
    icon: Icons.workspace_premium,
  ),
  GuidaScheda(
    id: 'scuola_figli',
    categoriaId: 'studio',
    titolo: 'Iscrizione a scuola dei figli',
    descrizione: 'Iscrizione scuola pubblica anche senza permesso perfetto.',
    ente: 'MIM / Scuola',
    linkUfficiale: 'https://www.istruzione.it/iscrizionionline/',
    emoji: '🏫',
    icon: Icons.menu_book,
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
    icon: Icons.swap_horizontal_circle_outlined,
  ),
  GuidaScheda(
    id: 'patente_rinnovo',
    categoriaId: 'patente',
    titolo: 'Rinnovo patente',
    descrizione: 'Visita medica, costi, dove e quando farlo.',
    ente: 'Motorizzazione / ASL',
    linkUfficiale: 'https://www.ilportaledellautomobilista.it/',
    emoji: '🔄',
    icon: Icons.refresh,
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
    icon: Icons.hourglass_bottom,
  ),
  GuidaScheda(
    id: 'cittadinanza_matrimonio',
    categoriaId: 'cittadinanza',
    titolo: 'Cittadinanza per matrimonio',
    descrizione: '2 anni se residente in Italia, 3 se all\'estero (dimezzati con figli).',
    ente: 'Ministero Interno',
    linkUfficiale: 'https://cittadinanza.dlci.interno.it/',
    emoji: '💍',
    icon: Icons.diamond_outlined,
  ),
  GuidaScheda(
    id: 'test_b1',
    categoriaId: 'cittadinanza',
    titolo: 'Test B1 italiano per cittadinanza',
    descrizione: 'Come iscriversi, dove farlo, quanto costa, come prepararsi.',
    ente: 'CILS / CELI / PLIDA',
    linkUfficiale: 'https://cittadinanza.dlci.interno.it/',
    emoji: '📖',
    icon: Icons.menu_book,
  ),
  GuidaScheda(
    id: 'ius_sanguinis',
    categoriaId: 'cittadinanza',
    titolo: 'Cittadinanza per discendenza (ius sanguinis)',
    descrizione: 'Se hai un antenato italiano puoi richiedere la cittadinanza.',
    ente: 'Consolato italiano',
    linkUfficiale: 'https://www.esteri.it/it/servizi-consolari-e-visti/italiani-all-estero/cittadinanza/',
    emoji: '🌳',
    icon: Icons.account_tree,
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
    icon: Icons.gavel,
  ),
  GuidaScheda(
    id: 'gratuito_patrocinio',
    categoriaId: 'diritti',
    titolo: 'Gratuito patrocinio (avvocato gratis)',
    descrizione: 'Se il reddito è basso puoi avere un avvocato pagato dallo Stato.',
    ente: 'Consiglio dell\'Ordine Avvocati',
    linkUfficiale: 'https://www.giustizia.it/giustizia/it/mg_2_4_3.page',
    emoji: '⚖️',
    icon: Icons.balance,
  ),
  GuidaScheda(
    id: 'discriminazione_lavoro',
    categoriaId: 'diritti',
    titolo: 'Tutela contro discriminazione sul lavoro',
    descrizione: 'Cosa fare se sei discriminato per origine/religione/genere.',
    ente: 'UNAR / Ispettorato',
    linkUfficiale: 'https://unar.it/',
    emoji: '🛡️',
    icon: Icons.security,
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
