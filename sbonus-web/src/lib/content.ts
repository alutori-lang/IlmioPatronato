import data from "@/generated/content.json";

import type { Bonus, Guida, StatoBonus } from "./content-shared";

export * from "./content-shared";

const all = data as { bonus: Bonus[]; guide: Guida[] };

// In produzione si vedono solo i contenuti pubblicati. Le bozze restano nel
// repository e nel pannello /admin finché la redazione non le verifica.
const statoOrdine: Record<StatoBonus, number> = { attivo: 0, "in-attesa": 1, "da-verificare": 2, scaduto: 3 };

export const bonusPubblicati: Bonus[] = all.bonus
  .filter((b) => b.pubblicato)
  .sort((a, b) => statoOrdine[a.stato] - statoOrdine[b.stato] || a.titolo.localeCompare(b.titolo, "it"));

export const guidePubblicate: Guida[] = all.guide
  .filter((g) => g.pubblicato)
  .sort((a, b) => (b.dataAggiornamento ?? "").localeCompare(a.dataAggiornamento ?? ""));

export const getBonus = (slug: string) => bonusPubblicati.find((b) => b.slug === slug);
export const getGuida = (slug: string) => guidePubblicate.find((g) => g.slug === slug);

export const bonusPerCategoria = (cat: string) => bonusPubblicati.filter((b) => b.categoria === cat);
export const guidePerCategoria = (cat: string) => guidePubblicate.filter((g) => g.categoria === cat);

/** Bonus più consultati: selezione editoriale, filtrata su quelli pubblicati. */
const IN_EVIDENZA = [
  "assegno-unico-universale-2026",
  "naspi-indennita-disoccupazione",
  "assegno-di-inclusione-adi",
  "bonus-asilo-nido-2026",
  "bonus-sociale-bollette-luce-gas-acqua",
  "bonus-nuovi-nati-2026",
  "carta-dedicata-a-te",
  "bonus-ristrutturazione-2026",
];
export const bonusInEvidenza = IN_EVIDENZA.map(getBonus).filter((b): b is Bonus => Boolean(b));

/** Novità in ordine dal più recente: come in app, i nuovi bonus stanno sempre in cima. */
export const bonusNovita = bonusPubblicati
  .filter((b) => b.novita)
  .sort((a, b) => (b.novita!.data.padEnd(10, "-00")).localeCompare(a.novita!.data.padEnd(10, "-00")));
