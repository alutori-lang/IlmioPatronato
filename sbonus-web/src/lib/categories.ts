import type React from "react";
import raw from "../../content/categorie.json";

export type Categoria = {
  slug: string;
  nome: string;
  descrizione: string;
  icona: IconName;
};

export type IconName =
  | "family"
  | "work"
  | "home"
  | "elderly"
  | "inps"
  | "tax"
  | "isee"
  | "school"
  | "health"
  | "support"
  | "map"
  | "calc"
  | "search"
  | "book"
  | "phone"
  | "euro";

// Elenco modificabile da /admin (content/categorie.json).
export const CATEGORIE: Categoria[] = (raw.categorie as Categoria[]).filter((c) => c.slug && c.nome);

export const getCategoria = (slug: string) => CATEGORIE.find((c) => c.slug === slug);

// Colore pieno di ogni categoria (stile "Sole"). Scelti scuri abbastanza da
// reggere il testo bianco in grassetto sopra.
const TONI: Record<string, string> = {
  famiglia: "#e0402a",
  lavoro: "#3b5bdb",
  casa: "#c75100",
  sostegno: "#1f8a5b",
  pensioni: "#7b45cc",
  isee: "#0b7a8c",
  fisco: "#1d1b2f",
  inps: "#4c3fc4",
  salute: "#c2255c",
  studenti: "#8a3ffc",
  regionali: "#0f7b6c",
};

export const tonoCategoria = (slug: string) => TONI[slug] ?? "#3b5bdb";

/** Variabili CSS --tone (pieno) e --tone-soft (sfondo tenue) per una categoria. */
export const stileTono = (slug: string) =>
  ({
    "--tone": tonoCategoria(slug),
    "--tone-soft": `color-mix(in srgb, ${tonoCategoria(slug)} 12%, white)`,
  }) as React.CSSProperties;
