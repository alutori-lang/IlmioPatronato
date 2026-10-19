import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage } from "@/components/LegalPage";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Contatti",
  description: "Come contattare la redazione di SBonus per segnalazioni, correzioni e collaborazioni.",
  alternates: { canonical: "/contatti" },
};

export default function Contatti() {
  const email = SITE.editor.email;
  return (
    <LegalPage titolo="Contatti" href="/contatti" aggiornata="2026-10-19">
      <p>
        Puoi scriverci a <a href={`mailto:${email}`}>{email}</a> per:
      </p>
      <ul>
        <li>segnalare un&apos;informazione superata o un errore (indica la pagina e, se puoi, la fonte ufficiale);</li>
        <li>suggerire un bonus o una guida da aggiungere;</li>
        <li>richieste sulla privacy o sull&apos;app Smart Bonus Italia;</li>
        <li>proposte di collaborazione.</li>
      </ul>

      <h2>Cosa non possiamo fare</h2>
      <p>
        SBonus non è un ente pubblico, un CAF o un patronato: non possiamo presentare domande, verificare lo stato delle tue pratiche
        né accedere ai tuoi dati INPS. Per queste richieste rivolgiti ai canali ufficiali (vedi la guida{" "}
        <Link href="/guide/accedere-servizi-inps-online-spid-cie">come accedere ai servizi INPS online</Link>) o a un patronato.
      </p>
      <blockquote>
        Per la tua sicurezza <strong>non inviarci</strong> documenti d&apos;identità, codici fiscali, password o dati sanitari.
      </blockquote>
    </LegalPage>
  );
}
