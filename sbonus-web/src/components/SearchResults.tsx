"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { cerca, type Documento, type TipoRisultato } from "@/lib/search";
import { SearchBox, TIPO_LABEL, caricaIndice } from "./SearchBox";

const FILTRI: (TipoRisultato | "tutti")[] = ["tutti", "bonus", "guida", "calcolatore", "faq", "categoria"];

const SUGGERIMENTI = [
  { label: "Assegno Unico", href: "/cerca?q=assegno+unico" },
  { label: "NASpI", href: "/cerca?q=naspi" },
  { label: "ISEE", href: "/cerca?q=isee" },
  { label: "Bonus bollette", href: "/cerca?q=bollette" },
];

export function SearchResults() {
  const q = useSearchParams().get("q")?.slice(0, 100) ?? "";
  const [indice, setIndice] = useState<Documento[] | null>(null);
  // Il filtro vale per la ricerca corrente: con una nuova query torna a «Tutti».
  const [scelta, setScelta] = useState<{ q: string; f: TipoRisultato | "tutti" }>({ q, f: "tutti" });
  const filtro = scelta.q === q ? scelta.f : "tutti";
  const setFiltro = (f: TipoRisultato | "tutti") => setScelta({ q, f });

  useEffect(() => {
    caricaIndice().then(setIndice);
  }, []);

  const risultati = indice && q ? cerca(indice, q, 100) : [];
  const visibili = filtro === "tutti" ? risultati : risultati.filter((r) => r.tipo === filtro);
  const conteggi = Object.fromEntries(FILTRI.map((f) => [f, f === "tutti" ? risultati.length : risultati.filter((r) => r.tipo === f).length]));

  return (
    <div className="mt-6">
      <SearchBox key={q} defaultValue={q} size="lg" />

      {!q && <p className="mt-8 text-ink-2">Scrivi cosa stai cercando: un bonus, una prestazione, una parola chiave.</p>}
      {q && indice === null && <p className="mt-8 text-ink-3">Ricerca in corso…</p>}

      {q && indice !== null && (
        <>
          <p role="status" className="mt-8 text-ink-2">
            {risultati.length === 0 ? (
              <>
                Nessun risultato per <strong className="text-ink">«{q}»</strong>.
              </>
            ) : (
              <>
                {risultati.length} {risultati.length === 1 ? "risultato" : "risultati"} per <strong className="text-ink">«{q}»</strong>
              </>
            )}
          </p>

          {risultati.length > 0 && (
            <div role="group" aria-label="Filtra per tipo" className="mt-4 flex flex-wrap gap-2">
              {FILTRI.filter((f) => conteggi[f] > 0).map((f) => (
                <button
                  key={f}
                  type="button"
                  aria-pressed={filtro === f}
                  onClick={() => setFiltro(f)}
                  className={`rounded-full border px-3.5 py-1.5 text-sm font-medium ${filtro === f ? "border-brand bg-brand text-brand-ink" : "border-line bg-surface text-ink-2 hover:text-brand"}`}
                >
                  {f === "tutti" ? "Tutti" : TIPO_LABEL[f]} ({conteggi[f]})
                </button>
              ))}
            </div>
          )}

          {risultati.length === 0 ? (
            <div className="mt-6 rounded-2xl border border-dashed border-line p-6">
              <p className="font-semibold text-ink">Qualche suggerimento:</p>
              <ul className="mt-2 list-disc space-y-1 pl-5 text-ink-2">
                <li>controlla l&apos;ortografia o usa meno parole;</li>
                <li>prova un termine più generale (es. «figli» invece di «terzo figlio»);</li>
                <li>
                  sfoglia l&apos;<Link href="/bonus" className="text-brand underline">elenco completo dei bonus</Link> o i{" "}
                  <Link href="/calcolatori" className="text-brand underline">calcolatori</Link>.
                </li>
              </ul>
              <p className="mt-4 text-sm text-ink-3">Ricerche frequenti:</p>
              <div className="mt-2 flex flex-wrap gap-2">
                {SUGGERIMENTI.map((s) => (
                  <Link key={s.href} href={s.href} className="rounded-full border border-line bg-surface px-3 py-1.5 text-sm text-ink-2 hover:text-brand">
                    {s.label}
                  </Link>
                ))}
              </div>
            </div>
          ) : (
            <ol className="mt-6 space-y-3">
              {visibili.map((r) => (
                <li key={r.url}>
                  <Link href={r.url} className="block rounded-2xl border border-line bg-surface p-4 transition hover:border-brand/40 hover:shadow-md">
                    <span className="text-xs font-semibold uppercase tracking-wide text-brand">{TIPO_LABEL[r.tipo]}</span>
                    <span className="mt-1 block font-semibold text-ink">{r.titolo}</span>
                    <span className="mt-1 line-clamp-2 text-sm text-ink-2">{r.sommario}</span>
                  </Link>
                </li>
              ))}
            </ol>
          )}
        </>
      )}
    </div>
  );
}
