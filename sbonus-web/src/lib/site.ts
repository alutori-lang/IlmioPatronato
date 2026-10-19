// Dati globali del portale. Le variabili NEXT_PUBLIC_* si impostano su Vercel
// (o in .env.local): nessun segreto vive in questo file.

export const SITE = {
  name: "SBonus",
  fullName: "SBonus – Smart Bonus Italia",
  slogan: "Tutti i bonus, le agevolazioni e i calcolatori utili in un solo posto.",
  url: (process.env.NEXT_PUBLIC_SITE_URL || "https://sbonus.it").replace(/\/$/, ""),
  locale: "it_IT",
  // Editore / titolare del trattamento. Indirizzo e P.IVA vanno aggiunti
  // dall'editore prima della pubblicazione (vedi README).
  editor: {
    name: "Adnan Riaz",
    email: "alutori@gmail.com",
    address: process.env.NEXT_PUBLIC_EDITOR_ADDRESS || "",
    vat: process.env.NEXT_PUBLIC_EDITOR_VAT || "",
  },
} as const;

export const APP = {
  name: "Smart Bonus Italia",
  android: "https://play.google.com/store/apps/details?id=com.docflow.docflow_immigrati",
  ios: "https://apps.apple.com/it/app/smart-bonus-italia/id6760600310",
  androidPackage: "com.docflow.docflow_immigrati",
  iosId: "6760600310",
} as const;

// AdSense: resta spento finché non si imposta il publisher ID reale
// (ca-pub-XXXXXXXXXXXXXXXX) dopo l'approvazione di Google.
export const ADSENSE_CLIENT = process.env.NEXT_PUBLIC_ADSENSE_CLIENT || "";
/** ID delle unità pubblicitarie create nel pannello AdSense. */
export const ADSENSE_SLOTS = {
  contenuto: process.env.NEXT_PUBLIC_ADSENSE_SLOT_CONTENUTO || "",
  elenco: process.env.NEXT_PUBLIC_ADSENSE_SLOT_ELENCO || "",
};

export const NAV = [
  { href: "/bonus", label: "Bonus" },
  { href: "/calcolatori", label: "Calcolatori" },
  { href: "/guide", label: "Guide" },
  { href: "/categorie", label: "Categorie" },
  { href: "/app", label: "App" },
] as const;

export function absoluteUrl(path = "/") {
  return `${SITE.url}${path.startsWith("/") ? path : `/${path}`}`;
}
