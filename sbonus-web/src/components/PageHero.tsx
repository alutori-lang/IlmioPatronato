import { Breadcrumbs, type Crumb } from "./Breadcrumbs";
import type { AnyIcon } from "./Icon";

/** Intestazione sobria delle pagine interne: percorso, titolo, introduzione. */
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
  /** Mantenuti per compatibilità: lo stile essenziale non usa icone né colori di categoria. */
  categoria?: string;
  icona?: AnyIcon;
  children?: React.ReactNode;
}) {
  return (
    <section className="border-b border-line">
      <div className="mx-auto max-w-6xl px-4 pb-10 pt-8 sm:px-6 sm:pb-12">
        <Breadcrumbs items={crumbs} />
        <div className="mt-8 max-w-3xl">
          {occhiello && <p className="text-sm font-medium text-brand">{occhiello}</p>}
          <h1 className="mt-2 text-3xl font-semibold leading-tight tracking-tight text-ink sm:text-4xl">{titolo}</h1>
          {intro && <p className="mt-4 text-lg leading-relaxed text-ink-2">{intro}</p>}
          {children && <div className="mt-5">{children}</div>}
        </div>
      </div>
    </section>
  );
}
