"use client";

import { useState } from "react";
import { calcolaTfr, type TfrResult } from "@/lib/calc/tfr";
import { formatEuro, formatPct, parseItNumber } from "@/lib/calc/money";
import { CalcForm, EmptyResult, ErrorBox, NumberField, ResultPanel, Righe } from "./Fields";

const INIZIALE = { ral: "", anni: "", infl: "2" };

export function TfrCalc() {
  const [f, setF] = useState(INIZIALE);
  const [err, setErr] = useState<Partial<Record<keyof typeof INIZIALE, string>>>({});
  const [res, setRes] = useState<TfrResult | null>(null);

  const calcola = () => {
    const ral = parseItNumber(f.ral);
    const anni = parseItNumber(f.anni);
    const infl = parseItNumber(f.infl);
    const e: typeof err = {};
    if (!(ral > 0)) e.ral = "Inserisci la retribuzione annua, ad esempio 26.000";
    if (!(anni >= 1 && anni <= 50 && Number.isInteger(anni))) e.anni = "Inserisci un numero intero di anni tra 1 e 50";
    if (!(infl >= 0 && infl <= 20)) e.infl = "Inserisci una percentuale tra 0 e 20";
    setErr(e);
    if (Object.keys(e).length) return setRes(null);
    setRes(calcolaTfr({ retribuzioneAnnua: ral, anni, inflazione: infl / 100 }));
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
        <NumberField label="Retribuzione annua lorda" suffix="€" value={f.ral} onChange={(v) => setF({ ...f, ral: v })} error={err.ral} placeholder="26.000" hint="Considerata costante per tutti gli anni." />
        <NumberField label="Anni di servizio" value={f.anni} onChange={(v) => setF({ ...f, anni: v })} error={err.anni} placeholder="8" inputMode="numeric" />
        <NumberField label="Inflazione media annua ipotizzata" suffix="%" value={f.infl} onChange={(v) => setF({ ...f, infl: v })} error={err.infl} hint="Serve a stimare la rivalutazione (1,5% + 75% dell'inflazione ISTAT)." />
      </CalcForm>

      <div className="space-y-4">
        {!res && <EmptyResult testo="Inserisci retribuzione e anni, poi premi Calcola." />}
        {res && !res.ok && <ErrorBox msg={res.errore} />}
        {res && res.ok && (
          <ResultPanel titolo="TFR netto stimato" valore={formatEuro(res.nettoStimato)} nota={`Fondo lordo maturato: ${formatEuro(res.fondoLordo)}`}>
            <Righe
              righe={[
                { l: "Quota annua accantonata", v: res.quotaAnnua },
                { l: "Rivalutazioni nette totali", v: res.totaleRivalutazioni, segno: "+" },
                { l: "Fondo TFR lordo", v: res.fondoLordo },
                { l: `Tassazione separata (aliquota media ${formatPct(res.aliquotaMedia)})`, v: res.impostaSeparata, segno: "-" },
                { l: "TFR netto stimato", v: res.nettoStimato, forte: true },
              ]}
            />
            {res.piano.length > 1 && (
              <details className="mt-4 rounded-xl border border-line">
                <summary className="cursor-pointer px-4 py-3 font-semibold text-ink">Andamento anno per anno</summary>
                <div className="max-h-80 overflow-auto px-4 pb-3">
                  <table className="w-full text-sm">
                    <caption className="sr-only">Accantonamento TFR per anno</caption>
                    <thead>
                      <tr className="text-left text-ink-3">
                        <th scope="col" className="py-2">Anno</th>
                        <th scope="col" className="py-2 text-right">Rivalutazione</th>
                        <th scope="col" className="py-2 text-right">Fondo</th>
                      </tr>
                    </thead>
                    <tbody className="tabular-nums text-ink-2">
                      {res.piano.map((a) => (
                        <tr key={a.anno} className="border-t border-line">
                          <td className="py-1.5">{a.anno}</td>
                          <td className="py-1.5 text-right">{formatEuro(a.rivalutazione - a.impostaRivalutazione)}</td>
                          <td className="py-1.5 text-right">{formatEuro(a.fondo)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </details>
            )}
          </ResultPanel>
        )}
      </div>
    </div>
  );
}
