import Link from "next/link";
import type { BonusLite, Guida, StatoBonus } from "@/lib/content-shared";
import { STATO_LABEL, formatData } from "@/lib/content-shared";
import { getCategoria, type Categoria } from "@/lib/categories";
import type { CalcolatoreMeta } from "@/lib/calcolatori";
import { Icon } from "./Icon";

const STATO_STYLE: Record<StatoBonus, string> = {
  attivo: "bg-accent-soft text-accent",
  scaduto: "bg-danger-soft text-danger",
  "in-attesa": "bg-warn-soft text-warn",
  "da-verificare": "bg-surface-2 text-ink-3",
};

export function StatoBadge({ stato }: { stato: StatoBonus }) {
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold ${STATO_STYLE[stato]}`}>
      <span className="h-1.5 w-1.5 rounded-full bg-current" aria-hidden="true" />
      {STATO_LABEL[stato]}
    </span>
  );
}

const card =
  "group relative flex h-full flex-col rounded-2xl border border-line bg-surface p-5 shadow-[0_1px_2px_rgba(15,27,51,0.04)] transition hover:-translate-y-0.5 hover:border-brand/40 hover:shadow-lg";

export function BonusCard({ b }: { b: BonusLite }) {
  const cat = getCategoria(b.categoria);
  return (
    <article className={card}>
      <div className="flex items-center justify-between gap-2">
        <span className="text-xs font-semibold uppercase tracking-wide text-ink-3">{cat?.nome ?? b.categoria}</span>
        <StatoBadge stato={b.stato} />
      </div>
      <h3 className="mt-3 font-display text-lg font-bold leading-snug text-ink">
        <Link href={`/bonus/${b.slug}`} className="after:absolute after:inset-0 after:rounded-2xl">
          {b.titolo}
        </Link>
      </h3>
      <p className="mt-2 line-clamp-3 text-[0.95rem] leading-relaxed text-ink-2">{b.descrizione}</p>
      <div className="mt-auto flex items-center justify-between pt-4 text-sm">
        <span className="text-ink-3">{b.ente}</span>
        <span className="inline-flex items-center gap-1 font-semibold text-brand">
          Scopri <Icon name="arrow" className="h-4 w-4 transition group-hover:translate-x-0.5" />
        </span>
      </div>
    </article>
  );
}

export function CalcCard({ c }: { c: CalcolatoreMeta }) {
  return (
    <article className={card}>
      <span className="grid h-11 w-11 place-items-center rounded-xl bg-accent-soft text-accent">
        <Icon name={c.icona} className="h-6 w-6" />
      </span>
      <h3 className="mt-4 font-display text-lg font-bold text-ink">
        <Link href={`/calcolatori/${c.slug}`} className="after:absolute after:inset-0 after:rounded-2xl">
          {c.titolo}
        </Link>
      </h3>
      <p className="mt-2 text-[0.95rem] leading-relaxed text-ink-2">{c.descrizione}</p>
      <span className="mt-auto inline-flex items-center gap-1 pt-4 text-sm font-semibold text-brand">
        Calcola ora <Icon name="arrow" className="h-4 w-4 transition group-hover:translate-x-0.5" />
      </span>
    </article>
  );
}

export function GuideCard({ g }: { g: Guida }) {
  const cat = getCategoria(g.categoria);
  return (
    <article className={card}>
      <span className="text-xs font-semibold uppercase tracking-wide text-brand">{cat?.nome ?? g.categoria}</span>
      <h3 className="mt-2 font-display text-lg font-bold leading-snug text-ink">
        <Link href={`/guide/${g.slug}`} className="after:absolute after:inset-0 after:rounded-2xl">
          {g.titolo}
        </Link>
      </h3>
      <p className="mt-2 line-clamp-3 text-[0.95rem] leading-relaxed text-ink-2">{g.descrizione}</p>
      <p className="mt-auto pt-4 text-sm text-ink-3">
        Aggiornata il <time dateTime={g.dataAggiornamento ?? undefined}>{formatData(g.dataAggiornamento)}</time>
      </p>
    </article>
  );
}

export function CategoriaCard({ c, conteggio }: { c: Categoria; conteggio: number }) {
  return (
    <Link
      href={`/categorie/${c.slug}`}
      className="group flex items-center gap-4 rounded-2xl border border-line bg-surface p-4 transition hover:border-brand/40 hover:shadow-md"
    >
      <span className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-brand-soft text-brand">
        <Icon name={c.icona} className="h-6 w-6" />
      </span>
      <span className="min-w-0">
        <span className="block font-semibold text-ink group-hover:text-brand">{c.nome}</span>
        <span className="block text-sm text-ink-3">
          {conteggio} {conteggio === 1 ? "contenuto" : "contenuti"}
        </span>
      </span>
    </Link>
  );
}

export function SectionHeading({ titolo, sottotitolo, href, cta }: { titolo: string; sottotitolo?: string; href?: string; cta?: string }) {
  return (
    <div className="mb-6 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <h2 className="font-display text-2xl font-extrabold tracking-tight text-ink sm:text-3xl">{titolo}</h2>
        {sottotitolo && <p className="mt-1.5 max-w-2xl text-ink-2">{sottotitolo}</p>}
      </div>
      {href && (
        <Link href={href} className="inline-flex shrink-0 items-center gap-1 font-semibold text-brand hover:underline">
          {cta ?? "Vedi tutti"} <Icon name="arrow" className="h-4 w-4" />
        </Link>
      )}
    </div>
  );
}
