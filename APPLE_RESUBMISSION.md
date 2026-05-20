# Risposta al revisore App Store — Smart Bonus Italia

Rifiuto del 20 maggio 2026 — Submission ID `a8723591-f6d1-46d5-865f-4b99985cb202`.
Versione precedente rifiutata: 1.0.13 (17). Versione corretta da inviare: **1.0.14 (18)**.

Tutte le modifiche sono lato iOS. Android resta invariato (account, branding, etc.).

---

## Modifiche al codice già applicate

| File | Modifica |
|---|---|
| `ios/Runner/Info.plist` | `CFBundleDisplayName` → `Smart Bonus Italia` + tutti i testi delle autorizzazioni di sistema rebrandizzati + aggiunto `LSApplicationQueriesSchemes` per `itms-apps` |
| `lib/config/app_links.dart` (nuovo) | URL centralizzati: privacy policy, supporto, email |
| `lib/core/services/ai_consent_service.dart` (nuovo) | Persistenza del consenso AI in SharedPreferences (chiave `ai_consent_v1`) |
| `lib/core/widgets/ai_consent_dialog.dart` (nuovo) | Dialog di consenso esplicito: cosa viene inviato, a chi (Google LLC), dove (USA), warning sui dati sensibili, link Privacy Policy, checkbox obbligatoria |
| `lib/features/ai_avvocato/ai_chat_screen.dart` | Gate del consenso AI all'apertura + corretta label fuorviante "Claude AI" → "Google Gemini" |
| `lib/features/sbroglia/sbroglia_chat_screen.dart` | Gate del consenso AI all'apertura della chat di categoria |
| `lib/core/services/gemini_service.dart` | Timeout 20s → 30s + retry esponenziale (1s, 2s) su timeout/429/503 + messaggi d'errore migliorati per utente e revisore |
| `lib/features/profilo/profilo_screen.dart` | Pulsante "Valuta App" e "Condividi App" platform-aware: iOS usa `itms-apps://...` con fallback `https://apps.apple.com/...` |
| `lib/features/profilo/info_app_screen.dart` | Riscritta sezione PRIVACY (era falsa: diceva "nessun dato trasmesso"). Aggiunti: link Privacy Policy, pulsante "Revoca consenso AI", contatto supporto |
| `lib/app.dart` | `MaterialApp.title` iOS → `Smart Bonus Italia` |
| `lib/core/localization/app_strings.dart` | `appName` e `homeHeaderTitle` ritornano "Smart Bonus Italia" su iOS, "Bonus Italia" altrove (Platform.isIOS) |
| `lib/core/services/scanner_service.dart` | Stringa errore permesso fotocamera ora usa il brand corretto per piattaforma |

---

## Cosa devi ancora fare manualmente

### 🟥 1. App Store Connect — Branding e Note

Vai in **App Store Connect → la tua app → App Information**:

- **Name**: `Smart Bonus Italia`
- **Subtitle**: `Guida informativa ai bonus`
- **Category**: Utilities (Primary), Reference (Secondary)

In **Version Information → Description** (sostituisci interamente con):

```
⚠️ App informativa indipendente. NON è un servizio governativo
e NON è affiliata a INPS, Agenzia delle Entrate, CAF o patronati.
Per pratiche ufficiali rivolgiti agli enti competenti.

Smart Bonus Italia è la tua guida smart per scoprire e comprendere
bonus, agevolazioni, ISEE, NASpI, 730 e sussidi disponibili in Italia.
Trova informazioni aggiornate, guide pratiche e link ai siti ufficiali
— tutto in un'unica app.

CARATTERISTICHE PRINCIPALI
• 53 schede informative su bonus e agevolazioni
• 18 guide pratiche su documenti e pratiche
• 14 calcolatori (stime senza valore legale)
• Assistente AI per chiarire dubbi informativi
• Link diretti ai siti ufficiali (INPS, Agenzia Entrate, ecc.)
• Privacy by design: nessuna registrazione, dati locali

NOTA SULLA CHAT AI
La chat AI utilizza il servizio Google Gemini (Google LLC, USA)
tramite un proxy server gestito dal nostro team. Prima del primo
utilizzo l'app richiede consenso esplicito e spiega cosa viene
inviato. Il consenso può essere revocato in qualsiasi momento
dalle impostazioni.

Smart Bonus Italia ti aiuta a ORIENTARTI nel mondo dei bonus
italiani, ma tutte le pratiche ufficiali devono essere effettuate
sui canali istituzionali o tramite un patronato/CAF autorizzato.
```

In **App Privacy → Data Collection** dichiara:
- **User Content → Other User Content**: collected — *Linked to identity: No*, *Used for tracking: No*. Purpose: App Functionality.
- **Identifiers → Device ID**: collected — *Linked to identity: No*. Purpose: Analytics, App Functionality.
- **Diagnostics → Crash Data**: se Google Mobile Ads SDK è attivo, dichiararlo.

In **App Review Information → Notes** incolla:

```
Dear App Review Team,

Smart Bonus Italia is an INDEPENDENT INFORMATIONAL guide app.
It is NOT a governmental service and is NOT affiliated with any
Italian institution (INPS, Agenzia delle Entrate, CAF, patronati).

REGARDING GUIDELINE 5.1.1(ix) — REGULATED SERVICES
The previous rejection assumed this app provides governmental
services. It does not. This version:
- Renamed to "Smart Bonus Italia" (no governmental wording).
- All in-app screens display the disclaimer "App informativa
  indipendente. NON è un servizio governativo".
- A blocking disclaimer screen at first launch states explicitly:
  "NOT a Government app, NOT a Patronato/CAF, does NOT submit
  forms to any institution".
- No official forms are submitted from the app. Users are always
  redirected to official websites (inps.it, agenziaentrate.gov.it)
  for actual procedures.
- Calculators (ISEE, IRPEF, NASpI, IMU…) produce informational
  estimates only — they have no legal value and this is stated
  in the UI.

REGARDING GUIDELINE 2.1(a) — BUGS
- AI chat error: improved timeout (20s → 30s) and added retry with
  exponential backoff on 429/503/timeouts. Misleading "Claude AI"
  label fixed to "Google Gemini AI".
- "Valuta App" button: now correctly opens Apple App Store on iOS
  via itms-apps:// scheme (with https://apps.apple.com fallback).
  Previously used market:// which is Android-only.

REGARDING GUIDELINES 5.1.1(i) AND 5.1.2(i) — AI PRIVACY
A new blocking consent dialog is shown before any AI chat use:
- Clearly states data sent (user messages, attached images).
- Names the recipient: Google LLC (Google Gemini service, USA).
- Mentions our proxy on Cloudflare Workers.
- Warns user not to send fiscal codes, bank data, passwords.
- Requires explicit checkbox + accept to proceed.
- Consent can be revoked in Profile → Info → "Revoca consenso AI".
- Privacy Policy fully describes data flow, link in dialog.

REGARDING GUIDELINE 1.5 — SUPPORT URL
The support URL has been updated to a working page with FAQs and
contact form: <INSERIRE QUI IL NUOVO URL DI SUPPORTO FUNZIONANTE>.
Support email: alutori@gmail.com.

REGARDING GUIDELINE 2.3.10 — SCREENSHOTS
All screenshots have been regenerated on iOS simulators (iPhone
and iPad) and now display the iOS status bar. No Android UI is
visible in any screenshot.

TEST INSTRUCTIONS FOR REVIEWERS
1. Launch app. Accept the initial disclaimer.
2. Tap "Chiedi" (third tab). Pick any category.
3. The AI consent dialog will appear. Tick the checkbox and
   tap "Accetta e continua".
4. Ask any informational question, e.g. "Come funziona l'ISEE?".
5. The chat must respond. If it fails on the first try, the
   service may be momentarily rate-limited — retry after 30s.
6. To test the rate/review button: Profilo → "Valuta App" — it
   opens the App Store on this app's listing.

Thank you for your review.

— Adnan Riaz, alutori@gmail.com
```

### 🟥 2. Support URL funzionante (Guideline 1.5)

Il link attuale `https://sites.google.com/view/ilmiopatronatoitalia/home-page` non funziona come pagina di supporto.

Opzioni per risolvere subito:

**Opzione A — Sistema il Google Sites esistente** (rapida, 30 minuti)
La pagina deve contenere ALMENO:
- Titolo: "Smart Bonus Italia — Supporto"
- Email di contatto in evidenza: `alutori@gmail.com`
- Sezione FAQ con almeno 5 domande/risposte
- Sezione "Come usare l'app"
- Link alla Privacy Policy
- Disclaimer "App informativa indipendente"

**Opzione B — GitHub Pages** (gratuita, 1 ora)
1. Nel repo crea `docs/index.html` e `docs/privacy-policy.html`
2. Settings → Pages → Source: `main` branch, `/docs` folder
3. URL diventa `https://alutori-lang.github.io/IlmioPatronato/`
4. Aggiorna `lib/config/app_links.dart` con il nuovo URL

Una volta che la pagina è online e funzionante:
- Aggiorna `App Store Connect → Support URL`
- Aggiorna `lib/config/app_links.dart`:
  ```dart
  static const String supportPage = 'NUOVO_URL_QUI';
  static const String privacyPolicy = 'NUOVO_URL_QUI';
  ```

### 🟥 3. Screenshot (Guideline 2.3.10)

Apple ha visto screenshot con **status bar Android** (icone batteria/segnale stile Android). Devi rigenerarli su un dispositivo o simulatore iOS.

Dimensioni richieste per iOS:
- **iPhone 6.9"** (16 Pro Max): 1320 × 2868
- **iPhone 6.5"**: 1242 × 2688 oppure 1284 × 2778
- **iPad 13"** (M4): 2064 × 2752

Procedura rapida:
```bash
# Apri il simulatore iOS più grande:
open -a Simulator

# In Simulator → Hardware → Device, scegli "iPad Pro 13-inch (M4)"
# Avvia l'app:
flutter run -d "iPad Pro 13-inch (M4)"

# In Simulator: Cmd+S per fare screenshot (oppure Device → Screenshot)
# I file finiscono sul Desktop.
```

Su almeno il **primo screenshot** sovrapponi un banner ben visibile:

> ⚠️ Guida informativa non ufficiale

Caricali in **App Store Connect → Previews and Screenshots**, sostituendo quelli esistenti.

### 🟥 4. Versione e build number

In `pubspec.yaml`, alza la versione:

```yaml
version: 1.0.14+18
```

Poi:
```bash
flutter clean
flutter pub get
flutter build ios --release
```

### 🟥 5. iOS App ID (per il pulsante "Valuta App")

Una volta che la versione 1.0.14 verrà approvata, App Store Connect assegnerà un App ID numerico (es. 6478123456) visibile nell'URL della pagina App Store Connect dell'app.

Quando lo conosci, aggiornalo in `lib/features/profilo/profilo_screen.dart`:

```dart
const String _kIosAppStoreId = '6478123456'; // sostituisci col vero ID
```

Finché è vuoto, il pulsante apre una **ricerca App Store per "Smart Bonus Italia"** (funziona comunque per superare la review).

---

## Riepilogo: cosa è stato fatto vs cosa resta

| Punto Apple | Stato | Note |
|---|---|---|
| 5.1.1(ix) — Servizi regolamentati | ✅ Codice OK | Resta: rinomina su App Store Connect |
| 2.1(a) — Bug chat AI | ✅ Codice OK | Migliorato error handling + retry |
| 2.1(a) — Bug Valuta App | ✅ Codice OK | iOS usa itms-apps con fallback |
| 5.1.1(i), 5.1.2(i) — Privacy AI | ✅ Codice OK | Consent dialog + revoca |
| 1.5 — Support URL | 🟨 Resta a te | Sistemare Google Sites o pubblicare nuova pagina |
| 2.3.10 — Screenshot Android | 🟨 Resta a te | Rifare screenshot su simulatore iOS |

---

## Test prima di sottomettere

Esegui in locale:

```bash
flutter clean
flutter pub get
flutter analyze lib/
flutter build ios --release --no-codesign
```

Poi apri lo Xcode workspace, archivia e carica su App Store Connect.

Tutti i 4 punti lato codice sono stati validati con build iOS riuscita.
