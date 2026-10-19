import { PARAMS, type Parametri } from "./params";
import { round2 } from "./money";
import {
  impostaLorda,
  detrazioneLavoroDipendente,
  ulterioreDetrazioneCuneo,
  sommaEsenteCuneo,
  trattamentoIntegrativo,
} from "./irpef";

type InpsParams = Parametri["inpsDipendente"];

export type StipendioInput = {
  /** Retribuzione annua lorda (RAL) in €. */
  ral: number;
  mensilita: 12 | 13 | 14;
  tempoDeterminato: boolean;
  /** Aliquota addizionale regionale, es. 0.0123 = 1,23%. */
  addizionaleRegionale: number;
  /** Aliquota addizionale comunale, es. 0.008 = 0,8%. */
  addizionaleComunale: number;
};

export type StipendioResult =
  | { ok: false; errore: string }
  | {
      ok: true;
      contributiInps: number;
      imponibileIrpef: number;
      irpefLorda: number;
      detrazioneLavoro: number;
      ulterioreDetrazione: number;
      irpefNetta: number;
      addizionaleRegionale: number;
      addizionaleComunale: number;
      sommaEsente: number;
      trattamentoIntegrativo: number;
      nettoAnnuo: number;
      nettoMensile: number;
    };

export function contributiInpsDipendente(ral: number, p: InpsParams = PARAMS.inpsDipendente): number {
  const base = ral * p.aliquota;
  const extra = Math.max(0, ral - p.sogliaAggiuntivaAnnua) * p.aliquotaAggiuntiva;
  return round2(base + extra);
}

export function calcolaStipendio(input: StipendioInput): StipendioResult {
  const { ral } = input;
  if (!(ral > 0)) return { ok: false, errore: "Inserisci la retribuzione annua lorda (RAL)." };
  if (ral > 1_000_000) return { ok: false, errore: "Il simulatore è pensato per RAL fino a 1.000.000 €." };
  if (![12, 13, 14].includes(input.mensilita)) return { ok: false, errore: "Scegli 12, 13 o 14 mensilità." };
  for (const a of [input.addizionaleRegionale, input.addizionaleComunale]) {
    if (!(a >= 0) || a > 0.05) return { ok: false, errore: "Le aliquote delle addizionali devono essere tra 0% e 5%." };
  }

  const inps = contributiInpsDipendente(ral);
  const imponibile = round2(ral - inps);
  const lorda = impostaLorda(imponibile);
  const detr = detrazioneLavoroDipendente(imponibile, input.tempoDeterminato);
  const ulteriore = ulterioreDetrazioneCuneo(imponibile);
  const netta = round2(Math.max(0, lorda - detr - ulteriore));
  const addReg = round2(imponibile * input.addizionaleRegionale);
  const addCom = round2(imponibile * input.addizionaleComunale);
  const esente = sommaEsenteCuneo(imponibile, imponibile);
  const ti = trattamentoIntegrativo(imponibile, lorda, detr);

  const nettoAnnuo = round2(ral - inps - netta - addReg - addCom + esente + ti);
  return {
    ok: true,
    contributiInps: inps,
    imponibileIrpef: imponibile,
    irpefLorda: lorda,
    detrazioneLavoro: detr,
    ulterioreDetrazione: ulteriore,
    irpefNetta: netta,
    addizionaleRegionale: addReg,
    addizionaleComunale: addCom,
    sommaEsente: esente,
    trattamentoIntegrativo: ti,
    nettoAnnuo,
    nettoMensile: round2(nettoAnnuo / input.mensilita),
  };
}
