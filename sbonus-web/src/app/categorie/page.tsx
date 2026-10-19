import type { Metadata } from "next";
import { PageHero } from "@/components/PageHero";
import { CategoriaCard } from "@/components/Cards";
import { CATEGORIE } from "@/lib/categories";
import { bonusPerCategoria, guidePerCategoria } from "@/lib/content";

export const metadata: Metadata = {
  title: "Categorie: famiglia, lavoro, casa, ISEE, pensioni",
  description: "Esplora bonus, guide e agevolazioni per categoria: famiglia, lavoro e disoccupazione, casa, sostegno al reddito, pensioni, ISEE, fisco e INPS.",
  alternates: { canonical: "/categorie" },
};

const categorieAttive = () =>
  CATEGORIE.map((c) => ({ c, n: bonusPerCategoria(c.slug).length + guidePerCategoria(c.slug).length })).filter((x) => x.n > 0);

export default function CategorieIndex() {
  return (
    <>
      <PageHero crumbs={[{ label: "Categorie", href: "/categorie" }]} occhiello="Esplora" titolo="Categorie" intro="Trova bonus e guide raggruppati per argomento." icona="search" />
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
      <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {categorieAttive().map(({ c, n }) => (
          <CategoriaCard key={c.slug} c={c} conteggio={n} />
        ))}
      </div>
      </div>
    </>
  );
}
