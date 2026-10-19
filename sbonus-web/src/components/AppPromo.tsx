import Image from "next/image";
import { APP } from "@/lib/site";
import { Icon } from "./Icon";

// Funzioni riportate dalla scheda ufficiale App Store / Google Play.
const FUNZIONI = [
  "Schede su bonus e agevolazioni",
  "14 calcolatori: ISEE, NASpI, stipendio netto, IRPEF e altri",
  "Guide passo passo su permessi, ricongiungimento e cittadinanza",
  "Assistente AI per orientarsi tra le pratiche",
  "Disponibile in 12 lingue, senza registrazione obbligatoria",
];

export function StoreBadges({ className = "" }: { className?: string }) {
  return (
    <div className={`flex flex-wrap items-center gap-3 ${className}`}>
      <a href={APP.android} target="_blank" rel="noopener" aria-label={`Scarica ${APP.name} su Google Play`}>
        {/* Badge ufficiale Google Play, non modificato */}
        <Image src="/badges/google-play-it.png" alt="Disponibile su Google Play" width={646} height={250} className="h-[58px] w-auto" />
      </a>
      <a href={APP.ios} target="_blank" rel="noopener" aria-label={`Scarica ${APP.name} su App Store`} className="inline-block py-[9px]">
        {/* Badge ufficiale Apple, non modificato */}
        <Image src="/badges/app-store.svg" alt="Download on the App Store" width={120} height={40} unoptimized className="h-10 w-auto" />
      </a>
    </div>
  );
}

export function AppPromo({ compatto = false }: { compatto?: boolean }) {
  return (
    <section aria-labelledby="app-promo-title" className="overflow-hidden rounded-3xl bg-gradient-to-br from-[#143aa6] via-[#1d4fd8] to-[#2a6af0] text-white">
      <div className={`grid items-center gap-8 p-6 sm:p-10 ${compatto ? "" : "lg:grid-cols-[1.3fr_1fr]"}`}>
        <div>
          <p className="text-sm font-semibold uppercase tracking-wider text-[#9ff0cf]">App gratuita</p>
          <h2 id="app-promo-title" className="mt-2 font-display text-3xl font-extrabold leading-tight sm:text-4xl">
            Porta {APP.name} sempre con te
          </h2>
          <p className="mt-3 max-w-xl text-white/85">
            Bonus, guide e calcolatori in tasca, anche quando sei in fila allo sportello. L&apos;app è gratuita, con acquisto
            facoltativo per rimuovere la pubblicità.
          </p>
          {!compatto && (
            <ul className="mt-5 grid gap-2 text-[0.95rem] sm:grid-cols-2">
              {FUNZIONI.map((f) => (
                <li key={f} className="flex items-start gap-2">
                  <Icon name="check" className="mt-0.5 h-5 w-5 shrink-0 text-[#6ff0bb]" />
                  <span className="text-white/90">{f}</span>
                </li>
              ))}
            </ul>
          )}
          <StoreBadges className="mt-6" />
        </div>
        {!compatto && (
          <div className="relative mx-auto hidden w-full max-w-[260px] lg:block">
            <div className="rotate-3 rounded-[2.5rem] bg-white/10 p-4 shadow-2xl ring-1 ring-white/20">
              <Image
                src="/img/smart-bonus-italia-icon.png"
                alt={`Icona dell'app ${APP.name}`}
                width={512}
                height={512}
                className="rounded-[2rem]"
              />
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
