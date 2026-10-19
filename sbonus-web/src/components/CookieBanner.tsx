"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { ADSENSE_CLIENT } from "@/lib/site";
import { CONSENSO_OPEN_EVENT, salvaConsenso, useConsenso } from "./consent";

export function CookieBanner() {
  const consenso = useConsenso();
  const [aperto, setAperto] = useState(false);
  const [dettagli, setDettagli] = useState(false);
  const [pubblicita, setPubblicita] = useState(false);

  useEffect(() => {
    const open = () => {
      setPubblicita(Boolean(consenso?.pubblicita));
      setDettagli(true);
      setAperto(true);
    };
    window.addEventListener(CONSENSO_OPEN_EVENT, open);
    return () => window.removeEventListener(CONSENSO_OPEN_EVENT, open);
  }, [consenso]);

  // Finché non sono attivi servizi di terze parti (AdSense), il sito usa solo
  // archiviazione tecnica: il banner compare solo quando serve davvero un consenso.
  const serveConsenso = Boolean(ADSENSE_CLIENT);
  const visibile = aperto || (serveConsenso && consenso === null);
  if (!visibile) return null;

  const scegli = (pub: boolean) => {
    salvaConsenso(pub);
    setAperto(false);
  };

  return (
    <div role="dialog" aria-modal="false" aria-labelledby="cookie-title" className="fixed inset-x-0 bottom-0 z-50 p-3 sm:p-4">
      <div className="animate-rise mx-auto max-w-3xl rounded-[28px] border-[3px] border-ink bg-white p-5 shadow-step">
        <h2 id="cookie-title" className="text-lg font-bold text-ink">
          La tua privacy
        </h2>
        <p className="mt-2 text-sm leading-relaxed text-ink-2">
          Usiamo strumenti tecnici necessari al funzionamento del sito.
          {serveConsenso
            ? " Con il tuo consenso, Google AdSense può usare cookie per mostrare annunci e misurarne l'efficacia."
            : " Al momento il sito non usa cookie pubblicitari né di profilazione."}{" "}
          Dettagli nella <Link href="/cookie" className="text-brand underline">Cookie Policy</Link>.
        </p>

        {dettagli && (
          <fieldset className="mt-4 space-y-3 rounded-xl bg-surface-2 p-4 text-sm">
            <legend className="sr-only">Preferenze</legend>
            <label className="flex items-start gap-3">
              <input type="checkbox" checked disabled className="mt-0.5 h-4 w-4" />
              <span>
                <strong className="text-ink">Necessari</strong> — sempre attivi: memorizzano la tua scelta sui cookie.
              </span>
            </label>
            <label className="flex items-start gap-3">
              <input
                type="checkbox"
                checked={pubblicita}
                disabled={!serveConsenso}
                onChange={(e) => setPubblicita(e.target.checked)}
                className="mt-0.5 h-4 w-4 accent-[var(--brand)]"
              />
              <span>
                <strong className="text-ink">Pubblicità</strong> — annunci Google AdSense {serveConsenso ? "personalizzati e misurazione." : "(non attivi su questo sito)."}
              </span>
            </label>
          </fieldset>
        )}

        <div className="mt-4 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          {!dettagli ? (
            <button type="button" onClick={() => setDettagli(true)} className="rounded-xl px-4 py-2.5 text-sm font-semibold text-ink-2 hover:bg-surface-2">
              Personalizza
            </button>
          ) : (
            <button type="button" onClick={() => scegli(pubblicita)} className="rounded-xl px-4 py-2.5 text-sm font-semibold text-ink-2 hover:bg-surface-2">
              Salva preferenze
            </button>
          )}
          <button type="button" onClick={() => scegli(false)} className="rounded-xl border border-line px-4 py-2.5 text-sm font-semibold text-ink hover:bg-surface-2">
            Rifiuta
          </button>
          <button type="button" onClick={() => scegli(serveConsenso)} className="rounded-full bg-coral px-5 py-2.5 text-sm font-black text-white hover:bg-coral-2">
            Accetta
          </button>
        </div>
      </div>
    </div>
  );
}
