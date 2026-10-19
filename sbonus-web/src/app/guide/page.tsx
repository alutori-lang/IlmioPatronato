import type { Metadata } from "next";
import Link from "next/link";
import { Breadcrumbs } from "@/components/Breadcrumbs";
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
    <div className="mx-auto max-w-6xl px-4 pt-6 sm:px-6">
      <Breadcrumbs items={[{ label: "Guide", href: "/guide" }]} />
      <header className="mt-6 max-w-3xl">
        <h1 className="font-display text-3xl font-extrabold tracking-tight text-ink sm:text-4xl">Guide e approfondimenti</h1>
        <p className="mt-3 text-lg text-ink-2">
          Spiegazioni chiare su come funzionano bonus, prestazioni e imposte, scritte dalla redazione di SBonus partendo dalle fonti
          ufficiali. Ogni guida riporta la data di pubblicazione e dell&apos;ultimo aggiornamento.
        </p>
      </header>
      <nav aria-label="Categorie delle guide" className="mt-6 flex flex-wrap gap-2">
        {categorie.map((c) => (
          <Link key={c.slug} href={`/categorie/${c.slug}`} className="rounded-full border border-line bg-surface px-3.5 py-2 text-sm font-medium text-ink-2 hover:border-brand/40 hover:text-brand">
            {c.nome}
          </Link>
        ))}
      </nav>
      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {guidePubblicate.map((g) => (
          <GuideCard key={g.slug} g={g} />
        ))}
      </div>
    </div>
  );
}
