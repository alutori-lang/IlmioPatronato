import type { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";
import { CookiePrefsLink } from "@/components/CookiePrefsLink";
import { ADSENSE_CLIENT } from "@/lib/site";

export const metadata: Metadata = {
  title: "Cookie Policy",
  description: "Quali cookie e strumenti di archiviazione usa SBonus e come gestire il consenso.",
  alternates: { canonical: "/cookie" },
};

export default function Cookie() {
  return (
    <LegalPage titolo="Cookie Policy" href="/cookie" aggiornata="2026-10-19">
      <p>
        I cookie sono piccoli file che un sito salva nel browser. Questa pagina spiega quali strumenti di questo tipo usa SBonus,
        secondo le Linee guida del Garante privacy del 10 giugno 2021.
      </p>

      <h2>Strumenti tecnici (sempre attivi)</h2>
      <table>
        <thead>
          <tr>
            <th>Nome</th>
            <th>Tipo</th>
            <th>Finalità</th>
            <th>Durata</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>sbonus-consenso</td>
            <td>Archiviazione locale del browser</td>
            <td>Ricorda la tua scelta sui cookie pubblicitari</td>
            <td>Finché non la cancelli</td>
          </tr>
        </tbody>
      </table>
      <p>Gli strumenti tecnici non richiedono consenso. Il sito non usa cookie di analisi o di profilazione propri.</p>

      <h2>Cookie pubblicitari di terze parti</h2>
      <p>
        {ADSENSE_CLIENT
          ? "Il sito usa Google AdSense per mostrare annunci. "
          : "Al momento la pubblicità non è attiva. Quando sarà attivata, il sito userà Google AdSense. "}
        Google può usare cookie e identificatori per mostrare annunci, anche personalizzati, e misurarne l&apos;efficacia. Questi
        cookie vengono installati <strong>solo dopo il tuo consenso</strong>. Puoi saperne di più su{" "}
        <a href="https://policies.google.com/technologies/ads" target="_blank" rel="noopener noreferrer">
          come Google usa i cookie nella pubblicità
        </a>{" "}
        e gestire la personalizzazione su{" "}
        <a href="https://adssettings.google.com" target="_blank" rel="noopener noreferrer">
          Impostazioni annunci
        </a>
        .
      </p>

      <h2>Come gestire il consenso</h2>
      <p>
        Puoi cambiare idea in qualsiasi momento: <CookiePrefsLink />. Puoi anche cancellare i dati del sito dalle impostazioni del
        tuo browser.
      </p>
    </LegalPage>
  );
}
