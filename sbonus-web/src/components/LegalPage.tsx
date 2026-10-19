import { PageHero } from "./PageHero";
import { formatData } from "@/lib/content-shared";

export function LegalPage({ titolo, href, aggiornata, children }: { titolo: string; href: string; aggiornata: string; children: React.ReactNode }) {
  return (
    <>
      <PageHero crumbs={[{ label: titolo, href }]} titolo={titolo} icona="info">
        <p className="text-sm text-ink-3">
          Ultimo aggiornamento: <time dateTime={aggiornata}>{formatData(aggiornata)}</time>
        </p>
      </PageHero>
      <div className="mx-auto max-w-3xl px-4 sm:px-6">
        <div className="prose-sb mt-10">{children}</div>
      </div>
    </>
  );
}
