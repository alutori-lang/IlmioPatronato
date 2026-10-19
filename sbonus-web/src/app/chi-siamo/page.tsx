import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage } from "@/components/LegalPage";
import { SITE, APP } from "@/lib/site";

export const metadata: Metadata = {
  title: "Chi siamo",
  description: "SBonus è il portale di Smart Bonus Italia: informazioni chiare su bonus, agevolazioni e prestazioni, con fonti ufficiali.",
  alternates: { canonical: "/chi-siamo" },
};

export default function ChiSiamo() {
  const e = SITE.editor;
  return (
    <LegalPage titolo="Chi siamo" href="/chi-siamo" aggiornata="2026-10-19">
      <p>
        <strong>{SITE.fullName}</strong> nasce per rendere semplici le informazioni su bonus, agevolazioni e prestazioni
        pubbliche, spesso sparse tra circolari, siti istituzionali e moduli difficili da leggere. È il portale web
        dell&apos;app <Link href="/app">{APP.name}</Link>.
      </p>

      <h2>Come lavoriamo</h2>
      <ul>
        <li>
          <strong>Fonti ufficiali prima di tutto.</strong> Ogni scheda si basa su pagine di INPS, Agenzia delle Entrate, Ministeri e
          Gazzetta Ufficiale, che citiamo con link diretto.
        </li>
        <li>
          <strong>Data di controllo visibile.</strong> In ogni scheda indichiamo quando abbiamo verificato le informazioni.
        </li>
        <li>
          <strong>Niente pubblicazione senza verifica.</strong> Le schede che non abbiamo ancora potuto controllare restano in bozza
          e non vengono pubblicate.
        </li>
        <li>
          <strong>Misure scadute segnalate.</strong> Se un bonus non è più attivo lo indichiamo chiaramente.
        </li>
        <li>
          <strong>Calcolatori trasparenti.</strong> Mostriamo formule, parametri e limiti di ogni stima.
        </li>
      </ul>

      <h2>Indipendenza</h2>
      <p>
        {SITE.name} è un progetto indipendente: non è un sito della Pubblica Amministrazione e non presenta domande per conto
        degli utenti. Il sito potrà essere sostenuto dalla pubblicità, sempre separata e riconoscibile dai contenuti editoriali.
      </p>

      <h2>Editore</h2>
      <p>
        {e.name}
        {e.address && ` – ${e.address}`}
        {e.vat && ` – P.IVA ${e.vat}`}
        <br />
        Email: <a href={`mailto:${e.email}`}>{e.email}</a>
      </p>
    </LegalPage>
  );
}
