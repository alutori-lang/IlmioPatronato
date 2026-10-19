"use client";

import { useMemo, useState } from "react";
import type { BonusLite, StatoBonus } from "@/lib/content-shared";
import { STATO_LABEL } from "@/lib/content-shared";
import { normalizza } from "@/lib/search";
import { BonusList } from "./Rows";

type Props = { bonus: BonusLite[]; categorie: { slug: string; nome: string }[] };

export function BonusFilter({ bonus, categorie }: Props) {
  const [cat, setCat] = useState("tutte");
  const [stato, setStato] = useState<StatoBonus | "tutti">("tutti");
  const [testo, setTesto] = useState("");

  const stati = useMemo(() => Array.from(new Set(bonus.map((b) => b.stato))), [bonus]);
  const filtrati = useMemo(() => {
    const t = normalizza(testo);
    return bonus.filter(
      (b) =>
        (cat === "tutte" || b.categoria === cat) &&
        (stato === "tutti" || b.stato === stato) &&
        (!t || normalizza(`${b.titolo} ${b.descrizione} ${b.tags.join(" ")}`).includes(t)),
    );
  }, [bonus, cat, stato, testo]);

  const chip = (on: boolean) =>
    `rounded-full border px-3.5 py-1.5 text-sm transition-colors ${on ? "border-ink bg-ink text-bg" : "border-line text-ink-2 hover:border-ink-3 hover:text-ink"}`;

  return (
    <div className="mt-10">
      <div className="space-y-5">
        <div>
          <label htmlFor="filtro-testo" className="text-sm font-semibold text-ink">
            Filtra per parola
          </label>
          <input
            id="filtro-testo"
            type="search"
            value={testo}
            onChange={(e) => setTesto(e.target.value)}
            placeholder="es. figli, affitto, disoccupazione"
            maxLength={60}
            className="mt-1.5 w-full rounded-xl border border-line bg-bg px-3.5 py-2.5 text-ink placeholder:text-ink-3 focus:border-brand focus:outline-none"
          />
        </div>
        <fieldset>
          <legend className="text-sm font-semibold text-ink">Categoria</legend>
          <div className="mt-2 flex flex-wrap gap-2">
            <button type="button" aria-pressed={cat === "tutte"} onClick={() => setCat("tutte")} className={chip(cat === "tutte")}>
              Tutte
            </button>
            {categorie.map((c) => (
              <button key={c.slug} type="button" aria-pressed={cat === c.slug} onClick={() => setCat(c.slug)} className={chip(cat === c.slug)}>
                {c.nome}
              </button>
            ))}
          </div>
        </fieldset>
        {stati.length > 1 && (
          <fieldset>
            <legend className="text-sm font-semibold text-ink">Stato</legend>
            <div className="mt-2 flex flex-wrap gap-2">
              <button type="button" aria-pressed={stato === "tutti"} onClick={() => setStato("tutti")} className={chip(stato === "tutti")}>
                Tutti
              </button>
              {stati.map((s) => (
                <button key={s} type="button" aria-pressed={stato === s} onClick={() => setStato(s)} className={chip(stato === s)}>
                  {STATO_LABEL[s]}
                </button>
              ))}
            </div>
          </fieldset>
        )}
      </div>

      <p role="status" className="mt-6 text-sm text-ink-3">
        {filtrati.length} {filtrati.length === 1 ? "bonus trovato" : "bonus trovati"}
      </p>
      {filtrati.length > 0 ? (
        <div className="mt-3">
          <BonusList bonus={filtrati} />
        </div>
      ) : (
        <div className="mt-3 rounded-2xl border border-dashed border-line p-10 text-center text-ink-2">
          Nessun bonus corrisponde ai filtri scelti.{" "}
          <button
            type="button"
            className="font-semibold text-brand underline"
            onClick={() => {
              setCat("tutte");
              setStato("tutti");
              setTesto("");
            }}
          >
            Azzera i filtri
          </button>
        </div>
      )}
    </div>
  );
}
