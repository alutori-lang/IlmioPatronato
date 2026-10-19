// Ricerca interna: indice costruito a build time, eseguito nel browser.
// Nessuna richiesta a servizi esterni, nessun dato inviato.

export type TipoRisultato = "bonus" | "guida" | "calcolatore" | "categoria" | "faq";

export type Documento = {
  tipo: TipoRisultato;
  titolo: string;
  url: string;
  sommario: string;
  categoria?: string;
  /** Testo su cui cercare, già normalizzato. */
  testo: string;
  /** Titolo normalizzato, per dare più peso alle corrispondenze nel titolo. */
  chiave: string;
};

export function normalizza(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9€]+/g, " ")
    .trim();
}

const STOP = new Set(["il", "lo", "la", "i", "gli", "le", "di", "a", "da", "in", "con", "su", "per", "tra", "fra", "e", "o", "un", "una", "del", "della", "dei", "delle", "al", "alla", "come", "cosa", "che"]);

export function tokens(q: string): string[] {
  return normalizza(q)
    .split(" ")
    .filter((t) => t.length > 1 && !STOP.has(t));
}

export function cerca(indice: Documento[], query: string, limite = 50): Documento[] {
  const tk = tokens(query);
  if (tk.length === 0) return [];
  const punteggi: { d: Documento; p: number }[] = [];
  for (const d of indice) {
    let p = 0;
    let tutti = true;
    for (const t of tk) {
      const inTitolo = d.chiave.includes(t);
      const inTesto = inTitolo || d.testo.includes(t);
      if (!inTesto) {
        tutti = false;
        break;
      }
      p += inTitolo ? 10 : 1;
      if (new RegExp(`(^| )${t}`).test(d.chiave)) p += 5;
    }
    if (!tutti) continue;
    if (d.tipo === "calcolatore" || d.tipo === "bonus") p += 2;
    punteggi.push({ d, p });
  }
  return punteggi
    .sort((a, b) => b.p - a.p || a.d.titolo.localeCompare(b.d.titolo, "it"))
    .slice(0, limite)
    .map((x) => x.d);
}
