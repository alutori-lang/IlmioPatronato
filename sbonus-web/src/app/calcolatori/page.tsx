import type { Metadata } from "next";
import { Breadcrumbs } from "@/components/Breadcrumbs";
import { CalcCard } from "@/components/Cards";
import { CALCOLATORI } from "@/lib/calcolatori";
import { PARAMS } from "@/lib/calc/params";

export const metadata: Metadata = {
  title: "Calcolatori gratuiti 2026: NASpI, Assegno Unico, stipendio netto, IRPEF",
  description: "Simulatori gratuiti con i parametri 2026: NASpI, Assegno Unico, stipendio netto, IRPEF, TFR, rata del mutuo e risparmio familiare.",
  alternates: { canonical: "/calcolatori" },
};

export default function CalcolatoriIndex() {
  return (
    <div className="mx-auto max-w-6xl px-4 pt-6 sm:px-6">
      <Breadcrumbs items={[{ label: "Calcolatori", href: "/calcolatori" }]} />
      <header className="mt-6 max-w-3xl">
        <h1 className="font-display text-3xl font-extrabold tracking-tight text-ink sm:text-4xl">Calcolatori gratuiti</h1>
        <p className="mt-3 text-lg text-ink-2">
          Strumenti per stimare importi e costi con i parametri {PARAMS.anno}. Ogni calcolatore spiega le formule, le ipotesi e
          le fonti usate. I calcoli avvengono nel tuo browser: nessun dato viene inviato.
        </p>
      </header>
      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {CALCOLATORI.map((c) => (
          <CalcCard key={c.slug} c={c} />
        ))}
      </div>
    </div>
  );
}
