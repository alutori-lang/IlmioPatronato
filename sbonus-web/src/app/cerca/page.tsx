import type { Metadata } from "next";
import { Suspense } from "react";
import { PageHero } from "@/components/PageHero";
import { SearchResults } from "@/components/SearchResults";

export const metadata: Metadata = {
  title: "Cerca",
  description: "Cerca tra bonus, guide, calcolatori e domande frequenti di SBonus.",
  alternates: { canonical: "/cerca" },
  // Le pagine di risultati non vanno indicizzate
  robots: { index: false, follow: true },
};

export default function CercaPage() {
  return (
    <>
      <PageHero crumbs={[{ label: "Cerca", href: "/cerca" }]} titolo="Cerca su SBonus" intro="Bonus, guide, calcolatori e domande frequenti." icona="search" />
      <div className="mx-auto max-w-4xl px-4 sm:px-6">
      <Suspense fallback={<p className="mt-6 text-ink-3">Caricamento…</p>}>
        <SearchResults />
      </Suspense>
      </div>
    </>
  );
}
