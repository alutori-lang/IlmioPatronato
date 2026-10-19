import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage } from "@/components/LegalPage";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: "Informativa sul trattamento dei dati personali degli utenti di SBonus (art. 13 Regolamento UE 2016/679).",
  alternates: { canonical: "/privacy" },
};

export default function Privacy() {
  const e = SITE.editor;
  return (
    <LegalPage titolo="Privacy Policy" href="/privacy" aggiornata="2026-10-19">
      <p>
        Questa informativa descrive come vengono trattati i dati personali di chi visita {SITE.url.replace("https://", "")} (di
        seguito «il sito»), ai sensi dell&apos;art. 13 del Regolamento (UE) 2016/679 («GDPR») e del D.Lgs. 196/2003.
      </p>

      <h2>Titolare del trattamento</h2>
      <p>
        {e.name}
        {e.address && `, ${e.address}`}
        {e.vat && ` – P.IVA ${e.vat}`}. Per qualsiasi richiesta: <a href={`mailto:${e.email}`}>{e.email}</a>.
      </p>

      <h2>Quali dati trattiamo</h2>
      <ul>
        <li>
          <strong>Dati di navigazione.</strong> Come ogni sito web, i server che ospitano il sito registrano automaticamente alcuni
          dati tecnici (indirizzo IP, data e ora, pagina richiesta, browser e sistema operativo). Servono a far funzionare il sito,
          a garantirne la sicurezza e a individuare abusi. Sono conservati dal fornitore di hosting per il tempo strettamente
          necessario.
        </li>
        <li>
          <strong>Dati inseriti nei calcolatori.</strong> I calcoli avvengono interamente nel tuo browser: gli importi che inserisci
          non vengono inviati né salvati sui nostri server.
        </li>
        <li>
          <strong>Ricerca interna.</strong> Anche la ricerca avviene nel browser: i termini cercati non vengono registrati.
        </li>
        <li>
          <strong>Dati che ci invii.</strong> Se ci scrivi per email trattiamo il tuo indirizzo e il contenuto del messaggio solo
          per risponderti, e li conserviamo per il tempo necessario a gestire la richiesta.
        </li>
        <li>
          <strong>Preferenze sui cookie.</strong> La tua scelta sui cookie viene salvata nel browser (archiviazione locale).
        </li>
      </ul>
      <p>
        Il sito <strong>non chiede</strong> codici fiscali, documenti di identità, dati sanitari o altri dati particolari. Ti
        invitiamo a non inviarli via email.
      </p>

      <h2>Pubblicità</h2>
      <p>
        Il sito potrà mostrare annunci tramite Google AdSense. Gli annunci e i relativi cookie vengono attivati solo dopo
        l&apos;approvazione di Google e, per gli annunci personalizzati, solo con il tuo consenso. In quel caso Google Ireland Ltd
        tratta i dati come titolare autonomo secondo la propria{" "}
        <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer">
          informativa privacy
        </a>
        . Dettagli nella <Link href="/cookie">Cookie Policy</Link>.
      </p>

      <h2>Base giuridica</h2>
      <ul>
        <li>Dati di navigazione: legittimo interesse al funzionamento e alla sicurezza del sito (art. 6.1.f GDPR).</li>
        <li>Richieste via email: esecuzione di misure richieste dall&apos;interessato (art. 6.1.b GDPR).</li>
        <li>Cookie pubblicitari: consenso (art. 6.1.a GDPR), revocabile in ogni momento.</li>
      </ul>

      <h2>Destinatari e trasferimenti</h2>
      <p>
        I dati possono essere trattati dal fornitore di hosting e, se attivata la pubblicità, da Google, in qualità di
        responsabili o titolari autonomi. Alcuni di questi fornitori possono trattare dati fuori dallo Spazio Economico Europeo:
        in tal caso il trasferimento avviene sulla base di decisioni di adeguatezza della Commissione europea (come l&apos;EU-US
        Data Privacy Framework) o delle clausole contrattuali standard.
      </p>

      <h2>I tuoi diritti</h2>
      <p>
        Puoi chiedere in qualsiasi momento l&apos;accesso, la rettifica, la cancellazione e la limitazione dei tuoi dati, opporti
        al trattamento e chiederne la portabilità (artt. 15–22 GDPR), scrivendo a <a href={`mailto:${e.email}`}>{e.email}</a>.
        Hai inoltre il diritto di proporre reclamo al{" "}
        <a href="https://www.garanteprivacy.it" target="_blank" rel="noopener noreferrer">
          Garante per la protezione dei dati personali
        </a>
        .
      </p>

      <h2>Modifiche</h2>
      <p>Questa informativa può essere aggiornata: la data in alto indica l&apos;ultima revisione.</p>
    </LegalPage>
  );
}
