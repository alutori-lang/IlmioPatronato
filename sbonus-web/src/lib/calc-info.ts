import { PARAMS } from "./calc/params";
import { formatEuro, formatPct } from "./calc/money";
import type { Faq, Fonte } from "./content-shared";

export type ParametroRiga = { voce: string; valore: string };

export type CalcInfo = {
  intro: string;
  come: string[];
  parametri: ParametroRiga[];
  ipotesi: string[];
  fonti: Fonte[];
  verificato: boolean;
  notaVerifica?: string;
  faq: Faq[];
  bonusCorrelato?: string;
};

const P = PARAMS;
const irpefScaglioni = `23% fino a 28.000 €, 33% da 28.000 a 50.000 €, 43% oltre 50.000 €`;

export const CALC_INFO: Record<string, CalcInfo> = {
  naspi: {
    intro:
      "Stima l'indennità mensile di disoccupazione NASpI con i valori 2026: importo iniziale, durata in base ai contributi versati e riduzione progressiva mese per mese.",
    come: [
      "Si calcola la retribuzione media mensile: retribuzione imponibile degli ultimi 4 anni divisa per le settimane di contribuzione, moltiplicata per 4,33.",
      `Fino a ${formatEuro(P.naspi.soglia)} l'indennità è il 75% della retribuzione media; sulla parte eccedente si aggiunge il 25%.`,
      `L'importo non può superare il massimale mensile 2026 di ${formatEuro(P.naspi.massimale)}.`,
      "La durata è pari a metà delle settimane di contribuzione degli ultimi 4 anni, fino a 24 mesi.",
      "Dal primo giorno del 6° mese (dell'8° se alla domanda hai almeno 55 anni) l'importo si riduce del 3% al mese.",
    ],
    parametri: [
      { voce: "Retribuzione di riferimento 2026", valore: formatEuro(P.naspi.soglia) },
      { voce: "Massimale mensile 2026", valore: formatEuro(P.naspi.massimale) },
      { voce: "Riduzione mensile", valore: `${formatPct(P.naspi.riduzioneMensile)} dal 6° mese (8° per over 55)` },
      { voce: "Durata massima", valore: `${P.naspi.durataMassimaMesi} mesi` },
      { voce: "Contribuzione minima", valore: `${P.naspi.settimaneMinime} settimane negli ultimi 4 anni` },
    ],
    ipotesi: [
      "Importi lordi: sull'indennità si applicano le ritenute IRPEF.",
      "La riduzione del 3% è calcolata sull'importo del mese precedente, come avviene nella prassi INPS.",
      "Non considera periodi già indennizzati da precedenti NASpI, che riducono la durata.",
      "Non verifica gli altri requisiti (stato di disoccupazione involontaria, domanda entro 68 giorni).",
    ],
    fonti: [P.naspi.fonte, P.naspi.fonteScheda],
    verificato: P.naspi.verificato,
    faq: [
      { q: "Entro quando si presenta la domanda NASpI?", a: "Entro 68 giorni dalla cessazione del rapporto di lavoro, online sul sito INPS con SPID, CIE o CNS, tramite Contact Center o con l'aiuto di un patronato." },
      { q: "La NASpI spetta se mi dimetto?", a: "In generale no: spetta per la perdita involontaria del lavoro. Fanno eccezione, ad esempio, le dimissioni per giusta causa e quelle durante il periodo tutelato di maternità." },
      { q: "Perché l'importo cala nel tempo?", a: "La legge prevede una riduzione del 3% al mese a partire dal sesto mese di fruizione, o dall'ottavo per chi ha almeno 55 anni alla data della domanda." },
    ],
    bonusCorrelato: "naspi-indennita-disoccupazione",
  },
  "assegno-unico": {
    intro:
      "Stima l'Assegno Unico e Universale 2026 per i figli a carico, in base all'ISEE del nucleo e alle principali maggiorazioni previste dall'INPS.",
    come: [
      `Per ogni figlio minorenne l'importo base va da ${formatEuro(P.assegnoUnico.figlioMinore.max)} (ISEE fino a ${formatEuro(P.assegnoUnico.iseeMin)}) a ${formatEuro(P.assegnoUnico.figlioMinore.min)} (ISEE da ${formatEuro(P.assegnoUnico.iseeMax)} o senza ISEE).`,
      "Tra le due soglie l'importo scende gradualmente: il simulatore usa un'interpolazione lineare.",
      "Per i figli sotto 1 anno l'importo aumenta del 50%; lo stesso vale per i figli tra 1 e 3 anni nei nuclei con almeno 3 figli e ISEE entro la soglia massima.",
      "Dal terzo figlio si aggiunge una maggiorazione per ciascun figlio; con 4 o più figli spetta una maggiorazione forfettaria di 150 € al mese.",
      "Si aggiungono le maggiorazioni per figli minorenni con disabilità e per madre con meno di 21 anni.",
    ],
    parametri: [
      { voce: "Figlio minorenne", valore: `${formatEuro(P.assegnoUnico.figlioMinore.min)} – ${formatEuro(P.assegnoUnico.figlioMinore.max)}` },
      { voce: "Soglie ISEE 2026", valore: `${formatEuro(P.assegnoUnico.iseeMin)} – ${formatEuro(P.assegnoUnico.iseeMax)}` },
      { voce: "Figlio 18–20 anni*", valore: `${formatEuro(P.assegnoUnico.figlio18_21.min)} – ${formatEuro(P.assegnoUnico.figlio18_21.max)}` },
      { voce: "Maggiorazione dal 3° figlio*", valore: `${formatEuro(P.assegnoUnico.maggiorazioneTerzoFiglio.min)} – ${formatEuro(P.assegnoUnico.maggiorazioneTerzoFiglio.max)}` },
      { voce: "Nucleo con 4+ figli", valore: `${formatEuro(P.assegnoUnico.forfettariaQuattroFigli)} al mese` },
      { voce: "Disabilità (media / grave / non autosuff.)*", valore: `${formatEuro(P.assegnoUnico.disabilitaMinore.media)} / ${formatEuro(P.assegnoUnico.disabilitaMinore.grave)} / ${formatEuro(P.assegnoUnico.disabilitaMinore.nonAutosufficienza)}` },
      { voce: "Madre under 21*", valore: `${formatEuro(P.assegnoUnico.maggiorazioneMadreUnder21)} per figlio` },
    ],
    ipotesi: [
      "La riduzione tra le soglie ISEE è approssimata in modo lineare: l'INPS applica tabelle per fasce, quindi l'importo reale può differire di qualche euro.",
      "Non include la maggiorazione per nuclei in cui entrambi i genitori lavorano.",
      "Non include le maggiorazioni per figli maggiorenni con disabilità e la clausola di salvaguardia per chi percepiva gli assegni familiari.",
      "L'ISEE va inteso come «ISEE per prestazioni familiari», che dal 2026 esclude l'Assegno Unico dal calcolo.",
    ],
    fonti: [P.assegnoUnico.fonte],
    verificato: false,
    notaVerifica:
      "Gli importi base e le soglie ISEE sono verificati sulla Circolare INPS n. 7/2026. Gli importi contrassegnati con * sono da ricontrollare sull'Allegato 1 della circolare.",
    faq: [
      { q: "Bisogna rifare la domanda ogni anno?", a: "No. La domanda resta valida negli anni successivi; serve però presentare una nuova DSU per avere l'ISEE aggiornato, altrimenti da marzo si riceve l'importo minimo." },
      { q: "Cosa succede senza ISEE?", a: "L'Assegno Unico spetta comunque, ma nella misura minima. Se presenti l'ISEE entro il 30 giugno ricevi anche gli arretrati da marzo." },
      { q: "Fino a quando spetta per i figli maggiorenni?", a: "Fino al compimento dei 21 anni, se il figlio studia, fa un tirocinio, ha un lavoro con reddito basso, è disoccupato iscritto al centro per l'impiego o svolge il servizio civile." },
    ],
    bonusCorrelato: "assegno-unico-universale-2026",
  },
  "stipendio-netto": {
    intro:
      "Dalla retribuzione annua lorda (RAL) al netto mensile in busta paga, con contributi INPS, IRPEF 2026, detrazioni, cuneo fiscale e addizionali.",
    come: [
      `Dalla RAL si tolgono i contributi INPS a carico del lavoratore: ${formatPct(P.inpsDipendente.aliquota)}, più ${formatPct(P.inpsDipendente.aliquotaAggiuntiva)} sulla parte oltre ${formatEuro(P.inpsDipendente.sogliaAggiuntivaAnnua)}.`,
      `Sull'imponibile si calcola l'IRPEF con gli scaglioni 2026: ${irpefScaglioni}.`,
      "Si sottraggono la detrazione per lavoro dipendente e, tra 20.000 e 40.000 € di reddito, l'ulteriore detrazione del cuneo fiscale.",
      "Fino a 20.000 € di reddito si aggiunge la somma esente del cuneo fiscale e, se spetta, il trattamento integrativo.",
      "Infine si tolgono le addizionali regionale e comunale con le aliquote che indichi.",
    ],
    parametri: [
      { voce: "Scaglioni IRPEF 2026", valore: irpefScaglioni },
      { voce: "Contributi INPS dipendente", valore: `${formatPct(P.inpsDipendente.aliquota)} (+${formatPct(P.inpsDipendente.aliquotaAggiuntiva)} oltre ${formatEuro(P.inpsDipendente.sogliaAggiuntivaAnnua)})` },
      { voce: "Somma esente cuneo", valore: "7,1% / 5,3% / 4,8% fino a 20.000 €" },
      { voce: "Ulteriore detrazione cuneo", valore: "1.000 € tra 20.000 e 32.000 €, decrescente fino a 40.000 €" },
    ],
    ipotesi: [
      "Rapporto di lavoro per l'intero anno, nessun altro reddito e nessun familiare a carico.",
      "Aliquota contributiva standard del settore privato: alcuni settori e qualifiche hanno aliquote diverse.",
      "Le addizionali regionali sono spesso a scaglioni: il simulatore applica l'aliquota indicata su tutto l'imponibile.",
      "Non considera benefit, straordinari, fondi pensione, rimborsi e conguagli di fine anno.",
    ],
    fonti: [P.irpef.fonte, P.cuneoFiscale.fonte, P.inpsDipendente.fonte],
    verificato: P.irpef.verificato && P.cuneoFiscale.verificato && P.inpsDipendente.verificato,
    notaVerifica: P.inpsDipendente.verificato ? undefined : "Scaglioni IRPEF e cuneo fiscale verificati su fonti dell'Agenzia delle Entrate. La soglia 2026 per il contributo aggiuntivo dell'1% è da ricontrollare sul testo della circolare INPS.",
    faq: [
      { q: "Che differenza c'è tra RAL e netto?", a: "La RAL è la retribuzione annua lorda indicata nel contratto. Il netto è ciò che ricevi dopo contributi previdenziali, IRPEF e addizionali." },
      { q: "Perché il netto cambia tra gennaio e dicembre?", a: "Le addizionali dell'anno precedente si trattengono a rate nell'anno successivo e a fine anno il datore di lavoro fa il conguaglio fiscale: per questo le buste paga non sono tutte uguali." },
      { q: "Cos'è il cuneo fiscale 2026?", a: "Dal 2025 chi ha redditi da lavoro dipendente fino a 20.000 € riceve una somma non tassata in busta paga; tra 20.000 e 40.000 € spetta invece un'ulteriore detrazione IRPEF." },
    ],
  },
  irpef: {
    intro: "Calcola l'IRPEF 2026 su un reddito annuo con i nuovi scaglioni (23%, 33%, 43%) e le detrazioni per lavoro dipendente o pensione.",
    come: [
      `L'imposta lorda si calcola a scaglioni: ${irpefScaglioni}. Ogni aliquota si applica solo alla parte di reddito che rientra nel suo scaglione.`,
      "Dall'imposta lorda si sottraggono le detrazioni per tipo di reddito (art. 13 TUIR), decrescenti al crescere del reddito.",
      "Per i dipendenti tra 20.000 e 40.000 € si aggiunge l'ulteriore detrazione del cuneo fiscale.",
      "L'imposta netta non può essere negativa: le detrazioni non usate non vengono rimborsate.",
    ],
    parametri: [
      { voce: "Scaglioni 2026", valore: irpefScaglioni },
      { voce: "Detrazione lavoro dipendente fino a 15.000 €", valore: formatEuro(1955) },
      { voce: "Detrazione pensione fino a 8.500 €", valore: formatEuro(1955) },
    ],
    ipotesi: [
      "Reddito percepito per l'intero anno.",
      "Non considera detrazioni per familiari a carico, spese (mediche, mutuo, ristrutturazioni) e crediti d'imposta.",
      "Addizionali regionali e comunali escluse.",
      "Per redditi oltre 75.000 € non applica il limite agli oneri detraibili, che riguarda solo le spese.",
    ],
    fonti: [P.irpef.fonte, P.cuneoFiscale.fonte],
    verificato: P.irpef.verificato && P.cuneoFiscale.verificato,
    faq: [
      { q: "Cosa cambia con l'IRPEF 2026?", a: "La Legge di Bilancio 2026 ha ridotto dal 35% al 33% l'aliquota dello scaglione tra 28.000 e 50.000 €. Gli altri scaglioni restano invariati." },
      { q: "Che differenza c'è tra aliquota media e marginale?", a: "La marginale è l'aliquota sull'ultimo euro guadagnato. La media è il rapporto tra imposta pagata e reddito: è sempre più bassa della marginale." },
    ],
  },
  tfr: {
    intro: "Stima il trattamento di fine rapporto maturato in base alla retribuzione e agli anni di lavoro, con rivalutazione annua e tassazione separata.",
    come: [
      `Ogni anno si accantona la retribuzione annua divisa per ${P.tfr.divisore.toLocaleString("it-IT")}, meno il contributo dello ${formatPct(P.tfr.contributoAggiuntivo)}.`,
      `Il fondo accumulato si rivaluta ogni anno dell'${formatPct(P.tfr.rivalutazioneFissa)} più il 75% dell'aumento dei prezzi ISTAT.`,
      `Sulla rivalutazione si paga ogni anno un'imposta sostitutiva del ${formatPct(P.tfr.impostaSostitutivaRivalutazione)}.`,
      "Alla fine del rapporto il TFR è soggetto a tassazione separata: si applica l'aliquota media IRPEF calcolata sul «reddito di riferimento».",
    ],
    parametri: [
      { voce: "Divisore annuo", valore: P.tfr.divisore.toLocaleString("it-IT") },
      { voce: "Contributo aggiuntivo", valore: formatPct(P.tfr.contributoAggiuntivo) },
      { voce: "Rivalutazione", valore: "1,5% + 75% inflazione ISTAT" },
      { voce: "Imposta sulla rivalutazione", valore: formatPct(P.tfr.impostaSostitutivaRivalutazione) },
    ],
    ipotesi: [
      "Retribuzione costante per tutti gli anni e inflazione media pari a quella indicata.",
      "Tutto il TFR resta in azienda (nessuna adesione a fondi pensione, nessun anticipo).",
      "La tassazione separata è stimata con gli scaglioni IRPEF 2026; l'Agenzia delle Entrate può riliquidare l'imposta in seguito.",
    ],
    fonti: [P.tfr.fonte, P.irpef.fonte],
    verificato: P.tfr.verificato,
    faq: [
      { q: "Quando viene pagato il TFR?", a: "Alla cessazione del rapporto di lavoro, di solito con l'ultima busta paga o entro i tempi previsti dal contratto collettivo." },
      { q: "Posso chiedere un anticipo del TFR?", a: "Dopo 8 anni di servizio si può chiedere un anticipo fino al 70% per spese sanitarie straordinarie, acquisto della prima casa o congedi, nei limiti previsti dalla legge." },
    ],
  },
  "rata-mutuo": {
    intro: "Calcola la rata mensile di un mutuo a tasso fisso con ammortamento alla francese, gli interessi totali e il piano anno per anno.",
    come: [
      "La rata è costante e si calcola con la formula dell'ammortamento alla francese: Rata = C × i / (1 − (1 + i)^−n).",
      "C è il capitale, i il tasso mensile (TAN / 12), n il numero di rate mensili.",
      "Nelle prime rate pesa di più la quota interessi; col passare del tempo cresce la quota capitale.",
    ],
    parametri: [{ voce: "Metodo", valore: "Ammortamento alla francese, rata mensile costante" }],
    ipotesi: [
      "Tasso fisso per tutta la durata.",
      "Non include spese di istruttoria, perizia, assicurazioni e imposta sostitutiva: per confrontare le offerte usa il TAEG indicato dalla banca.",
    ],
    fonti: [],
    verificato: true,
    faq: [
      { q: "Che differenza c'è tra TAN e TAEG?", a: "Il TAN è il tasso di interesse puro. Il TAEG comprende anche le spese accessorie ed è l'indicatore giusto per confrontare offerte diverse." },
      { q: "Esistono aiuti per i giovani che comprano casa?", a: "Sì: il Fondo di garanzia per la prima casa gestito da Consap può garantire una parte del mutuo. Trovi requisiti e modalità nella scheda dedicata." },
    ],
    bonusCorrelato: "fondo-garanzia-prima-casa-consap",
  },
  "risparmio-familiare": {
    intro: "Scopri quanto riesci a risparmiare ogni mese, quanto accumuli nel tempo e in quanto raggiungi un obiettivo, con o senza rendimento.",
    come: [
      "Il risparmio mensile è la differenza tra entrate e spese.",
      "Il capitale cresce ogni mese con il nuovo risparmio e, se indicato, con il rendimento netto ipotizzato (capitalizzazione mensile).",
      "Il fondo emergenze consigliato corrisponde a 6 mesi di spese, una regola prudenziale diffusa.",
    ],
    parametri: [{ voce: "Capitalizzazione", valore: "Mensile, rendimento annuo / 12" }],
    ipotesi: ["Entrate, spese e rendimento costanti nel tempo.", "Il rendimento indicato deve essere già al netto di tasse e costi."],
    fonti: [],
    verificato: true,
    faq: [
      { q: "Quanto conviene risparmiare ogni mese?", a: "Non esiste una cifra giusta per tutti. Un riferimento spesso usato è mettere da parte almeno il 10–20% delle entrate, partendo da un fondo per le emergenze." },
    ],
  },
};
