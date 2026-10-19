import { PARAMS, type Parametri } from "./params";
import { round2 } from "./money";
import { impostaLorda } from "./irpef";

type TfrParams = Parametri["tfr"];

export type TfrInput = {
  /** Retribuzione annua lorda utile ai fini TFR (€). */
  retribuzioneAnnua: number;
  /** Anni di servizio (interi). */
  anni: number;
  /** Inflazione annua media ipotizzata (es. 0.02 = 2%). */
  inflazione: number;
};

export type TfrAnno = { anno: number; quota: number; rivalutazione: number; impostaRivalutazione: number; fondo: number };

export type TfrResult =
  | { ok: false; errore: string }
  | {
      ok: true;
      quotaAnnua: number;
      coefficienteRivalutazione: number;
      piano: TfrAnno[];
      fondoLordo: number;
      totaleRivalutazioni: number;
      redditoRiferimento: number;
      aliquotaMedia: number;
      impostaSeparata: number;
      nettoStimato: number;
    };

export function calcolaTfr(input: TfrInput, p: TfrParams = PARAMS.tfr): TfrResult {
  const { retribuzioneAnnua: ral, anni, inflazione } = input;
  if (!(ral > 0)) return { ok: false, errore: "Inserisci la retribuzione annua lorda." };
  if (!Number.isInteger(anni) || anni < 1 || anni > 50) return { ok: false, errore: "Gli anni di servizio devono essere un numero intero tra 1 e 50." };
  if (!(inflazione >= 0) || inflazione > 0.2) return { ok: false, errore: "L'inflazione ipotizzata deve essere tra 0% e 20%." };

  const quotaAnnua = round2(ral / p.divisore - ral * p.contributoAggiuntivo);
  const coeff = p.rivalutazioneFissa + p.quotaInflazione * inflazione;

  const piano: TfrAnno[] = [];
  let fondo = 0;
  let totRiv = 0;
  for (let a = 1; a <= anni; a++) {
    // La rivalutazione si applica al fondo accantonato al 31 dicembre dell'anno precedente
    const riv = round2(fondo * coeff);
    const impRiv = round2(riv * p.impostaSostitutivaRivalutazione);
    totRiv += riv - impRiv;
    fondo = round2(fondo + riv - impRiv + quotaAnnua);
    piano.push({ anno: a, quota: quotaAnnua, rivalutazione: riv, impostaRivalutazione: impRiv, fondo });
  }

  // Tassazione separata: aliquota media IRPEF sul reddito di riferimento
  // (TFR al netto delle rivalutazioni già tassate, diviso anni × 12)
  const baseImponibile = Math.max(0, fondo - totRiv);
  const redditoRif = round2((baseImponibile / anni) * 12);
  const aliquotaMedia = redditoRif > 0 ? impostaLorda(redditoRif) / redditoRif : 0;
  const imposta = round2(baseImponibile * aliquotaMedia);

  return {
    ok: true,
    quotaAnnua,
    coefficienteRivalutazione: coeff,
    piano,
    fondoLordo: fondo,
    totaleRivalutazioni: round2(totRiv),
    redditoRiferimento: redditoRif,
    aliquotaMedia,
    impostaSeparata: imposta,
    nettoStimato: round2(fondo - imposta),
  };
}
