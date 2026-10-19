// Legge content/ (bonus JSON + guide Markdown), valida i campi e genera
// src/generated/content.json, importato staticamente dalle pagine.
// Gira prima di dev, build e test (vedi package.json).
import fs from "node:fs";
import path from "node:path";
import matter from "gray-matter";
import { marked } from "marked";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));
const contentDir = path.join(root, "content");
const outFile = path.join(root, "src", "generated", "content.json");

const ICONE = ["family", "work", "home", "elderly", "inps", "tax", "isee", "school", "health", "support", "map", "calc", "search", "book", "phone", "euro"];
const categorieJson = JSON.parse(fs.readFileSync(path.join(contentDir, "categorie.json"), "utf8")).categorie;
const STATI = ["attivo", "scaduto", "in-attesa", "da-verificare"];
const errors = [];
for (const c of categorieJson) {
  if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(c.slug || "")) errors.push(`categorie.json: slug non valido (${c.slug})`);
  if (!ICONE.includes(c.icona)) errors.push(`categorie.json: icona "${c.icona}" non valida per ${c.slug}`);
}
const CATEGORIE = categorieJson.map((c) => c.slug);

function readDir(dir, ext) {
  const full = path.join(contentDir, dir);
  if (!fs.existsSync(full)) return [];
  return fs
    .readdirSync(full)
    .filter((f) => f.endsWith(ext))
    .sort()
    .map((f) => ({ file: `${dir}/${f}`, raw: fs.readFileSync(path.join(full, f), "utf8") }));
}

const isUrl = (u) => typeof u === "string" && /^https:\/\/[^\s]+$/.test(u);
const isDate = (d) => typeof d === "string" && /^\d{4}-\d{2}-\d{2}$/.test(d);
const asList = (v) => (Array.isArray(v) ? v.filter((x) => typeof x === "string" && x.trim()) : []);

function checkCommon(item, file) {
  if (!item.slug || !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(item.slug)) errors.push(`${file}: slug non valido`);
  if (!item.titolo) errors.push(`${file}: titolo mancante`);
  if (!CATEGORIE.includes(item.categoria)) errors.push(`${file}: categoria "${item.categoria}" non valida`);
  for (const f of item.fonti) if (!isUrl(f.url)) errors.push(`${file}: fonte con URL non valido (${f.url})`);
  if (item.pubblicato) {
    if (!item.descrizione) errors.push(`${file}: descrizione obbligatoria per pubblicare`);
    if (item.fonti.length === 0) errors.push(`${file}: almeno una fonte ufficiale per pubblicare`);
  }
}

const fonti = (v) => (Array.isArray(v) ? v.filter((f) => f && f.url).map((f) => ({ label: String(f.label || f.url), url: String(f.url) })) : []);
const faq = (v) => (Array.isArray(v) ? v.filter((f) => f && f.q && f.a).map((f) => ({ q: String(f.q), a: String(f.a) })) : []);

const bonus = readDir("bonus", ".json").map(({ file, raw }) => {
  let j;
  try {
    j = JSON.parse(raw);
  } catch (e) {
    errors.push(`${file}: JSON non valido (${e.message})`);
    return null;
  }
  const b = {
    slug: j.slug,
    titolo: j.titolo,
    descrizione: j.descrizione || "",
    intro: j.intro || "",
    categoria: j.categoria,
    ente: j.ente || "",
    stato: j.stato,
    pubblicato: j.pubblicato === true,
    verificato: j.verificato === true,
    ultimoControllo: isDate(j.ultimoControllo) ? j.ultimoControllo : null,
    aggiornatoIl: isDate(j.aggiornatoIl) ? j.aggiornatoIl : null,
    aChiSpetta: asList(j.aChiSpetta),
    requisiti: asList(j.requisiti),
    importi: asList(j.importi),
    comeFare: asList(j.comeFare),
    documenti: asList(j.documenti),
    scadenze: j.scadenze || "",
    faq: faq(j.faq),
    fonti: fonti(j.fonti),
    tags: asList(j.tags),
  };
  checkCommon(b, file);
  if (!STATI.includes(b.stato)) errors.push(`${file}: stato "${b.stato}" non valido`);
  if (b.pubblicato && !b.verificato) errors.push(`${file}: non si può pubblicare un bonus non verificato`);
  if (b.pubblicato && !b.ultimoControllo) errors.push(`${file}: data ultimo controllo obbligatoria per pubblicare`);
  return b;
}).filter(Boolean);

marked.use({ gfm: true });

const guide = readDir("guide", ".md").map(({ file, raw }) => {
  const { data, content } = matter(raw);
  const toIso = (d) => (d instanceof Date ? d.toISOString().slice(0, 10) : isDate(d) ? d : null);
  const g = {
    slug: data.slug || path.basename(file, ".md"),
    titolo: data.titolo,
    titoloSeo: data.titoloSeo || data.titolo,
    descrizione: data.descrizione || "",
    categoria: data.categoria,
    pubblicato: data.pubblicato === true,
    dataPubblicazione: toIso(data.dataPubblicazione),
    dataAggiornamento: toIso(data.dataAggiornamento) || toIso(data.dataPubblicazione),
    autore: data.autore || "Redazione SBonus",
    fonti: fonti(data.fonti),
    faq: faq(data.faq),
    correlati: asList(data.correlati),
    tags: asList(data.tags),
    html: marked.parse(content),
    testo: content.replace(/[#*_>`\[\]()|-]/g, " ").replace(/\s+/g, " ").trim(),
  };
  checkCommon(g, file);
  if (g.pubblicato && !g.dataPubblicazione) errors.push(`${file}: dataPubblicazione obbligatoria per pubblicare`);
  return g;
});

// Parametri dei calcolatori: un valore sbagliato dal pannello non deve
// arrivare in produzione, quindi la build si ferma.
const parametri = JSON.parse(fs.readFileSync(path.join(contentDir, "parametri", "2026.json"), "utf8"));
const num = (v, nome, { min = 0, max = Infinity } = {}) => {
  if (typeof v !== "number" || !Number.isFinite(v) || v < min || v > max) errors.push(`parametri: ${nome} non valido (${v})`);
};
{
  const sc = parametri.irpef?.scaglioni ?? [];
  if (sc.length < 2) errors.push("parametri: servono almeno 2 scaglioni IRPEF");
  sc.forEach((s, i) => {
    num(s.aliquota, `irpef.scaglioni[${i}].aliquota`, { max: 1 });
    const ultimo = i === sc.length - 1;
    if (ultimo ? s.fino !== null && s.fino !== undefined : !(s.fino > (sc[i - 1]?.fino ?? 0))) {
      errors.push(`parametri: irpef.scaglioni[${i}].fino deve essere crescente (vuoto solo per l'ultimo scaglione)`);
    }
  });
  const pct = (v, n) => num(v, n, { max: 1 });
  parametri.cuneoFiscale?.sommaEsente?.forEach((f, i) => {
    num(f.fino, `sommaEsente[${i}].fino`);
    pct(f.percentuale, `sommaEsente[${i}].percentuale`);
  });
  const u = parametri.cuneoFiscale?.ulterioreDetrazione ?? {};
  ["pieno", "da", "pienoFino", "azzeraA"].forEach((k) => num(u[k], `ulterioreDetrazione.${k}`));
  if (!(u.da < u.pienoFino && u.pienoFino < u.azzeraA)) errors.push("parametri: ulterioreDetrazione da < pienoFino < azzeraA");
  const i = parametri.inpsDipendente ?? {};
  pct(i.aliquota, "inpsDipendente.aliquota"); pct(i.aliquotaAggiuntiva, "inpsDipendente.aliquotaAggiuntiva"); num(i.sogliaAggiuntivaAnnua, "inpsDipendente.soglia");
  const n = parametri.naspi ?? {};
  ["soglia", "massimale", "durataMassimaMesi", "settimaneMinime", "meseInizioRiduzione", "meseInizioRiduzioneOver55"].forEach((k) => num(n[k], `naspi.${k}`));
  ["percentualeSotto", "percentualeSopra", "riduzioneMensile"].forEach((k) => pct(n[k], `naspi.${k}`));
  const a = parametri.assegnoUnico ?? {};
  num(a.iseeMin, "assegnoUnico.iseeMin"); num(a.iseeMax, "assegnoUnico.iseeMax");
  if (!(a.iseeMin < a.iseeMax)) errors.push("parametri: assegnoUnico.iseeMin deve essere minore di iseeMax");
  for (const k of ["figlioMinore", "figlio18_21", "maggiorazioneTerzoFiglio"]) {
    num(a[k]?.max, `assegnoUnico.${k}.max`); num(a[k]?.min, `assegnoUnico.${k}.min`);
    if (!(a[k]?.min <= a[k]?.max)) errors.push(`parametri: assegnoUnico.${k} min > max`);
  }
  pct(a.maggiorazioneUnderUnoPercent, "assegnoUnico.maggiorazioneUnderUnoPercent");
  num(a.maggiorazioneMadreUnder21, "assegnoUnico.maggiorazioneMadreUnder21"); num(a.forfettariaQuattroFigli, "assegnoUnico.forfettaria");
  ["media", "grave", "nonAutosufficienza"].forEach((k) => num(a.disabilitaMinore?.[k], `assegnoUnico.disabilitaMinore.${k}`));
  const t = parametri.tfr ?? {};
  num(t.divisore, "tfr.divisore", { min: 1 });
  ["contributoAggiuntivo", "rivalutazioneFissa", "quotaInflazione", "impostaSostitutivaRivalutazione"].forEach((k) => pct(t[k], `tfr.${k}`));
  if (!isDate(parametri.ultimoControllo)) errors.push("parametri: ultimoControllo deve essere una data AAAA-MM-GG");
}

const seen = new Set();
for (const item of [...bonus.map((b) => `bonus/${b.slug}`), ...guide.map((g) => `guide/${g.slug}`)]) {
  if (seen.has(item)) errors.push(`slug duplicato: ${item}`);
  seen.add(item);
}

if (errors.length) {
  console.error("\n[content] Errori nei contenuti:\n - " + errors.join("\n - ") + "\n");
  process.exit(1);
}

fs.mkdirSync(path.dirname(outFile), { recursive: true });
fs.writeFileSync(outFile, JSON.stringify({ bonus, guide }, null, 0));
const pub = (a) => a.filter((x) => x.pubblicato).length;
console.log(`[content] bonus: ${pub(bonus)} pubblicati / ${bonus.length} · guide: ${pub(guide)} pubblicate / ${guide.length}`);
