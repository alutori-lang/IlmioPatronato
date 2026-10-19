import type { Faq, Fonte } from "@/lib/content";
import { formatData } from "@/lib/content";
import { JsonLd } from "./JsonLd";
import { Icon } from "./Icon";

export function Faqs({ faq }: { faq: Faq[] }) {
  return (
    <section id="faq" aria-labelledby="faq-t" className="scroll-mt-24 rounded-2xl border border-line bg-surface p-5 sm:p-6">
      <h2 id="faq-t" className="font-display text-xl font-bold text-ink">
        Domande frequenti
      </h2>
      <div className="mt-4 divide-y divide-line">
        {faq.map((f, i) => (
          <details key={f.q} id={`faq-${i + 1}`} className="group scroll-mt-24 py-3" open={i === 0}>
            <summary className="flex cursor-pointer list-none items-start justify-between gap-4 py-1 font-semibold text-ink [&::-webkit-details-marker]:hidden">
              {f.q}
              <span aria-hidden="true" className="mt-0.5 text-xl leading-none text-brand transition group-open:rotate-45">
                +
              </span>
            </summary>
            <p className="mt-2 leading-relaxed text-ink-2">{f.a}</p>
          </details>
        ))}
      </div>
      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "FAQPage",
          mainEntity: faq.map((f) => ({ "@type": "Question", name: f.q, acceptedAnswer: { "@type": "Answer", text: f.a } })),
        }}
      />
    </section>
  );
}

export function Fonti({ fonti, ultimoControllo }: { fonti: Fonte[]; ultimoControllo?: string | null }) {
  return (
    <section id="fonti" aria-labelledby="fonti-t" className="scroll-mt-24 rounded-2xl border border-line bg-surface-2 p-5 sm:p-6">
      <h2 id="fonti-t" className="font-display text-xl font-bold text-ink">
        Fonti ufficiali
      </h2>
      <ul className="mt-3 space-y-2">
        {fonti.map((f) => (
          <li key={f.url}>
            <a href={f.url} target="_blank" rel="noopener noreferrer" className="inline-flex items-start gap-2 text-brand underline-offset-2 hover:underline">
              <Icon name="external" className="mt-1 h-4 w-4 shrink-0" />
              <span>{f.label}</span>
            </a>
          </li>
        ))}
      </ul>
      {ultimoControllo && (
        <p className="mt-4 text-sm text-ink-3">
          Informazioni controllate il <time dateTime={ultimoControllo}>{formatData(ultimoControllo)}</time>. Le regole possono
          cambiare: verifica sempre sul sito dell&apos;ente prima di presentare domanda.
        </p>
      )}
    </section>
  );
}

export function AvvisoIndipendente() {
  return (
    <p className="flex gap-2.5 rounded-2xl border border-line p-4 text-sm leading-relaxed text-ink-3">
      <Icon name="info" className="mt-0.5 h-4 w-4 shrink-0" />
      <span>
        SBonus è un portale informativo indipendente, non affiliato a INPS, Agenzia delle Entrate o altri enti pubblici. Le
        informazioni hanno scopo divulgativo e non sostituiscono la consulenza di CAF, patronati o professionisti.
      </span>
    </p>
  );
}
