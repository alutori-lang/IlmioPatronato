import type { IconName } from "./categories";

export type CalcolatoreMeta = {
  slug: string;
  titolo: string;
  titoloBreve: string;
  descrizione: string;
  categoria: string;
  icona: IconName;
  parole: string[];
};

export const CALCOLATORI: CalcolatoreMeta[] = [
  {
    slug: "naspi",
    titolo: "Simulatore NASpI 2026",
    titoloBreve: "NASpI",
    descrizione: "Stima importo mensile, durata e riduzione mese per mese dell'indennità di disoccupazione.",
    categoria: "lavoro",
    icona: "work",
    parole: ["disoccupazione", "licenziamento", "indennità"],
  },
  {
    slug: "assegno-unico",
    titolo: "Stima Assegno Unico 2026",
    titoloBreve: "Assegno Unico",
    descrizione: "Calcola l'importo mensile per figlio in base all'ISEE e alle principali maggiorazioni.",
    categoria: "famiglia",
    icona: "family",
    parole: ["figli", "auu", "isee"],
  },
  {
    slug: "stipendio-netto",
    titolo: "Calcolo stipendio netto 2026",
    titoloBreve: "Stipendio netto",
    descrizione: "Dalla RAL al netto in busta paga: contributi INPS, IRPEF 2026, cuneo fiscale e addizionali.",
    categoria: "fisco",
    icona: "euro",
    parole: ["ral", "busta paga", "lordo", "netto"],
  },
  {
    slug: "irpef",
    titolo: "Simulatore IRPEF 2026",
    titoloBreve: "IRPEF",
    descrizione: "Imposta lorda, detrazioni e aliquota media con gli scaglioni 2026 (23%, 33%, 43%).",
    categoria: "fisco",
    icona: "tax",
    parole: ["tasse", "aliquote", "scaglioni", "detrazioni"],
  },
  {
    slug: "tfr",
    titolo: "Calcolo TFR",
    titoloBreve: "TFR",
    descrizione: "Stima del trattamento di fine rapporto maturato, con rivalutazione e tassazione separata.",
    categoria: "lavoro",
    icona: "work",
    parole: ["liquidazione", "fine rapporto"],
  },
  {
    slug: "rata-mutuo",
    titolo: "Simulatore rata mutuo",
    titoloBreve: "Rata mutuo",
    descrizione: "Rata mensile, interessi totali e piano di ammortamento alla francese.",
    categoria: "casa",
    icona: "home",
    parole: ["mutuo", "prestito", "ammortamento", "casa"],
  },
  {
    slug: "risparmio-familiare",
    titolo: "Simulatore risparmio familiare",
    titoloBreve: "Risparmio familiare",
    descrizione: "Quanto riesci a mettere da parte ogni mese e in quanto tempo raggiungi un obiettivo.",
    categoria: "famiglia",
    icona: "calc",
    parole: ["budget", "spese", "obiettivo"],
  },
];

export const getCalcolatore = (slug: string) => CALCOLATORI.find((c) => c.slug === slug);
