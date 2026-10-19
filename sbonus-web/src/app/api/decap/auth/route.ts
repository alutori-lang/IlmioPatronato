import { cookies } from "next/headers";
import { randomBytes } from "node:crypto";

// Avvio del login GitHub per il pannello /admin (Decap CMS).
// Richiede le variabili d'ambiente DECAP_GITHUB_CLIENT_ID e
// DECAP_GITHUB_CLIENT_SECRET di una GitHub OAuth App (vedi README).

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const clientId = process.env.DECAP_GITHUB_CLIENT_ID;
  if (!clientId) return new Response("Login redazione non configurato.", { status: 503 });

  const state = randomBytes(24).toString("hex");
  (await cookies()).set("decap_oauth_state", state, {
    httpOnly: true,
    secure: true,
    sameSite: "lax",
    path: "/api/decap",
    maxAge: 600,
  });

  const origin = new URL(req.url).origin;
  const url = new URL("https://github.com/login/oauth/authorize");
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("redirect_uri", `${origin}/api/decap/callback`);
  // Il repository è pubblico: basta l'accesso ai repository pubblici
  url.searchParams.set("scope", "public_repo");
  url.searchParams.set("state", state);
  return Response.redirect(url.toString(), 302);
}
