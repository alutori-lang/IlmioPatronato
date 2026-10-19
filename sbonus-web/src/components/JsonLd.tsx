/** Dati strutturati schema.org. Il contenuto è nostro (non input utente); si
 *  esegue comunque l'escape di "<" per evitare la chiusura anticipata dello script. */
export function JsonLd({ data }: { data: Record<string, unknown> | Record<string, unknown>[] }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data).replace(/</g, "\\u003c") }}
    />
  );
}
