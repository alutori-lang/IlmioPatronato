import type { Metadata } from "next";
import { PageHero } from "@/components/PageHero";
import Link from "next/link";
import { Icon } from "@/components/Icon";
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
      <ul className="mt-10 border-t border-line">
        {categorieAttive().map(({ c, n }) => (
          <li key={c.slug} className="border-b border-line">
            <Link href={`/categorie/${c.slug}`} className="group -mx-3 flex items-center gap-6 rounded-lg px-3 py-5 transition-colors hover:bg-surface-2">
              <div className="min-w-0 flex-1">
                <p className="font-medium text-ink group-hover:text-brand">{c.nome}</p>
                <p className="mt-1 text-sm text-ink-3">{c.descrizione}</p>
              </div>
              <span className="shrink-0 text-sm tabular-nums text-ink-3">
                {n} {n === 1 ? "contenuto" : "contenuti"}
              </span>
              <Icon name="arrow" className="hidden h-4 w-4 shrink-0 text-ink-3 sm:block" />
            </Link>
          </li>
        ))}
      </ul>
      </div>
    </>
  );
}
