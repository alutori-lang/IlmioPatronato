import Link from "next/link";
import { SearchBox } from "@/components/SearchBox";
import { BonusCard, CalcCard, CategoriaCard, GuideCard, SectionHeading } from "@/components/Cards";
import { AppPromo } from "@/components/AppPromo";
import { Icon } from "@/components/Icon";
import { AdSlot } from "@/components/AdSlot";
import { bonusInEvidenza, bonusPerCategoria, bonusPubblicati, guidePubblicate, guidePerCategoria, formatData } from "@/lib/content";
import { CATEGORIE } from "@/lib/categories";
import { CALCOLATORI } from "@/lib/calcolatori";
import { ADSENSE_SLOTS } from "@/lib/site";

const RICERCHE_RAPIDE = [
  { label: "Assegno Unico", href: "/bonus/assegno-unico-universale-2026" },
  { label: "NASpI", href: "/bonus/naspi-indennita-disoccupazione" },
  { label: "ISEE", href: "/categorie/isee" },
  { label: "Bonus bollette", href: "/bonus/bonus-sociale-bollette-luce-gas-acqua" },
  { label: "Stipendio netto", href: "/calcolatori/stipendio-netto" },
];

function Sezione({ id, children, className = "" }: { id?: string; children: React.ReactNode; className?: string }) {
  return (
    <section id={id} aria-labelledby={id ? `${id}-title` : undefined} className={`mx-auto max-w-6xl px-4 sm:px-6 ${className}`}>
      {children}
    </section>
  );
}

function ListaTematica({ cat, titolo, sottotitolo }: { cat: string; titolo: string; sottotitolo: string }) {
  const items = bonusPerCategoria(cat).slice(0, 3);
  if (items.length === 0) return null;
  return (
    <Sezione className="mt-16">
      <SectionHeading titolo={titolo} sottotitolo={sottotitolo} href={`/categorie/${cat}`} cta="Tutta la categoria" />
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {items.map((b) => (
          <BonusCard key={b.slug} b={b} />
        ))}
      </div>
    </Sezione>
  );
}

export default function Home() {
  const novita = [
    ...bonusPubblicati.map((b) => ({ titolo: b.titolo, href: `/bonus/${b.slug}`, data: b.ultimoControllo ?? "", tipo: "Bonus" })),
    ...guidePubblicate.map((g) => ({ titolo: g.titolo, href: `/guide/${g.slug}`, data: g.dataAggiornamento ?? "", tipo: "Guida" })),
  ]
    .sort((a, b) => b.data.localeCompare(a.data) || a.titolo.localeCompare(b.titolo, "it"))
    .slice(0, 6);

  const categorieConContenuti = CATEGORIE.map((c) => ({ c, n: bonusPerCategoria(c.slug).length + guidePerCategoria(c.slug).length })).filter((x) => x.n > 0);
  const guideInps = guidePubblicate.filter((g) => g.categoria === "inps" || g.categoria === "isee").slice(0, 3);

  return (
    <>
      {/* HERO */}
      <section className="relative overflow-hidden border-b border-line bg-surface">
        <div aria-hidden="true" className="pointer-events-none absolute inset-0 bg-[radial-gradient(60rem_30rem_at_85%_-10%,var(--brand-soft),transparent),radial-gradient(40rem_24rem_at_0%_110%,var(--accent-soft),transparent)]" />
        <div className="relative mx-auto max-w-6xl px-4 pb-14 pt-12 sm:px-6 sm:pb-20 sm:pt-20">
          <p className="inline-flex items-center gap-2 rounded-full border border-line bg-surface px-3 py-1 text-sm font-medium text-ink-2">
            <span className="h-2 w-2 rounded-full bg-accent" aria-hidden="true" />
            Contenuti controllati sulle fonti ufficiali
          </p>
          <h1 className="mt-5 max-w-3xl font-display text-4xl font-extrabold leading-[1.1] tracking-tight text-ink sm:text-5xl lg:text-6xl">
            Scopri tutti i bonus e le agevolazioni in Italia
          </h1>
          <p className="mt-5 max-w-2xl text-lg leading-relaxed text-ink-2 sm:text-xl">
            Guide, calcolatori e informazioni utili per famiglie, lavoratori e cittadini.
          </p>
          <div className="mt-8 max-w-2xl">
            <SearchBox size="lg" />
          </div>
          <nav aria-label="Ricerche frequenti" className="mt-4 flex flex-wrap items-center gap-2 text-sm">
            <span className="text-ink-3">Più cercati:</span>
            {RICERCHE_RAPIDE.map((r) => (
              <Link key={r.href} href={r.href} className="rounded-full border border-line bg-surface px-3 py-1.5 font-medium text-ink-2 transition hover:border-brand/40 hover:text-brand">
                {r.label}
              </Link>
            ))}
          </nav>
          <dl className="mt-10 grid max-w-xl grid-cols-3 gap-4">
            {[
              { n: bonusPubblicati.length, l: "schede bonus verificate" },
              { n: CALCOLATORI.length, l: "calcolatori gratuiti" },
              { n: guidePubblicate.length, l: "guide pratiche" },
            ].map((s) => (
              <div key={s.l}>
                <dt className="sr-only">{s.l}</dt>
                <dd>
                  <span className="block font-display text-3xl font-extrabold text-brand">{s.n}</span>
                  <span className="block text-sm text-ink-3">{s.l}</span>
                </dd>
              </div>
            ))}
          </dl>
        </div>
      </section>

      {/* BONUS PIÙ CERCATI */}
      <Sezione id="piu-cercati" className="mt-14">
        <SectionHeading titolo="Bonus più cercati" sottotitolo="Le misure su cui riceviamo più domande, con requisiti e importi aggiornati." href="/bonus" cta="Tutti i bonus" />
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {bonusInEvidenza.map((b) => (
            <BonusCard key={b.slug} b={b} />
          ))}
        </div>
      </Sezione>

      <ListaTematica cat="famiglia" titolo="Bonus famiglia" sottotitolo="Figli, nascite, asilo nido, maternità e congedi." />
      <ListaTematica cat="lavoro" titolo="Lavoro e disoccupazione" sottotitolo="Indennità per chi perde il lavoro e misure per tornare a lavorare." />
      <ListaTematica cat="casa" titolo="Casa" sottotitolo="Detrazioni per lavori e arredi, affitto e garanzia sul mutuo." />

      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <AdSlot slot={ADSENSE_SLOTS.elenco} />
      </div>

      {/* CALCOLATORI */}
      <Sezione id="calcolatori" className="mt-16">
        <SectionHeading titolo="Calcolatori gratuiti" sottotitolo="Stime immediate con i parametri 2026, senza registrazione e senza inviare i tuoi dati." href="/calcolatori" />
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {CALCOLATORI.slice(0, 4).map((c) => (
            <CalcCard key={c.slug} c={c} />
          ))}
        </div>
      </Sezione>

      {/* ISEE E GUIDE INPS */}
      {guideInps.length > 0 && (
        <Sezione className="mt-16">
          <SectionHeading titolo="ISEE e guide INPS" sottotitolo="Come ottenere l'ISEE e usare i servizi online, passo per passo." href="/guide" cta="Tutte le guide" />
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {guideInps.map((g) => (
              <GuideCard key={g.slug} g={g} />
            ))}
          </div>
        </Sezione>
      )}

      {/* CATEGORIE */}
      <Sezione className="mt-16">
        <SectionHeading titolo="Esplora per categoria" />
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {categorieConContenuti.map(({ c, n }) => (
            <CategoriaCard key={c.slug} c={c} conteggio={n} />
          ))}
        </div>
      </Sezione>

      {/* ARTICOLI + NOVITÀ */}
      <Sezione className="mt-16">
        <div className="grid gap-10 lg:grid-cols-[1.6fr_1fr]">
          <div>
            <SectionHeading titolo="Articoli aggiornati" href="/guide" cta="Tutte le guide" />
            <div className="grid gap-4 sm:grid-cols-2">
              {guidePubblicate.slice(0, 4).map((g) => (
                <GuideCard key={g.slug} g={g} />
              ))}
            </div>
          </div>
          <div>
            <SectionHeading titolo="Ultime novità verificate" />
            <ol className="divide-y divide-line rounded-2xl border border-line bg-surface">
              {novita.map((n) => (
                <li key={n.href}>
                  <Link href={n.href} className="flex items-start gap-3 p-4 transition hover:bg-surface-2">
                    <Icon name="check" className="mt-0.5 h-5 w-5 shrink-0 text-accent" />
                    <span className="min-w-0">
                      <span className="block font-medium text-ink">{n.titolo}</span>
                      <span className="block text-sm text-ink-3">
                        {n.tipo} · controllato il <time dateTime={n.data}>{formatData(n.data)}</time>
                      </span>
                    </span>
                  </Link>
                </li>
              ))}
            </ol>
          </div>
        </div>
      </Sezione>

      {/* APP */}
      <Sezione id="app" className="mt-20">
        <AppPromo />
      </Sezione>

      {/* FIDUCIA */}
      <Sezione className="mt-16">
        <div className="grid gap-4 sm:grid-cols-3">
          {[
            { i: "book" as const, t: "Fonti ufficiali", d: "Ogni scheda cita le pagine di INPS, Agenzia delle Entrate e Ministeri da cui proviene, con la data dell'ultimo controllo." },
            { i: "calc" as const, t: "Calcoli trasparenti", d: "I calcolatori mostrano anno, parametri e ipotesi usate. Sono stime: l'importo ufficiale lo stabilisce l'ente." },
            { i: "info" as const, t: "Portale indipendente", d: "SBonus non è un sito della Pubblica Amministrazione. Le domande vanno presentate sui canali ufficiali o tramite CAF e patronati." },
          ].map((x) => (
            <div key={x.t} className="rounded-2xl border border-line bg-surface p-5">
              <Icon name={x.i} className="h-6 w-6 text-brand" />
              <h3 className="mt-3 font-semibold text-ink">{x.t}</h3>
              <p className="mt-1.5 text-sm leading-relaxed text-ink-2">{x.d}</p>
            </div>
          ))}
        </div>
      </Sezione>
    </>
  );
}
