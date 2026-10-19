export function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

const euro = new Intl.NumberFormat("it-IT", { style: "currency", currency: "EUR" });
const euro0 = new Intl.NumberFormat("it-IT", {
  style: "currency",
  currency: "EUR",
  maximumFractionDigits: 0,
});
const pct = new Intl.NumberFormat("it-IT", { style: "percent", maximumFractionDigits: 2 });

export const formatEuro = (n: number) => euro.format(n);
export const formatEuro0 = (n: number) => euro0.format(n);
export const formatPct = (n: number) => pct.format(n);

/**
 * Converte un input scritto all'italiana ("1.234,56", "1234,5", "1234.5") in numero.
 * Restituisce NaN se il testo non è un numero valido.
 */
export function parseItNumber(input: string): number {
  const s = input.trim().replace(/[€\s]/g, "");
  if (s === "") return NaN;
  if (!/^-?[\d.,]+$/.test(s)) return NaN;
  let normalized = s;
  if (s.includes(",")) {
    normalized = s.replace(/\./g, "").replace(",", ".");
  } else if ((s.match(/\./g) || []).length > 1 || /\.\d{3}$/.test(s)) {
    // "1.234" o "1.234.567": punti come separatori delle migliaia
    normalized = s.replace(/\./g, "");
  }
  const n = Number(normalized);
  return Number.isFinite(n) ? n : NaN;
}
