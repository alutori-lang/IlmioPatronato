import { round2 } from "./money";

export type RisparmioInput = {
  entrateMensili: number;
  speseMensili: number;
  /** Obiettivo di risparmio (€); 0 = nessun obiettivo. */
  obiettivo: number;
  /** Rendimento annuo netto ipotizzato del risparmio (es. 0.02). */
  rendimento: number;
  anni: number;
};

export type RisparmioResult =
  | { ok: false; errore: string }
  | {
      ok: true;
      risparmioMensile: number;
      tassoRisparmio: number;
      mesiPerObiettivo: number | null;
      capitaleFinale: number;
      versato: number;
      interessi: number;
      fondoEmergenza: number;
      andamento: { anno: number; capitale: number }[];
    };

export function calcolaRisparmio(input: RisparmioInput): RisparmioResult {
  const { entrateMensili: e, speseMensili: s, obiettivo, rendimento, anni } = input;
  if (!(e > 0)) return { ok: false, errore: "Inserisci le entrate mensili." };
  if (!(s >= 0)) return { ok: false, errore: "Le spese mensili non possono essere negative." };
  if (!(obiettivo >= 0)) return { ok: false, errore: "L'obiettivo non può essere negativo." };
  if (!(rendimento >= 0) || rendimento > 0.15) return { ok: false, errore: "Il rendimento deve essere tra 0% e 15%." };
  if (!Number.isInteger(anni) || anni < 1 || anni > 50) return { ok: false, errore: "Gli anni devono essere tra 1 e 50." };

  const mensile = round2(e - s);
  if (mensile <= 0) {
    return { ok: false, errore: "Le spese superano o eguagliano le entrate: non resta margine di risparmio. Prova a rivedere le voci di spesa." };
  }
  const r = rendimento / 12;
  let capitale = 0;
  let mesiObiettivo: number | null = null;
  const andamento: { anno: number; capitale: number }[] = [];
  const maxMesi = Math.max(anni * 12, obiettivo > 0 ? 50 * 12 : 0);
  for (let m = 1; m <= maxMesi; m++) {
    capitale = capitale * (1 + r) + mensile;
    if (mesiObiettivo === null && obiettivo > 0 && capitale >= obiettivo) mesiObiettivo = m;
    if (m <= anni * 12 && m % 12 === 0) andamento.push({ anno: m / 12, capitale: round2(capitale) });
    if (m >= anni * 12 && (mesiObiettivo !== null || obiettivo === 0)) break;
  }
  const finale = andamento[andamento.length - 1].capitale;
  const versato = round2(mensile * anni * 12);
  return {
    ok: true,
    risparmioMensile: mensile,
    tassoRisparmio: mensile / e,
    mesiPerObiettivo: mesiObiettivo,
    capitaleFinale: finale,
    versato,
    interessi: round2(finale - versato),
    fondoEmergenza: round2(s * 6),
    andamento,
  };
}
