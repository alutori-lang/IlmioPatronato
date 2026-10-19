import { PARAMS, type Parametri } from "./params";
import { round2 } from "./money";

type IrpefParams = Parametri["irpef"];
type CuneoParams = Parametri["cuneoFiscale"];

export type TipoReddito = "dipendente" | "pensionato" | "altro";

/** IRPEF lorda per scaglioni (art. 11 TUIR). */
export function impostaLorda(imponibile: number, p: IrpefParams = PARAMS.irpef): number {
  if (imponibile <= 0) return 0;
  let tassa = 0;
  let base = 0;
  for (const s of p.scaglioni) {
    const tetto = s.fino ?? Infinity;
    if (imponibile <= base) break;
    tassa += (Math.min(imponibile, tetto) - base) * s.aliquota;
    base = tetto;
  }
  return round2(tassa);
}

/** Aliquota marginale applicata all'ultimo euro di reddito. */
export function aliquotaMarginale(imponibile: number, p: IrpefParams = PARAMS.irpef): number {
  for (const s of p.scaglioni) {
    if (s.fino === null || imponibile <= s.fino) return s.aliquota;
  }
  return p.scaglioni[p.scaglioni.length - 1].aliquota;
}

/**
 * Detrazione per redditi di lavoro dipendente (art. 13, c. 1 e 1.1 TUIR),
 * per un rapporto durato l'intero anno.
 */
export function detrazioneLavoroDipendente(rc: number, tempoDeterminato = false): number {
  if (rc <= 0) return 0;
  let d: number;
  if (rc <= 15000) {
    // Per un anno intero 1.955 € supera già i minimi garantiti (690 € o 1.380 €
    // a tempo determinato), che contano solo per periodi di lavoro più brevi.
    d = Math.max(1955, tempoDeterminato ? 1380 : 690);
  } else if (rc <= 28000) {
    d = 1910 + 1190 * ((28000 - rc) / 13000);
  } else if (rc <= 50000) {
    d = 1910 * ((50000 - rc) / 22000);
  } else {
    d = 0;
  }
  if (rc > 25000 && rc <= 35000) d += 65;
  return round2(d);
}

/** Detrazione per redditi da pensione (art. 13, c. 3 e 5-bis TUIR). */
export function detrazionePensione(rc: number): number {
  if (rc <= 0) return 0;
  let d: number;
  if (rc <= 8500) d = 1955;
  else if (rc <= 28000) d = 700 + 1255 * ((28000 - rc) / 19500);
  else if (rc <= 50000) d = 700 * ((50000 - rc) / 22000);
  else d = 0;
  if (rc <= 8500) d = Math.max(d, 713);
  if (rc > 25000 && rc <= 29000) d += 50;
  return round2(d);
}

/** Somma esente da cuneo fiscale (L. 207/2024): spetta con reddito complessivo ≤ 20.000 €. */
export function sommaEsenteCuneo(
  redditoLavoro: number,
  rc: number,
  p: CuneoParams = PARAMS.cuneoFiscale,
): number {
  const limite = p.sommaEsente[p.sommaEsente.length - 1].fino;
  if (rc > limite || redditoLavoro <= 0) return 0;
  const fascia = p.sommaEsente.find((f) => redditoLavoro <= f.fino) ?? p.sommaEsente[p.sommaEsente.length - 1];
  return round2(redditoLavoro * fascia.percentuale);
}

/** Ulteriore detrazione da cuneo fiscale (L. 207/2024) per reddito complessivo 20.000–40.000 €. */
export function ulterioreDetrazioneCuneo(rc: number, p: CuneoParams = PARAMS.cuneoFiscale): number {
  const u = p.ulterioreDetrazione;
  if (rc <= u.da || rc > u.azzeraA) return 0;
  if (rc <= u.pienoFino) return u.pieno;
  return round2(u.pieno * ((u.azzeraA - rc) / (u.azzeraA - u.pienoFino)));
}

/**
 * Trattamento integrativo (D.L. 3/2020, art. 1), versione semplificata che
 * considera solo la detrazione per lavoro dipendente.
 */
export function trattamentoIntegrativo(rc: number, lorda: number, detrLavoro: number): number {
  if (rc <= 0) return 0;
  if (rc <= 15000) {
    return lorda > detrLavoro - 75 ? 1200 : 0;
  }
  if (rc <= 28000) {
    return detrLavoro > lorda ? round2(Math.min(1200, detrLavoro - lorda)) : 0;
  }
  return 0;
}

export type IrpefInput = {
  redditoComplessivo: number;
  tipo: TipoReddito;
  tempoDeterminato?: boolean;
};

export type IrpefResult = {
  imponibile: number;
  lorda: number;
  detrazioneTipo: number;
  ulterioreDetrazione: number;
  detrazioniTotali: number;
  netta: number;
  sommaEsente: number;
  trattamentoIntegrativo: number;
  aliquotaMedia: number;
  aliquotaMarginale: number;
};

export function calcolaIrpef(input: IrpefInput): IrpefResult {
  const rc = Math.max(0, input.redditoComplessivo);
  const lorda = impostaLorda(rc);
  const detrazioneTipo =
    input.tipo === "dipendente"
      ? detrazioneLavoroDipendente(rc, input.tempoDeterminato)
      : input.tipo === "pensionato"
        ? detrazionePensione(rc)
        : 0;
  const ulteriore = input.tipo === "dipendente" ? ulterioreDetrazioneCuneo(rc) : 0;
  const detrazioniTotali = round2(Math.min(lorda, detrazioneTipo + ulteriore));
  const netta = round2(Math.max(0, lorda - detrazioneTipo - ulteriore));
  const sommaEsente = input.tipo === "dipendente" ? sommaEsenteCuneo(rc, rc) : 0;
  const ti = input.tipo === "dipendente" ? trattamentoIntegrativo(rc, lorda, detrazioneTipo) : 0;
  return {
    imponibile: rc,
    lorda,
    detrazioneTipo,
    ulterioreDetrazione: ulteriore,
    detrazioniTotali,
    netta,
    sommaEsente,
    trattamentoIntegrativo: ti,
    aliquotaMedia: rc > 0 ? netta / rc : 0,
    aliquotaMarginale: aliquotaMarginale(rc),
  };
}
