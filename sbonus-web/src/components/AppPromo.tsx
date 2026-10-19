import Image from "next/image";
import { APP } from "@/lib/site";
import { Icon } from "./Icon";

// Funzioni riportate dalla scheda ufficiale App Store / Google Play.
const FUNZIONI = [
  "Schede su bonus e agevolazioni",
  "14 calcolatori: ISEE, NASpI, stipendio, IRPEF…",
  "Guide su permessi, ricongiungimento, cittadinanza",
  "Assistente AI per orientarsi tra le pratiche",
  "12 lingue, nessuna registrazione obbligatoria",
];

export function StoreBadges({ className = "" }: { className?: string }) {
  return (
    <div className={`flex flex-wrap items-center gap-3 ${className}`}>
      <a href={APP.android} target="_blank" rel="noopener" aria-label={`Scarica ${APP.name} su Google Play`} className="transition hover:scale-[1.03]">
        {/* Badge ufficiale Google Play, non modificato */}
        <Image src="/badges/google-play-it.png" alt="Disponibile su Google Play" width={646} height={250} className="h-[58px] w-auto" />
      </a>
      <a href={APP.ios} target="_blank" rel="noopener" aria-label={`Scarica ${APP.name} su App Store`} className="inline-block py-[9px] transition hover:scale-[1.03]">
        {/* Badge ufficiale Apple, non modificato */}
        <Image src="/badges/app-store.svg" alt="Download on the App Store" width={120} height={40} unoptimized className="h-10 w-auto" />
      </a>
    </div>
  );
}

function Telefono({ src, alt, className = "" }: { src: string; alt: string; className?: string }) {
  return (
    <div className={`rounded-[2.6rem] bg-[#0b1020] p-2.5 shadow-[0_40px_80px_-24px_rgba(0,0,0,0.6)] ring-1 ring-white/15 ${className}`}>
      <Image src={src} alt={alt} width={660} height={1434} sizes="240px" className="rounded-[2.1rem]" />
    </div>
  );
}

export function AppPromo({ compatto = false }: { compatto?: boolean }) {
  if (compatto) {
    return (
      <section aria-labelledby="app-promo-c" className="hero-bg relative overflow-hidden rounded-3xl p-6 text-white">
        <div aria-hidden="true" className="grid-pattern pointer-events-none absolute inset-0" />
        <div className="relative">
          <Image src="/img/smart-bonus-italia-icon.png" alt="" width={64} height={64} className="rounded-2xl shadow-lg ring-2 ring-white/30" />
          <h2 id="app-promo-c" className="mt-4 font-display text-xl font-extrabold leading-tight">
            Porta {APP.name} sempre con te
          </h2>
          <p className="mt-2 text-sm text-white/80">Bonus, guide e calcolatori sul telefono. Gratis, in 12 lingue.</p>
          <StoreBadges className="mt-4 [&_img]:h-[46px] [&_a:last-child_img]:h-8" />
        </div>
      </section>
    );
  }
  return (
    <section aria-labelledby="app-promo-title" className="hero-bg relative overflow-hidden rounded-[2rem] text-white">
      <div aria-hidden="true" className="grid-pattern pointer-events-none absolute inset-0" />
      <div className="relative grid items-center gap-10 p-6 sm:p-12 lg:grid-cols-[1.1fr_1fr]">
        <div>
          <div className="flex items-center gap-3">
            <Image src="/img/smart-bonus-italia-icon.png" alt="" width={56} height={56} className="rounded-2xl shadow-lg ring-2 ring-white/30" />
            <p className="text-sm font-bold uppercase tracking-[0.14em] text-[#7df3c4]">App gratuita · Android e iPhone</p>
          </div>
          <h2 id="app-promo-title" className="mt-5 font-display text-3xl font-extrabold leading-tight sm:text-[2.6rem]">
            Porta {APP.name} sempre con te
          </h2>
          <p className="mt-3 max-w-xl text-lg text-white/80">
            Bonus, guide e calcolatori in tasca, anche quando sei in fila allo sportello. Gratuita, con acquisto facoltativo per
            togliere la pubblicità.
          </p>
          <ul className="mt-6 grid gap-2.5 sm:grid-cols-2">
            {FUNZIONI.map((f) => (
              <li key={f} className="flex items-start gap-2.5 text-[0.95rem]">
                <span className="mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-full bg-[#3ee0a1] text-[#0b1d5c]">
                  <Icon name="check" className="h-3.5 w-3.5" />
                </span>
                <span className="text-white/90">{f}</span>
              </li>
            ))}
          </ul>
          <StoreBadges className="mt-8" />
        </div>
        <div aria-hidden="true" className="relative mx-auto h-[380px] w-full max-w-[420px] sm:h-[460px]">
          <div className="absolute left-1/2 top-1/2 h-72 w-72 -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#3ee0a1]/25 blur-3xl" />
          <Telefono src="/img/app/app-strumenti.png" alt="" className="absolute left-0 top-10 w-[46%] -rotate-6 opacity-90 sm:w-[48%]" />
          <Telefono src="/img/app/app-assistente.png" alt="" className="absolute right-2 top-0 w-[50%] rotate-3 sm:w-[52%]" />
        </div>
      </div>
    </section>
  );
}
