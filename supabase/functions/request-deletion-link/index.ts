// OUR-151 - Public endpoint that asks Supabase Auth for the account-deletion
// magic link without revealing whether the account exists.
//
// Auth itself answers 422 `otp_disabled` for unknown emails and 200 (after the
// ~2 s SMTP send) for known ones. This function hides both differences: it
// always answers 202 `{ ok: true }` after a fixed delay, and sends in the
// background. Deployed with verify_jwt = false (called from the public page).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const REDIRECT_TO =
  "https://www.ournego.com/auth/callback?next=/delete-account/confirm";
const RESPONSE_DELAY_MS = 800;
const ALLOWED_ORIGINS = new Set([
  "https://www.ournego.com",
  "https://ournego.com",
  "http://localhost:3000",
]);
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("origin") ?? "";
  return {
    "Access-Control-Allow-Origin": ALLOWED_ORIGINS.has(origin)
      ? origin
      : "https://www.ournego.com",
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

function reply(req: Request, status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(req), "Content-Type": "application/json" },
  });
}

async function requestLink(email: string): Promise<void> {
  try {
    const url = `${Deno.env.get("SUPABASE_URL")}/auth/v1/otp?redirect_to=${
      encodeURIComponent(REDIRECT_TO)
    }`;
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "apikey": Deno.env.get("SUPABASE_ANON_KEY")!,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, create_user: false }),
    });
    // Never surface the result (422 unknown email, 429 rate limit, 200).
    await res.text();
  } catch (_) {
    // Swallowed on purpose: the caller must not learn anything from failures.
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(req) });
  }
  if (req.method !== "POST") {
    return reply(req, 405, { ok: false });
  }

  let email = "";
  try {
    const body = await req.json();
    email = String(body?.email ?? "").trim().toLowerCase();
  } catch (_) {
    return reply(req, 400, { ok: false });
  }
  // Format validation only; it says nothing about whether the account exists.
  if (email.length > 254 || !EMAIL_PATTERN.test(email)) {
    return reply(req, 400, { ok: false });
  }

  // Send in the background so the response time does not depend on the SMTP.
  EdgeRuntime.waitUntil(requestLink(email));
  await new Promise((resolve) => setTimeout(resolve, RESPONSE_DELAY_MS));
  return reply(req, 202, { ok: true });
});
