import type { Metadata } from "next";
import { Breadcrumbs } from "@/components/Breadcrumbs";
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
    <div className="mx-auto max-w-6xl px-4 pt-6 sm:px-6">
      <Breadcrumbs items={[{ label: "Bonus", href: "/bonus" }]} />
      <header className="mt-6 max-w-3xl">
        <h1 className="font-display text-3xl font-extrabold tracking-tight text-ink sm:text-4xl">Bonus e agevolazioni 2026</h1>
        <p className="mt-3 text-lg text-ink-2">
          Ogni scheda riporta requisiti, importi e modalità di domanda controllati sulle fonti ufficiali, con la data dell&apos;ultimo
          controllo. Le misure scadute restano visibili, chiaramente segnalate.
        </p>
      </header>
      <BonusFilter bonus={bonusPubblicati.map(toLite)} categorie={categorie} />
    </div>
  );
}
