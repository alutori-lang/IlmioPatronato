import type { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Disclaimer",
  description: "SBonus è un portale informativo indipendente, non affiliato a enti pubblici. Limiti delle informazioni e dei calcolatori.",
  alternates: { canonical: "/disclaimer" },
};

export default function Disclaimer() {
  return (
    <LegalPage titolo="Disclaimer" href="/disclaimer" aggiornata="2026-10-19">
      <h2>Portale indipendente</h2>
      <p>
        {SITE.name} <strong>non è un sito ufficiale</strong> e non è affiliato, collegato o approvato da INPS, Agenzia delle
        Entrate, Ministeri, Regioni, Comuni, CAF o patronati. I nomi degli enti sono citati solo per indicare le fonti e i canali
        ufficiali a cui rivolgersi.
      </p>

      <h2>Le informazioni</h2>
      <p>
        Ogni scheda indica le fonti ufficiali usate e la data dell&apos;ultimo controllo. Nonostante l&apos;attenzione della
        redazione, le informazioni possono contenere errori o non essere aggiornate rispetto a modifiche normative recenti. Fanno
        sempre fede i testi di legge e le comunicazioni ufficiali degli enti.
      </p>

      <h2>I calcolatori</h2>
      <p>
        I risultati sono <strong>stime</strong> calcolate con i parametri e le ipotesi riportati in ogni pagina. Non tengono conto
        di tutte le situazioni personali e non hanno valore legale. L&apos;importo effettivo di una prestazione o di un&apos;imposta
        è determinato esclusivamente dall&apos;ente competente.
      </p>

      <h2>Nessuna consulenza</h2>
      <p>
        I contenuti non costituiscono consulenza fiscale, legale o previdenziale. Per la tua situazione specifica rivolgiti a un
        CAF, a un patronato o a un professionista abilitato.
      </p>

      <h2>Segnala un errore</h2>
      <p>
        Hai trovato un&apos;informazione superata o sbagliata? Scrivici a <a href={`mailto:${SITE.editor.email}`}>{SITE.editor.email}</a>{" "}
        indicando la pagina e la fonte ufficiale: correggeremo al più presto.
      </p>
    </LegalPage>
  );
}
