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
