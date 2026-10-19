import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Breadcrumbs } from "@/components/Breadcrumbs";
import { Faqs, Fonti, AvvisoIndipendente } from "@/components/Editorial";
import { JsonLd } from "@/components/JsonLd";
import { Icon } from "@/components/Icon";
import { CalcCard } from "@/components/Cards";
import { AdSlot } from "@/components/AdSlot";
import { NaspiCalc } from "@/components/calc/NaspiCalc";
import { AssegnoUnicoCalc } from "@/components/calc/AssegnoUnicoCalc";
import { StipendioCalc } from "@/components/calc/StipendioCalc";
import { IrpefCalc } from "@/components/calc/IrpefCalc";
import { TfrCalc } from "@/components/calc/TfrCalc";
import { MutuoCalc } from "@/components/calc/MutuoCalc";
import { RisparmioCalc } from "@/components/calc/RisparmioCalc";
import { CALCOLATORI, getCalcolatore } from "@/lib/calcolatori";
import { CALC_INFO } from "@/lib/calc-info";
import { PARAMS } from "@/lib/calc/params";
import { getBonus, formatData } from "@/lib/content";
import { ADSENSE_SLOTS, absoluteUrl } from "@/lib/site";

export const dynamicParams = false;

const WIDGET: Record<string, React.ComponentType> = {
  naspi: NaspiCalc,
  "assegno-unico": AssegnoUnicoCalc,
  "stipendio-netto": StipendioCalc,
  irpef: IrpefCalc,
  tfr: TfrCalc,
  "rata-mutuo": MutuoCalc,
  "risparmio-familiare": RisparmioCalc,
};

export function generateStaticParams() {
  return CALCOLATORI.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: PageProps<"/calcolatori/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const c = getCalcolatore(slug);
  if (!c) return {};
  const url = `/calcolatori/${c.slug}`;
  return { title: c.titolo, description: c.descrizione, alternates: { canonical: url }, openGraph: { url, title: c.titolo, description: c.descrizione } };
}

export default async function CalcolatorePage({ params }: PageProps<"/calcolatori/[slug]">) {
  const { slug } = await params;
  const c = getCalcolatore(slug);
  const info = CALC_INFO[slug];
  const Widget = WIDGET[slug];
  if (!c || !info || !Widget) notFound();
  const bonus = info.bonusCorrelato ? getBonus(info.bonusCorrelato) : undefined;
  const altri = CALCOLATORI.filter((x) => x.slug !== c.slug).slice(0, 3);

  return (
    <div className="mx-auto max-w-6xl px-4 pt-6 sm:px-6">
      <Breadcrumbs items={[{ label: "Calcolatori", href: "/calcolatori" }, { label: c.titoloBreve, href: `/calcolatori/${c.slug}` }]} />
      <header className="mt-6 max-w-3xl">
        <h1 className="font-display text-3xl font-extrabold tracking-tight text-ink sm:text-4xl">{c.titolo}</h1>
        <p className="mt-3 text-lg leading-relaxed text-ink-2">{info.intro}</p>
        <p className="mt-3 inline-flex flex-wrap items-center gap-2 text-sm text-ink-3">
          <Icon name="calendar" className="h-4 w-4" />
          Parametri anno {PARAMS.anno} · ultimo controllo <time dateTime={PARAMS.ultimoControllo}>{formatData(PARAMS.ultimoControllo)}</time>
        </p>
      </header>

      <div className="mt-8">
        <Widget />
      </div>

      <p className="mt-4 flex gap-2 rounded-2xl bg-warn-soft p-4 text-sm leading-relaxed text-ink">
        <Icon name="info" className="mt-0.5 h-4 w-4 shrink-0 text-warn" />
        <span>
          <strong>È una stima, non un importo ufficiale.</strong> Il risultato ha valore orientativo: l&apos;importo effettivo lo
          stabilisce l&apos;ente competente sulla base della tua situazione completa. I dati che inserisci restano nel tuo browser e
          non vengono inviati né salvati.
        </span>
      </p>

      <AdSlot slot={ADSENSE_SLOTS.contenuto} />

      <div className="mt-10 grid gap-8 lg:grid-cols-[1fr_320px]">
        <div className="min-w-0 space-y-5">
          <section aria-labelledby="come" className="rounded-2xl border border-line bg-surface p-5 sm:p-6">
            <h2 id="come" className="font-display text-xl font-bold text-ink">
              Come funziona il calcolo
            </h2>
            <ol className="mt-4 space-y-3 text-ink-2">
              {info.come.map((s, i) => (
                <li key={s} className="flex gap-3 leading-relaxed">
                  <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-brand-soft text-sm font-bold text-brand">{i + 1}</span>
                  <span className="pt-0.5">{s}</span>
                </li>
              ))}
            </ol>
          </section>

          <section aria-labelledby="ipotesi" className="rounded-2xl border border-line bg-surface p-5 sm:p-6">
            <h2 id="ipotesi" className="font-display text-xl font-bold text-ink">
              Ipotesi e limiti
            </h2>
            <ul className="mt-4 space-y-2.5 text-ink-2">
              {info.ipotesi.map((s) => (
                <li key={s} className="flex gap-2.5 leading-relaxed">
                  <Icon name="alert" className="mt-1 h-4 w-4 shrink-0 text-warn" />
                  <span>{s}</span>
                </li>
              ))}
            </ul>
          </section>

          {info.faq.length > 0 && <Faqs faq={info.faq} />}
          {info.fonti.length > 0 && <Fonti fonti={info.fonti} ultimoControllo={PARAMS.ultimoControllo} />}
          <AvvisoIndipendente />
        </div>

        <aside className="space-y-5 lg:sticky lg:top-24 lg:self-start">
          <section aria-labelledby="parametri" className="rounded-2xl border border-line bg-surface p-5">
            <h2 id="parametri" className="font-bold text-ink">
              Parametri {PARAMS.anno}
            </h2>
            <dl className="mt-3 space-y-3 text-sm">
              {info.parametri.map((p) => (
                <div key={p.voce}>
                  <dt className="text-ink-3">{p.voce}</dt>
                  <dd className="font-semibold text-ink">{p.valore}</dd>
                </div>
              ))}
            </dl>
            <p className={`mt-4 rounded-xl p-3 text-xs leading-relaxed ${info.verificato ? "bg-accent-soft text-accent" : "bg-warn-soft text-warn"}`}>
              {info.verificato
                ? "Parametri verificati su fonti ufficiali."
                : (info.notaVerifica ?? "Alcuni parametri sono in corso di verifica sulle fonti ufficiali.")}
            </p>
          </section>
          {bonus && (
            <Link href={`/bonus/${bonus.slug}`} className="flex items-center justify-between gap-3 rounded-2xl border border-line bg-surface p-5 font-semibold text-ink hover:border-brand/40">
              <span>
                <span className="block text-xs font-semibold uppercase tracking-wide text-brand">Scheda completa</span>
                {bonus.titolo}
              </span>
              <Icon name="arrow" className="h-5 w-5 text-brand" />
            </Link>
          )}
        </aside>
      </div>

      <section aria-labelledby="altri" className="mt-14">
        <h2 id="altri" className="font-display text-2xl font-extrabold text-ink">
          Altri calcolatori
        </h2>
        <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {altri.map((x) => (
            <CalcCard key={x.slug} c={x} />
          ))}
        </div>
      </section>

      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "WebApplication",
          name: c.titolo,
          description: c.descrizione,
          url: absoluteUrl(`/calcolatori/${c.slug}`),
          applicationCategory: "FinanceApplication",
          operatingSystem: "Web",
          inLanguage: "it-IT",
          isAccessibleForFree: true,
          offers: { "@type": "Offer", price: "0", priceCurrency: "EUR" },
        }}
      />
    </div>
  );
}
