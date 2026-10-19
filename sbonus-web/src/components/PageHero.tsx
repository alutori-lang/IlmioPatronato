import { Breadcrumbs, type Crumb } from "./Breadcrumbs";
import type { AnyIcon } from "./Icon";
import { Wave } from "./Wave";

/** Testata blu delle pagine interne, chiusa dall'onda. */
export function PageHero({
  crumbs,
  titolo,
  intro,
  occhiello,
  children,
}: {
  crumbs: Crumb[];
  titolo: string;
  intro?: string;
  occhiello?: string;
  /** Mantenuti per compatibilità con le pagine che li passano. */
  categoria?: string;
  icona?: AnyIcon;
  children?: React.ReactNode;
}) {
  return (
    <>
      <section className="bg-blu">
        <div className="mx-auto max-w-6xl px-4 pb-8 pt-6 sm:px-6 sm:pb-10">
          <Breadcrumbs items={crumbs} />
          <div className="mt-6 max-w-3xl">
            {occhiello && (
              <p className="inline-block rounded-full bg-white/15 px-3 py-1 text-xs font-extrabold uppercase tracking-wider text-white">{occhiello}</p>
            )}
            <h1 className="mt-3 text-3xl font-black leading-[1.08] tracking-tight text-white text-balance sm:text-5xl">{titolo}</h1>
            {intro && <p className="mt-4 text-lg font-semibold leading-relaxed text-sun-ink">{intro}</p>}
            {children && <div className="mt-5">{children}</div>}
          </div>
        </div>
      </section>
      <Wave />
    </>
  );
}
