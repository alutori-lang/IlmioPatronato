import type { Metadata } from "next";
import { PageHero } from "@/components/PageHero";
import Link from "next/link";
import { Bolla } from "@/components/Rows";
import { CATEGORIE, stileTono } from "@/lib/categories";
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
      <ul className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {categorieAttive().map(({ c, n }) => (
          <li key={c.slug}>
            <Link href={`/categorie/${c.slug}`} style={stileTono(c.slug)} className="group flex h-full items-center gap-4 rounded-[28px] border-2 border-line bg-white p-5 transition hover:-translate-y-0.5 hover:border-[var(--tone)]">
              <Bolla categoria={c.slug} size="lg" />
              <div className="min-w-0">
                <p className="text-lg font-black text-ink">{c.nome}</p>
                <p className="mt-0.5 text-sm font-semibold text-ink-3">{c.descrizione}</p>
                <p className="mt-1.5 text-sm font-extrabold text-[var(--tone)]">
                  {n} {n === 1 ? "contenuto" : "contenuti"}
                </p>
              </div>
            </Link>
          </li>
        ))}
      </ul>
      </div>
    </>
  );
}
