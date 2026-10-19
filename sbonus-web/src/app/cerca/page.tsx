import type { Metadata } from "next";
import { Suspense } from "react";
import { Breadcrumbs } from "@/components/Breadcrumbs";
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
    <div className="mx-auto max-w-4xl px-4 pt-6 sm:px-6">
      <Breadcrumbs items={[{ label: "Cerca", href: "/cerca" }]} />
      <h1 className="mt-6 font-display text-3xl font-extrabold tracking-tight text-ink">Cerca su SBonus</h1>
      <Suspense fallback={<p className="mt-6 text-ink-3">Caricamento…</p>}>
        <SearchResults />
      </Suspense>
    </div>
  );
}
