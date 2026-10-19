import { PageHero } from "./PageHero";
import { formatData } from "@/lib/content-shared";

export function LegalPage({ titolo, href, aggiornata, children }: { titolo: string; href: string; aggiornata: string; children: React.ReactNode }) {
  return (
    <>
      <PageHero crumbs={[{ label: titolo, href }]} titolo={titolo} icona="info">
        <p className="text-sm text-white/75">
          Ultimo aggiornamento: <time dateTime={aggiornata}>{formatData(aggiornata)}</time>
        </p>
      </PageHero>
      <div className="mx-auto max-w-3xl px-4 sm:px-6">
        <div className="prose-sb relative z-10 -mt-8 rounded-3xl border border-line bg-surface p-5 shadow-sm sm:p-8">{children}</div>
      </div>
    </>
  );
}
