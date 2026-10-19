import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { PageHero } from "@/components/PageHero";
import { BonusList, CalcList, GuideList } from "@/components/Rows";
import { CATEGORIE, getCategoria } from "@/lib/categories";
import { CALCOLATORI } from "@/lib/calcolatori";
import { bonusPerCategoria, guidePerCategoria, toLite } from "@/lib/content";

export const dynamicParams = false;

// Si generano solo le categorie con almeno un contenuto pubblicato: niente pagine vuote.
export function generateStaticParams() {
  return CATEGORIE.filter((c) => bonusPerCategoria(c.slug).length + guidePerCategoria(c.slug).length > 0).map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: PageProps<"/categorie/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const c = getCategoria(slug);
  if (!c) return {};
  return { title: `${c.nome}: bonus e guide 2026`, description: c.descrizione, alternates: { canonical: `/categorie/${c.slug}` } };
}

export default async function CategoriaPage({ params }: PageProps<"/categorie/[slug]">) {
  const { slug } = await params;
  const c = getCategoria(slug);
  if (!c) notFound();
  const bonus = bonusPerCategoria(c.slug);
  const guide = guidePerCategoria(c.slug);
  const calc = CALCOLATORI.filter((x) => x.categoria === c.slug);
  if (bonus.length + guide.length === 0) notFound();

  return (
    <>
      <PageHero
        crumbs={[{ label: "Categorie", href: "/categorie" }, { label: c.nome, href: `/categorie/${c.slug}` }]}
        occhiello="Categoria"
        titolo={c.nome}
        intro={c.descrizione}
        categoria={c.slug}
        icona={c.icona}
      />
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
      {bonus.length > 0 && (
        <section aria-labelledby="cat-bonus" className="mt-12">
          <h2 id="cat-bonus" className="text-2xl font-black tracking-tight text-ink">
            Bonus e prestazioni
          </h2>
          <div className="mt-5">
            <BonusList bonus={bonus.map(toLite)} />
          </div>
        </section>
      )}
      {guide.length > 0 && (
        <section aria-labelledby="cat-guide" className="mt-14">
          <h2 id="cat-guide" className="text-2xl font-black tracking-tight text-ink">
            Guide
          </h2>
          <div className="mt-5">
            <GuideList guide={guide} />
          </div>
        </section>
      )}
      {calc.length > 0 && (
        <section aria-labelledby="cat-calc" className="mt-12">
          <h2 id="cat-calc" className="text-2xl font-black tracking-tight text-ink">
            Calcolatori
          </h2>
          <div className="mt-5">
            <CalcList calcolatori={calc} />
          </div>
        </section>
      )}
      </div>
    </>
  );
}
