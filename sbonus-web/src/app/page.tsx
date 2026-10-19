import Link from "next/link";
import { SearchBox } from "@/components/SearchBox";
import { BonusCard, CalcCard, GuideCard, SectionHeading } from "@/components/Cards";
import { ExploreTabs, type Tab } from "@/components/ExploreTabs";
import { AppPromo } from "@/components/AppPromo";
import { Icon, type AnyIcon } from "@/components/Icon";
import { AdSlot } from "@/components/AdSlot";
import { bonusInEvidenza, bonusPerCategoria, bonusPubblicati, guidePubblicate, getBonus, toLite, formatData } from "@/lib/content";
import { getCategoria, stileTono, type IconName } from "@/lib/categories";
import { CALCOLATORI } from "@/lib/calcolatori";
import { ADSENSE_SLOTS } from "@/lib/site";

const RICERCHE_RAPIDE = [
  { label: "Assegno Unico", href: "/bonus/assegno-unico-universale-2026" },
  { label: "NASpI", href: "/bonus/naspi-indennita-disoccupazione" },
  { label: "ISEE", href: "/guide/isee-2026-come-ottenerlo-dsu-precompilata" },
  { label: "Bonus bollette", href: "/bonus/bonus-sociale-bollette-luce-gas-acqua" },
  { label: "Stipendio netto", href: "/calcolatori/stipendio-netto" },
];

// "Di cosa hai bisogno?": porte d'ingresso per situazione di vita
const ESIGENZE: { titolo: string; testo: string; href: string; tono: string; icona: IconName }[] = [
  { titolo: "Ho dei figli", testo: "Assegno Unico, nido, nuovi nati", href: "/categorie/famiglia", tono: "famiglia", icona: "family" },
  { titolo: "Ho perso il lavoro", testo: "NASpI, DIS-COLL, formazione", href: "/categorie/lavoro", tono: "lavoro", icona: "work" },
  { titolo: "Casa e affitto", testo: "Ristrutturazione, mobili, mutuo", href: "/categorie/casa", tono: "casa", icona: "home" },
  { titolo: "Reddito basso", testo: "ADI, carte acquisti, bollette", href: "/categorie/sostegno", tono: "sostegno", icona: "support" },
  { titolo: "Sono in pensione", testo: "Assegno sociale e aiuti", href: "/categorie/pensioni", tono: "pensioni", icona: "elderly" },
  { titolo: "Devo fare l'ISEE", testo: "DSU precompilata passo passo", href: "/guide/isee-2026-come-ottenerlo-dsu-precompilata", tono: "isee", icona: "isee" },
  { titolo: "Tasse e busta paga", testo: "IRPEF 2026, cuneo, netto", href: "/categorie/fisco", tono: "fisco", icona: "tax" },
  { titolo: "Domande all'INPS", testo: "SPID, CIE, MyINPS", href: "/guide/accedere-servizi-inps-online-spid-cie", tono: "inps", icona: "inps" },
];

const PASSI: { n: string; t: string; d: string; i: AnyIcon }[] = [
  { n: "01", t: "Trova la misura giusta", d: "Cerca per parola o per situazione: famiglia, lavoro, casa, reddito.", i: "search" },
  { n: "02", t: "Controlla requisiti e importi", d: "Ogni scheda riassume chi ne ha diritto, quanto spetta e le scadenze, con le fonti ufficiali.", i: "check" },
  { n: "03", t: "Stima quanto ti spetta", d: "Usa i calcolatori gratuiti: i dati restano nel tuo browser.", i: "calc" },
  { n: "04", t: "Presenta la domanda", d: "Ti indichiamo il canale ufficiale: sito dell'ente, patronato o CAF.", i: "external" },
];

function HeroTicket({ slug, nome, rot, className = "" }: { slug: string; nome: string; rot: string; className?: string }) {
  const b = getBonus(slug);
  if (!b?.evidenza) return null;
  const cat = getCategoria(b.categoria);
  return (
    <Link
      href={`/bonus/${b.slug}`}
      style={{ ...stileTono(b.categoria), ["--rot" as string]: rot }}
      className={`animate-float block rounded-3xl bg-white p-4 text-[#0f1b33] shadow-[0_30px_60px_-20px_rgba(0,0,0,0.45)] ring-1 ring-black/5 transition hover:scale-[1.03] ${className}`}
    >
      <div className="flex items-center gap-3">
        <span className="tone-icon grid h-10 w-10 shrink-0 place-items-center rounded-xl">
          <Icon name={cat?.icona ?? "euro"} className="h-5 w-5" />
        </span>
        <span className="min-w-0">
          <span className="block text-[0.7rem] font-bold uppercase tracking-wider text-[#6b7790]">{cat?.nome}</span>
          <span className="block truncate font-semibold">{nome}</span>
        </span>
      </div>
      <p className="mt-3 font-display text-3xl font-extrabold tracking-tight">{b.evidenza.valore}</p>
      <p className="text-sm text-[#44516b]">{b.evidenza.etichetta}</p>
    </Link>
  );
}

export default function Home() {
  const conEvidenza = bonusInEvidenza.map(toLite);
  const tabs: Tab[] = ["famiglia", "lavoro", "casa", "sostegno"]
    .map((slug) => {
      const c = getCategoria(slug);
      return c ? { slug, nome: c.nome, icona: c.icona, bonus: bonusPerCategoria(slug).map(toLite) } : null;
    })
    .filter((t): t is Tab => Boolean(t && t.bonus.length));
  const [guidaTop, ...altreGuide] = guidePubblicate;
  const novita = [
    ...bonusPubblicati.map((b) => ({ titolo: b.titolo, href: `/bonus/${b.slug}`, data: b.ultimoControllo ?? "", tipo: "Bonus", cat: b.categoria })),
    ...guidePubblicate.map((g) => ({ titolo: g.titolo, href: `/guide/${g.slug}`, data: g.dataAggiornamento ?? "", tipo: "Guida", cat: g.categoria })),
  ]
    .sort((a, b) => b.data.localeCompare(a.data) || a.titolo.localeCompare(b.titolo, "it"))
    .slice(0, 5);

  return (
    <>
      {/* ───────── HERO ───────── */}
      <section className="hero-bg relative overflow-hidden text-white">
        <div aria-hidden="true" className="grid-pattern pointer-events-none absolute inset-0" />
        <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-4 pb-8 pt-12 sm:px-6 sm:pt-20 lg:grid-cols-[1.15fr_0.85fr] lg:pb-40">
          <div className="animate-rise">
            <p className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3.5 py-1.5 text-sm font-medium backdrop-blur">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-[#3ee0a1] opacity-75" />
                <span className="relative inline-flex h-2 w-2 rounded-full bg-[#3ee0a1]" />
              </span>
              Aggiornato con le misure 2026
            </p>
            <h1 className="mt-6 font-display text-[2.6rem] font-extrabold leading-[1.05] tracking-tight sm:text-6xl lg:text-[4.1rem]">
              Scopri tutti i <span className="text-gradient">bonus</span> e le agevolazioni in Italia
            </h1>
            <p className="mt-5 max-w-xl text-lg leading-relaxed text-white/80 sm:text-xl">
              Guide, calcolatori e informazioni utili per famiglie, lavoratori e cittadini. Chiare, gratuite, con le fonti ufficiali.
            </p>
            <div className="mt-8 max-w-xl rounded-[1.4rem] bg-white/10 p-1.5 shadow-2xl ring-1 ring-white/20 backdrop-blur">
              <SearchBox size="lg" />
            </div>
            <nav aria-label="Ricerche frequenti" className="mt-5 flex flex-wrap items-center gap-2 text-sm">
              <span className="mr-1 text-white/60">Più cercati:</span>
              {RICERCHE_RAPIDE.map((r) => (
                <Link key={r.href} href={r.href} className="rounded-full border border-white/20 bg-white/5 px-3.5 py-1.5 font-medium text-white/90 transition hover:bg-white hover:text-[#1534a8]">
                  {r.label}
                </Link>
              ))}
            </nav>
          </div>

          {/* Biglietti con cifre reali (desktop) */}
          <div aria-label="Importi in evidenza" className="relative hidden h-[440px] lg:block">
            <HeroTicket slug="assegno-unico-universale-2026" nome="Assegno Unico" rot="-4deg" className="absolute left-0 top-0 w-64" />
            <HeroTicket slug="naspi-indennita-disoccupazione" nome="NASpI" rot="3deg" className="absolute right-0 top-[150px] w-64 [animation-delay:-2s]" />
            <HeroTicket slug="bonus-asilo-nido-2026" nome="Bonus Asilo Nido" rot="-2deg" className="absolute left-8 top-[300px] w-64 [animation-delay:-4s]" />
          </div>
        </div>

        {/* Biglietti scorrevoli (mobile) */}
        <div className="relative pb-24 lg:hidden">
          <div className="no-scrollbar flex snap-x scroll-px-4 gap-4 overflow-x-auto px-4 pb-4 sm:scroll-px-6 sm:px-6">
            {[
              ["assegno-unico-universale-2026", "Assegno Unico"],
              ["naspi-indennita-disoccupazione", "NASpI"],
              ["bonus-asilo-nido-2026", "Bonus Asilo Nido"],
              ["carta-dedicata-a-te", "Carta Dedicata a te"],
            ].map(([s, nome]) => (
              <div key={s} className="w-60 shrink-0 snap-start">
                <HeroTicket slug={s} nome={nome} rot="0deg" className="[animation:none]" />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ───────── NUMERI ───────── */}
      <section aria-label="SBonus in numeri" className="relative z-10 mx-auto -mt-16 max-w-5xl px-4 sm:px-6 lg:-mt-24">
        <dl className="grid grid-cols-3 divide-x divide-line rounded-3xl border border-line bg-surface p-2 shadow-[0_20px_50px_-20px_rgba(15,27,51,0.35)]">
          {[
            { n: bonusPubblicati.length, l: "schede verificate", i: "check" as const },
            { n: CALCOLATORI.length, l: "calcolatori gratuiti", i: "calc" as const },
            { n: guidePubblicate.length, l: "guide pratiche", i: "book" as const },
          ].map((s) => (
            <div key={s.l} className="flex flex-col items-center gap-1 px-2 py-4 text-center sm:flex-row sm:justify-center sm:gap-4 sm:text-left">
              <span className="hidden h-12 w-12 place-items-center rounded-2xl bg-brand-soft text-brand sm:grid">
                <Icon name={s.i} className="h-6 w-6" />
              </span>
              <div>
                <dt className="sr-only">{s.l}</dt>
                <dd className="font-display text-3xl font-extrabold text-ink sm:text-4xl">{s.n}</dd>
                <dd className="text-xs text-ink-3 sm:text-sm">{s.l}</dd>
              </div>
            </div>
          ))}
        </dl>
      </section>

      {/* ───────── ESIGENZE ───────── */}
      <section aria-labelledby="esigenze-t" className="mx-auto mt-20 max-w-6xl px-4 sm:px-6">
        <div className="mb-8 text-center">
          <p className="text-sm font-bold uppercase tracking-[0.14em] text-brand">Parti dalla tua situazione</p>
          <h2 id="esigenze-t" className="mt-2 font-display text-3xl font-extrabold tracking-tight text-ink sm:text-[2.1rem]">
            Di cosa hai bisogno?
          </h2>
        </div>
        <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
          {ESIGENZE.map((e) => (
            <Link
              key={e.titolo}
              href={e.href}
              style={stileTono(e.tono)}
              className="group relative overflow-hidden rounded-3xl border border-line bg-surface p-4 transition duration-300 hover:-translate-y-1 hover:shadow-[0_18px_40px_-16px_rgba(15,27,51,0.28)] sm:p-5"
            >
              <span aria-hidden="true" className="tone-soft absolute -right-8 -top-8 h-28 w-28 rounded-full transition duration-500 group-hover:scale-150" />
              <span className="tone-icon relative grid h-12 w-12 place-items-center rounded-2xl">
                <Icon name={e.icona} className="h-6 w-6" />
              </span>
              <span className="relative mt-4 block font-display text-base font-bold text-ink sm:text-lg">{e.titolo}</span>
              <span className="relative mt-1 block text-sm leading-snug text-ink-3">{e.testo}</span>
            </Link>
          ))}
        </div>
      </section>

      {/* ───────── PIÙ CERCATI ───────── */}
      <section aria-label="Bonus più cercati" className="mx-auto mt-24 max-w-6xl px-4 sm:px-6">
        <SectionHeading occhiello="In primo piano" titolo="Bonus più cercati" sottotitolo="Le misure su cui riceviamo più domande, con gli importi 2026." href="/bonus" cta="Tutti i bonus" />
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {conEvidenza.map((b) => (
            <BonusCard key={b.slug} b={b} />
          ))}
        </div>
      </section>

      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <AdSlot slot={ADSENSE_SLOTS.elenco} />
      </div>

      {/* ───────── CALCOLATORI (banda scura) ───────── */}
      <section aria-label="Calcolatori gratuiti" className="band-dark relative mt-24 overflow-hidden py-20 text-white">
        <div aria-hidden="true" className="grid-pattern pointer-events-none absolute inset-0 opacity-60" />
        <div className="relative mx-auto max-w-6xl px-4 sm:px-6">
          <SectionHeading
            chiaro
            occhiello="Strumenti gratuiti"
            titolo="Calcola in un minuto quanto ti spetta"
            sottotitolo="Parametri 2026, formule spiegate, nessuna registrazione. I dati restano sul tuo dispositivo."
            href="/calcolatori"
            cta="Tutti i calcolatori"
          />
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {CALCOLATORI.slice(0, 4).map((c) => (
              <CalcCard key={c.slug} c={c} scuro />
            ))}
          </div>
        </div>
      </section>

      {/* ───────── ESPLORA PER CATEGORIA (tab) ───────── */}
      <section aria-label="Bonus per categoria" className="mx-auto mt-24 max-w-6xl px-4 sm:px-6">
        <SectionHeading occhiello="Esplora" titolo="Bonus per famiglia, lavoro e casa" sottotitolo="Scegli una categoria per vedere tutte le misure attive." />
        <ExploreTabs tabs={tabs} />
      </section>

      {/* ───────── COME FUNZIONA ───────── */}
      <section aria-labelledby="come-t" className="mx-auto mt-24 max-w-6xl px-4 sm:px-6">
        <div className="rounded-[2rem] border border-line bg-surface p-6 sm:p-10">
          <div className="text-center">
            <p className="text-sm font-bold uppercase tracking-[0.14em] text-brand">Come funziona</p>
            <h2 id="come-t" className="mt-2 font-display text-3xl font-extrabold tracking-tight text-ink sm:text-[2.1rem]">
              Dalla domanda alla risposta in 4 passi
            </h2>
          </div>
          <ol className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {PASSI.map((p, i) => (
              <li key={p.n} className="relative">
                {i < PASSI.length - 1 && <span aria-hidden="true" className="absolute left-14 right-0 top-6 hidden border-t-2 border-dashed border-line lg:block" />}
                <span className="relative grid h-12 w-12 place-items-center rounded-2xl bg-brand text-brand-ink shadow-lg shadow-brand/30">
                  <Icon name={p.i} className="h-6 w-6" />
                </span>
                <p className="mt-4 font-display text-sm font-extrabold text-brand">{p.n}</p>
                <h3 className="mt-1 font-display text-lg font-bold text-ink">{p.t}</h3>
                <p className="mt-1.5 text-[0.95rem] leading-relaxed text-ink-2">{p.d}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* ───────── GUIDE + NOVITÀ ───────── */}
      <section aria-label="Guide e novità" className="mx-auto mt-24 max-w-6xl px-4 sm:px-6">
        <SectionHeading occhiello="Guide" titolo="Articoli aggiornati" sottotitolo="Spiegazioni semplici su ISEE, INPS, tasse e prestazioni." href="/guide" cta="Tutte le guide" />
        <div className="grid gap-5 lg:grid-cols-3">
          {guidaTop && (
            <div className="lg:col-span-2 lg:row-span-2">
              <GuideCard g={guidaTop} grande />
            </div>
          )}
          {altreGuide.slice(0, 2).map((g) => (
            <GuideCard key={g.slug} g={g} />
          ))}
        </div>

        <div className="mt-10 rounded-3xl border border-line bg-surface p-5 sm:p-6">
          <div className="flex items-center gap-3">
            <span className="grid h-10 w-10 place-items-center rounded-xl bg-accent-soft text-accent">
              <Icon name="check" className="h-5 w-5" />
            </span>
            <h3 className="font-display text-xl font-bold text-ink">Ultime novità verificate</h3>
          </div>
          <ol className="mt-4 grid grid-cols-1 gap-x-8 sm:grid-cols-2">
            {novita.map((n) => (
              <li key={n.href} className="border-t border-line first:border-t-0 sm:[&:nth-child(2)]:border-t-0">
                <Link href={n.href} style={stileTono(n.cat)} className="group flex items-center gap-3 py-3.5">
                  <span className="tone-bar h-8 w-1 shrink-0 rounded-full" aria-hidden="true" />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate font-semibold text-ink group-hover:text-brand">{n.titolo}</span>
                    <span className="block text-sm text-ink-3">
                      {n.tipo} · <time dateTime={n.data}>{formatData(n.data)}</time>
                    </span>
                  </span>
                  <Icon name="arrow" className="h-4 w-4 shrink-0 text-ink-3 transition group-hover:translate-x-0.5 group-hover:text-brand" />
                </Link>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* ───────── APP ───────── */}
      <section id="app" className="mx-auto mt-24 max-w-6xl px-4 sm:px-6">
        <AppPromo />
      </section>

      {/* ───────── FIDUCIA ───────── */}
      <section aria-label="Perché fidarsi di SBonus" className="mx-auto mt-16 max-w-6xl px-4 sm:px-6">
        <div className="grid gap-4 sm:grid-cols-3">
          {[
            { i: "book" as const, t: "Fonti ufficiali", d: "Ogni scheda cita INPS, Agenzia delle Entrate e Ministeri, con la data dell'ultimo controllo." },
            { i: "calc" as const, t: "Calcoli trasparenti", d: "Anno, parametri e ipotesi sempre visibili. L'importo ufficiale lo stabilisce l'ente." },
            { i: "info" as const, t: "Portale indipendente", d: "Non siamo un sito della Pubblica Amministrazione: le domande si fanno sui canali ufficiali." },
          ].map((x) => (
            <div key={x.t} className="flex gap-4 rounded-3xl border border-line bg-surface p-5">
              <span className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand">
                <Icon name={x.i} className="h-5 w-5" />
              </span>
              <div>
                <h3 className="font-display font-bold text-ink">{x.t}</h3>
                <p className="mt-1 text-sm leading-relaxed text-ink-2">{x.d}</p>
              </div>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
