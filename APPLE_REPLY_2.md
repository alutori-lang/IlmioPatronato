## Reply to App Review — Submission b8cad634-e11e-46b0-86a2-fbaf5bbe64f5

Copy/paste this entire reply into the "Reply to App Review" textbox in App Store Connect when resubmitting Smart Bonus Italia 1.0.13 (build 19 or later).

---

Dear App Review Team,

Thank you for the detailed feedback. We have addressed every guideline raised in the rejection. Please find our responses and code changes below.

---

### Guideline 2.1(b) — Business Model

Smart Bonus Italia is a **free, informational, ad-supported guide app**. It does **not** sell, resell, or grant access to any paid service, subscription, governmental service, or third-party offering.

1. **Who are the users that will use the paid services in the app?**
   There are no paid services in the app. The app is entirely free for end users. No subscriptions, no In-App Purchases, no paywalled features. Revenue comes exclusively from AdMob banner ads displayed at the bottom of some screens.

2. **Where can users purchase the services that can be accessed in the app?**
   No purchases are possible inside the app, and the app does not link users to any external paid service. Users are sometimes redirected to official Italian government websites (inps.it, agenziaentrate.gov.it) to read public, free information — these are not paid services.

3. **What specific types of previously purchased services can a user access in the app?**
   None. There is no concept of "previously purchased" content. Every feature in the app is freely accessible to every user from the moment they install it.

4. **What paid content, subscriptions, or features are unlocked within the app that do not use In-App Purchase?**
   None. There is no unlockable content of any kind. The app has no "premium" tier, no hidden features, no external payment flow. Every screen and every tool is available to every user, free, from day one.

5. **How do users obtain an account? Do users have to pay a fee to create an account?**
   The app does **not** have an account system. There is no login, no signup, no email/password, no Sign in with Apple, no Google sign-in, no server-side user record. Users can use 100% of the app without ever providing any identifying information.
   The only "profile" in the app is a local form (ISEE, age, family size, citizenship, employment status) saved in SharedPreferences on the user's device, used solely to filter which government benefits to suggest. Nothing leaves the device.

---

### Guideline 2.1 — Logout

Since the app has no login or server-side account (see answer to 2.1(b) question 5), there is no logout flow.

The only personal data the app stores is a local profile in SharedPreferences. To give users full control over that data we have added an in-app **"Cancella i miei dati e account"** ("Delete my data and account") button.

**Location**: Profilo tab → Informazioni app → bottom of the page, red button with trash icon.

When tapped, it:
1. Shows a confirmation dialog
2. On confirm, clears the local profile (`ProfiloUtenteService.clear()`)
3. Revokes the AI consent flag (`AiConsentService.revoke()`)
4. Wipes every other SharedPreferences entry (`prefs.clear()`)
5. Confirms with a SnackBar and returns the user to the previous screen

A screen recording demonstrating this flow is attached to this submission in the App Review Information → Notes field.

---

### Guideline 5.1.1(v) — Account Deletion

Per the answer above, the app does not create a server-side account. There is therefore no remote data tied to the user — every byte the app stores is in the local SharedPreferences on the user's own device.

To meet the spirit of 5.1.1(v) we have nonetheless added an explicit in-app **"Cancella i miei dati e account"** flow (described in the Guideline 2.1 section above) that wipes 100% of the user's local footprint in one tap.

The button:
- Is labelled clearly so reviewers can find it without searching
- Is placed in the standard Settings / About location (Profilo → Informazioni app)
- Confirms the action with a dialog before destroying data
- Cannot only "deactivate" — it permanently deletes every stored byte
- Requires no external website, no email, no phone call

Code reference: `lib/features/profilo/info_app_screen.dart`, function `_confirmDeleteData`.

---

### Guideline 2.3.10 — iPad Screenshots

We have re-uploaded the iPad 13" screenshots. The previous set was generated from a macOS-hosted simulator and accidentally captured the macOS menu bar at the top of the frame. The new set was generated directly from the iOS Simulator's "Save Screen" feature (Cmd+S) on an iPad Pro 13" runtime, which produces clean 2064×2752 PNGs with only the iOS status bar — no macOS chrome.

---

### Summary of changes in this resubmission

- **Code**: Added in-app "Delete my data and account" flow (`lib/features/profilo/info_app_screen.dart`).
- **Metadata**: Re-uploaded iPad 13" screenshots without any macOS UI elements.
- **App Review Information → Notes**: Added a screen recording of the delete-data flow on a physical device.

We remain at your disposal for any further clarification.

Kind regards,
Adnan Riaz
