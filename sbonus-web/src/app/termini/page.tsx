import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage } from "@/components/LegalPage";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Termini di utilizzo",
  description: "Condizioni d'uso del portale informativo SBonus.",
  alternates: { canonical: "/termini" },
};

export default function Termini() {
  return (
    <LegalPage titolo="Termini di utilizzo" href="/termini" aggiornata="2026-10-19">
      <p>Usando il sito accetti le condizioni che seguono.</p>

      <h2>Natura del servizio</h2>
      <p>
        {SITE.name} è un portale <strong>informativo e gratuito</strong>. Non è un sito della Pubblica Amministrazione, non
        rappresenta INPS, Agenzia delle Entrate o altri enti e non presenta domande per conto degli utenti.
      </p>

      <h2>Contenuti e calcolatori</h2>
      <p>
        I contenuti sono redatti con cura partendo da fonti ufficiali, che citiamo in ogni scheda, ma hanno scopo divulgativo. Le
        norme cambiano spesso: prima di prendere decisioni verifica sempre sul sito dell&apos;ente competente o rivolgiti a CAF,
        patronati o professionisti. I calcolatori forniscono <strong>stime</strong> basate sulle ipotesi indicate in ciascuna pagina
        e non sostituiscono il calcolo ufficiale dell&apos;ente. Leggi anche il <Link href="/disclaimer">disclaimer</Link>.
      </p>

      <h2>Proprietà intellettuale</h2>
      <p>
        Testi, grafica, logo e codice del sito appartengono ai rispettivi titolari. Puoi citare brevi estratti indicando la fonte
        con un link alla pagina. I marchi di terzi (ad esempio Google Play e App Store) appartengono ai rispettivi proprietari.
      </p>

      <h2>Link esterni</h2>
      <p>Il sito contiene link a siti di terzi, compresi quelli istituzionali, sui quali non abbiamo controllo.</p>

      <h2>Uso corretto</h2>
      <p>
        È vietato usare il sito in modo da danneggiarne il funzionamento, eseguire estrazioni massive automatizzate dei contenuti o
        tentare di accedere ad aree riservate.
      </p>

      <h2>Legge applicabile</h2>
      <p>Questi termini sono regolati dalla legge italiana. Restano salvi i diritti inderogabili dei consumatori.</p>

      <h2>Contatti</h2>
      <p>
        Per segnalazioni: <a href={`mailto:${SITE.editor.email}`}>{SITE.editor.email}</a>.
      </p>
    </LegalPage>
  );
}
