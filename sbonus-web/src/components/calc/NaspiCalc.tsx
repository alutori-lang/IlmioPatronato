"use client";

import { useState } from "react";
import { calcolaNaspi, type NaspiResult } from "@/lib/calc/naspi";
import { formatEuro, formatPct, parseItNumber } from "@/lib/calc/money";
import { CalcForm, CheckField, EmptyResult, ErrorBox, NumberField, ResultPanel, Righe } from "./Fields";

export function NaspiCalc() {
  const [retr, setRetr] = useState("");
  const [sett, setSett] = useState("");
  const [over55, setOver55] = useState(false);
  const [err, setErr] = useState<{ retr?: string; sett?: string }>({});
  const [res, setRes] = useState<NaspiResult | null>(null);

  const calcola = () => {
    const r = parseItNumber(retr);
    const s = parseItNumber(sett);
    const e: typeof err = {};
    if (!(r > 0)) e.retr = "Inserisci un importo valido, ad esempio 85.000";
    if (!(s > 0) || !Number.isInteger(s)) e.sett = "Inserisci un numero intero di settimane, ad esempio 156";
    setErr(e);
    if (Object.keys(e).length) return setRes(null);
    setRes(calcolaNaspi({ retribuzioneQuattroAnni: r, settimaneContributi: s, over55 }));
  };

  const reset = () => {
    setRetr("");
    setSett("");
    setOver55(false);
    setErr({});
    setRes(null);
  };

  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <CalcForm onSubmit={calcola} onReset={reset}>
        <NumberField
          label="Retribuzione imponibile degli ultimi 4 anni"
          suffix="€"
          value={retr}
          onChange={setRetr}
          error={err.retr}
          placeholder="85.000"
          hint="Somma delle retribuzioni lorde soggette a contributi nei 4 anni prima della perdita del lavoro (dalle CU o dall'estratto conto INPS)."
        />
        <NumberField
          label="Settimane di contribuzione negli ultimi 4 anni"
          value={sett}
          onChange={setSett}
          error={err.sett}
          placeholder="156"
          inputMode="numeric"
          hint="Un anno pieno vale circa 52 settimane; il massimo in 4 anni è 208."
        />
        <CheckField label="Avevo 55 anni o più alla data della domanda" checked={over55} onChange={setOver55} hint="La riduzione mensile parte dall'8° mese anziché dal 6°." />
      </CalcForm>

      <div className="space-y-4">
        {!res && <EmptyResult testo="Compila i campi e premi Calcola per vedere la stima." />}
        {res && !res.ok && <ErrorBox msg={res.errore} />}
        {res && res.ok && (
          <ResultPanel titolo="Importo mensile iniziale stimato (lordo)" valore={formatEuro(res.importoIniziale)} nota={res.massimaleApplicato ? "Applicato il massimale mensile 2026." : undefined}>
            <Righe
              righe={[
                { l: "Retribuzione media mensile", v: res.retribuzioneMediaMensile },
                { l: "Settimane indennizzate", v: `${res.settimaneIndennizzate}` },
                { l: "Durata stimata", v: `${res.mesiStimati.toLocaleString("it-IT")} mesi` },
                { l: "Totale lordo stimato", v: res.totaleStimato, forte: true },
              ]}
            />
            <details className="mt-4 rounded-xl border border-line">
              <summary className="cursor-pointer px-4 py-3 font-semibold text-ink">Importo mese per mese</summary>
              <div className="max-h-80 overflow-auto px-4 pb-3">
                <table className="w-full text-sm">
                  <caption className="sr-only">Piano mensile stimato della NASpI</caption>
                  <thead>
                    <tr className="text-left text-ink-3">
                      <th scope="col" className="py-2">Mese</th>
                      <th scope="col" className="py-2 text-right">Importo</th>
                      <th scope="col" className="py-2 text-right">Riduzione</th>
                    </tr>
                  </thead>
                  <tbody className="tabular-nums text-ink-2">
                    {res.piano.map((m) => (
                      <tr key={m.mese} className="border-t border-line">
                        <td className="py-1.5">{m.mese}°</td>
                        <td className="py-1.5 text-right">{formatEuro(m.importo)}</td>
                        <td className="py-1.5 text-right">{m.riduzione > 0 ? `−${formatPct(m.riduzione)}` : "—"}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <p className="mt-2 text-xs text-ink-3">L&apos;ultimo mese può essere parziale. Importi lordi, prima delle ritenute IRPEF.</p>
              </div>
            </details>
          </ResultPanel>
        )}
      </div>
    </div>
  );
}
