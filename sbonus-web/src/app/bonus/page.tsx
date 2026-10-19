import type { Metadata } from "next";
import { PageHero } from "@/components/PageHero";
import { BonusFilter } from "@/components/BonusFilter";
import { bonusPubblicati, toLite } from "@/lib/content";
import { CATEGORIE } from "@/lib/categories";

export const metadata: Metadata = {
  title: "Tutti i bonus e le agevolazioni 2026",
  description: "Elenco dei bonus e delle agevolazioni attive in Italia: requisiti, importi, come fare domanda e fonti ufficiali, con filtri per categoria.",
  alternates: { canonical: "/bonus" },
};

export default function BonusIndex() {
  const categorie = CATEGORIE.filter((c) => bonusPubblicati.some((b) => b.categoria === c.slug)).map((c) => ({ slug: c.slug, nome: c.nome }));
  return (
    <>
      <PageHero
        crumbs={[{ label: "Bonus", href: "/bonus" }]}
        occhiello="Schede verificate"
        titolo="Bonus e agevolazioni 2026"
        intro="Requisiti, importi e modalità di domanda controllati sulle fonti ufficiali, con la data dell'ultimo controllo. Le misure scadute restano visibili, chiaramente segnalate."
        icona="euro"
      />
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <BonusFilter bonus={bonusPubblicati.map(toLite)} categorie={categorie} />
      </div>
    </>
  );
}
