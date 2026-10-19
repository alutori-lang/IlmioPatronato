"use client";

import { useState } from "react";
import { calcolaRisparmio, type RisparmioResult } from "@/lib/calc/risparmio";
import { formatEuro, formatPct, parseItNumber } from "@/lib/calc/money";
import { CalcForm, EmptyResult, ErrorBox, NumberField, ResultPanel, Righe } from "./Fields";

const INIZIALE = { entrate: "", spese: "", obiettivo: "", rendimento: "0", anni: "5" };

function durata(mesi: number) {
  const a = Math.floor(mesi / 12);
  const m = mesi % 12;
  return [a && `${a} ${a === 1 ? "anno" : "anni"}`, m && `${m} ${m === 1 ? "mese" : "mesi"}`].filter(Boolean).join(" e ");
}

export function RisparmioCalc() {
  const [f, setF] = useState(INIZIALE);
  const [err, setErr] = useState<Partial<Record<keyof typeof INIZIALE, string>>>({});
  const [res, setRes] = useState<RisparmioResult | null>(null);

  const calcola = () => {
    const entrate = parseItNumber(f.entrate);
    const spese = parseItNumber(f.spese);
    const obiettivo = f.obiettivo.trim() ? parseItNumber(f.obiettivo) : 0;
    const rend = parseItNumber(f.rendimento);
    const anni = parseItNumber(f.anni);
    const e: typeof err = {};
    if (!(entrate > 0)) e.entrate = "Inserisci le entrate mensili, ad esempio 2.300";
    if (!(spese >= 0)) e.spese = "Inserisci le spese mensili, ad esempio 1.900";
    if (!(obiettivo >= 0)) e.obiettivo = "Inserisci un importo valido o lascia vuoto";
    if (!(rend >= 0 && rend <= 15)) e.rendimento = "Inserisci una percentuale tra 0 e 15";
    if (!(anni >= 1 && anni <= 50 && Number.isInteger(anni))) e.anni = "Inserisci un numero intero di anni tra 1 e 50";
    setErr(e);
    if (Object.keys(e).length) return setRes(null);
    setRes(calcolaRisparmio({ entrateMensili: entrate, speseMensili: spese, obiettivo, rendimento: rend / 100, anni }));
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
        <div className="grid gap-4 sm:grid-cols-2">
          <NumberField label="Entrate mensili nette" suffix="€" value={f.entrate} onChange={(v) => setF({ ...f, entrate: v })} error={err.entrate} placeholder="2.300" hint="Stipendi, pensioni, assegni." />
          <NumberField label="Spese mensili" suffix="€" value={f.spese} onChange={(v) => setF({ ...f, spese: v })} error={err.spese} placeholder="1.900" hint="Affitto, bollette, spesa, rate." />
        </div>
        <NumberField label="Obiettivo di risparmio (facoltativo)" suffix="€" value={f.obiettivo} onChange={(v) => setF({ ...f, obiettivo: v })} error={err.obiettivo} placeholder="5.000" />
        <div className="grid gap-4 sm:grid-cols-2">
          <NumberField label="Rendimento netto annuo" suffix="%" value={f.rendimento} onChange={(v) => setF({ ...f, rendimento: v })} error={err.rendimento} hint="0% se tieni i soldi sul conto." />
          <NumberField label="Orizzonte" suffix="anni" value={f.anni} onChange={(v) => setF({ ...f, anni: v })} error={err.anni} inputMode="numeric" />
        </div>
      </CalcForm>

      <div className="space-y-4">
        {!res && <EmptyResult testo="Inserisci entrate e spese, poi premi Calcola." />}
        {res && !res.ok && <ErrorBox msg={res.errore} />}
        {res && res.ok && (
          <ResultPanel titolo="Risparmio mensile" valore={formatEuro(res.risparmioMensile)} nota={`Metti da parte il ${formatPct(res.tassoRisparmio)} delle entrate`}>
            <Righe
              righe={[
                { l: `Capitale dopo ${f.anni} anni`, v: res.capitaleFinale, forte: true },
                { l: "di cui versato", v: res.versato },
                { l: "di cui rendimento", v: res.interessi },
                ...(res.mesiPerObiettivo !== null ? [{ l: "Tempo per l'obiettivo", v: durata(res.mesiPerObiettivo) }] : []),
                { l: "Fondo emergenze consigliato (6 mesi di spese)", v: res.fondoEmergenza },
              ]}
            />
          </ResultPanel>
        )}
      </div>
    </div>
  );
}
