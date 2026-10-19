import { Breadcrumbs } from "./Breadcrumbs";
import { formatData } from "@/lib/content-shared";

export function LegalPage({ titolo, href, aggiornata, children }: { titolo: string; href: string; aggiornata: string; children: React.ReactNode }) {
  return (
    <div className="mx-auto max-w-3xl px-4 pt-6 sm:px-6">
      <Breadcrumbs items={[{ label: titolo, href }]} />
      <h1 className="mt-6 font-display text-3xl font-extrabold tracking-tight text-ink sm:text-4xl">{titolo}</h1>
      <p className="mt-2 text-sm text-ink-3">
        Ultimo aggiornamento: <time dateTime={aggiornata}>{formatData(aggiornata)}</time>
      </p>
      <div className="prose-sb mt-8">{children}</div>
    </div>
  );
}
