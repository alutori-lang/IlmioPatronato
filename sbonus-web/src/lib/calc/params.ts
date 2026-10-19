import raw from "../../../content/parametri/2026.json";

export type Fonte = { label: string; url: string };

export type Parametri = typeof raw;

/** Parametri normativi in vigore. Si aggiornano da /admin (content/parametri). */
export const PARAMS: Parametri = raw;
