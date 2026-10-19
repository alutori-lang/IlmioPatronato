"use client";

import { useEffect, useRef } from "react";
import { ADSENSE_CLIENT } from "@/lib/site";
import { useConsenso } from "./consent";

declare global {
  interface Window {
    adsbygoogle?: unknown[];
  }
}

let scriptInserito = false;
function caricaScript() {
  if (scriptInserito || !ADSENSE_CLIENT) return;
  scriptInserito = true;
  const s = document.createElement("script");
  s.async = true;
  s.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${encodeURIComponent(ADSENSE_CLIENT)}`;
  s.crossOrigin = "anonymous";
  document.head.appendChild(s);
}

/**
 * Spazio pubblicitario non invasivo. Non mostra nulla (né segnaposto né annunci
 * finti) finché non sono configurati il publisher ID e lo slot reale, e
 * finché l'utente non ha dato il consenso alla pubblicità.
 *
 * Nota: nello SEE Google richiede una CMP certificata IAB TCF per gli annunci
 * personalizzati. Prima di attivare AdSense configurare il messaggio "Privacy e
 * messaggi" di AdSense (vedi README).
 */
export function AdSlot({ slot, className = "" }: { slot?: string; className?: string }) {
  const consenso = useConsenso();
  const ref = useRef<HTMLModElement>(null);
  const attivo = Boolean(ADSENSE_CLIENT && slot && consenso?.pubblicita);

  useEffect(() => {
    if (!attivo || !ref.current || ref.current.dataset.caricato) return;
    caricaScript();
    ref.current.dataset.caricato = "1";
    (window.adsbygoogle = window.adsbygoogle || []).push({});
  }, [attivo]);

  if (!attivo) return null;
  return (
    <aside aria-label="Pubblicità" className={`my-8 ${className}`}>
      <p className="mb-1 text-center text-[0.7rem] uppercase tracking-wider text-ink-3">Pubblicità</p>
      <ins
        ref={ref}
        className="adsbygoogle block min-h-[100px]"
        data-ad-client={ADSENSE_CLIENT}
        data-ad-slot={slot}
        data-ad-format="auto"
        data-full-width-responsive="true"
      />
    </aside>
  );
}
