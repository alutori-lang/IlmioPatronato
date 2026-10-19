import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { PageHero } from "@/components/PageHero";
import { StatoBadge, BonusList } from "@/components/Rows";
import { JsonLd } from "@/components/JsonLd";
import { Icon } from "@/components/Icon";
import { AdSlot } from "@/components/AdSlot";
import { AppPromo } from "@/components/AppPromo";
import { Fonti, Faqs, AvvisoIndipendente } from "@/components/Editorial";
import { bonusPubblicati, getBonus, bonusPerCategoria, formatData, toLite } from "@/lib/content";
import { getCategoria } from "@/lib/categories";
import { CALCOLATORI } from "@/lib/calcolatori";
import { ADSENSE_SLOTS, absoluteUrl } from "@/lib/site";

export const dynamicParams = false;

export function generateStaticParams() {
  return bonusPubblicati.map((b) => ({ slug: b.slug }));
}

export async function generateMetadata({ params }: PageProps<"/bonus/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const b = getBonus(slug);
  if (!b) return {};
  const url = `/bonus/${b.slug}`;
  return {
    title: b.titolo,
    description: b.descrizione,
    alternates: { canonical: url },
    openGraph: { type: "article", url, title: b.titolo, description: b.descrizione, modifiedTime: b.aggiornatoIl ?? undefined },
  };
}

// Collegamenti tra schede e calcolatori pertinenti
const CALC_PER_BONUS: Record<string, string> = {
  "naspi-indennita-disoccupazione": "naspi",
  "assegno-unico-universale-2026": "assegno-unico",
  "fondo-garanzia-prima-casa-consap": "rata-mutuo",
};

function Blocco({ id, titolo, children }: { id: string; titolo: string; icona?: string; children: React.ReactNode }) {
  return (
    <section id={id} aria-labelledby={`${id}-t`} className="scroll-mt-24 border-t border-line pt-8">
      <h2 id={`${id}-t`} className="text-xl font-semibold tracking-tight text-ink">
        {titolo}
      </h2>
      <div className="mt-4 text-ink-2">{children}</div>
    </section>
  );
}

function Lista({ items }: { items: string[] }) {
  return (
    <ul className="space-y-2.5">
      {items.map((x) => (
        <li key={x} className="flex gap-3 leading-relaxed">
          <span className="mt-[0.6rem] h-1.5 w-1.5 shrink-0 rounded-full bg-brand" aria-hidden="true" />
          <span>{x}</span>
        </li>
      ))}
    </ul>
  );
}

export default async function BonusPage({ params }: PageProps<"/bonus/[slug]">) {
  const { slug } = await params;
  const b = getBonus(slug);
  if (!b) notFound();
  const cat = getCategoria(b.categoria);
  const correlati = bonusPerCategoria(b.categoria).filter((x) => x.slug !== b.slug).slice(0, 3);
  const calc = CALCOLATORI.find((c) => c.slug === CALC_PER_BONUS[b.slug]);

  const indice = [
    b.aChiSpetta.length > 0 && { id: "a-chi-spetta", l: "A chi spetta" },
    b.requisiti.length > 0 && { id: "requisiti", l: "Requisiti" },
    b.importi.length > 0 && { id: "importi", l: "Importi" },
    b.comeFare.length > 0 && { id: "come-fare-domanda", l: "Come fare domanda" },
    b.documenti.length > 0 && { id: "documenti", l: "Documenti" },
    b.scadenze && { id: "scadenze", l: "Scadenze" },
    b.faq.length > 0 && { id: "faq", l: "Domande frequenti" },
    { id: "fonti", l: "Fonti ufficiali" },
  ].filter(Boolean) as { id: string; l: string }[];

  return (
    <article className="pb-8">
      <PageHero
        crumbs={[{ label: "Bonus", href: "/bonus" }, ...(cat ? [{ label: cat.nome, href: `/categorie/${cat.slug}` }] : []), { label: b.titolo, href: `/bonus/${b.slug}` }]}
        titolo={b.titolo}
        intro={b.intro || b.descrizione}
        categoria={b.categoria}
        icona={cat?.icona}
        occhiello={cat?.nome}
      >
        <div className="flex flex-wrap items-center gap-x-5 gap-y-2">
          <StatoBadge stato={b.stato} />
          {b.ente && <span className="text-sm text-ink-3">{b.ente}</span>}
          {b.ultimoControllo && (
            <span className="inline-flex items-center gap-1.5 text-sm text-ink-3">
              <Icon name="calendar" className="h-3.5 w-3.5" />
              Controllato il <time dateTime={b.ultimoControllo}>{formatData(b.ultimoControllo)}</time>
            </span>
          )}
        </div>
      </PageHero>

      <div className="mx-auto max-w-6xl px-4 sm:px-6">
      {b.evidenza && (
        <dl className="mt-8 flex flex-wrap gap-x-12 gap-y-4">
          <div>
            <dt className="text-sm text-ink-3">Importo</dt>
            <dd className="mt-1 text-3xl font-semibold tracking-tight text-ink">{b.evidenza.valore}</dd>
            <dd className="text-sm text-ink-2">{b.evidenza.etichetta}</dd>
          </div>
          {b.scadenze && (
            <div className="max-w-md">
              <dt className="text-sm text-ink-3">Scadenza</dt>
              <dd className="mt-1 line-clamp-3 text-ink-2">{b.scadenze}</dd>
            </div>
          )}
        </dl>
      )}

      {b.stato === "scaduto" && (
        <div role="note" className="mt-6 flex max-w-3xl gap-3 rounded-2xl border border-danger/30 bg-danger-soft p-4 text-ink">
          <Icon name="alert" className="h-5 w-5 shrink-0 text-danger" />
          <p>
            <strong>Misura scaduta.</strong> Questa agevolazione non è più richiedibile nella forma descritta. La scheda resta
            disponibile come riferimento: leggi le note e le alternative indicate qui sotto.
          </p>
        </div>
      )}
      {b.stato === "in-attesa" && (
        <div role="note" className="mt-6 flex max-w-3xl gap-3 rounded-2xl border border-warn/30 bg-warn-soft p-4 text-ink">
          <Icon name="info" className="h-5 w-5 shrink-0 text-warn" />
          <p>
            <strong>In attesa di attuazione.</strong> La misura è prevista ma le modalità di domanda non sono ancora state
            pubblicate dall&apos;ente. Aggiorneremo la scheda appena saranno disponibili.
          </p>
        </div>
      )}

      <div className="mt-10 grid gap-12 lg:grid-cols-[1fr_260px]">
        <div className="min-w-0 space-y-10">
          {b.aChiSpetta.length > 0 && (
            <Blocco id="a-chi-spetta" titolo="A chi spetta" icona="family">
              <Lista items={b.aChiSpetta} />
            </Blocco>
          )}
          {b.requisiti.length > 0 && (
            <Blocco id="requisiti" titolo="Requisiti" icona="check">
              <Lista items={b.requisiti} />
            </Blocco>
          )}
          {b.importi.length > 0 && (
            <Blocco id="importi" titolo="Importi" icona="euro">
              <Lista items={b.importi} />
              {calc && (
                <Link href={`/calcolatori/${calc.slug}`} className="mt-5 inline-flex items-center gap-2 font-medium text-brand hover:underline">
                  <Icon name="calc" className="h-5 w-5" /> Stima il tuo importo: {calc.titolo}
                </Link>
              )}
            </Blocco>
          )}

          <AdSlot slot={ADSENSE_SLOTS.contenuto} />

          {b.comeFare.length > 0 && (
            <Blocco id="come-fare-domanda" titolo="Come fare domanda" icona="book">
              <ol className="space-y-3">
                {b.comeFare.map((s, i) => (
                  <li key={s} className="flex gap-3 leading-relaxed">
                    <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full border border-line text-sm font-medium tabular-nums text-ink">{i + 1}</span>
                    <span className="pt-0.5">{s}</span>
                  </li>
                ))}
              </ol>
            </Blocco>
          )}
          {b.documenti.length > 0 && (
            <Blocco id="documenti" titolo="Documenti necessari" icona="tax">
              <Lista items={b.documenti} />
            </Blocco>
          )}
          {b.scadenze && (
            <Blocco id="scadenze" titolo="Scadenze" icona="calendar">
              <p className="leading-relaxed">{b.scadenze}</p>
            </Blocco>
          )}
          {b.faq.length > 0 && <Faqs faq={b.faq} />}
          <Fonti fonti={b.fonti} ultimoControllo={b.ultimoControllo} />
          <AvvisoIndipendente />
        </div>

        <aside className="space-y-5 lg:sticky lg:top-24 lg:self-start">
          <nav aria-label="Indice della scheda" className="hidden lg:block">
            <p className="text-sm font-semibold text-ink">In questa scheda</p>
            <ul className="mt-3 space-y-2 text-[0.95rem]">
              {indice.map((x) => (
                <li key={x.id}>
                  <a href={`#${x.id}`} className="text-ink-2 hover:text-brand">
                    {x.l}
                  </a>
                </li>
              ))}
            </ul>
          </nav>
          <AppPromo />
        </aside>
      </div>

      {correlati.length > 0 && (
        <section aria-labelledby="correlati" className="mt-14">
          <h2 id="correlati" className="text-xl font-semibold tracking-tight text-ink">
            Altri bonus in {cat?.nome ?? "questa categoria"}
          </h2>
          <div className="mt-5">
            <BonusList bonus={correlati.map(toLite)} />
          </div>
        </section>
      )}

      </div>

      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "Article",
          headline: b.titolo,
          description: b.descrizione,
          inLanguage: "it-IT",
          mainEntityOfPage: absoluteUrl(`/bonus/${b.slug}`),
          dateModified: b.aggiornatoIl ?? undefined,
          author: { "@type": "Organization", name: "Redazione SBonus" },
          publisher: { "@type": "Organization", name: "SBonus", logo: { "@type": "ImageObject", url: absoluteUrl("/icon.svg") } },
          citation: b.fonti.map((f) => f.url),
        }}
      />
    </article>
  );
}
