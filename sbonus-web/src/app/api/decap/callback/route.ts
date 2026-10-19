import { cookies } from "next/headers";
import { timingSafeEqual } from "node:crypto";

export const dynamic = "force-dynamic";

const html = (body: string, status = 200) =>
  new Response(`<!doctype html><html lang="it"><meta charset="utf-8"><meta name="robots" content="noindex"><body>${body}</body></html>`, {
    status,
    headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" },
  });

/**
 * Risposta al popup di login secondo il protocollo di Decap CMS: il popup
 * annuncia "authorizing:github", attende la risposta della finestra del CMS
 * e invia il token SOLO a quella origine (la stessa del sito).
 */
function risposta(origin: string, stato: "success" | "error", payload: Record<string, string>) {
  const msg = JSON.stringify(`authorization:github:${stato}:${JSON.stringify(payload)}`);
  const target = JSON.stringify(origin);
  return html(`<script>
  (function () {
    var target = ${target};
    function onMessage(e) {
      if (e.origin !== target) return;
      window.opener.postMessage(${msg}, target);
      window.removeEventListener("message", onMessage);
      setTimeout(function () { window.close(); }, 200);
    }
    window.addEventListener("message", onMessage);
    window.opener && window.opener.postMessage("authorizing:github", target);
  })();
</script><p>Accesso in corso…</p>`);
}

export async function GET(req: Request) {
  const url = new URL(req.url);
  const origin = url.origin;
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state") ?? "";
  const jar = await cookies();
  const atteso = jar.get("decap_oauth_state")?.value ?? "";
  jar.delete({ name: "decap_oauth_state", path: "/api/decap" });

  const stateOk = atteso.length > 0 && atteso.length === state.length && timingSafeEqual(Buffer.from(atteso), Buffer.from(state));
  if (!code || !stateOk) return risposta(origin, "error", { error: "Richiesta di accesso non valida o scaduta. Riprova." });

  const clientId = process.env.DECAP_GITHUB_CLIENT_ID;
  const clientSecret = process.env.DECAP_GITHUB_CLIENT_SECRET;
  if (!clientId || !clientSecret) return html("Login redazione non configurato.", 503);

  try {
    const r = await fetch("https://github.com/login/oauth/access_token", {
      method: "POST",
      headers: { Accept: "application/json", "Content-Type": "application/json" },
      body: JSON.stringify({ client_id: clientId, client_secret: clientSecret, code, redirect_uri: `${origin}/api/decap/callback` }),
      cache: "no-store",
    });
    const data = (await r.json()) as { access_token?: string; error?: string };
    if (!r.ok || !data.access_token) return risposta(origin, "error", { error: "GitHub ha rifiutato l'accesso." });
    return risposta(origin, "success", { token: data.access_token, provider: "github" });
  } catch {
    // Nessun dettaglio tecnico esposto all'utente
    return risposta(origin, "error", { error: "Impossibile completare l'accesso. Riprova più tardi." });
  }
}
