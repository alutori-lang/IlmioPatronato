"use client";

import { useState } from "react";
import { calcolaStipendio, type StipendioResult } from "@/lib/calc/stipendio";
import { formatEuro, parseItNumber } from "@/lib/calc/money";
import { CalcForm, CheckField, EmptyResult, ErrorBox, NumberField, ResultPanel, Righe, SelectField } from "./Fields";

const INIZIALE = { ral: "", mens: "13" as "12" | "13" | "14", td: false, reg: "1,23", com: "0,8" };

export function StipendioCalc() {
  const [f, setF] = useState(INIZIALE);
  const [err, setErr] = useState<Partial<Record<"ral" | "reg" | "com", string>>>({});
  const [res, setRes] = useState<StipendioResult | null>(null);
  const set = <K extends keyof typeof f>(k: K, v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));

  const calcola = () => {
    const ral = parseItNumber(f.ral);
    const reg = parseItNumber(f.reg);
    const com = parseItNumber(f.com);
    const e: typeof err = {};
    if (!(ral > 0)) e.ral = "Inserisci la RAL, ad esempio 28.000";
    if (!(reg >= 0 && reg <= 5)) e.reg = "Inserisci una percentuale tra 0 e 5";
    if (!(com >= 0 && com <= 5)) e.com = "Inserisci una percentuale tra 0 e 5";
    setErr(e);
    if (Object.keys(e).length) return setRes(null);
    setRes(
      calcolaStipendio({
        ral,
        mensilita: Number(f.mens) as 12 | 13 | 14,
        tempoDeterminato: f.td,
        addizionaleRegionale: reg / 100,
        addizionaleComunale: com / 100,
      }),
    );
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
        <NumberField label="Retribuzione annua lorda (RAL)" suffix="€" value={f.ral} onChange={(v) => set("ral", v)} error={err.ral} placeholder="28.000" hint="La trovi nel contratto o nella lettera di assunzione." />
        <SelectField
          label="Numero di mensilità"
          value={f.mens}
          onChange={(v) => set("mens", v)}
          options={[
            { value: "12", label: "12 mensilità" },
            { value: "13", label: "13 mensilità (con tredicesima)" },
            { value: "14", label: "14 mensilità (con tredicesima e quattordicesima)" },
          ]}
          hint="Dipende dal contratto collettivo applicato."
        />
        <CheckField label="Contratto a tempo determinato" checked={f.td} onChange={(v) => set("td", v)} />
        <div className="grid gap-4 sm:grid-cols-2">
          <NumberField label="Addizionale regionale" suffix="%" value={f.reg} onChange={(v) => set("reg", v)} error={err.reg} hint="1,23% è l'aliquota base: molte Regioni la aumentano." />
          <NumberField label="Addizionale comunale" suffix="%" value={f.com} onChange={(v) => set("com", v)} error={err.com} hint="Varia da 0 a 0,8% secondo il Comune." />
        </div>
      </CalcForm>

      <div className="space-y-4">
        {!res && <EmptyResult testo="Inserisci la RAL e premi Calcola." />}
        {res && !res.ok && <ErrorBox msg={res.errore} />}
        {res && res.ok && (
          <ResultPanel titolo={`Netto mensile stimato (${f.mens} mensilità)`} valore={formatEuro(res.nettoMensile)} nota={`Netto annuo stimato: ${formatEuro(res.nettoAnnuo)}`}>
            <Righe
              righe={[
                { l: "Contributi INPS a tuo carico", v: res.contributiInps, segno: "-" },
                { l: "Imponibile IRPEF", v: res.imponibileIrpef },
                { l: "IRPEF lorda", v: res.irpefLorda },
                { l: "Detrazione lavoro dipendente", v: res.detrazioneLavoro, segno: "-" },
                ...(res.ulterioreDetrazione > 0 ? [{ l: "Ulteriore detrazione (cuneo fiscale)", v: res.ulterioreDetrazione, segno: "-" as const }] : []),
                { l: "IRPEF netta", v: res.irpefNetta, segno: "-" },
                { l: "Addizionale regionale", v: res.addizionaleRegionale, segno: "-" },
                { l: "Addizionale comunale", v: res.addizionaleComunale, segno: "-" },
                ...(res.sommaEsente > 0 ? [{ l: "Somma esente (cuneo fiscale)", v: res.sommaEsente, segno: "+" as const }] : []),
                ...(res.trattamentoIntegrativo > 0 ? [{ l: "Trattamento integrativo", v: res.trattamentoIntegrativo, segno: "+" as const }] : []),
                { l: "Netto annuo", v: res.nettoAnnuo, forte: true },
              ]}
            />
          </ResultPanel>
        )}
      </div>
    </div>
  );
}
