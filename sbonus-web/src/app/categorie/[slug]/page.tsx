import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Breadcrumbs } from "@/components/Breadcrumbs";
import { BonusCard, CalcCard, GuideCard } from "@/components/Cards";
import { Icon } from "@/components/Icon";
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
    <div className="mx-auto max-w-6xl px-4 pt-6 sm:px-6">
      <Breadcrumbs items={[{ label: "Categorie", href: "/categorie" }, { label: c.nome, href: `/categorie/${c.slug}` }]} />
      <header className="mt-6 flex items-start gap-4">
        <span className="grid h-14 w-14 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand">
          <Icon name={c.icona} className="h-7 w-7" />
        </span>
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight text-ink sm:text-4xl">{c.nome}</h1>
          <p className="mt-2 max-w-2xl text-lg text-ink-2">{c.descrizione}</p>
        </div>
      </header>

      {bonus.length > 0 && (
        <section aria-labelledby="cat-bonus" className="mt-10">
          <h2 id="cat-bonus" className="font-display text-2xl font-extrabold text-ink">
            Bonus e prestazioni
          </h2>
          <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {bonus.map((b) => (
              <BonusCard key={b.slug} b={toLite(b)} />
            ))}
          </div>
        </section>
      )}
      {guide.length > 0 && (
        <section aria-labelledby="cat-guide" className="mt-12">
          <h2 id="cat-guide" className="font-display text-2xl font-extrabold text-ink">
            Guide
          </h2>
          <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {guide.map((g) => (
              <GuideCard key={g.slug} g={g} />
            ))}
          </div>
        </section>
      )}
      {calc.length > 0 && (
        <section aria-labelledby="cat-calc" className="mt-12">
          <h2 id="cat-calc" className="font-display text-2xl font-extrabold text-ink">
            Calcolatori
          </h2>
          <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {calc.map((x) => (
              <CalcCard key={x.slug} c={x} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
