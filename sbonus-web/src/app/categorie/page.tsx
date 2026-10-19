import type { Metadata } from "next";
import { Breadcrumbs } from "@/components/Breadcrumbs";
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
    <div className="mx-auto max-w-6xl px-4 pt-6 sm:px-6">
      <Breadcrumbs items={[{ label: "Categorie", href: "/categorie" }]} />
      <h1 className="mt-6 font-display text-3xl font-extrabold tracking-tight text-ink sm:text-4xl">Categorie</h1>
      <p className="mt-3 max-w-2xl text-lg text-ink-2">Trova bonus e guide raggruppati per argomento.</p>
      <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {categorieAttive().map(({ c, n }) => (
          <CategoriaCard key={c.slug} c={c} conteggio={n} />
        ))}
      </div>
    </div>
  );
}
