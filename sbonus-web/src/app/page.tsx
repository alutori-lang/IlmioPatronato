import Image from "next/image";
import Link from "next/link";
import { SearchBox } from "@/components/SearchBox";
import { Bolla, BonusFeature, GuideList, NuovoBadge, SectionTitle, titoloBreve } from "@/components/Rows";
import { StoreBadges } from "@/components/AppPromo";
import { AdSlot } from "@/components/AdSlot";
import { Icon } from "@/components/Icon";
import { Wave } from "@/components/Wave";
import { bonusInEvidenza, bonusNovita, bonusPerCategoria, guidePubblicate, toLite, formatNovita, isNuovo } from "@/lib/content";
import { CATEGORIE, stileTono } from "@/lib/categories";
import { CALCOLATORI } from "@/lib/calcolatori";
import { ADSENSE_SLOTS, APP } from "@/lib/site";

const RICERCHE_RAPIDE = [
  { label: "Assegno Unico", href: "/bonus/assegno-unico-universale-2026" },
  { label: "NASpI", href: "/bonus/naspi-indennita-disoccupazione" },
  { label: "ISEE", href: "/guide/isee-2026-come-ottenerlo-dsu-precompilata" },
  { label: "Bonus bollette", href: "/bonus/bonus-sociale-bollette-luce-gas-acqua" },
];

export default function Home() {
  const categorie = CATEGORIE.map((c) => ({ c, n: bonusPerCategoria(c.slug).length })).filter((x) => x.n > 0);
  const [ultimo, ...altreNovita] = bonusNovita;
  const piuAmati = bonusInEvidenza.slice(0, 3).map(toLite);

  return (
    <>
      {/* ───── Testata blu ───── */}
      <section className="bg-blu">
        <div className="mx-auto max-w-6xl px-4 pb-14 pt-8 text-center sm:px-6 sm:pb-20 sm:pt-12">
          <h1 className="mx-auto max-w-[15ch] text-[2.6rem] font-black leading-[1.02] tracking-tight text-white text-balance sm:text-6xl lg:text-7xl">
            Scopri tutti i bonus che ti spettano!
          </h1>
          <p className="mx-auto mt-5 max-w-[42ch] text-lg font-bold text-sun-ink sm:text-xl">
            Guide, calcolatori e informazioni utili per famiglie, lavoratori e cittadini.
          </p>
          <div className="mx-auto mt-8 max-w-2xl text-left">
            <SearchBox size="lg" />
          </div>
          <nav aria-label="Ricerche frequenti" className="mt-5 flex flex-wrap justify-center gap-2">
            {RICERCHE_RAPIDE.map((r) => (
              <Link key={r.href} href={r.href} className="rounded-full bg-white/15 px-4 py-1.5 text-sm font-extrabold text-white transition hover:bg-white hover:text-blu-1">
                {r.label}
              </Link>
            ))}
          </nav>
        </div>
      </section>
      <Wave />

      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        {/* ───── Categorie a bolle ───── */}
        <nav aria-label="Categorie" className="no-scrollbar -mx-4 mt-2 flex gap-5 overflow-x-auto px-4 pb-2 sm:mx-0 sm:justify-center sm:px-0">
          {categorie.map(({ c }) => (
            <Link key={c.slug} href={`/categorie/${c.slug}`} className="group flex w-20 shrink-0 flex-col items-center gap-2 text-center sm:w-24">
              <span className="transition group-hover:-translate-y-1">
                <Bolla categoria={c.slug} size="lg" />
              </span>
              <span className="text-sm font-extrabold leading-tight text-ink">{c.nome.replace(" e disoccupazione", "").replace(" al reddito", "")}</span>
            </Link>
          ))}
        </nav>

        {/* ───── Novità: sempre in cima, come nell'app ───── */}
        {ultimo?.novita && (
          <section aria-labelledby="novita" className="mt-14">
            <SectionTitle id="novita" titolo="Le [novità] sui bonus" sottotitolo="I bonus nuovi o appena aggiornati, dal più recente." href="/bonus" cta="Tutti i bonus" />
            <div className="grid gap-4 lg:grid-cols-[1.25fr_1fr]">
              <Link
                href={`/bonus/${ultimo.slug}`}
                style={stileTono(ultimo.categoria)}
                className="group relative flex flex-col overflow-hidden rounded-[32px] border-[3px] border-ink bg-white p-6 shadow-step transition hover:-translate-y-1 sm:p-8"
              >
                <div className="flex flex-wrap items-center gap-2">
                  {isNuovo(ultimo.novita.data) && <NuovoBadge />}
                  <span className="text-sm font-extrabold text-ink-3">
                    Aggiornato {ultimo.novita.data.length === 10 ? "il" : "a"} {formatNovita(ultimo.novita.data)}
                  </span>
                </div>
                <div className="mt-5 flex items-start gap-4">
                  <Bolla categoria={ultimo.categoria} size="lg" />
                  <div className="min-w-0">
                    <h3 className="text-2xl font-black leading-tight text-ink sm:text-3xl">{titoloBreve(ultimo.titolo)}</h3>
                    <p className="mt-2 line-clamp-3 text-lg font-bold text-ink-2">{ultimo.novita.nota}</p>
                    <p className="mt-3 line-clamp-3 font-semibold leading-relaxed text-ink-3">{ultimo.descrizione}</p>
                  </div>
                </div>
                {ultimo.evidenza && (
                  <div className="mt-auto flex flex-wrap items-end justify-between gap-4 pt-8">
                    <p>
                      <span className="block text-5xl font-black tracking-tight text-coral tabular-nums">{ultimo.evidenza.valore}</span>
                      <span className="font-extrabold text-ink-3">{ultimo.evidenza.etichetta}</span>
                    </p>
                    <span className="inline-flex items-center gap-2 rounded-full bg-ink px-5 py-3 font-black text-sun transition group-hover:bg-coral group-hover:text-white">
                      Leggi la scheda <Icon name="arrow" className="h-4 w-4" />
                    </span>
                  </div>
                )}
              </Link>

              <ol className="flex flex-col gap-3">
                {altreNovita.slice(0, 4).map((b) => (
                  <li key={b.slug}>
                    <Link
                      href={`/bonus/${b.slug}`}
                      style={stileTono(b.categoria)}
                      className="group flex items-center gap-4 rounded-[24px] border-2 border-line bg-white p-4 transition hover:border-[var(--tone)]"
                    >
                      <Bolla categoria={b.categoria} />
                      <span className="min-w-0 flex-1">
                        <span className="flex flex-wrap items-center gap-2">
                          <span className="font-black text-ink">{titoloBreve(b.titolo)}</span>
                          {b.novita && isNuovo(b.novita.data) && <NuovoBadge />}
                        </span>
                        <span className="mt-0.5 line-clamp-2 text-sm font-semibold text-ink-3">{b.novita?.nota}</span>
                      </span>
                      <span className="hidden shrink-0 text-right text-xs font-extrabold text-ink-3 sm:block">{b.novita && formatNovita(b.novita.data)}</span>
                    </Link>
                  </li>
                ))}
              </ol>
            </div>
          </section>
        )}

        {/* ───── I più amati: card a colore pieno ───── */}
        <section aria-labelledby="amati" className="mt-20">
          <SectionTitle id="amati" titolo="I bonus [più amati]" sottotitolo="Quelli che le famiglie cercano di più, con gli importi 2026." />
          <div className="grid gap-4 md:grid-cols-3">
            {piuAmati.map((b) => (
              <BonusFeature key={b.slug} b={b} />
            ))}
          </div>
        </section>

        <AdSlot slot={ADSENSE_SLOTS.elenco} />

        {/* ───── Calcolatori ───── */}
        <section aria-labelledby="calcola" className="mt-20 rounded-[36px] bg-surface-2 p-6 sm:p-10">
          <div className="grid items-center gap-8 lg:grid-cols-2">
            <div>
              <h2 id="calcola" className="text-3xl font-black tracking-tight text-ink sm:text-[2.4rem]">
                Quanto ti <mark className="hl text-ink">spetta?</mark>
              </h2>
              <p className="mt-3 text-lg font-semibold text-ink-3">Calcolatori gratuiti con i parametri 2026. Senza registrarti: i dati restano sul tuo telefono.</p>
              <div className="mt-6 flex flex-wrap gap-2.5">
                {CALCOLATORI.map((c) => (
                  <Link key={c.slug} href={`/calcolatori/${c.slug}`} className="rounded-full border-2 border-ink bg-white px-4 py-2 font-extrabold text-ink transition hover:bg-ink hover:text-sun">
                    {c.titoloBreve}
                  </Link>
                ))}
              </div>
            </div>
            <Link href="/calcolatori/assegno-unico" className="block rounded-[28px] border-[3px] border-ink bg-white p-6 shadow-step transition hover:-translate-y-1">
              <p className="text-sm font-extrabold text-ink-3">Esempio · 2 figli, ISEE 25.000 €</p>
              <p className="mt-1 text-5xl font-black tracking-tight text-coral tabular-nums">332,32 €</p>
              <p className="font-extrabold text-ink-3">di Assegno Unico al mese</p>
              <p className="mt-4 flex flex-wrap gap-2 text-sm font-extrabold">
                <span className="rounded-xl bg-surface-2 px-3 py-1.5 text-ink">circa 3.988 € l&apos;anno</span>
                <span className="rounded-xl bg-surface-2 px-3 py-1.5 text-ink">parametri 2026</span>
              </p>
            </Link>
          </div>
        </section>

        {/* ───── Guide ───── */}
        <section aria-labelledby="guide" className="mt-20">
          <SectionTitle id="guide" titolo="Guide [facili]" sottotitolo="ISEE, INPS, tasse e prestazioni spiegate semplici." href="/guide" cta="Tutte le guide" />
          <GuideList guide={guidePubblicate.slice(0, 3)} />
        </section>

        {/* ───── App ───── */}
        <section aria-labelledby="app" className="mt-20 flex flex-col items-start justify-between gap-6 rounded-[36px] bg-ink p-6 text-white sm:p-10 lg:flex-row lg:items-center">
          <div className="flex items-center gap-4">
            <Image src="/img/smart-bonus-italia-icon.png" alt="" width={72} height={72} className="rounded-2xl" />
            <h2 id="app" className="text-2xl font-black tracking-tight sm:text-4xl">
              Hai già l&apos;app <mark className="hl-dark">{APP.name}</mark>?
            </h2>
          </div>
          <StoreBadges />
        </section>

        <p className="mt-10 text-center text-sm font-semibold text-ink-3">
          SBonus è un portale informativo indipendente: non è un sito della Pubblica Amministrazione e non è affiliato a INPS o
          Agenzia delle Entrate. Le domande si presentano sui canali ufficiali.
        </p>
      </div>
    </>
  );
}
