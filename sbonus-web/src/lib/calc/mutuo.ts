import { round2 } from "./money";

export type MutuoInput = {
  importo: number;
  /** Tasso annuo nominale (TAN), es. 0.035 = 3,5%. */
  tasso: number;
  anni: number;
};

export type RigaAmmortamento = { anno: number; quotaCapitale: number; quotaInteressi: number; debitoResiduo: number };

export type MutuoResult =
  | { ok: false; errore: string }
  | {
      ok: true;
      rata: number;
      numeroRate: number;
      totaleRestituito: number;
      totaleInteressi: number;
      pianoAnnuale: RigaAmmortamento[];
    };

/** Ammortamento alla francese a rata costante mensile. */
export function calcolaMutuo(input: MutuoInput): MutuoResult {
  const { importo, tasso, anni } = input;
  if (!(importo > 0)) return { ok: false, errore: "Inserisci l'importo del mutuo." };
  if (importo > 10_000_000) return { ok: false, errore: "L'importo massimo gestito è 10.000.000 €." };
  if (!(tasso >= 0) || tasso > 0.25) return { ok: false, errore: "Il tasso deve essere tra 0% e 25%." };
  if (!Number.isInteger(anni) || anni < 1 || anni > 40) return { ok: false, errore: "La durata deve essere tra 1 e 40 anni." };

  const n = anni * 12;
  const r = tasso / 12;
  const rata = r === 0 ? importo / n : (importo * r) / (1 - Math.pow(1 + r, -n));

  const pianoAnnuale: RigaAmmortamento[] = [];
  let debito = importo;
  let capAnno = 0;
  let intAnno = 0;
  for (let m = 1; m <= n; m++) {
    const interessi = debito * r;
    const capitale = rata - interessi;
    debito = Math.max(0, debito - capitale);
    capAnno += capitale;
    intAnno += interessi;
    if (m % 12 === 0) {
      pianoAnnuale.push({ anno: m / 12, quotaCapitale: round2(capAnno), quotaInteressi: round2(intAnno), debitoResiduo: round2(debito) });
      capAnno = 0;
      intAnno = 0;
    }
  }
  const totale = rata * n;
  return {
    ok: true,
    rata: round2(rata),
    numeroRate: n,
    totaleRestituito: round2(totale),
    totaleInteressi: round2(totale - importo),
    pianoAnnuale,
  };
}
