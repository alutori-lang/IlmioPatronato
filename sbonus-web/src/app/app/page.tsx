import type { Metadata } from "next";
import Image from "next/image";
import { Breadcrumbs } from "@/components/Breadcrumbs";
import { StoreBadges } from "@/components/AppPromo";
import { JsonLd } from "@/components/JsonLd";
import { Icon } from "@/components/Icon";
import { APP, absoluteUrl } from "@/lib/site";

export const metadata: Metadata = {
  title: `App ${APP.name}: bonus, ISEE e NASpI sul telefono`,
  description: `Scarica gratis ${APP.name} per Android e iPhone: schede sui bonus, 14 calcolatori, guide passo passo e assistente AI, in 12 lingue.`,
  alternates: { canonical: "/app" },
};

// Contenuti ripresi dalle schede ufficiali di App Store e Google Play.
const FUNZIONI = [
  { t: "Bonus e agevolazioni", d: "53 schede informative su bonus, sostegni e prestazioni.", i: "book" as const },
  { t: "14 calcolatori", d: "ISEE, stipendio netto, IRPEF e 730, NASpI, Assegno Unico, IMU, TFR, bollo auto, rata del mutuo e altri.", i: "calc" as const },
  { t: "Guide passo passo", d: "18 guide su permessi di soggiorno, ricongiungimento familiare e cittadinanza.", i: "map" as const },
  { t: "Assistente AI", d: "Una chat basata su Google Gemini per orientarsi tra pratiche e documenti.", i: "support" as const },
  { t: "Strumenti utili", d: "Quiz per la cittadinanza, CV Europass, lettura della busta paga e portafoglio documenti sul telefono.", i: "tax" as const },
  { t: "12 lingue", d: "Italiano, inglese, arabo, albanese, rumeno, cinese, bengalese, urdu, ucraino, francese, hindi e punjabi.", i: "phone" as const },
];

export default function AppPage() {
  return (
    <>
      <section className="hero-bg relative overflow-hidden text-white">
        <div aria-hidden="true" className="grid-pattern pointer-events-none absolute inset-0" />
        <div className="relative mx-auto max-w-6xl px-4 pb-16 pt-6 sm:px-6">
          <Breadcrumbs items={[{ label: "App", href: "/app" }]} chiaro />
          <div className="mt-8 grid items-center gap-10 lg:grid-cols-[1.15fr_1fr]">
            <div>
              <div className="flex items-center gap-3">
                <Image src="/img/smart-bonus-italia-icon.png" alt="" width={64} height={64} priority className="rounded-2xl shadow-lg ring-2 ring-white/30" />
                <p className="text-sm font-bold uppercase tracking-[0.14em] text-[#7df3c4]">Gratis per Android e iPhone</p>
              </div>
              <h1 className="mt-5 font-display text-4xl font-extrabold leading-tight tracking-tight sm:text-6xl">{APP.name}</h1>
              <p className="mt-4 max-w-xl text-lg leading-relaxed text-white/80">
                L&apos;app di SBonus per avere bonus, ISEE, NASpI e guide sempre a portata di mano. Senza registrazione
                obbligatoria, con i documenti elaborati sul tuo telefono.
              </p>
              <StoreBadges className="mt-7" />
              <p className="mt-4 text-sm text-white/65">
                Gratuita con pubblicità. Acquisto facoltativo «Premium PRO» per rimuovere gli annunci e usare l&apos;assistente
                senza limiti.
              </p>
            </div>
            <div aria-hidden="true" className="relative mx-auto h-[420px] w-full max-w-[420px] sm:h-[500px]">
              <div className="absolute left-1/2 top-1/2 h-72 w-72 -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#3ee0a1]/25 blur-3xl" />
              <div className="absolute left-0 top-12 w-[48%] -rotate-6 rounded-[2.6rem] bg-[#0b1020] p-2.5 shadow-2xl ring-1 ring-white/15">
                <Image src="/img/app/app-strumenti.png" alt="" width={660} height={1434} sizes="220px" priority className="rounded-[2.1rem]" />
              </div>
              <div className="absolute right-2 top-0 w-[52%] rotate-3 rounded-[2.6rem] bg-[#0b1020] p-2.5 shadow-2xl ring-1 ring-white/15">
                <Image src="/img/app/app-assistente.png" alt="" width={660} height={1434} sizes="240px" priority className="rounded-[2.1rem]" />
              </div>
            </div>
          </div>
        </div>
      </section>
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
      <section aria-labelledby="funzioni" className="mt-16">
        <h2 id="funzioni" className="font-display text-2xl font-extrabold text-ink sm:text-3xl">
          Cosa trovi nell&apos;app
        </h2>
        <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {FUNZIONI.map((f) => (
            <div key={f.t} className="rounded-3xl border border-line bg-surface p-5 transition hover:-translate-y-0.5 hover:shadow-lg">
              <span className="grid h-12 w-12 place-items-center rounded-2xl bg-brand text-brand-ink shadow-lg shadow-brand/25">
                <Icon name={f.i} className="h-6 w-6" />
              </span>
              <h3 className="mt-4 font-display text-lg font-bold text-ink">{f.t}</h3>
              <p className="mt-1.5 text-sm leading-relaxed text-ink-2">{f.d}</p>
            </div>
          ))}
        </div>
      </section>

      <p className="mt-10 flex gap-2.5 rounded-2xl border border-line p-4 text-sm leading-relaxed text-ink-3">
        <Icon name="info" className="mt-0.5 h-4 w-4 shrink-0" />
        {APP.name} non è un servizio governativo e non è affiliata a INPS, Agenzia delle Entrate, CAF o sindacati. I calcolatori
        forniscono stime senza valore legale: le domande vanno presentate sui canali ufficiali.
      </p>

      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "MobileApplication",
          name: APP.name,
          operatingSystem: "Android, iOS",
          applicationCategory: "FinanceApplication",
          inLanguage: "it-IT",
          url: absoluteUrl("/app"),
          downloadUrl: [APP.android, APP.ios],
          offers: { "@type": "Offer", price: "0", priceCurrency: "EUR" },
        }}
      />
      </div>
    </>
  );
}
