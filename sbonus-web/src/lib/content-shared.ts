// Tipi e utilità condivisi, senza dati: importabili anche dai componenti client.

export type Fonte = { label: string; url: string };
export type Faq = { q: string; a: string };
export type StatoBonus = "attivo" | "scaduto" | "in-attesa" | "da-verificare";

export type Bonus = {
  slug: string;
  titolo: string;
  descrizione: string;
  intro: string;
  categoria: string;
  ente: string;
  stato: StatoBonus;
  pubblicato: boolean;
  verificato: boolean;
  ultimoControllo: string | null;
  aggiornatoIl: string | null;
  aChiSpetta: string[];
  requisiti: string[];
  importi: string[];
  comeFare: string[];
  documenti: string[];
  scadenze: string;
  faq: Faq[];
  fonti: Fonte[];
  tags: string[];
};

export type BonusLite = Pick<Bonus, "slug" | "titolo" | "descrizione" | "categoria" | "stato" | "ente" | "tags">;

export const toLite = (b: Bonus): BonusLite => ({
  slug: b.slug,
  titolo: b.titolo,
  descrizione: b.descrizione,
  categoria: b.categoria,
  stato: b.stato,
  ente: b.ente,
  tags: b.tags,
});

export type Guida = {
  slug: string;
  titolo: string;
  titoloSeo: string;
  descrizione: string;
  categoria: string;
  pubblicato: boolean;
  dataPubblicazione: string | null;
  dataAggiornamento: string | null;
  autore: string;
  fonti: Fonte[];
  faq: Faq[];
  correlati: string[];
  tags: string[];
  html: string;
  testo: string;
};

export const STATO_LABEL: Record<StatoBonus, string> = {
  attivo: "Attivo",
  scaduto: "Scaduto",
  "in-attesa": "In attesa di attuazione",
  "da-verificare": "Da verificare",
};

export function formatData(iso: string | null | undefined) {
  if (!iso) return "";
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d)).toLocaleDateString("it-IT", { day: "numeric", month: "long", year: "numeric", timeZone: "UTC" });
}
