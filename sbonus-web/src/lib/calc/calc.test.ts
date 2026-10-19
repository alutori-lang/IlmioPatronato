import { describe, expect, it } from "vitest";
import { parseItNumber, round2 } from "./money";
import {
  impostaLorda,
  aliquotaMarginale,
  detrazioneLavoroDipendente,
  detrazionePensione,
  ulterioreDetrazioneCuneo,
  sommaEsenteCuneo,
  trattamentoIntegrativo,
  calcolaIrpef,
} from "./irpef";
import { calcolaNaspi } from "./naspi";
import { calcolaAssegnoUnico, interpola } from "./assegnoUnico";
import { calcolaTfr } from "./tfr";
import { calcolaStipendio, contributiInpsDipendente } from "./stipendio";
import { calcolaMutuo } from "./mutuo";
import { calcolaRisparmio } from "./risparmio";

describe("parseItNumber", () => {
  it.each([
    ["1.234,56", 1234.56],
    ["1234,5", 1234.5],
    ["1234.5", 1234.5],
    ["30.000", 30000],
    ["1.250.000", 1250000],
    ["€ 2.000", 2000],
    ["0", 0],
  ])("%s → %d", (s, n) => expect(parseItNumber(s)).toBe(n));
  it.each(["", "abc", "12a", "--1"])("rifiuta %s", (s) => expect(parseItNumber(s)).toBeNaN());
});

describe("IRPEF 2026", () => {
  it("scaglioni 23/33/43", () => {
    expect(impostaLorda(0)).toBe(0);
    expect(impostaLorda(-5)).toBe(0);
    expect(impostaLorda(28000)).toBe(6440);
    expect(impostaLorda(50000)).toBe(13700);
    expect(impostaLorda(60000)).toBe(18000);
  });
  it("aliquota marginale ai confini", () => {
    expect(aliquotaMarginale(28000)).toBe(0.23);
    expect(aliquotaMarginale(28000.01)).toBe(0.33);
    expect(aliquotaMarginale(50001)).toBe(0.43);
  });
  it("detrazione lavoro dipendente", () => {
    expect(detrazioneLavoroDipendente(10000)).toBe(1955);
    expect(detrazioneLavoroDipendente(15000)).toBe(1955);
    expect(detrazioneLavoroDipendente(20000)).toBe(2642.31);
    expect(detrazioneLavoroDipendente(28000)).toBe(1975); // 1910 + 65
    expect(detrazioneLavoroDipendente(30000)).toBe(1801.36);
    expect(detrazioneLavoroDipendente(50000)).toBe(0);
    expect(detrazioneLavoroDipendente(80000)).toBe(0);
  });
  it("detrazione pensione", () => {
    expect(detrazionePensione(8000)).toBe(1955);
    expect(detrazionePensione(28000)).toBe(750); // 700 + 50 (fascia 25-29k)
    expect(detrazionePensione(30000)).toBe(round2(700 * (20000 / 22000)));
    expect(detrazionePensione(26000)).toBe(round2(700 + 1255 * (2000 / 19500) + 50));
    expect(detrazionePensione(55000)).toBe(0);
  });
  it("cuneo fiscale", () => {
    expect(sommaEsenteCuneo(8000, 8000)).toBe(568);
    expect(sommaEsenteCuneo(12000, 12000)).toBe(636);
    expect(sommaEsenteCuneo(18000, 18000)).toBe(864);
    expect(sommaEsenteCuneo(20000, 20000)).toBe(960);
    expect(sommaEsenteCuneo(20001, 20001)).toBe(0);
    expect(ulterioreDetrazioneCuneo(20000)).toBe(0);
    expect(ulterioreDetrazioneCuneo(25000)).toBe(1000);
    expect(ulterioreDetrazioneCuneo(32000)).toBe(1000);
    expect(ulterioreDetrazioneCuneo(36000)).toBe(500);
    expect(ulterioreDetrazioneCuneo(40000)).toBe(0);
  });
  it("trattamento integrativo", () => {
    // 12.000 €: lorda 2.760 > 1.955 − 75 → spetta
    expect(trattamentoIntegrativo(12000, impostaLorda(12000), 1955)).toBe(1200);
    // 8.000 €: lorda 1.840 < 1.880 → incapiente, non spetta
    expect(trattamentoIntegrativo(8000, impostaLorda(8000), 1955)).toBe(0);
    expect(trattamentoIntegrativo(30000, 7000, 1800)).toBe(0);
  });
  it("calcolaIrpef non va mai sotto zero", () => {
    const r = calcolaIrpef({ redditoComplessivo: 7000, tipo: "dipendente" });
    expect(r.netta).toBe(0);
    expect(r.detrazioniTotali).toBe(r.lorda);
    const a = calcolaIrpef({ redditoComplessivo: 40000, tipo: "altro" });
    expect(a.netta).toBe(a.lorda);
  });
});

describe("INPS e stipendio netto", () => {
  it("contributi con aliquota aggiuntiva oltre soglia", () => {
    expect(contributiInpsDipendente(30000)).toBe(2757);
    expect(contributiInpsDipendente(60000)).toBe(round2(60000 * 0.0919 + (60000 - 56224) * 0.01));
  });
  it("RAL 30.000 €, 13 mensilità", () => {
    const r = calcolaStipendio({ ral: 30000, mensilita: 13, tempoDeterminato: false, addizionaleRegionale: 0.0123, addizionaleComunale: 0.008 });
    if (!r.ok) throw new Error(r.errore);
    expect(r.imponibileIrpef).toBe(27243);
    expect(r.ulterioreDetrazione).toBe(1000);
    expect(r.sommaEsente).toBe(0);
    expect(r.nettoAnnuo).toBeGreaterThan(21000);
    expect(r.nettoAnnuo).toBeLessThan(24000);
    expect(r.nettoMensile).toBe(round2(r.nettoAnnuo / 13));
  });
  it("redditi bassi ricevono la somma esente", () => {
    const r = calcolaStipendio({ ral: 15000, mensilita: 13, tempoDeterminato: false, addizionaleRegionale: 0, addizionaleComunale: 0 });
    if (!r.ok) throw new Error(r.errore);
    expect(r.sommaEsente).toBeGreaterThan(0);
    expect(r.nettoAnnuo).toBeGreaterThan(15000 - r.contributiInps - r.irpefNetta);
  });
  it("valida gli input", () => {
    expect(calcolaStipendio({ ral: 0, mensilita: 13, tempoDeterminato: false, addizionaleRegionale: 0, addizionaleComunale: 0 }).ok).toBe(false);
    expect(calcolaStipendio({ ral: 30000, mensilita: 13, tempoDeterminato: false, addizionaleRegionale: 0.2, addizionaleComunale: 0 }).ok).toBe(false);
  });
});

describe("NASpI 2026", () => {
  it("sotto soglia: 75%", () => {
    // media = 60.000 / 208 × 4,33 = 1.249,04
    const r = calcolaNaspi({ retribuzioneQuattroAnni: 60000, settimaneContributi: 208, over55: false });
    if (!r.ok) throw new Error(r.errore);
    expect(r.retribuzioneMediaMensile).toBe(1249.04);
    expect(r.importoIniziale).toBe(936.78);
    expect(r.piano).toHaveLength(24);
    expect(r.settimaneIndennizzate).toBe(104);
  });
  it("sopra soglia: 75% + 25% dell'eccedenza", () => {
    const r = calcolaNaspi({ retribuzioneQuattroAnni: 100000, settimaneContributi: 208, over55: false });
    if (!r.ok) throw new Error(r.errore);
    expect(r.importoIniziale).toBe(round2(1456.72 * 0.75 + (r.retribuzioneMediaMensile - 1456.72) * 0.25));
    expect(r.massimaleApplicato).toBe(false);
  });
  it("applica il massimale", () => {
    const r = calcolaNaspi({ retribuzioneQuattroAnni: 400000, settimaneContributi: 208, over55: false });
    if (!r.ok) throw new Error(r.errore);
    expect(r.importoIniziale).toBe(1584.7);
    expect(r.massimaleApplicato).toBe(true);
  });
  it("riduzione dal 6° mese, dall'8° per over 55", () => {
    const base = { retribuzioneQuattroAnni: 60000, settimaneContributi: 208 };
    const u = calcolaNaspi({ ...base, over55: false });
    const o = calcolaNaspi({ ...base, over55: true });
    if (!u.ok || !o.ok) throw new Error();
    expect(u.piano[4].importo).toBe(u.importoIniziale);
    expect(u.piano[5].importo).toBe(round2(u.importoIniziale * 0.97));
    expect(o.piano[6].importo).toBe(o.importoIniziale);
    expect(o.piano[7].importo).toBe(round2(o.importoIniziale * 0.97));
  });
  it("durata pari a metà delle settimane", () => {
    const r = calcolaNaspi({ retribuzioneQuattroAnni: 20000, settimaneContributi: 52, over55: false });
    if (!r.ok) throw new Error(r.errore);
    expect(r.settimaneIndennizzate).toBe(26);
    expect(r.piano.length).toBe(6); // 26 / 4,33 = 6,005 mesi
  });
  it("rifiuta meno di 13 settimane e input assurdi", () => {
    expect(calcolaNaspi({ retribuzioneQuattroAnni: 5000, settimaneContributi: 12, over55: false }).ok).toBe(false);
    expect(calcolaNaspi({ retribuzioneQuattroAnni: 5000, settimaneContributi: 300, over55: false }).ok).toBe(false);
    expect(calcolaNaspi({ retribuzioneQuattroAnni: 0, settimaneContributi: 50, over55: false }).ok).toBe(false);
  });
});

describe("Assegno Unico 2026", () => {
  const minore = { eta: "3-18" as const, disabilita: "nessuna" as const };
  it("importo massimo e minimo", () => {
    const max = calcolaAssegnoUnico({ isee: 10000, figli: [minore], madreUnder21: false });
    const min = calcolaAssegnoUnico({ isee: 60000, figli: [minore], madreUnder21: false });
    const senza = calcolaAssegnoUnico({ isee: null, figli: [minore], madreUnder21: false });
    if (!max.ok || !min.ok || !senza.ok) throw new Error();
    expect(max.mensile).toBe(203.8);
    expect(min.mensile).toBe(58.3);
    expect(senza.mensile).toBe(58.3);
    expect(senza.importoMinimo).toBe(true);
  });
  it("interpolazione a metà fascia", () => {
    expect(round2(interpola(203.8, 58.3, (17468.51 + 46582.71) / 2))).toBe(131.05);
  });
  it("figlio sotto 1 anno: +50%", () => {
    const r = calcolaAssegnoUnico({ isee: 10000, figli: [{ eta: "under1", disabilita: "nessuna" }], madreUnder21: false });
    if (!r.ok) throw new Error();
    expect(r.mensile).toBe(305.7);
  });
  it("quattro figli: maggiorazioni dal terzo e forfettaria", () => {
    const r = calcolaAssegnoUnico({ isee: 10000, figli: [minore, minore, minore, minore], madreUnder21: false });
    if (!r.ok) throw new Error();
    expect(r.mensile).toBe(round2(203.8 * 4 + 99.1 * 2 + 150));
  });
  it("richiede almeno un figlio", () => {
    expect(calcolaAssegnoUnico({ isee: 10000, figli: [], madreUnder21: false }).ok).toBe(false);
  });
});

describe("TFR", () => {
  it("un anno senza inflazione", () => {
    const r = calcolaTfr({ retribuzioneAnnua: 30000, anni: 1, inflazione: 0 });
    if (!r.ok) throw new Error(r.errore);
    expect(r.quotaAnnua).toBe(2072.22);
    expect(r.fondoLordo).toBe(2072.22);
    expect(r.totaleRivalutazioni).toBe(0);
  });
  it("rivalutazione 1,5% + 75% inflazione, netta del 17%", () => {
    const r = calcolaTfr({ retribuzioneAnnua: 30000, anni: 2, inflazione: 0.02 });
    if (!r.ok) throw new Error(r.errore);
    expect(r.coefficienteRivalutazione).toBeCloseTo(0.03, 10);
    const riv = round2(2072.22 * 0.03);
    expect(r.piano[1].rivalutazione).toBe(riv);
    expect(r.piano[1].fondo).toBe(round2(2072.22 + riv - round2(riv * 0.17) + 2072.22));
    expect(r.nettoStimato).toBeLessThan(r.fondoLordo);
  });
  it("valida anni e retribuzione", () => {
    expect(calcolaTfr({ retribuzioneAnnua: 30000, anni: 0, inflazione: 0 }).ok).toBe(false);
    expect(calcolaTfr({ retribuzioneAnnua: 30000, anni: 2.5, inflazione: 0 }).ok).toBe(false);
    expect(calcolaTfr({ retribuzioneAnnua: -1, anni: 2, inflazione: 0 }).ok).toBe(false);
  });
});

describe("Rata mutuo", () => {
  it("100.000 € al 3% per 20 anni", () => {
    const r = calcolaMutuo({ importo: 100000, tasso: 0.03, anni: 20 });
    if (!r.ok) throw new Error(r.errore);
    expect(r.rata).toBe(554.6);
    expect(r.pianoAnnuale).toHaveLength(20);
    expect(r.pianoAnnuale[19].debitoResiduo).toBeCloseTo(0, 2);
  });
  it("tasso zero", () => {
    const r = calcolaMutuo({ importo: 120000, tasso: 0, anni: 10 });
    if (!r.ok) throw new Error(r.errore);
    expect(r.rata).toBe(1000);
    expect(r.totaleInteressi).toBe(0);
  });
  it("valida durata", () => {
    expect(calcolaMutuo({ importo: 100000, tasso: 0.03, anni: 0 }).ok).toBe(false);
    expect(calcolaMutuo({ importo: 100000, tasso: 0.03, anni: 41 }).ok).toBe(false);
  });
});

describe("Risparmio familiare", () => {
  it("senza rendimento", () => {
    const r = calcolaRisparmio({ entrateMensili: 2000, speseMensili: 1500, obiettivo: 6000, rendimento: 0, anni: 2 });
    if (!r.ok) throw new Error(r.errore);
    expect(r.risparmioMensile).toBe(500);
    expect(r.tassoRisparmio).toBe(0.25);
    expect(r.mesiPerObiettivo).toBe(12);
    expect(r.capitaleFinale).toBe(12000);
    expect(r.fondoEmergenza).toBe(9000);
  });
  it("obiettivo oltre l'orizzonte", () => {
    const r = calcolaRisparmio({ entrateMensili: 2000, speseMensili: 1900, obiettivo: 5000, rendimento: 0, anni: 1 });
    if (!r.ok) throw new Error(r.errore);
    expect(r.mesiPerObiettivo).toBe(50);
  });
  it("spese pari alle entrate", () => {
    expect(calcolaRisparmio({ entrateMensili: 1500, speseMensili: 1500, obiettivo: 0, rendimento: 0, anni: 1 }).ok).toBe(false);
  });
});
