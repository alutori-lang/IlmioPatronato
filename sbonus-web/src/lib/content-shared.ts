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
  /** Cifra chiave mostrata in grande sulle card (es. "203,80 €" + "al mese per figlio"). */
  evidenza: { valore: string; etichetta: string } | null;
  /** Ultima novità ufficiale sulla misura: data AAAA-MM o AAAA-MM-GG e cosa è cambiato. */
  novita: { data: string; nota: string } | null;
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

export type BonusLite = Pick<Bonus, "slug" | "titolo" | "descrizione" | "categoria" | "stato" | "ente" | "tags" | "evidenza" | "novita">;

export const toLite = (b: Bonus): BonusLite => ({
  slug: b.slug,
  titolo: b.titolo,
  descrizione: b.descrizione,
  categoria: b.categoria,
  stato: b.stato,
  ente: b.ente,
  tags: b.tags,
  evidenza: b.evidenza,
  novita: b.novita,
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

/** "2026-09" → "settembre 2026"; "2026-03-27" → "27 marzo 2026". */
export function formatNovita(d: string) {
  if (d.length === 10) return formatData(d);
  const [y, m] = d.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, 1)).toLocaleDateString("it-IT", { month: "long", year: "numeric", timeZone: "UTC" });
}

/** "Nuovo" se la novità è degli ultimi 90 giorni rispetto a oggi (data della build). */
export function isNuovo(d: string, oggi = new Date()) {
  const t = Date.parse(d.length === 7 ? `${d}-01` : d);
  return Number.isFinite(t) && oggi.getTime() - t <= 90 * 24 * 3600 * 1000;
}
