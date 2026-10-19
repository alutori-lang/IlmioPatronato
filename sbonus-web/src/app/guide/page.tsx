import type { Metadata } from "next";
import Link from "next/link";
import { PageHero } from "@/components/PageHero";
import { GuideCard } from "@/components/Cards";
import { guidePubblicate } from "@/lib/content";
import { CATEGORIE } from "@/lib/categories";

export const metadata: Metadata = {
  title: "Guide su bonus, INPS, ISEE e fisco",
  description: "Guide pratiche e aggiornate su ISEE, NASpI, Assegno Unico, IRPEF, servizi INPS online e bonus casa, con fonti ufficiali.",
  alternates: { canonical: "/guide" },
};

export default function GuideIndex() {
  const categorie = CATEGORIE.filter((c) => guidePubblicate.some((g) => g.categoria === c.slug));
  return (
    <>
      <PageHero
        crumbs={[{ label: "Guide", href: "/guide" }]}
        occhiello="Approfondimenti"
        titolo="Guide e approfondimenti"
        intro="Spiegazioni chiare su bonus, prestazioni e imposte, scritte partendo dalle fonti ufficiali. Ogni guida riporta la data di pubblicazione e dell'ultimo aggiornamento."
        icona="book"
      />
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
      <nav aria-label="Categorie delle guide" className="mt-6 flex flex-wrap gap-2">
        {categorie.map((c) => (
          <Link key={c.slug} href={`/categorie/${c.slug}`} className="rounded-full border border-line bg-surface px-3.5 py-2 text-sm font-medium text-ink-2 hover:border-brand/40 hover:text-brand">
            {c.nome}
          </Link>
        ))}
      </nav>
      <div className="mt-8 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {guidePubblicate.map((g) => (
          <GuideCard key={g.slug} g={g} />
        ))}
      </div>
      </div>
    </>
  );
}
