import { PARAMS, type Parametri } from "./params";
import { round2 } from "./money";

type AuParams = Parametri["assegnoUnico"];

export type FasciaEta = "under1" | "1-3" | "3-18" | "18-21";
export type Disabilita = "nessuna" | "media" | "grave" | "nonAutosufficienza";

export type Figlio = { eta: FasciaEta; disabilita: Disabilita };

export type AssegnoUnicoInput = {
  /** ISEE in corso di validità; null = nessun ISEE presentato. */
  isee: number | null;
  figli: Figlio[];
  madreUnder21: boolean;
};

export type RigaFiglio = { indice: number; base: number; maggiorazioni: number; totale: number; voci: string[] };

export type AssegnoUnicoResult =
  | { ok: false; errore: string }
  | {
      ok: true;
      righe: RigaFiglio[];
      maggiorazioniNucleo: { voce: string; importo: number }[];
      mensile: number;
      annuale: number;
      importoMinimo: boolean;
    };

/**
 * Importo decrescente con l'ISEE. La riduzione reale segue le tabelle INPS per
 * fasce; qui è approssimata con un'interpolazione lineare tra soglia minima e massima.
 */
export function interpola(max: number, min: number, isee: number | null, p: AuParams = PARAMS.assegnoUnico): number {
  if (isee === null || isee >= p.iseeMax) return min;
  if (isee <= p.iseeMin) return max;
  const t = (isee - p.iseeMin) / (p.iseeMax - p.iseeMin);
  return max - (max - min) * t;
}

export function calcolaAssegnoUnico(input: AssegnoUnicoInput, p: AuParams = PARAMS.assegnoUnico): AssegnoUnicoResult {
  if (input.figli.length === 0) return { ok: false, errore: "Aggiungi almeno un figlio." };
  if (input.isee !== null && !(input.isee >= 0)) return { ok: false, errore: "L'ISEE deve essere un numero positivo." };

  const n = input.figli.length;
  const righe: RigaFiglio[] = input.figli.map((f, i) => {
    const voci: string[] = [];
    const isMaggiorenne = f.eta === "18-21";
    const base = isMaggiorenne
      ? interpola(p.figlio18_21.max, p.figlio18_21.min, input.isee, p)
      : interpola(p.figlioMinore.max, p.figlioMinore.min, input.isee, p);
    let magg = 0;
    if (f.eta === "under1") {
      magg += base * p.maggiorazioneUnderUnoPercent;
      voci.push("Figlio sotto 1 anno (+50%)");
    }
    if (f.eta === "1-3" && n >= 3 && (input.isee === null ? false : input.isee <= p.iseeMax)) {
      magg += base * p.maggiorazioneUnderUnoPercent;
      voci.push("Figlio tra 1 e 3 anni in nucleo con 3+ figli (+50%)");
    }
    if (i >= 2) {
      magg += interpola(p.maggiorazioneTerzoFiglio.max, p.maggiorazioneTerzoFiglio.min, input.isee, p);
      voci.push("Maggiorazione dal terzo figlio");
    }
    if (!isMaggiorenne && f.disabilita !== "nessuna") {
      magg += p.disabilitaMinore[f.disabilita];
      voci.push("Maggiorazione per disabilità");
    }
    if (input.madreUnder21 && !isMaggiorenne) {
      magg += p.maggiorazioneMadreUnder21;
      voci.push("Madre under 21");
    }
    return { indice: i + 1, base: round2(base), maggiorazioni: round2(magg), totale: round2(base + magg), voci };
  });

  const maggiorazioniNucleo: { voce: string; importo: number }[] = [];
  if (n >= 4) maggiorazioniNucleo.push({ voce: "Nucleo con 4 o più figli (forfettaria)", importo: p.forfettariaQuattroFigli });

  const mensile = round2(righe.reduce((s, r) => s + r.totale, 0) + maggiorazioniNucleo.reduce((s, m) => s + m.importo, 0));
  return {
    ok: true,
    righe,
    maggiorazioniNucleo,
    mensile,
    annuale: round2(mensile * 12),
    importoMinimo: input.isee === null || input.isee >= p.iseeMax,
  };
}
