import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Breadcrumbs } from "@/components/Breadcrumbs";
import { Faqs, Fonti, AvvisoIndipendente } from "@/components/Editorial";
import { GuideCard } from "@/components/Cards";
import { JsonLd } from "@/components/JsonLd";
import { AdSlot } from "@/components/AdSlot";
import { AppPromo } from "@/components/AppPromo";
import { guidePubblicate, getGuida, formatData } from "@/lib/content";
import { getCategoria } from "@/lib/categories";
import { ADSENSE_SLOTS, absoluteUrl } from "@/lib/site";

export const dynamicParams = false;

export function generateStaticParams() {
  return guidePubblicate.map((g) => ({ slug: g.slug }));
}

export async function generateMetadata({ params }: PageProps<"/guide/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const g = getGuida(slug);
  if (!g) return {};
  const url = `/guide/${g.slug}`;
  return {
    title: g.titoloSeo,
    description: g.descrizione,
    alternates: { canonical: url },
    openGraph: {
      type: "article",
      url,
      title: g.titoloSeo,
      description: g.descrizione,
      publishedTime: g.dataPubblicazione ?? undefined,
      modifiedTime: g.dataAggiornamento ?? undefined,
    },
  };
}

export default async function GuidaPage({ params }: PageProps<"/guide/[slug]">) {
  const { slug } = await params;
  const g = getGuida(slug);
  if (!g) notFound();
  const cat = getCategoria(g.categoria);
  const correlate = [
    ...g.correlati.map(getGuida).filter((x) => x !== undefined),
    ...guidePubblicate.filter((x) => x.categoria === g.categoria && x.slug !== g.slug),
  ]
    .filter((x, i, arr) => x.slug !== g.slug && arr.findIndex((y) => y.slug === x.slug) === i)
    .slice(0, 3);

  return (
    <div className="mx-auto max-w-6xl px-4 pt-6 sm:px-6">
      <Breadcrumbs items={[{ label: "Guide", href: "/guide" }, { label: g.titolo, href: `/guide/${g.slug}` }]} />
      <div className="mt-6 grid gap-10 lg:grid-cols-[minmax(0,1fr)_300px]">
        <article className="min-w-0">
          <header>
            {cat && <p className="text-sm font-semibold uppercase tracking-wide text-brand">{cat.nome}</p>}
            <h1 className="mt-2 font-display text-3xl font-extrabold leading-tight tracking-tight text-ink sm:text-4xl">{g.titolo}</h1>
            <p className="mt-4 text-lg leading-relaxed text-ink-2">{g.descrizione}</p>
            <p className="mt-4 text-sm text-ink-3">
              {g.autore} · Pubblicata il <time dateTime={g.dataPubblicazione ?? undefined}>{formatData(g.dataPubblicazione)}</time>
              {g.dataAggiornamento && g.dataAggiornamento !== g.dataPubblicazione && (
                <>
                  {" "}· Aggiornata il <time dateTime={g.dataAggiornamento}>{formatData(g.dataAggiornamento)}</time>
                </>
              )}
            </p>
          </header>
          {/* HTML generato a build time dal Markdown della redazione (contenuto attendibile del repository) */}
          <div className="prose-sb mt-8" dangerouslySetInnerHTML={{ __html: g.html }} />
          <AdSlot slot={ADSENSE_SLOTS.contenuto} />
          <div className="mt-10 space-y-5">
            {g.faq.length > 0 && <Faqs faq={g.faq} />}
            {g.fonti.length > 0 && <Fonti fonti={g.fonti} ultimoControllo={g.dataAggiornamento} />}
            <AvvisoIndipendente />
          </div>
        </article>
        <aside className="space-y-5 lg:sticky lg:top-24 lg:self-start">
          <AppPromo compatto />
        </aside>
      </div>

      {correlate.length > 0 && (
        <section aria-labelledby="correlate" className="mt-14">
          <h2 id="correlate" className="font-display text-2xl font-extrabold text-ink">
            Leggi anche
          </h2>
          <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {correlate.map((x) => (
              <GuideCard key={x.slug} g={x} />
            ))}
          </div>
        </section>
      )}

      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "Article",
          headline: g.titoloSeo,
          description: g.descrizione,
          inLanguage: "it-IT",
          mainEntityOfPage: absoluteUrl(`/guide/${g.slug}`),
          datePublished: g.dataPubblicazione ?? undefined,
          dateModified: g.dataAggiornamento ?? undefined,
          author: { "@type": "Organization", name: g.autore },
          publisher: { "@type": "Organization", name: "SBonus", logo: { "@type": "ImageObject", url: absoluteUrl("/icon.svg") } },
          citation: g.fonti.map((f) => f.url),
        }}
      />
    </div>
  );
}
