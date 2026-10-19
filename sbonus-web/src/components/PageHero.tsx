import { Breadcrumbs, type Crumb } from "./Breadcrumbs";
import { Icon, type AnyIcon } from "./Icon";
import { tonoCategoria } from "@/lib/categories";

/** Intestazione colorata delle pagine interne, tinta con il colore della categoria. */
export function PageHero({
  crumbs,
  titolo,
  intro,
  categoria,
  icona,
  occhiello,
  children,
}: {
  crumbs: Crumb[];
  titolo: string;
  intro?: string;
  categoria?: string;
  icona?: AnyIcon;
  occhiello?: string;
  children?: React.ReactNode;
}) {
  const tono = categoria ? tonoCategoria(categoria) : "#2a62f0";
  return (
    <section
      className="relative overflow-hidden text-white"
      style={{
        background: `radial-gradient(40rem 22rem at 90% 0%, color-mix(in srgb, ${tono} 55%, transparent), transparent 70%), linear-gradient(160deg, #0b1d5c 0%, #142f8f 60%, color-mix(in srgb, ${tono} 45%, #142f8f) 100%)`,
      }}
    >
      <div aria-hidden="true" className="grid-pattern pointer-events-none absolute inset-0" />
      {icona && <Icon name={icona} className="pointer-events-none absolute -right-10 -top-6 h-64 w-64 text-white opacity-[0.07]" />}
      <div className="relative mx-auto max-w-6xl px-4 pb-14 pt-6 sm:px-6 sm:pb-16">
        <Breadcrumbs items={crumbs} chiaro />
        <div className="mt-7 flex items-start gap-4 sm:gap-5">
          {icona && (
            <span
              className="grid h-14 w-14 shrink-0 place-items-center rounded-2xl text-white shadow-lg ring-1 ring-white/25 sm:h-16 sm:w-16"
              style={{ background: `linear-gradient(135deg, ${tono}, color-mix(in srgb, ${tono} 55%, #ffffff))` }}
            >
              <Icon name={icona} className="h-7 w-7 sm:h-8 sm:w-8" />
            </span>
          )}
          <div className="min-w-0 max-w-3xl">
            {occhiello && <p className="text-sm font-bold uppercase tracking-[0.14em] text-[#7df3c4]">{occhiello}</p>}
            <h1 className="mt-1 font-display text-3xl font-extrabold leading-[1.12] tracking-tight sm:text-[2.6rem]">{titolo}</h1>
            {intro && <p className="mt-4 text-lg leading-relaxed text-white/80">{intro}</p>}
            {children && <div className="mt-5">{children}</div>}
          </div>
        </div>
      </div>
    </section>
  );
}
