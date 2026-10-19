import Link from "next/link";
import type { BonusLite, Guida, StatoBonus } from "@/lib/content-shared";
import { STATO_LABEL, formatData } from "@/lib/content-shared";
import { getCategoria, stileTono, type Categoria } from "@/lib/categories";
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
    <span className={`inline-flex shrink-0 items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold ${STATO_STYLE[stato]}`}>
      <span className={`h-1.5 w-1.5 rounded-full bg-current ${stato === "attivo" ? "animate-pulse" : ""}`} aria-hidden="true" />
      {STATO_LABEL[stato]}
    </span>
  );
}

function Freccia() {
  return (
    <span
      aria-hidden="true"
      className="grid h-9 w-9 shrink-0 place-items-center rounded-full border border-line text-ink-2 transition group-hover:border-transparent group-hover:bg-[var(--tone,var(--brand))] group-hover:text-white"
    >
      <Icon name="arrow" className="h-4 w-4 transition group-hover:translate-x-0.5" />
    </span>
  );
}

const cardBase =
  "group relative flex h-full flex-col overflow-hidden rounded-3xl border border-line bg-surface shadow-[0_1px_3px_rgba(15,27,51,0.06)] transition duration-300 hover:-translate-y-1 hover:shadow-[0_18px_40px_-16px_rgba(15,27,51,0.28)]";

export function BonusCard({ b }: { b: BonusLite }) {
  const cat = getCategoria(b.categoria);
  return (
    <article className={cardBase} style={stileTono(b.categoria)}>
      <div className="tone-bar h-1.5" aria-hidden="true" />
      <div className="flex flex-1 flex-col p-5">
        <div className="flex items-start justify-between gap-3">
          <span className="tone-icon grid h-12 w-12 shrink-0 place-items-center rounded-2xl">
            <Icon name={cat?.icona ?? "euro"} className="h-6 w-6" />
          </span>
          <StatoBadge stato={b.stato} />
        </div>
        <p className="mt-4 text-xs font-bold uppercase tracking-wider text-ink-3">{cat?.nome ?? b.categoria}</p>
        <h3 className="mt-1 font-display text-[1.1rem] font-bold leading-snug text-ink">
          <Link href={`/bonus/${b.slug}`} className="after:absolute after:inset-0 after:rounded-3xl focus-visible:outline-none">
            {b.titolo}
          </Link>
        </h3>
        {b.evidenza && (
          <div className="tone-soft mt-4 rounded-2xl px-4 py-3">
            <p className="font-display text-2xl font-extrabold leading-none tracking-tight text-ink">{b.evidenza.valore}</p>
            <p className="mt-1 text-sm text-ink-2">{b.evidenza.etichetta}</p>
          </div>
        )}
        <p className="mt-3 line-clamp-2 text-[0.93rem] leading-relaxed text-ink-2">{b.descrizione}</p>
        <div className="mt-auto flex items-center justify-between gap-3 pt-5">
          <span className="min-w-0 truncate text-sm font-medium text-ink-3">{b.ente}</span>
          <Freccia />
        </div>
      </div>
    </article>
  );
}

export function CalcCard({ c, scuro = false }: { c: CalcolatoreMeta; scuro?: boolean }) {
  if (scuro) {
    return (
      <article
        className="group relative flex h-full flex-col rounded-3xl border border-white/10 bg-white/[0.06] p-5 backdrop-blur transition duration-300 hover:-translate-y-1 hover:bg-white/[0.1]"
        style={stileTono(c.categoria)}
      >
        <span className="tone-icon grid h-12 w-12 place-items-center rounded-2xl">
          <Icon name={c.icona} className="h-6 w-6" />
        </span>
        <h3 className="mt-4 font-display text-lg font-bold text-white">
          <Link href={`/calcolatori/${c.slug}`} className="after:absolute after:inset-0 after:rounded-3xl focus-visible:outline-none">
            {c.titolo}
          </Link>
        </h3>
        <p className="mt-2 text-[0.93rem] leading-relaxed text-white/70">{c.descrizione}</p>
        <span className="mt-auto inline-flex items-center gap-1.5 pt-5 text-sm font-semibold text-[#7df3c4]">
          Calcola ora <Icon name="arrow" className="h-4 w-4 transition group-hover:translate-x-1" />
        </span>
      </article>
    );
  }
  return (
    <article className={cardBase} style={stileTono(c.categoria)}>
      <div className="flex flex-1 flex-col p-5">
        <span className="tone-icon grid h-12 w-12 place-items-center rounded-2xl">
          <Icon name={c.icona} className="h-6 w-6" />
        </span>
        <h3 className="mt-4 font-display text-lg font-bold text-ink">
          <Link href={`/calcolatori/${c.slug}`} className="after:absolute after:inset-0 after:rounded-3xl focus-visible:outline-none">
            {c.titolo}
          </Link>
        </h3>
        <p className="mt-2 text-[0.93rem] leading-relaxed text-ink-2">{c.descrizione}</p>
        <div className="mt-auto flex items-center justify-between pt-5">
          <span className="text-sm font-semibold text-ink">Calcola ora</span>
          <Freccia />
        </div>
      </div>
    </article>
  );
}

export function GuideCard({ g, grande = false }: { g: Guida; grande?: boolean }) {
  const cat = getCategoria(g.categoria);
  return (
    <article className={cardBase} style={stileTono(g.categoria)}>
      <div className={`tone-soft relative flex items-end overflow-hidden px-5 ${grande ? "min-h-40 flex-1 sm:min-h-52" : "h-28"}`}>
        <Icon name={cat?.icona ?? "book"} className={`tone-text absolute opacity-20 ${grande ? "-right-6 top-1/2 h-64 w-64 -translate-y-1/2" : "-right-4 -top-4 h-32 w-32"}`} />
        <span className="tone-icon mb-4 inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold uppercase tracking-wide">
          <Icon name="book" className="h-3.5 w-3.5" />
          {cat?.nome ?? "Guida"}
        </span>
      </div>
      <div className={`flex flex-col p-5 ${grande ? "sm:p-7" : "flex-1"}`}>
        <h3 className={`font-display font-bold leading-snug text-ink ${grande ? "text-2xl sm:text-[1.7rem]" : "text-lg"}`}>
          <Link href={`/guide/${g.slug}`} className="after:absolute after:inset-0 after:rounded-3xl focus-visible:outline-none">
            {g.titolo}
          </Link>
        </h3>
        <p className={`mt-2 text-[0.93rem] leading-relaxed text-ink-2 ${grande ? "line-clamp-3" : "line-clamp-2"}`}>{g.descrizione}</p>
        <div className="mt-auto flex items-center justify-between gap-3 pt-5">
          <span className="inline-flex items-center gap-1.5 text-sm text-ink-3">
            <Icon name="calendar" className="h-4 w-4" />
            <time dateTime={g.dataAggiornamento ?? undefined}>{formatData(g.dataAggiornamento)}</time>
          </span>
          <Freccia />
        </div>
      </div>
    </article>
  );
}

export function CategoriaCard({ c, conteggio }: { c: Categoria; conteggio: number }) {
  return (
    <Link
      href={`/categorie/${c.slug}`}
      style={stileTono(c.slug)}
      className="group flex items-center gap-4 rounded-3xl border border-line bg-surface p-4 transition duration-300 hover:-translate-y-0.5 hover:shadow-lg"
    >
      <span className="tone-icon grid h-14 w-14 shrink-0 place-items-center rounded-2xl">
        <Icon name={c.icona} className="h-7 w-7" />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block font-display font-bold text-ink">{c.nome}</span>
        <span className="block text-sm text-ink-3">
          {conteggio} {conteggio === 1 ? "contenuto" : "contenuti"}
        </span>
      </span>
      <Freccia />
    </Link>
  );
}

export function SectionHeading({
  titolo,
  sottotitolo,
  href,
  cta,
  occhiello,
  chiaro = false,
}: {
  titolo: string;
  sottotitolo?: string;
  href?: string;
  cta?: string;
  occhiello?: string;
  chiaro?: boolean;
}) {
  return (
    <div className="mb-8 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
      <div className="max-w-2xl">
        {occhiello && (
          <p className={`mb-2 text-sm font-bold uppercase tracking-[0.14em] ${chiaro ? "text-[#7df3c4]" : "text-brand"}`}>{occhiello}</p>
        )}
        <h2 className={`font-display text-3xl font-extrabold tracking-tight sm:text-[2.1rem] ${chiaro ? "text-white" : "text-ink"}`}>{titolo}</h2>
        {sottotitolo && <p className={`mt-2 text-lg ${chiaro ? "text-white/70" : "text-ink-2"}`}>{sottotitolo}</p>}
      </div>
      {href && (
        <Link
          href={href}
          className={`inline-flex shrink-0 items-center gap-1.5 self-start rounded-full px-4 py-2 text-sm font-semibold transition sm:self-auto ${
            chiaro ? "bg-white/10 text-white hover:bg-white/20" : "bg-brand-soft text-brand hover:bg-brand hover:text-brand-ink"
          }`}
        >
          {cta ?? "Vedi tutti"} <Icon name="arrow" className="h-4 w-4" />
        </Link>
      )}
    </div>
  );
}
