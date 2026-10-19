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
    <div className="mx-auto max-w-6xl px-4 pt-6 sm:px-6">
      <Breadcrumbs items={[{ label: "App", href: "/app" }]} />
      <section className="mt-6 grid items-center gap-10 lg:grid-cols-[1.2fr_1fr]">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wider text-accent">Gratis per Android e iPhone</p>
          <h1 className="mt-2 font-display text-4xl font-extrabold leading-tight tracking-tight text-ink sm:text-5xl">{APP.name}</h1>
          <p className="mt-4 text-lg leading-relaxed text-ink-2">
            L&apos;app di SBonus per avere bonus, ISEE, NASpI e guide sempre a portata di mano. Senza registrazione obbligatoria,
            con i documenti elaborati sul tuo telefono.
          </p>
          <StoreBadges className="mt-6" />
          <p className="mt-4 text-sm text-ink-3">
            Gratuita con pubblicità. Acquisto facoltativo «Premium PRO» per rimuovere gli annunci e usare l&apos;assistente senza
            limiti.
          </p>
        </div>
        <div className="mx-auto w-full max-w-xs">
          <Image src="/img/smart-bonus-italia-icon.png" alt={`Icona dell'app ${APP.name}`} width={512} height={512} priority className="rounded-[2.5rem] shadow-2xl" />
        </div>
      </section>

      <section aria-labelledby="funzioni" className="mt-16">
        <h2 id="funzioni" className="font-display text-2xl font-extrabold text-ink sm:text-3xl">
          Cosa trovi nell&apos;app
        </h2>
        <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {FUNZIONI.map((f) => (
            <div key={f.t} className="rounded-2xl border border-line bg-surface p-5">
              <Icon name={f.i} className="h-6 w-6 text-brand" />
              <h3 className="mt-3 font-semibold text-ink">{f.t}</h3>
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
  );
}
