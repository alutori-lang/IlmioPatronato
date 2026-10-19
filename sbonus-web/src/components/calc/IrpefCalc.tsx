"use client";

import { useState } from "react";
import { calcolaIrpef, type IrpefResult, type TipoReddito } from "@/lib/calc/irpef";
import { formatEuro, formatPct, parseItNumber } from "@/lib/calc/money";
import { CalcForm, EmptyResult, NumberField, ResultPanel, Righe, SelectField } from "./Fields";

export function IrpefCalc() {
  const [reddito, setReddito] = useState("");
  const [tipo, setTipo] = useState<TipoReddito>("dipendente");
  const [err, setErr] = useState<string>();
  const [res, setRes] = useState<IrpefResult | null>(null);

  const calcola = () => {
    const r = parseItNumber(reddito);
    if (!(r >= 0) || r > 10_000_000) {
      setErr("Inserisci un reddito valido, ad esempio 32.000");
      return setRes(null);
    }
    setErr(undefined);
    setRes(calcolaIrpef({ redditoComplessivo: r, tipo }));
  };

  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <CalcForm
        onSubmit={calcola}
        onReset={() => {
          setReddito("");
          setTipo("dipendente");
          setErr(undefined);
          setRes(null);
        }}
      >
        <NumberField
          label="Reddito complessivo annuo"
          suffix="€"
          value={reddito}
          onChange={setReddito}
          error={err}
          placeholder="32.000"
          hint="Al netto dei contributi previdenziali e degli oneri deducibili (per i dipendenti è il reddito indicato nella CU)."
        />
        <SelectField
          label="Tipo di reddito prevalente"
          value={tipo}
          onChange={setTipo}
          options={[
            { value: "dipendente", label: "Lavoro dipendente" },
            { value: "pensionato", label: "Pensione" },
            { value: "altro", label: "Altro (nessuna detrazione per tipo di reddito)" },
          ]}
        />
      </CalcForm>

      <div className="space-y-4">
        {!res && <EmptyResult testo="Inserisci il reddito e premi Calcola." />}
        {res && (
          <ResultPanel titolo="IRPEF netta stimata 2026" valore={formatEuro(res.netta)} nota={`Aliquota media ${formatPct(res.aliquotaMedia)} · aliquota marginale ${formatPct(res.aliquotaMarginale)}`}>
            <Righe
              righe={[
                { l: "IRPEF lorda (scaglioni 2026)", v: res.lorda },
                ...(res.detrazioneTipo > 0 ? [{ l: tipo === "pensionato" ? "Detrazione pensione" : "Detrazione lavoro dipendente", v: res.detrazioneTipo, segno: "-" as const }] : []),
                ...(res.ulterioreDetrazione > 0 ? [{ l: "Ulteriore detrazione cuneo fiscale", v: res.ulterioreDetrazione, segno: "-" as const }] : []),
                { l: "IRPEF netta", v: res.netta, forte: true },
                ...(res.sommaEsente > 0 ? [{ l: "Somma esente cuneo fiscale (in busta paga, non tassata)", v: res.sommaEsente, segno: "+" as const }] : []),
                ...(res.trattamentoIntegrativo > 0 ? [{ l: "Trattamento integrativo (in busta paga)", v: res.trattamentoIntegrativo, segno: "+" as const }] : []),
              ]}
            />
            <p className="mt-3 text-sm text-ink-3">Addizionali regionale e comunale escluse: si aggiungono in base alla residenza.</p>
          </ResultPanel>
        )}
      </div>
    </div>
  );
}
