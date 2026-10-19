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
      <section className="bg-sun">
        <div className="mx-auto max-w-6xl px-4 pb-16 pt-8 sm:px-6">
          <Breadcrumbs items={[{ label: "App", href: "/app" }]} />
          <div className="mt-10 grid items-center gap-12 lg:grid-cols-[1.2fr_1fr]">
            <div>
              <Image src="/img/smart-bonus-italia-icon.png" alt="" width={72} height={72} priority className="rounded-2xl" />
              <h1 className="mt-6 text-4xl font-black tracking-tight text-ink sm:text-6xl">{APP.name}</h1>
              <p className="mt-4 max-w-xl text-lg font-bold leading-relaxed text-sun-ink">
                L&apos;app di SBonus per avere bonus, ISEE, NASpI e guide sempre a portata di mano. Gratuita per Android e iPhone,
                senza registrazione obbligatoria.
              </p>
              <StoreBadges className="mt-7" />
              <p className="mt-4 text-sm font-semibold text-sun-ink">
                Gratuita con pubblicità. Acquisto facoltativo «Premium PRO» per rimuovere gli annunci e usare l&apos;assistente
                senza limiti.
              </p>
            </div>
            <div aria-hidden="true" className="mx-auto flex w-full max-w-[400px] justify-center gap-4">
              <div className="mt-10 w-1/2 rounded-[2.2rem] bg-ink p-2">
                <Image src="/img/app/app-strumenti.png" alt="" width={660} height={1434} sizes="200px" priority className="rounded-[1.8rem]" />
              </div>
              <div className="w-1/2 rounded-[2.2rem] bg-ink p-2">
                <Image src="/img/app/app-assistente.png" alt="" width={660} height={1434} sizes="200px" priority className="rounded-[1.8rem]" />
              </div>
            </div>
          </div>
        </div>
      </section>
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
      <section aria-labelledby="funzioni" className="mt-16">
        <h2 id="funzioni" className="mt-6 text-3xl font-black tracking-tight text-ink">
          Cosa trovi nell&apos;app
        </h2>
        <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {FUNZIONI.map((f) => (
            <div key={f.t} className="rounded-[28px] bg-surface-2 p-6">
              <span className="grid h-12 w-12 place-items-center rounded-full bg-coral text-white">
                <Icon name={f.i} className="h-6 w-6" />
              </span>
              <h3 className="mt-4 text-lg font-black text-ink">{f.t}</h3>
              <p className="mt-1.5 text-sm leading-relaxed text-ink-2">{f.d}</p>
            </div>
          ))}
        </div>
      </section>

      <p className="mt-12 flex gap-2.5 rounded-[24px] bg-surface-2 p-5 text-sm font-semibold leading-relaxed text-ink-3">
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
