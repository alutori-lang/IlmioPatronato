import { PARAMS, type Parametri } from "./params";
import { round2 } from "./money";

type NaspiParams = Parametri["naspi"];

export type NaspiInput = {
  /** Retribuzione imponibile previdenziale complessiva degli ultimi 4 anni (€). */
  retribuzioneQuattroAnni: number;
  /** Settimane di contribuzione negli ultimi 4 anni. */
  settimaneContributi: number;
  /** Età pari o superiore a 55 anni alla data della domanda. */
  over55: boolean;
};

export type NaspiMese = { mese: number; importo: number; riduzione: number };

export type NaspiResult =
  | { ok: false; errore: string }
  | {
      ok: true;
      retribuzioneMediaMensile: number;
      importoIniziale: number;
      massimaleApplicato: boolean;
      settimaneIndennizzate: number;
      mesiStimati: number;
      piano: NaspiMese[];
      totaleStimato: number;
    };

const SETTIMANE_PER_MESE = 4.33;

export function calcolaNaspi(input: NaspiInput, p: NaspiParams = PARAMS.naspi): NaspiResult {
  const { retribuzioneQuattroAnni: retr, settimaneContributi: sett } = input;
  if (!(retr > 0)) return { ok: false, errore: "Inserisci la retribuzione imponibile degli ultimi 4 anni." };
  if (!(sett > 0)) return { ok: false, errore: "Inserisci le settimane di contribuzione." };
  if (sett > 208) return { ok: false, errore: "In 4 anni le settimane di contribuzione non possono superare 208." };
  if (sett < p.settimaneMinime) {
    return {
      ok: false,
      errore: `Servono almeno ${p.settimaneMinime} settimane di contribuzione negli ultimi 4 anni per avere diritto alla NASpI.`,
    };
  }

  // Retribuzione media mensile = (imponibile 4 anni / settimane) × 4,33
  const media = round2((retr / sett) * SETTIMANE_PER_MESE);
  let importo = media <= p.soglia ? media * p.percentualeSotto : p.soglia * p.percentualeSotto + (media - p.soglia) * p.percentualeSopra;
  const massimaleApplicato = importo > p.massimale;
  importo = round2(Math.min(importo, p.massimale));

  // Durata: metà delle settimane di contribuzione, massimo 24 mesi (104 settimane)
  const settimaneIndennizzate = Math.min(Math.floor(sett / 2), Math.round(p.durataMassimaMesi * SETTIMANE_PER_MESE));
  const mesiEsatti = Math.min(settimaneIndennizzate / SETTIMANE_PER_MESE, p.durataMassimaMesi);
  const mesiInteri = Math.floor(mesiEsatti);
  const frazione = mesiEsatti - mesiInteri;

  const inizioRiduzione = input.over55 ? p.meseInizioRiduzioneOver55 : p.meseInizioRiduzione;
  const piano: NaspiMese[] = [];
  let corrente = importo;
  const mesiTotali = mesiInteri + (frazione > 0.01 ? 1 : 0);
  let totale = 0;
  for (let m = 1; m <= mesiTotali; m++) {
    // Riduzione del 3% al mese sull'importo del mese precedente, dal primo giorno del 6° (o 8°) mese
    if (m >= inizioRiduzione) corrente = corrente * (1 - p.riduzioneMensile);
    const quota = m > mesiInteri ? frazione : 1;
    const valore = round2(corrente * quota);
    piano.push({ mese: m, importo: valore, riduzione: importo > 0 ? round2(1 - corrente / importo) : 0 });
    totale += valore;
  }

  return {
    ok: true,
    retribuzioneMediaMensile: media,
    importoIniziale: importo,
    massimaleApplicato,
    settimaneIndennizzate,
    mesiStimati: round2(mesiEsatti),
    piano,
    totaleStimato: round2(totale),
  };
}
