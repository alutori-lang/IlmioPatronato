import Link from "next/link";
import type { BonusLite, Guida, StatoBonus } from "@/lib/content-shared";
import { STATO_LABEL, formatData, formatNovita, isNuovo } from "@/lib/content-shared";
import { getCategoria, stileTono } from "@/lib/categories";
import type { CalcolatoreMeta } from "@/lib/calcolatori";
import { Icon } from "./Icon";

// Componenti dei contenuti in stile "Sole": card tonde, bolle colorate, cifre grandi.

/** "NASpI 2026: l'indennità di…" → "NASpI 2026" (il resto è già nella descrizione). */
export const titoloBreve = (t: string) => t.split(/:\s/)[0].trim();

const STATO_STYLE: Record<StatoBonus, string> = {
  attivo: "bg-accent-soft text-accent",
  scaduto: "bg-danger-soft text-danger",
  "in-attesa": "bg-warn-soft text-warn",
  "da-verificare": "bg-surface-2 text-ink-3",
};

export function StatoBadge({ stato }: { stato: StatoBonus }) {
  return (
    <span className={`inline-flex shrink-0 items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-extrabold ${STATO_STYLE[stato]}`}>
      <span className="h-1.5 w-1.5 rounded-full bg-current" aria-hidden="true" />
      {STATO_LABEL[stato]}
    </span>
  );
}

export function NuovoBadge() {
  return <span className="inline-flex shrink-0 items-center rounded-full bg-coral px-2.5 py-0.5 text-xs font-black uppercase tracking-wide text-white">Nuovo</span>;
}

/** Bolla colorata con l'icona della categoria. */
export function Bolla({ categoria, size = "md" }: { categoria: string; size?: "md" | "lg" }) {
  const cat = getCategoria(categoria);
  const s = size === "lg" ? "h-[72px] w-[72px] [&_svg]:h-8 [&_svg]:w-8" : "h-12 w-12 [&_svg]:h-6 [&_svg]:w-6";
  return (
    <span style={stileTono(categoria)} className={`grid shrink-0 place-items-center rounded-full bg-[var(--tone)] text-white ${s}`}>
      <Icon name={cat?.icona ?? "euro"} />
    </span>
  );
}

/** Card bianca di un bonus (elenchi). */
export function BonusCard({ b }: { b: BonusLite }) {
  const cat = getCategoria(b.categoria);
  return (
    <li className="h-full">
      <Link
        href={`/bonus/${b.slug}`}
        style={stileTono(b.categoria)}
        className="group flex h-full flex-col rounded-[28px] border-2 border-line bg-white p-5 transition hover:-translate-y-0.5 hover:border-[var(--tone)]"
      >
        <div className="flex items-start justify-between gap-3">
          <Bolla categoria={b.categoria} />
          <div className="flex flex-wrap justify-end gap-1.5">
            {b.novita && isNuovo(b.novita.data) && <NuovoBadge />}
            {b.stato !== "attivo" && <StatoBadge stato={b.stato} />}
          </div>
        </div>
        <p className="mt-4 text-xs font-extrabold uppercase tracking-wider text-[var(--tone)]">{cat?.nome ?? b.categoria}</p>
        <h3 className="mt-1 text-lg font-black leading-snug text-ink">{titoloBreve(b.titolo)}</h3>
        <p className="mt-1.5 line-clamp-2 text-[0.95rem] font-semibold leading-relaxed text-ink-3">{b.descrizione}</p>
        {b.evidenza && (
          <p className="mt-auto pt-4">
            <span className="block text-2xl font-black tracking-tight text-ink tabular-nums">{b.evidenza.valore}</span>
            <span className="text-sm font-bold text-ink-3">{b.evidenza.etichetta}</span>
          </p>
        )}
      </Link>
    </li>
  );
}

/** Card a colore pieno per i bonus in primo piano. */
export function BonusFeature({ b }: { b: BonusLite }) {
  const cat = getCategoria(b.categoria);
  return (
    <Link
      href={`/bonus/${b.slug}`}
      style={stileTono(b.categoria)}
      className="group relative flex min-h-[220px] flex-col overflow-hidden rounded-[28px] bg-[var(--tone)] p-6 text-white transition hover:-translate-y-1"
    >
      <span aria-hidden="true" className="absolute -right-10 -top-10 h-40 w-40 rounded-full bg-white/15 transition group-hover:scale-110" />
      <span className="relative text-sm font-extrabold opacity-90">{cat?.nome}</span>
      <h3 className="relative mt-1 text-[1.4rem] font-black leading-tight">{titoloBreve(b.titolo)}</h3>
      {b.evidenza && (
        <p className="relative mt-auto pt-6">
          <span className="block text-4xl font-black tracking-tight tabular-nums">{b.evidenza.valore}</span>
          <span className="text-[0.95rem] font-extrabold opacity-90">{b.evidenza.etichetta}</span>
        </p>
      )}
    </Link>
  );
}

export function BonusList({ bonus }: { bonus: BonusLite[] }) {
  return (
    <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {bonus.map((b) => (
        <BonusCard key={b.slug} b={b} />
      ))}
    </ul>
  );
}

export function CalcList({ calcolatori }: { calcolatori: CalcolatoreMeta[]; colonne?: boolean }) {
  return (
    <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {calcolatori.map((c) => (
        <li key={c.slug}>
          <Link
            href={`/calcolatori/${c.slug}`}
            style={stileTono(c.categoria)}
            className="group flex h-full items-start gap-4 rounded-[28px] border-2 border-line bg-white p-5 transition hover:-translate-y-0.5 hover:border-ink"
          >
            <span className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-[var(--tone-soft)] text-[var(--tone)]">
              <Icon name={c.icona} className="h-6 w-6" />
            </span>
            <span className="min-w-0">
              <span className="block font-black text-ink">{c.titolo}</span>
              <span className="mt-1 block text-sm font-semibold leading-relaxed text-ink-3">{c.descrizione}</span>
            </span>
          </Link>
        </li>
      ))}
    </ul>
  );
}

export function GuideList({ guide }: { guide: Guida[] }) {
  return (
    <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {guide.map((g) => {
        const cat = getCategoria(g.categoria);
        return (
          <li key={g.slug}>
            <Link
              href={`/guide/${g.slug}`}
              style={stileTono(g.categoria)}
              className="group flex h-full flex-col rounded-[28px] bg-surface-2 p-6 transition hover:-translate-y-0.5 hover:bg-[var(--tone-soft)]"
            >
              <span className="self-start rounded-full bg-[var(--tone)] px-3 py-1 text-xs font-extrabold text-white">{cat?.nome ?? "Guida"}</span>
              <span className="mt-4 block text-lg font-black leading-snug text-ink">{g.titolo}</span>
              <span className="mt-2 line-clamp-2 block text-sm font-semibold leading-relaxed text-ink-3">{g.descrizione}</span>
              <span className="mt-auto flex items-center justify-between pt-5 text-sm font-bold text-ink-3">
                <time dateTime={g.dataAggiornamento ?? undefined}>{formatData(g.dataAggiornamento)}</time>
                <span className="grid h-9 w-9 place-items-center rounded-full bg-white text-ink transition group-hover:bg-ink group-hover:text-sun">
                  <Icon name="arrow" className="h-4 w-4" />
                </span>
              </span>
            </Link>
          </li>
        );
      })}
    </ul>
  );
}

/** Titolo di sezione: la parola chiave tra [quadre] viene evidenziata in giallo. */
export function SectionTitle({ titolo, sottotitolo, href, cta, id }: { titolo: string; sottotitolo?: string; href?: string; cta?: string; id?: string }) {
  const parti = titolo.split(/\[(.+?)\]/);
  return (
    <div className="mb-7 flex flex-wrap items-end justify-between gap-4">
      <div className="min-w-0">
        <h2 id={id} className="text-3xl font-black tracking-tight text-ink text-balance sm:text-[2.4rem]">
          {parti.map((p, i) => (i % 2 ? <mark key={i} className="hl text-ink">{p}</mark> : p))}
        </h2>
        {sottotitolo && <p className="mt-2 text-lg font-semibold text-ink-3">{sottotitolo}</p>}
      </div>
      {href && (
        <Link href={href} className="inline-flex shrink-0 items-center gap-1.5 rounded-full border-2 border-ink px-4 py-2 text-sm font-black text-ink transition hover:bg-ink hover:text-sun">
          {cta ?? "Vedi tutti"} <Icon name="arrow" className="h-4 w-4" />
        </Link>
      )}
    </div>
  );
}

export { formatNovita };
