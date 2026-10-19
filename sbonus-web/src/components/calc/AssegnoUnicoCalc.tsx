"use client";

import { useState } from "react";
import { calcolaAssegnoUnico, type AssegnoUnicoResult, type Disabilita, type FasciaEta, type Figlio } from "@/lib/calc/assegnoUnico";
import { formatEuro, parseItNumber } from "@/lib/calc/money";
import { CalcForm, CheckField, EmptyResult, ErrorBox, NumberField, ResultPanel, Righe, SelectField } from "./Fields";

const ETA: { value: FasciaEta; label: string }[] = [
  { value: "under1", label: "Meno di 1 anno" },
  { value: "1-3", label: "Da 1 a 3 anni" },
  { value: "3-18", label: "Da 3 a 17 anni" },
  { value: "18-21", label: "Da 18 a 20 anni (studente, tirocinante o con lavoro a basso reddito)" },
];
const DIS: { value: Disabilita; label: string }[] = [
  { value: "nessuna", label: "Nessuna disabilità" },
  { value: "media", label: "Disabilità media" },
  { value: "grave", label: "Disabilità grave" },
  { value: "nonAutosufficienza", label: "Non autosufficienza" },
];
const nuovoFiglio = (): Figlio => ({ eta: "3-18", disabilita: "nessuna" });

export function AssegnoUnicoCalc() {
  const [isee, setIsee] = useState("");
  const [senzaIsee, setSenzaIsee] = useState(false);
  const [figli, setFigli] = useState<Figlio[]>([nuovoFiglio()]);
  const [madre, setMadre] = useState(false);
  const [err, setErr] = useState<string>();
  const [res, setRes] = useState<AssegnoUnicoResult | null>(null);

  const aggiorna = (i: number, f: Partial<Figlio>) => setFigli((xs) => xs.map((x, j) => (j === i ? { ...x, ...f } : x)));

  const calcola = () => {
    let v: number | null = null;
    if (!senzaIsee) {
      v = parseItNumber(isee);
      if (!(v >= 0)) {
        setErr("Inserisci il valore ISEE (es. 18.500) oppure spunta «Non ho un ISEE valido».");
        return setRes(null);
      }
    }
    setErr(undefined);
    setRes(calcolaAssegnoUnico({ isee: v, figli, madreUnder21: madre }));
  };

  const reset = () => {
    setIsee("");
    setSenzaIsee(false);
    setFigli([nuovoFiglio()]);
    setMadre(false);
    setErr(undefined);
    setRes(null);
  };

  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <CalcForm onSubmit={calcola} onReset={reset}>
        {!senzaIsee && (
          <NumberField label="Valore ISEE del nucleo" suffix="€" value={isee} onChange={setIsee} error={err} placeholder="18.500" hint="Lo trovi nell'attestazione ISEE rilasciata dall'INPS." />
        )}
        <CheckField label="Non ho un ISEE valido" checked={senzaIsee} onChange={setSenzaIsee} hint="Senza ISEE spetta l'importo minimo." />

        <fieldset className="space-y-3">
          <legend className="text-sm font-semibold text-ink">Figli a carico</legend>
          {figli.map((f, i) => (
            <div key={i} className="space-y-3 rounded-xl border border-line bg-bg p-3.5">
              <div className="flex items-center justify-between">
                <span className="font-semibold text-ink">Figlio {i + 1}</span>
                {figli.length > 1 && (
                  <button type="button" onClick={() => setFigli((xs) => xs.filter((_, j) => j !== i))} className="text-sm font-semibold text-danger hover:underline">
                    Rimuovi
                  </button>
                )}
              </div>
              <SelectField label="Età" value={f.eta} onChange={(v) => aggiorna(i, { eta: v })} options={ETA} />
              {f.eta !== "18-21" && <SelectField label="Disabilità" value={f.disabilita} onChange={(v) => aggiorna(i, { disabilita: v })} options={DIS} />}
            </div>
          ))}
          {figli.length < 10 && (
            <button type="button" onClick={() => setFigli((xs) => [...xs, nuovoFiglio()])} className="w-full rounded-xl border border-dashed border-brand/50 py-2.5 font-semibold text-brand hover:bg-brand-soft">
              + Aggiungi un figlio
            </button>
          )}
        </fieldset>
        <CheckField label="La madre ha meno di 21 anni" checked={madre} onChange={setMadre} />
      </CalcForm>

      <div className="space-y-4">
        {!res && <EmptyResult testo="Inserisci ISEE e figli, poi premi Calcola." />}
        {res && !res.ok && <ErrorBox msg={res.errore} />}
        {res && res.ok && (
          <ResultPanel
            titolo="Assegno Unico mensile stimato"
            valore={formatEuro(res.mensile)}
            nota={`Circa ${formatEuro(res.annuale)} in un anno${res.importoMinimo ? " · importo minimo (ISEE assente o oltre la soglia massima)" : ""}`}
          >
            <Righe
              righe={[
                ...res.righe.map((r) => ({ l: `Figlio ${r.indice}${r.voci.length ? ` (${r.voci.join(", ")})` : ""}`, v: r.totale })),
                ...res.maggiorazioniNucleo.map((m) => ({ l: m.voce, v: m.importo })),
                { l: "Totale mensile", v: res.mensile, forte: true },
              ]}
            />
          </ResultPanel>
        )}
      </div>
    </div>
  );
}
