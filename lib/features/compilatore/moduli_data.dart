import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Tipi di campo supportati dal compilatore
// ---------------------------------------------------------------------------
enum CampoTipo {
  testo,
  data,
  dropdown,
  radio,
  numero,
  telefono,
  email,
  multilinea,
}

// ---------------------------------------------------------------------------
// Singolo campo all'interno di uno step
// ---------------------------------------------------------------------------
class CampoModulo {
  final String id;
  final String etichetta;
  final String suggerimento;
  final CampoTipo tipo;
  final List<String>? opzioni;
  final bool obbligatorio;

  const CampoModulo({
    required this.id,
    required this.etichetta,
    this.suggerimento = '',
    this.tipo = CampoTipo.testo,
    this.opzioni,
    this.obbligatorio = true,
  });
}

// ---------------------------------------------------------------------------
// Uno step (pagina) del wizard
// ---------------------------------------------------------------------------
class StepModulo {
  final String titolo;
  final String sottotitolo;
  final IconData icona;
  final List<CampoModulo> campi;

  const StepModulo({
    required this.titolo,
    this.sottotitolo = '',
    required this.icona,
    required this.campi,
  });
}

// ---------------------------------------------------------------------------
// Modulo completo (template di un modulo ufficiale)
// ---------------------------------------------------------------------------
class Modulo {
  final String id;
  final String titolo;
  final String descrizione;
  final String nomeUfficiale;
  final IconData icona;
  final Color colore;
  final List<StepModulo> steps;
  final String note;

  const Modulo({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.nomeUfficiale,
    required this.icona,
    required this.colore,
    required this.steps,
    this.note = '',
  });
}

// ---------------------------------------------------------------------------
// Province italiane (sigle)
// ---------------------------------------------------------------------------
const List<String> _province = [
  'AG', 'AL', 'AN', 'AO', 'AP', 'AR', 'AT', 'AV',
  'BA', 'BG', 'BI', 'BL', 'BN', 'BO', 'BR', 'BS', 'BT', 'BZ',
  'CA', 'CB', 'CE', 'CH', 'CL', 'CN', 'CO', 'CR', 'CS', 'CT', 'CZ',
  'EN',
  'FC', 'FE', 'FG', 'FI', 'FM', 'FR',
  'GE', 'GO', 'GR',
  'IM', 'IS',
  'KR',
  'LC', 'LE', 'LI', 'LO', 'LT', 'LU',
  'MB', 'MC', 'ME', 'MI', 'MN', 'MO', 'MS', 'MT',
  'NA', 'NO', 'NU',
  'OG', 'OR', 'OT',
  'PA', 'PC', 'PD', 'PE', 'PG', 'PI', 'PN', 'PO', 'PR', 'PT', 'PU', 'PV', 'PZ',
  'RA', 'RC', 'RE', 'RG', 'RI', 'RM', 'RN', 'RO',
  'SA', 'SI', 'SO', 'SP', 'SR', 'SS', 'SU', 'SV',
  'TA', 'TE', 'TN', 'TO', 'TP', 'TR', 'TS', 'TV',
  'UD',
  'VA', 'VB', 'VC', 'VE', 'VI', 'VR', 'VT', 'VV',
];

// ---------------------------------------------------------------------------
// Database di tutti i moduli disponibili
// ---------------------------------------------------------------------------
class ModuliDatabase {
  ModuliDatabase._();

  static final List<Modulo> tutti = [
    // ------------------------------------------------------------------
    // 1. Kit Postale Permesso di Soggiorno (Modulo 1)
    // ------------------------------------------------------------------
    Modulo(
      id: 'kit_postale',
      titolo: 'Kit Postale Permesso di Soggiorno',
      descrizione:
          'Compila il modulo per richiedere o rinnovare il permesso di soggiorno tramite kit postale',
      nomeUfficiale: 'Modulo 1 - Kit Postale',
      icona: Icons.card_travel,
      colore: Colors.blue,
      note:
          'Presentare il kit all\'ufficio postale con marca da bollo da \u20AC16 e bollettino postale',
      steps: [
        StepModulo(
          titolo: 'Dati Personali',
          sottotitolo: 'Inserisci i tuoi dati anagrafici',
          icona: Icons.person,
          campi: [
            const CampoModulo(
              id: 'cognome',
              etichetta: 'Cognome',
              suggerimento: 'Es. Rossi',
            ),
            const CampoModulo(
              id: 'nome',
              etichetta: 'Nome',
              suggerimento: 'Es. Mario',
            ),
            const CampoModulo(
              id: 'sesso',
              etichetta: 'Sesso',
              tipo: CampoTipo.dropdown,
              opzioni: ['M', 'F'],
            ),
            const CampoModulo(
              id: 'data_nascita',
              etichetta: 'Data di Nascita',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
            const CampoModulo(
              id: 'luogo_nascita',
              etichetta: 'Luogo di Nascita',
              suggerimento: 'Es. Dhaka',
            ),
            const CampoModulo(
              id: 'stato_nascita',
              etichetta: 'Stato di Nascita',
              suggerimento: 'Es. Bangladesh',
            ),
            const CampoModulo(
              id: 'nazionalita',
              etichetta: 'Nazionalit\u00e0',
              suggerimento: 'Es. Bangladese',
            ),
            const CampoModulo(
              id: 'codice_fiscale',
              etichetta: 'Codice Fiscale',
              suggerimento: 'Es. RSSMRA80A01H501Z',
            ),
          ],
        ),
        const StepModulo(
          titolo: 'Documento',
          sottotitolo: 'Dati del documento di identit\u00e0',
          icona: Icons.badge,
          campi: [
            CampoModulo(
              id: 'tipo_documento',
              etichetta: 'Tipo Documento',
              tipo: CampoTipo.dropdown,
              opzioni: ['Passaporto', 'Carta d\'identit\u00e0'],
            ),
            CampoModulo(
              id: 'numero_documento',
              etichetta: 'Numero Documento',
              suggerimento: 'Es. AA1234567',
            ),
            CampoModulo(
              id: 'rilasciato_da',
              etichetta: 'Rilasciato da',
              suggerimento: 'Es. Questura di Roma',
            ),
            CampoModulo(
              id: 'data_rilascio',
              etichetta: 'Data Rilascio',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
            CampoModulo(
              id: 'data_scadenza',
              etichetta: 'Data Scadenza',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
          ],
        ),
        StepModulo(
          titolo: 'Residenza in Italia',
          sottotitolo: 'Il tuo indirizzo attuale in Italia',
          icona: Icons.home,
          campi: [
            const CampoModulo(
              id: 'indirizzo',
              etichetta: 'Indirizzo (Via/Piazza)',
              suggerimento: 'Es. Via Roma',
            ),
            const CampoModulo(
              id: 'numero_civico',
              etichetta: 'Numero Civico',
              suggerimento: 'Es. 10',
            ),
            const CampoModulo(
              id: 'cap',
              etichetta: 'CAP',
              suggerimento: 'Es. 00100',
              tipo: CampoTipo.numero,
            ),
            const CampoModulo(
              id: 'comune',
              etichetta: 'Comune',
              suggerimento: 'Es. Roma',
            ),
            CampoModulo(
              id: 'provincia',
              etichetta: 'Provincia',
              tipo: CampoTipo.dropdown,
              opzioni: _province,
            ),
          ],
        ),
        const StepModulo(
          titolo: 'Tipo Richiesta',
          sottotitolo: 'Motivo della richiesta',
          icona: Icons.assignment,
          campi: [
            CampoModulo(
              id: 'motivo_richiesta',
              etichetta: 'Motivo',
              tipo: CampoTipo.dropdown,
              opzioni: [
                'Primo rilascio',
                'Rinnovo',
                'Conversione',
                'Aggiornamento',
              ],
            ),
            CampoModulo(
              id: 'tipo_permesso',
              etichetta: 'Tipo Permesso',
              tipo: CampoTipo.dropdown,
              opzioni: [
                'Lavoro subordinato',
                'Lavoro autonomo',
                'Famiglia',
                'Studio',
                'Motivi religiosi',
                'Asilo',
                'Protezione sussidiaria',
                'Attesa occupazione',
                'Cure mediche',
                'Altro',
              ],
            ),
            CampoModulo(
              id: 'numero_permesso_precedente',
              etichetta: 'Numero Permesso Precedente',
              suggerimento: 'Solo per rinnovo/conversione',
              obbligatorio: false,
            ),
          ],
        ),
      ],
    ),

    // ------------------------------------------------------------------
    // 2. Domanda Cittadinanza Italiana (Modulo B)
    // ------------------------------------------------------------------
    Modulo(
      id: 'cittadinanza',
      titolo: 'Domanda Cittadinanza Italiana',
      descrizione:
          'Compila la domanda per ottenere la cittadinanza italiana per matrimonio o residenza',
      nomeUfficiale: 'Modulo B - Domanda di Cittadinanza',
      icona: Icons.flag,
      colore: Colors.green,
      note:
          'Per matrimonio: 2 anni residenza. Per residenza: 10 anni. Costo: \u20AC250 contributo',
      steps: [
        StepModulo(
          titolo: 'Dati Anagrafici',
          sottotitolo: 'Dati personali del richiedente',
          icona: Icons.person,
          campi: [
            const CampoModulo(
              id: 'cognome',
              etichetta: 'Cognome',
              suggerimento: 'Es. Rossi',
            ),
            const CampoModulo(
              id: 'nome',
              etichetta: 'Nome',
              suggerimento: 'Es. Mario',
            ),
            const CampoModulo(
              id: 'sesso',
              etichetta: 'Sesso',
              tipo: CampoTipo.dropdown,
              opzioni: ['M', 'F'],
            ),
            const CampoModulo(
              id: 'data_nascita',
              etichetta: 'Data di Nascita',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
            const CampoModulo(
              id: 'luogo_nascita',
              etichetta: 'Luogo di Nascita',
              suggerimento: 'Es. Casablanca',
            ),
            const CampoModulo(
              id: 'stato_nascita',
              etichetta: 'Stato di Nascita',
              suggerimento: 'Es. Marocco',
            ),
            const CampoModulo(
              id: 'nazionalita',
              etichetta: 'Nazionalit\u00e0 Attuale',
              suggerimento: 'Es. Marocchina',
            ),
            const CampoModulo(
              id: 'codice_fiscale',
              etichetta: 'Codice Fiscale',
              suggerimento: 'Es. RSSMRA80A01H501Z',
            ),
          ],
        ),
        const StepModulo(
          titolo: 'Stato Civile',
          sottotitolo: 'Situazione familiare',
          icona: Icons.favorite,
          campi: [
            CampoModulo(
              id: 'stato_civile',
              etichetta: 'Stato Civile',
              tipo: CampoTipo.dropdown,
              opzioni: [
                'Celibe/Nubile',
                'Coniugato/a',
                'Divorziato/a',
                'Vedovo/a',
              ],
            ),
            CampoModulo(
              id: 'nome_coniuge',
              etichetta: 'Nome Coniuge',
              suggerimento: 'Solo se coniugato/a',
              obbligatorio: false,
            ),
            CampoModulo(
              id: 'cognome_coniuge',
              etichetta: 'Cognome Coniuge',
              suggerimento: 'Solo se coniugato/a',
              obbligatorio: false,
            ),
            CampoModulo(
              id: 'nazionalita_coniuge',
              etichetta: 'Nazionalit\u00e0 Coniuge',
              suggerimento: 'Solo se coniugato/a',
              obbligatorio: false,
            ),
            CampoModulo(
              id: 'data_matrimonio',
              etichetta: 'Data Matrimonio',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
              obbligatorio: false,
            ),
          ],
        ),
        StepModulo(
          titolo: 'Residenza',
          sottotitolo: 'Dati di residenza in Italia',
          icona: Icons.location_on,
          campi: [
            const CampoModulo(
              id: 'data_arrivo_italia',
              etichetta: 'Data Arrivo in Italia',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
            const CampoModulo(
              id: 'data_iscrizione_anagrafe',
              etichetta: 'Data Iscrizione Anagrafe',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
            const CampoModulo(
              id: 'comune',
              etichetta: 'Comune di Residenza',
              suggerimento: 'Es. Roma',
            ),
            const CampoModulo(
              id: 'indirizzo',
              etichetta: 'Indirizzo',
              suggerimento: 'Es. Via Roma 10',
            ),
            const CampoModulo(
              id: 'cap',
              etichetta: 'CAP',
              suggerimento: 'Es. 00100',
              tipo: CampoTipo.numero,
            ),
          ],
        ),
        const StepModulo(
          titolo: 'Tipo Domanda',
          sottotitolo: 'Dettagli della richiesta',
          icona: Icons.description,
          campi: [
            CampoModulo(
              id: 'tipo_domanda',
              etichetta: 'Tipo',
              tipo: CampoTipo.dropdown,
              opzioni: ['Per matrimonio', 'Per residenza'],
            ),
            CampoModulo(
              id: 'condanne_penali',
              etichetta: 'Condanne Penali',
              tipo: CampoTipo.dropdown,
              opzioni: ['No', 'S\u00ec'],
            ),
            CampoModulo(
              id: 'reddito_annuo',
              etichetta: 'Reddito Annuo Lordo',
              suggerimento: 'Es. 25000',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'titolo_studio',
              etichetta: 'Titolo di Studio',
              tipo: CampoTipo.dropdown,
              opzioni: ['Nessuno', 'Licenza media', 'Diploma', 'Laurea'],
            ),
          ],
        ),
      ],
    ),

    // ------------------------------------------------------------------
    // 3. Domanda ADI - Assegno di Inclusione
    // ------------------------------------------------------------------
    const Modulo(
      id: 'adi',
      titolo: 'Domanda ADI - Assegno di Inclusione',
      descrizione:
          'Compila la domanda per l\'Assegno di Inclusione (ex Reddito di Cittadinanza)',
      nomeUfficiale: 'Domanda ADI - Assegno di Inclusione',
      icona: Icons.account_balance_wallet,
      colore: Color(0xFFEF6C00), // Colors.orange.shade700
      note:
          'Requisiti: ISEE < \u20AC9.360, patrimonio immob. < \u20AC30.000, residenza 5 anni (2 continuativi)',
      steps: [
        StepModulo(
          titolo: 'Dati Richiedente',
          sottotitolo: 'Informazioni sul richiedente',
          icona: Icons.person,
          campi: [
            CampoModulo(
              id: 'cognome',
              etichetta: 'Cognome',
              suggerimento: 'Es. Rossi',
            ),
            CampoModulo(
              id: 'nome',
              etichetta: 'Nome',
              suggerimento: 'Es. Mario',
            ),
            CampoModulo(
              id: 'codice_fiscale',
              etichetta: 'Codice Fiscale',
              suggerimento: 'Es. RSSMRA80A01H501Z',
            ),
            CampoModulo(
              id: 'data_nascita',
              etichetta: 'Data di Nascita',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
            CampoModulo(
              id: 'nazionalita',
              etichetta: 'Nazionalit\u00e0',
              suggerimento: 'Es. Albanese',
            ),
            CampoModulo(
              id: 'tipo_permesso',
              etichetta: 'Tipo Permesso di Soggiorno',
              tipo: CampoTipo.dropdown,
              opzioni: [
                'Lungo periodo',
                'Protezione internazionale',
                'Altro',
              ],
            ),
          ],
        ),
        StepModulo(
          titolo: 'Nucleo Familiare',
          sottotitolo: 'Composizione del nucleo',
          icona: Icons.people,
          campi: [
            CampoModulo(
              id: 'numero_componenti',
              etichetta: 'Numero Componenti',
              suggerimento: 'Es. 4',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'minori_under_18',
              etichetta: 'Minori Under 18',
              suggerimento: 'Es. 2',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'disabili',
              etichetta: 'Disabili',
              suggerimento: 'Es. 0',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'over_60',
              etichetta: 'Over 60',
              suggerimento: 'Es. 1',
              tipo: CampoTipo.numero,
            ),
          ],
        ),
        StepModulo(
          titolo: 'Situazione Economica',
          sottotitolo: 'Dati economici e patrimoniali',
          icona: Icons.euro,
          campi: [
            CampoModulo(
              id: 'isee_corrente',
              etichetta: 'ISEE Corrente',
              suggerimento: 'Es. 8000',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'patrimonio_immobiliare',
              etichetta: 'Patrimonio Immobiliare',
              suggerimento: 'Es. 0',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'patrimonio_mobiliare',
              etichetta: 'Patrimonio Mobiliare',
              suggerimento: 'Es. 3000',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'reddito_familiare',
              etichetta: 'Reddito Familiare Annuo',
              suggerimento: 'Es. 12000',
              tipo: CampoTipo.numero,
            ),
          ],
        ),
        StepModulo(
          titolo: 'Residenza',
          sottotitolo: 'Dati di residenza',
          icona: Icons.home,
          campi: [
            CampoModulo(
              id: 'anni_residenza',
              etichetta: 'Anni di Residenza in Italia',
              suggerimento: 'Es. 7',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'indirizzo',
              etichetta: 'Indirizzo',
              suggerimento: 'Es. Via Roma 10',
            ),
            CampoModulo(
              id: 'comune',
              etichetta: 'Comune',
              suggerimento: 'Es. Milano',
            ),
            CampoModulo(
              id: 'cap',
              etichetta: 'CAP',
              suggerimento: 'Es. 20100',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'residenza_continuativa',
              etichetta: 'Residenza Continuativa Ultimi 2 Anni',
              tipo: CampoTipo.dropdown,
              opzioni: ['S\u00ec', 'No'],
            ),
          ],
        ),
      ],
    ),

    // ------------------------------------------------------------------
    // 4. Richiesta Codice Fiscale (Modello AA4/8)
    // ------------------------------------------------------------------
    Modulo(
      id: 'codice_fiscale',
      titolo: 'Richiesta Codice Fiscale',
      descrizione:
          'Compila il modello per richiedere il codice fiscale all\'Agenzia delle Entrate',
      nomeUfficiale: 'Modello AA4/8',
      icona: Icons.pin,
      colore: Colors.red.shade700,
      note:
          'Presentare all\'Agenzia delle Entrate con documento di identit\u00e0 e permesso di soggiorno',
      steps: [
        const StepModulo(
          titolo: 'Dati Personali',
          sottotitolo: 'Dati anagrafici del richiedente',
          icona: Icons.person,
          campi: [
            CampoModulo(
              id: 'cognome',
              etichetta: 'Cognome',
              suggerimento: 'Es. Rossi',
            ),
            CampoModulo(
              id: 'nome',
              etichetta: 'Nome',
              suggerimento: 'Es. Mario',
            ),
            CampoModulo(
              id: 'sesso',
              etichetta: 'Sesso',
              tipo: CampoTipo.dropdown,
              opzioni: ['M', 'F'],
            ),
            CampoModulo(
              id: 'data_nascita',
              etichetta: 'Data di Nascita',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
            CampoModulo(
              id: 'luogo_nascita',
              etichetta: 'Comune/Stato di Nascita',
              suggerimento: 'Es. Lagos, Nigeria',
            ),
            CampoModulo(
              id: 'cittadinanza',
              etichetta: 'Cittadinanza',
              suggerimento: 'Es. Nigeriana',
            ),
          ],
        ),
        StepModulo(
          titolo: 'Domicilio Fiscale',
          sottotitolo: 'Indirizzo di domicilio in Italia',
          icona: Icons.home,
          campi: [
            const CampoModulo(
              id: 'indirizzo',
              etichetta: 'Indirizzo',
              suggerimento: 'Es. Via Roma 10',
            ),
            const CampoModulo(
              id: 'cap',
              etichetta: 'CAP',
              suggerimento: 'Es. 00100',
              tipo: CampoTipo.numero,
            ),
            const CampoModulo(
              id: 'comune',
              etichetta: 'Comune',
              suggerimento: 'Es. Roma',
            ),
            CampoModulo(
              id: 'provincia',
              etichetta: 'Provincia',
              tipo: CampoTipo.dropdown,
              opzioni: _province,
            ),
          ],
        ),
      ],
    ),

    // ------------------------------------------------------------------
    // 5. Ricongiungimento Familiare (Modulo S)
    // ------------------------------------------------------------------
    const Modulo(
      id: 'ricongiungimento',
      titolo: 'Ricongiungimento Familiare',
      descrizione:
          'Compila la domanda per il ricongiungimento con i familiari all\'estero',
      nomeUfficiale: 'Modulo S - Ricongiungimento Familiare',
      icona: Icons.family_restroom,
      colore: Color(0xFF7B1FA2), // Colors.purple.shade700
      note:
          'Reddito minimo: \u20AC8.500 per 1 familiare. Presentare allo Sportello Unico Immigrazione',
      steps: [
        StepModulo(
          titolo: 'Dati Richiedente',
          sottotitolo: 'Dati del familiare in Italia',
          icona: Icons.person,
          campi: [
            CampoModulo(
              id: 'cognome',
              etichetta: 'Cognome',
              suggerimento: 'Es. Rossi',
            ),
            CampoModulo(
              id: 'nome',
              etichetta: 'Nome',
              suggerimento: 'Es. Mario',
            ),
            CampoModulo(
              id: 'data_nascita',
              etichetta: 'Data di Nascita',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
            CampoModulo(
              id: 'nazionalita',
              etichetta: 'Nazionalit\u00e0',
              suggerimento: 'Es. Pakistana',
            ),
            CampoModulo(
              id: 'codice_fiscale',
              etichetta: 'Codice Fiscale',
              suggerimento: 'Es. RSSMRA80A01H501Z',
            ),
            CampoModulo(
              id: 'tipo_permesso',
              etichetta: 'Tipo Permesso',
              tipo: CampoTipo.dropdown,
              opzioni: [
                'Lungo periodo',
                'Lavoro subordinato',
                'Lavoro autonomo',
                'Protezione internazionale',
                'Altro',
              ],
            ),
            CampoModulo(
              id: 'numero_permesso',
              etichetta: 'Numero Permesso',
              suggerimento: 'Numero del permesso di soggiorno',
            ),
            CampoModulo(
              id: 'reddito_annuo',
              etichetta: 'Reddito Annuo',
              suggerimento: 'Es. 15000',
              tipo: CampoTipo.numero,
            ),
          ],
        ),
        StepModulo(
          titolo: 'Familiare da Ricongiungere',
          sottotitolo: 'Dati del familiare all\'estero',
          icona: Icons.person_add,
          campi: [
            CampoModulo(
              id: 'parentela',
              etichetta: 'Grado di Parentela',
              tipo: CampoTipo.dropdown,
              opzioni: [
                'Coniuge',
                'Figlio minore',
                'Figlio maggiorenne',
                'Genitore',
              ],
            ),
            CampoModulo(
              id: 'cognome_familiare',
              etichetta: 'Cognome Familiare',
              suggerimento: 'Cognome del familiare',
            ),
            CampoModulo(
              id: 'nome_familiare',
              etichetta: 'Nome Familiare',
              suggerimento: 'Nome del familiare',
            ),
            CampoModulo(
              id: 'data_nascita_familiare',
              etichetta: 'Data di Nascita Familiare',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
            CampoModulo(
              id: 'nazionalita_familiare',
              etichetta: 'Nazionalit\u00e0 Familiare',
              suggerimento: 'Es. Pakistana',
            ),
            CampoModulo(
              id: 'stato_residenza',
              etichetta: 'Stato di Residenza Attuale',
              suggerimento: 'Es. Pakistan',
            ),
          ],
        ),
        StepModulo(
          titolo: 'Alloggio',
          sottotitolo: 'Dati sull\'alloggio disponibile',
          icona: Icons.apartment,
          campi: [
            CampoModulo(
              id: 'indirizzo_alloggio',
              etichetta: 'Indirizzo',
              suggerimento: 'Es. Via Roma 10',
            ),
            CampoModulo(
              id: 'comune_alloggio',
              etichetta: 'Comune',
              suggerimento: 'Es. Brescia',
            ),
            CampoModulo(
              id: 'tipo_alloggio',
              etichetta: 'Tipo Alloggio',
              tipo: CampoTipo.dropdown,
              opzioni: ['Propriet\u00e0', 'Affitto', 'Comodato'],
            ),
            CampoModulo(
              id: 'metri_quadri',
              etichetta: 'Metri Quadri',
              suggerimento: 'Es. 65',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'idoneita_alloggiativa',
              etichetta: 'Certificato Idoneit\u00e0 Alloggiativa',
              tipo: CampoTipo.dropdown,
              opzioni: ['S\u00ec', 'No'],
            ),
          ],
        ),
      ],
    ),

    // ------------------------------------------------------------------
    // 6. DSU per ISEE
    // ------------------------------------------------------------------
    Modulo(
      id: 'isee',
      titolo: 'DSU per ISEE',
      descrizione:
          'Compila la Dichiarazione Sostitutiva Unica per il calcolo dell\'ISEE',
      nomeUfficiale: 'DSU - Dichiarazione Sostitutiva Unica',
      icona: Icons.calculate,
      colore: Colors.teal.shade700,
      note:
          'Presentare al CAF con documenti reddituali e patrimoniali di tutti i componenti',
      steps: [
        StepModulo(
          titolo: 'Dichiarante',
          sottotitolo: 'Dati del dichiarante',
          icona: Icons.person,
          campi: [
            const CampoModulo(
              id: 'cognome',
              etichetta: 'Cognome',
              suggerimento: 'Es. Rossi',
            ),
            const CampoModulo(
              id: 'nome',
              etichetta: 'Nome',
              suggerimento: 'Es. Mario',
            ),
            const CampoModulo(
              id: 'codice_fiscale',
              etichetta: 'Codice Fiscale',
              suggerimento: 'Es. RSSMRA80A01H501Z',
            ),
            const CampoModulo(
              id: 'data_nascita',
              etichetta: 'Data di Nascita',
              suggerimento: 'GG/MM/AAAA',
              tipo: CampoTipo.data,
            ),
            const CampoModulo(
              id: 'indirizzo',
              etichetta: 'Indirizzo',
              suggerimento: 'Es. Via Roma 10',
            ),
            const CampoModulo(
              id: 'comune',
              etichetta: 'Comune',
              suggerimento: 'Es. Roma',
            ),
            const CampoModulo(
              id: 'cap',
              etichetta: 'CAP',
              suggerimento: 'Es. 00100',
              tipo: CampoTipo.numero,
            ),
          ],
        ),
        const StepModulo(
          titolo: 'Nucleo Familiare',
          sottotitolo: 'Composizione del nucleo familiare',
          icona: Icons.people,
          campi: [
            CampoModulo(
              id: 'numero_componenti',
              etichetta: 'Numero Componenti',
              suggerimento: 'Es. 4',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'elenco_componenti',
              etichetta: 'Elenco Componenti',
              suggerimento:
                  'Nome, Codice Fiscale, Parentela per ciascun componente',
              tipo: CampoTipo.multilinea,
            ),
          ],
        ),
        const StepModulo(
          titolo: 'Redditi',
          sottotitolo: 'Redditi del nucleo familiare',
          icona: Icons.euro,
          campi: [
            CampoModulo(
              id: 'reddito_complessivo',
              etichetta: 'Reddito Complessivo Nucleo',
              suggerimento: 'Es. 25000',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'redditi_lavoro_dipendente',
              etichetta: 'Redditi da Lavoro Dipendente',
              suggerimento: 'Es. 20000',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'redditi_lavoro_autonomo',
              etichetta: 'Redditi da Lavoro Autonomo',
              suggerimento: 'Es. 5000',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'altri_redditi',
              etichetta: 'Altri Redditi',
              suggerimento: 'Es. 0',
              tipo: CampoTipo.numero,
            ),
          ],
        ),
        const StepModulo(
          titolo: 'Patrimonio',
          sottotitolo: 'Patrimonio mobiliare e immobiliare',
          icona: Icons.account_balance,
          campi: [
            CampoModulo(
              id: 'patrimonio_mobiliare',
              etichetta: 'Patrimonio Mobiliare',
              suggerimento: 'Conti correnti, depositi, ecc.',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'patrimonio_immobiliare',
              etichetta: 'Patrimonio Immobiliare',
              suggerimento: 'Case, terreni, ecc.',
              tipo: CampoTipo.numero,
            ),
            CampoModulo(
              id: 'mutuo_residuo',
              etichetta: 'Mutuo Residuo',
              suggerimento: 'Es. 50000',
              tipo: CampoTipo.numero,
            ),
          ],
        ),
      ],
    ),
  ];
}
