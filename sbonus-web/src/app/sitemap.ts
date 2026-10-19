import type { MetadataRoute } from "next";
import { bonusPubblicati, guidePubblicate, bonusPerCategoria, guidePerCategoria } from "@/lib/content";
import { CATEGORIE } from "@/lib/categories";
import { CALCOLATORI } from "@/lib/calcolatori";
import { PARAMS } from "@/lib/calc/params";
import { absoluteUrl } from "@/lib/site";

// Solo contenuti pubblicati: le bozze non entrano mai nella sitemap.
export default function sitemap(): MetadataRoute.Sitemap {
  const d = (iso?: string | null) => (iso ? new Date(`${iso}T00:00:00Z`) : undefined);
  const ultimoBonus = bonusPubblicati.map((b) => b.aggiornatoIl ?? "").sort().at(-1);
  const statiche = ["/", "/bonus", "/calcolatori", "/guide", "/categorie", "/app", "/chi-siamo", "/contatti", "/privacy", "/cookie", "/termini", "/disclaimer"];
  return [
    ...statiche.map((p) => ({ url: absoluteUrl(p), lastModified: p === "/" || p === "/bonus" ? d(ultimoBonus) : undefined, priority: p === "/" ? 1 : 0.6 })),
    ...bonusPubblicati.map((b) => ({ url: absoluteUrl(`/bonus/${b.slug}`), lastModified: d(b.aggiornatoIl), priority: b.stato === "scaduto" ? 0.3 : 0.8 })),
    ...guidePubblicate.map((g) => ({ url: absoluteUrl(`/guide/${g.slug}`), lastModified: d(g.dataAggiornamento), priority: 0.7 })),
    ...CALCOLATORI.map((c) => ({ url: absoluteUrl(`/calcolatori/${c.slug}`), lastModified: d(PARAMS.ultimoControllo), priority: 0.8 })),
    ...CATEGORIE.filter((c) => bonusPerCategoria(c.slug).length + guidePerCategoria(c.slug).length > 0).map((c) => ({
      url: absoluteUrl(`/categorie/${c.slug}`),
      priority: 0.5,
    })),
  ];
}
