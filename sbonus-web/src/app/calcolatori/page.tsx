import type { Metadata } from "next";
import { PageHero } from "@/components/PageHero";
import { CalcList } from "@/components/Rows";
import { CALCOLATORI } from "@/lib/calcolatori";
import { PARAMS } from "@/lib/calc/params";

export const metadata: Metadata = {
  title: "Calcolatori gratuiti 2026: NASpI, Assegno Unico, stipendio netto, IRPEF",
  description: "Simulatori gratuiti con i parametri 2026: NASpI, Assegno Unico, stipendio netto, IRPEF, TFR, rata del mutuo e risparmio familiare.",
  alternates: { canonical: "/calcolatori" },
};

export default function CalcolatoriIndex() {
  return (
    <>
      <PageHero
        crumbs={[{ label: "Calcolatori", href: "/calcolatori" }]}
        occhiello="Strumenti gratuiti"
        titolo="Calcolatori gratuiti"
        intro={`Stima importi e costi con i parametri ${PARAMS.anno}. Ogni calcolatore spiega formule, ipotesi e fonti. I calcoli avvengono nel tuo browser: nessun dato viene inviato.`}
        icona="calc"
      />
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
      <div className="mt-10">
        <CalcList calcolatori={CALCOLATORI} />
      </div>
      </div>
    </>
  );
}
