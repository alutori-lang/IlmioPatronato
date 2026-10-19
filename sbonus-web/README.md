# SBonus – Smart Bonus Italia (sbonus.it)

Portale informativo indipendente su bonus, agevolazioni, prestazioni INPS, ISEE e fisco, con calcolatori gratuiti.
È il sito web collegato all'app **Smart Bonus Italia** (cartella principale di questo repository, progetto Flutter).

Questa cartella è un progetto **separato**: Next.js 16 + TypeScript + Tailwind CSS 4. Non tocca l'app Flutter.

## Avvio rapido

```bash
cd sbonus-web
npm install
npm run dev          # http://localhost:3000
npm test             # test dei calcolatori (Vitest)
npm run lint
npm run typecheck
npm run build        # build di produzione (genera prima i contenuti)
```

## Struttura

```
sbonus-web/
├─ content/                  ← TUTTI i contenuti, modificabili anche da /admin
│  ├─ bonus/*.json           schede bonus (pubblicate e bozze)
│  ├─ guide/*.md             guide e articoli (Markdown + frontmatter)
│  ├─ categorie.json         categorie
│  └─ parametri/2026.json    parametri normativi dei calcolatori, con fonte
├─ scripts/build-content.mjs valida content/ e genera src/generated/content.json
├─ public/admin/             pannello redazione (Decap CMS)
└─ src/
   ├─ app/                   pagine (App Router)
   ├─ components/            UI, calcolatori (calc/), consenso cookie, AdSlot
   └─ lib/calc/              logica dei calcolatori + test
```

## Regole editoriali (applicate dal codice)

- Un bonus va online solo se `pubblicato: true` **e** `verificato: true`, con almeno una fonte ufficiale e la data
  `ultimoControllo`. Altrimenti `npm run build` si ferma con un errore.
- Le bozze (`pubblicato: false`) non generano pagine, non entrano nella sitemap né nella ricerca.
- Le misure scadute restano online con `stato: "scaduto"` e un avviso ben visibile.
- I parametri dei calcolatori hanno fonte e flag `verificato`; un valore non valido blocca la build.

### Stato attuale dei contenuti (controllo del 19/10/2026)

- **19 schede pubblicate**, verificate su inps.it, agenziaentrate.gov.it, lavoro.gov.it, mef.gov.it, masaf.gov.it,
  arera.it, consap.it.
- **33 bozze** importate dall'app (dati di aprile 2026), da verificare prima della pubblicazione. Una (bonus psicologo) è
  in attesa del bando 2026.
- **7 guide** originali.

## Calcolatori

| Calcolatore | Stato parametri 2026 |
|---|---|
| NASpI | Verificati sulla Circolare INPS 4/2026 |
| Assegno Unico | Importi base e soglie ISEE verificati (Circolare INPS 7/2026); maggiorazioni terzo figlio, disabilità, madre under 21 e figli 18–21 da ricontrollare sull'Allegato 1 |
| Stipendio netto | IRPEF e cuneo fiscale verificati (Agenzia delle Entrate); soglia 2026 del contributo INPS aggiuntivo dell'1% da ricontrollare (Circolare INPS 6/2026) |
| IRPEF | Verificati (Agenzia delle Entrate) |
| TFR | Regole del codice civile (art. 2120) |
| Rata mutuo, Risparmio familiare | Solo matematica finanziaria |

I calcoli girano nel browser: nessun dato inserito viene inviato al server.

## Pannello redazione `/admin`

Decap CMS con login GitHub: possono entrare solo gli account con permesso di scrittura sul repository. Il flusso
editoriale crea una pull request per ogni modifica (Bozza → In revisione → Pronta → Pubblica).

Configurazione (una volta):

1. GitHub → Settings → Developer settings → OAuth Apps → **New OAuth App**
   - Homepage URL: `https://sbonus.it`
   - Authorization callback URL: `https://sbonus.it/api/decap/callback`
2. Su Vercel imposta `DECAP_GITHUB_CLIENT_ID` e `DECAP_GITHUB_CLIENT_SECRET`.
3. Il pannello salva sul branch `main` (vedi `public/admin/config.yml`): funziona dopo il merge di questo progetto.

## Pubblicazione (Vercel)

1. Importa il repository `alutori-lang/IlmioPatronato` su Vercel e imposta **Root Directory = `sbonus-web`**
   (framework Next.js, comandi predefiniti).
2. Imposta le variabili di `.env.example`.
3. Dominio: Vercel → Settings → Domains → `sbonus.it` e `www.sbonus.it`, poi su Aruba inserisci i record DNS (A e CNAME) che
   Vercel mostra in quella schermata. **Non cambiare i nameserver** se il dominio usa già email Aruba.
4. Nota: il piano gratuito Hobby di Vercel è riservato a uso non commerciale. Con la pubblicità AdSense serve il piano
   **Pro** oppure un altro hosting Node.js.

**Indicizzazione:** è spenta di default (`robots.txt` blocca tutto e ogni pagina ha `noindex`). Imposta
`SBONUS_INDEXABLE=1` nelle variabili di **Production** solo quando `sbonus.it` è collegato e pronto.

## Google AdSense

Pronto ma **spento**: senza `NEXT_PUBLIC_ADSENSE_CLIENT` non viene caricato nessuno script, non compaiono spazi
pubblicitari e il banner cookie non viene mostrato (il sito usa solo archiviazione tecnica).

Dopo l'approvazione:

1. imposta `NEXT_PUBLIC_ADSENSE_CLIENT=ca-pub-…` e gli ID delle unità annuncio;
2. aggiungi `public/ads.txt` con la riga fornita da AdSense;
3. **nello SEE serve una CMP certificata IAB TCF** per gli annunci personalizzati: attiva il messaggio GDPR in AdSense →
   Privacy e messaggi (il banner del sito gestisce solo la scelta base, non sostituisce la CMP certificata);
4. aggiorna Privacy e Cookie Policy se cambiano i fornitori.

## Prima di andare online

- [ ] Inserire indirizzo dell'editore (e P.IVA se presente) in `NEXT_PUBLIC_EDITOR_ADDRESS` / `NEXT_PUBLIC_EDITOR_VAT`
- [ ] Far rivedere Privacy, Cookie Policy e Termini a un consulente
- [ ] Verificare le 33 bozze o lasciarle non pubblicate
- [ ] Ricontrollare i parametri contrassegnati come non verificati
- [ ] Collegare Google Search Console e inviare `https://sbonus.it/sitemap.xml`
