"use client";

import { useState } from "react";
import { calcolaMutuo, type MutuoResult } from "@/lib/calc/mutuo";
import { formatEuro, parseItNumber } from "@/lib/calc/money";
import { CalcForm, EmptyResult, ErrorBox, NumberField, ResultPanel, Righe } from "./Fields";

const INIZIALE = { importo: "", tasso: "", anni: "25" };

export function MutuoCalc() {
  const [f, setF] = useState(INIZIALE);
  const [err, setErr] = useState<Partial<Record<keyof typeof INIZIALE, string>>>({});
  const [res, setRes] = useState<MutuoResult | null>(null);

  const calcola = () => {
    const importo = parseItNumber(f.importo);
    const tasso = parseItNumber(f.tasso);
    const anni = parseItNumber(f.anni);
    const e: typeof err = {};
    if (!(importo > 0)) e.importo = "Inserisci l'importo, ad esempio 150.000";
    if (!(tasso >= 0 && tasso <= 25)) e.tasso = "Inserisci un tasso tra 0 e 25, ad esempio 3,2";
    if (!(anni >= 1 && anni <= 40 && Number.isInteger(anni))) e.anni = "Inserisci una durata intera tra 1 e 40 anni";
    setErr(e);
    if (Object.keys(e).length) return setRes(null);
    setRes(calcolaMutuo({ importo, tasso: tasso / 100, anni }));
  };

  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <CalcForm
        onSubmit={calcola}
        onReset={() => {
          setF(INIZIALE);
          setErr({});
          setRes(null);
        }}
      >
        <NumberField label="Importo del mutuo" suffix="€" value={f.importo} onChange={(v) => setF({ ...f, importo: v })} error={err.importo} placeholder="150.000" />
        <NumberField label="Tasso annuo nominale (TAN)" suffix="%" value={f.tasso} onChange={(v) => setF({ ...f, tasso: v })} error={err.tasso} placeholder="3,2" hint="Il TAN indicato nell'offerta della banca, non il TAEG." />
        <NumberField label="Durata" suffix="anni" value={f.anni} onChange={(v) => setF({ ...f, anni: v })} error={err.anni} inputMode="numeric" />
      </CalcForm>

      <div className="space-y-4">
        {!res && <EmptyResult testo="Inserisci importo, tasso e durata, poi premi Calcola." />}
        {res && !res.ok && <ErrorBox msg={res.errore} />}
        {res && res.ok && (
          <ResultPanel titolo="Rata mensile" valore={formatEuro(res.rata)} nota={`${res.numeroRate} rate a tasso fisso`}>
            <Righe
              righe={[
                { l: "Capitale finanziato", v: res.totaleRestituito - res.totaleInteressi },
                { l: "Interessi totali", v: res.totaleInteressi, segno: "+" },
                { l: "Totale da restituire", v: res.totaleRestituito, forte: true },
              ]}
            />
            <details className="mt-4 rounded-xl border border-line">
              <summary className="cursor-pointer px-4 py-3 font-semibold text-ink">Piano di ammortamento annuale</summary>
              <div className="max-h-80 overflow-auto px-4 pb-3">
                <table className="w-full text-sm">
                  <caption className="sr-only">Quote di capitale e interessi per anno</caption>
                  <thead>
                    <tr className="text-left text-ink-3">
                      <th scope="col" className="py-2">Anno</th>
                      <th scope="col" className="py-2 text-right">Capitale</th>
                      <th scope="col" className="py-2 text-right">Interessi</th>
                      <th scope="col" className="py-2 text-right">Debito residuo</th>
                    </tr>
                  </thead>
                  <tbody className="tabular-nums text-ink-2">
                    {res.pianoAnnuale.map((r) => (
                      <tr key={r.anno} className="border-t border-line">
                        <td className="py-1.5">{r.anno}</td>
                        <td className="py-1.5 text-right">{formatEuro(r.quotaCapitale)}</td>
                        <td className="py-1.5 text-right">{formatEuro(r.quotaInteressi)}</td>
                        <td className="py-1.5 text-right">{formatEuro(r.debitoResiduo)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </details>
          </ResultPanel>
        )}
      </div>
    </div>
  );
}
