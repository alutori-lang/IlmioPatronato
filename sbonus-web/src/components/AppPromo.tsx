import Image from "next/image";
import { APP } from "@/lib/site";

export function StoreBadges({ className = "" }: { className?: string }) {
  return (
    <div className={`flex flex-wrap items-center gap-3 ${className}`}>
      <a href={APP.android} target="_blank" rel="noopener" aria-label={`Scarica ${APP.name} su Google Play`}>
        {/* Badge ufficiale Google Play, non modificato */}
        <Image src="/badges/google-play-it.png" alt="Disponibile su Google Play" width={646} height={250} className="h-[52px] w-auto" />
      </a>
      <a href={APP.ios} target="_blank" rel="noopener" aria-label={`Scarica ${APP.name} su App Store`} className="inline-block py-[8px]">
        {/* Badge ufficiale Apple, non modificato */}
        <Image src="/badges/app-store.svg" alt="Download on the App Store" width={120} height={40} unoptimized className="h-9 w-auto" />
      </a>
    </div>
  );
}

/** Riquadro sobrio di promozione dell'app, usato nelle barre laterali. */
export function AppPromo() {
  return (
    <section aria-labelledby="app-promo" className="rounded-[28px] bg-ink p-5 text-white">
      <div className="flex items-center gap-3">
        <Image src="/img/smart-bonus-italia-icon.png" alt="" width={44} height={44} className="rounded-xl" />
        <h2 id="app-promo" className="font-black leading-snug">
          {APP.name}
        </h2>
      </div>
      <p className="mt-3 text-sm font-semibold leading-relaxed text-white/80">Bonus, guide e calcolatori sul telefono. Gratis, in 12 lingue.</p>
      <StoreBadges className="mt-4 [&_a:last-child_img]:h-8 [&_img]:h-[44px]" />
    </section>
  );
}
