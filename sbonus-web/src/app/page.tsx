import Image from "next/image";
import Link from "next/link";
import { SearchBox } from "@/components/SearchBox";
import { BonusList, CalcList, GuideList, SectionTitle } from "@/components/Rows";
import { StoreBadges } from "@/components/AppPromo";
import { AdSlot } from "@/components/AdSlot";
import { bonusPerCategoria, bonusPubblicati, guidePubblicate, toLite } from "@/lib/content";
import { CATEGORIE } from "@/lib/categories";
import { CALCOLATORI } from "@/lib/calcolatori";
import { ADSENSE_SLOTS, APP } from "@/lib/site";

const RICERCHE_RAPIDE = [
  { label: "Assegno Unico", href: "/bonus/assegno-unico-universale-2026" },
  { label: "NASpI", href: "/bonus/naspi-indennita-disoccupazione" },
  { label: "ISEE", href: "/guide/isee-2026-come-ottenerlo-dsu-precompilata" },
  { label: "Bonus bollette", href: "/bonus/bonus-sociale-bollette-luce-gas-acqua" },
  { label: "Stipendio netto", href: "/calcolatori/stipendio-netto" },
];

export default function Home() {
  // Elenco completo dei bonus, raggruppato per categoria (in ordine di categoria)
  const gruppi = CATEGORIE.map((c) => ({ c, bonus: bonusPerCategoria(c.slug).map(toLite) })).filter((g) => g.bonus.length > 0);

  return (
    <>
      {/* Testata */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-6xl px-4 pb-14 pt-14 sm:px-6 sm:pb-20 sm:pt-20">
          <div className="max-w-3xl">
            <p className="text-sm font-medium text-brand">Bonus e agevolazioni 2026</p>
            <h1 className="mt-3 text-4xl font-semibold leading-[1.1] tracking-tight text-ink sm:text-5xl">
              Scopri tutti i bonus e le agevolazioni in Italia
            </h1>
            <p className="mt-5 text-lg leading-relaxed text-ink-2 sm:text-xl">
              Guide, calcolatori e informazioni utili per famiglie, lavoratori e cittadini, controllati sulle fonti ufficiali.
            </p>
            <div className="mt-8">
              <SearchBox size="lg" />
            </div>
            <p className="mt-4 text-sm text-ink-3">
              Più cercati:{" "}
              {RICERCHE_RAPIDE.map((r, i) => (
                <span key={r.href}>
                  {i > 0 && <span aria-hidden="true"> · </span>}
                  <Link href={r.href} className="font-medium text-ink-2 hover:text-brand hover:underline">
                    {r.label}
                  </Link>
                </span>
              ))}
            </p>
          </div>
        </div>
      </section>

      {/* Elenco dei bonus per categoria */}
      <section aria-labelledby="elenco-bonus" className="mx-auto max-w-6xl px-4 pt-16 sm:px-6">
        <div className="grid grid-cols-1 gap-10 lg:grid-cols-[220px_minmax(0,1fr)] lg:gap-16">
          <aside className="min-w-0 lg:sticky lg:top-24 lg:self-start">
            <h2 id="elenco-bonus" className="text-2xl font-semibold tracking-tight text-ink">
              Bonus 2026
            </h2>
            <p className="mt-1.5 text-sm text-ink-3">{bonusPubblicati.length} schede verificate sulle fonti ufficiali</p>
            <nav aria-label="Categorie" className="mt-6">
              <ul className="no-scrollbar -mx-4 flex gap-1 overflow-x-auto px-4 lg:mx-0 lg:flex-col lg:px-0">
                {gruppi.map(({ c, bonus }) => (
                  <li key={c.slug} className="shrink-0">
                    <a
                      href={`#${c.slug}`}
                      className="flex items-center justify-between gap-4 rounded-lg border border-line px-3 py-2 text-sm text-ink-2 transition-colors hover:bg-surface-2 hover:text-ink lg:border-transparent"
                    >
                      {c.nome}
                      <span className="tabular-nums text-ink-3">{bonus.length}</span>
                    </a>
                  </li>
                ))}
              </ul>
            </nav>
            <Link href="/bonus" className="mt-4 hidden items-center gap-1 px-3 text-sm font-medium text-brand hover:underline lg:inline-flex">
              Elenco completo con filtri →
            </Link>
          </aside>

          <div className="min-w-0 space-y-12">
            {gruppi.map(({ c, bonus }) => (
              <section key={c.slug} id={c.slug} aria-labelledby={`g-${c.slug}`} className="scroll-mt-24">
                <div className="mb-2 flex items-baseline justify-between gap-4">
                  <h3 id={`g-${c.slug}`} className="text-xs font-semibold uppercase tracking-[0.12em] text-ink-3">
                    {c.nome}
                  </h3>
                  <Link href={`/categorie/${c.slug}`} className="text-sm text-ink-3 hover:text-brand">
                    Categoria →
                  </Link>
                </div>
                <BonusList bonus={bonus} />
              </section>
            ))}
          </div>
        </div>
      </section>

      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <AdSlot slot={ADSENSE_SLOTS.elenco} />
      </div>

      {/* Calcolatori */}
      <section aria-labelledby="calcolatori" className="mx-auto mt-24 max-w-6xl px-4 sm:px-6">
        <SectionTitle
          id="calcolatori"
          titolo="Calcolatori"
          sottotitolo="Stime gratuite con i parametri 2026. I dati restano nel tuo browser."
          href="/calcolatori"
          cta="Tutti i calcolatori"
        />
        <CalcList calcolatori={CALCOLATORI} colonne />
      </section>

      {/* Guide */}
      <section aria-labelledby="guide" className="mx-auto mt-24 max-w-6xl px-4 sm:px-6">
        <SectionTitle id="guide" titolo="Guide" sottotitolo="Spiegazioni pratiche su ISEE, INPS, tasse e prestazioni." href="/guide" cta="Tutte le guide" />
        <GuideList guide={guidePubblicate.slice(0, 5)} />
      </section>

      {/* App */}
      <section aria-labelledby="app" className="mx-auto mt-24 max-w-6xl px-4 sm:px-6">
        <div className="flex flex-col gap-6 rounded-2xl border border-line p-6 sm:flex-row sm:items-center sm:p-8">
          <Image src="/img/smart-bonus-italia-icon.png" alt="" width={64} height={64} className="rounded-2xl" />
          <div className="flex-1">
            <h2 id="app" className="text-xl font-semibold tracking-tight text-ink">
              {APP.name}
            </h2>
            <p className="mt-1 text-ink-2">L&apos;app gratuita con bonus, guide e calcolatori, in 12 lingue.</p>
          </div>
          <StoreBadges />
        </div>
      </section>

      {/* Nota di indipendenza */}
      <p className="mx-auto mt-12 max-w-6xl px-4 text-sm leading-relaxed text-ink-3 sm:px-6">
        SBonus è un portale informativo indipendente: non è un sito della Pubblica Amministrazione e non è affiliato a INPS o
        Agenzia delle Entrate. Ogni scheda indica le fonti ufficiali e la data dell&apos;ultimo controllo; le domande si
        presentano sui canali ufficiali.
      </p>
    </>
  );
}
