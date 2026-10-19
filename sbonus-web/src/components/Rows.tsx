import Link from "next/link";
import type { BonusLite, Guida, StatoBonus } from "@/lib/content-shared";
import { STATO_LABEL, formatData } from "@/lib/content-shared";
import type { CalcolatoreMeta } from "@/lib/calcolatori";
import { Icon } from "./Icon";

// Elenchi in stile indice: righe sottili, testo sobrio, un solo colore d'accento.

/** "NASpI 2026: l'indennità di…" → "NASpI 2026" (il resto è già nella descrizione). */
export const titoloBreve = (t: string) => t.split(/:\s/)[0].trim();

const STATO_STYLE: Record<StatoBonus, string> = {
  attivo: "text-accent",
  scaduto: "text-danger",
  "in-attesa": "text-warn",
  "da-verificare": "text-ink-3",
};

export function StatoBadge({ stato }: { stato: StatoBonus }) {
  return (
    <span className={`inline-flex shrink-0 items-center gap-1.5 text-xs font-medium ${STATO_STYLE[stato]}`}>
      <span className="h-1.5 w-1.5 rounded-full bg-current" aria-hidden="true" />
      {STATO_LABEL[stato]}
    </span>
  );
}

function Chevron() {
  return <Icon name="arrow" className="hidden h-4 w-4 shrink-0 text-ink-3 transition group-hover:translate-x-0.5 group-hover:text-brand sm:block" />;
}

const rowCls = "group -mx-3 flex items-center gap-6 rounded-lg px-3 py-4 transition-colors hover:bg-surface-2";

export function BonusRow({ b }: { b: BonusLite }) {
  return (
    <li>
      <Link href={`/bonus/${b.slug}`} className={rowCls}>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
            <span className="font-medium text-ink group-hover:text-brand">{titoloBreve(b.titolo)}</span>
            {b.stato !== "attivo" && <StatoBadge stato={b.stato} />}
          </div>
          <p className="mt-1 line-clamp-2 text-sm leading-relaxed text-ink-3 sm:line-clamp-1">{b.descrizione}</p>
          {b.evidenza && (
            <p className="mt-1.5 text-sm sm:hidden">
              <span className="font-semibold tabular-nums text-ink">{b.evidenza.valore}</span>{" "}
              <span className="text-ink-3">{b.evidenza.etichetta}</span>
            </p>
          )}
        </div>
        {b.evidenza && (
          <div className="hidden w-48 shrink-0 text-right sm:block">
            <p className="font-semibold tabular-nums text-ink">{b.evidenza.valore}</p>
            <p className="text-xs text-ink-3">{b.evidenza.etichetta}</p>
          </div>
        )}
        <Chevron />
      </Link>
    </li>
  );
}

export function BonusList({ bonus }: { bonus: BonusLite[] }) {
  return (
    <ul className="divide-y divide-line border-y border-line">
      {bonus.map((b) => (
        <BonusRow key={b.slug} b={b} />
      ))}
    </ul>
  );
}

export function CalcRow({ c }: { c: CalcolatoreMeta }) {
  return (
    <li>
      <Link href={`/calcolatori/${c.slug}`} className={rowCls}>
        <span className="grid h-10 w-10 shrink-0 place-items-center rounded-lg border border-line text-brand">
          <Icon name={c.icona} className="h-5 w-5" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="font-medium text-ink group-hover:text-brand">{c.titolo}</p>
          <p className="mt-0.5 line-clamp-2 text-sm leading-relaxed text-ink-3">{c.descrizione}</p>
        </div>
        <Chevron />
      </Link>
    </li>
  );
}

export function CalcList({ calcolatori, colonne = false }: { calcolatori: CalcolatoreMeta[]; colonne?: boolean }) {
  return (
    <ul className={`border-t border-line [&>li]:border-b [&>li]:border-line ${colonne ? "grid gap-x-12 md:grid-cols-2" : ""}`}>
      {calcolatori.map((c) => (
        <CalcRow key={c.slug} c={c} />
      ))}
    </ul>
  );
}

export function GuideRow({ g }: { g: Guida }) {
  return (
    <li>
      <Link href={`/guide/${g.slug}`} className={rowCls}>
        <div className="min-w-0 flex-1">
          <p className="font-medium text-ink group-hover:text-brand">{g.titolo}</p>
          <p className="mt-1 line-clamp-1 text-sm text-ink-3">{g.descrizione}</p>
        </div>
        <time dateTime={g.dataAggiornamento ?? undefined} className="hidden shrink-0 text-sm tabular-nums text-ink-3 sm:block">
          {formatData(g.dataAggiornamento)}
        </time>
        <Chevron />
      </Link>
    </li>
  );
}

export function GuideList({ guide }: { guide: Guida[] }) {
  return (
    <ul className="divide-y divide-line border-y border-line">
      {guide.map((g) => (
        <GuideRow key={g.slug} g={g} />
      ))}
    </ul>
  );
}

export function SectionTitle({ titolo, sottotitolo, href, cta, id }: { titolo: string; sottotitolo?: string; href?: string; cta?: string; id?: string }) {
  return (
    <div className="mb-6 flex items-end justify-between gap-6">
      <div>
        <h2 id={id} className="text-2xl font-semibold tracking-tight text-ink">
          {titolo}
        </h2>
        {sottotitolo && <p className="mt-1.5 text-ink-2">{sottotitolo}</p>}
      </div>
      {href && (
        <Link href={href} className="inline-flex shrink-0 items-center gap-1 text-sm font-medium text-brand hover:underline">
          {cta ?? "Vedi tutti"} <Icon name="arrow" className="h-3.5 w-3.5" />
        </Link>
      )}
    </div>
  );
}
