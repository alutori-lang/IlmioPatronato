import { bonusPubblicati, guidePubblicate } from "./content";
import { CATEGORIE } from "./categories";
import { CALCOLATORI } from "./calcolatori";
import { normalizza, type Documento } from "./search";

/** Indice completo, generato sul server e passato al componente di ricerca. */
export function costruisciIndice(): Documento[] {
  const docs: Documento[] = [];
  const add = (d: Omit<Documento, "testo" | "chiave">, extra: string[]) =>
    docs.push({ ...d, chiave: normalizza(d.titolo), testo: normalizza([d.titolo, d.sommario, ...extra].join(" ")) });

  for (const b of bonusPubblicati) {
    add(
      { tipo: "bonus", titolo: b.titolo, url: `/bonus/${b.slug}`, sommario: b.descrizione, categoria: b.categoria },
      [b.intro, b.ente, ...b.tags, ...b.requisiti, ...b.importi],
    );
    b.faq.forEach((f, i) =>
      add({ tipo: "faq", titolo: f.q, url: `/bonus/${b.slug}#faq-${i + 1}`, sommario: f.a, categoria: b.categoria }, [b.titolo]),
    );
  }
  for (const g of guidePubblicate) {
    add({ tipo: "guida", titolo: g.titolo, url: `/guide/${g.slug}`, sommario: g.descrizione, categoria: g.categoria }, [g.testo, ...g.tags]);
    g.faq.forEach((f, i) =>
      add({ tipo: "faq", titolo: f.q, url: `/guide/${g.slug}#faq-${i + 1}`, sommario: f.a, categoria: g.categoria }, [g.titolo]),
    );
  }
  for (const c of CALCOLATORI) {
    add({ tipo: "calcolatore", titolo: c.titolo, url: `/calcolatori/${c.slug}`, sommario: c.descrizione, categoria: c.categoria }, [
      "calcolatore simulatore calcolo",
      ...c.parole,
    ]);
  }
  for (const c of CATEGORIE) {
    add({ tipo: "categoria", titolo: c.nome, url: `/categorie/${c.slug}`, sommario: c.descrizione }, []);
  }
  return docs;
}
