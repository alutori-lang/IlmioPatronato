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

// Colore di ogni categoria: usato per icone, accenti e sfondi tenui.
// Le tinte sono sufficientemente sature per funzionare sia in chiaro sia in scuro.
const TONI: Record<string, string> = {
  famiglia: "#e11d48",
  lavoro: "#2563eb",
  casa: "#ea580c",
  sostegno: "#059669",
  pensioni: "#7c3aed",
  isee: "#0891b2",
  fisco: "#d97706",
  inps: "#4f46e5",
  salute: "#dc2626",
  studenti: "#9333ea",
  regionali: "#0d9488",
};

export const tonoCategoria = (slug: string) => TONI[slug] ?? "#1d4fd8";

/** Variabili CSS da applicare con style={...}: --tone (pieno) e --tone-soft (sfondo tenue). */
export const stileTono = (slug: string) =>
  ({
    "--tone": tonoCategoria(slug),
    "--tone-soft": `color-mix(in srgb, ${tonoCategoria(slug)} 12%, transparent)`,
  }) as React.CSSProperties;
