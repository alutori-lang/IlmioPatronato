import type { Metadata } from "next";
import Link from "next/link";
import { PageHero } from "@/components/PageHero";
import { GuideList } from "@/components/Rows";
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
      <nav aria-label="Categorie delle guide" className="mt-4 flex flex-wrap gap-2">
        {categorie.map((c) => (
          <Link key={c.slug} href={`/categorie/${c.slug}`} className="rounded-full border-2 border-line bg-white px-4 py-1.5 text-sm font-extrabold text-ink transition-colors hover:border-ink">
            {c.nome}
          </Link>
        ))}
      </nav>
      <div className="mt-8">
        <GuideList guide={guidePubblicate} />
      </div>
      </div>
    </>
  );
}
