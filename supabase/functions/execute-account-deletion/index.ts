// OUR-152 - Executes a scheduled account deletion.
//
// Order: Storage files -> delete_user_data(uid) -> auth.admin.deleteUser ->
// request marked `completed`. Every step is idempotent, so a request left in
// `failed` (or interrupted midway) can be retried safely. A `scheduled` request
// runs only once execute_after has passed, so it cannot race a cancellation.
//
// Deployed with verify_jwt = false (pg_net sends no JWT); the function does its
// own check and accepts either:
//   - the one-time token of public.dispatch_due_account_deletions() (OUR-153,
//     run by pg_cron): POST { "request_id": "<uuid>", "dispatch_token": "<hex>" }
//   - the service role key as Bearer, for a manual run: POST { "request_id" }
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const BUCKETS = new Set([
  "profile_pictures",
  "businesses_pictures",
  "feedback_attachments",
]);
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// Constant-time comparison so the key check does not leak its length/prefix.
function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  }
  return diff === 0;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const bearer = (req.headers.get("authorization") ?? "").replace(
    /^Bearer\s+/i,
    "",
  );

  let requestId: string | undefined;
  let dispatchToken: string | undefined;
  try {
    const body = await req.json();
    requestId = body.request_id;
    dispatchToken = body.dispatch_token;
  } catch (_) {
    // handled below
  }
  if (!requestId || !UUID_PATTERN.test(requestId)) {
    return json(400, { error: "invalid_request_id" });
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  if (!bearer || !safeEqual(bearer, serviceKey)) {
    if (typeof dispatchToken !== "string" || !dispatchToken) {
      return json(401, { error: "unauthorized" });
    }
    const { data: valid, error: tokenError } = await admin.rpc(
      "consume_account_deletion_dispatch",
      { p_request_id: requestId, p_token: dispatchToken },
    );
    if (tokenError) return json(500, { error: "token_check_failed" });
    if (valid !== true) return json(401, { error: "unauthorized" });
  }

  const { data: request, error: loadError } = await admin
    .from("account_deletion_requests")
    .select("id, user_id, status, execute_after")
    .eq("id", requestId)
    .maybeSingle();
  if (loadError) return json(500, { error: "load_failed" });
  if (!request) return json(404, { error: "not_found" });
  if (request.status === "completed") {
    return json(200, { status: "completed", already: true });
  }
  if (request.status !== "scheduled" && request.status !== "failed") {
    return json(409, { error: "not_executable", status: request.status });
  }
  if (
    request.status === "scheduled" &&
    (!request.execute_after || new Date(request.execute_after) > new Date())
  ) {
    return json(409, { error: "not_due", execute_after: request.execute_after });
  }

  const markFailed = async () => {
    await admin
      .from("account_deletion_requests")
      .update({ status: "failed" })
      .eq("id", request.id)
      .in("status", ["scheduled", "failed"]);
  };

  try {
    // user_id is NULL only if the auth user was already deleted on a previous
    // attempt that died before the final update; the data is gone by then.
    if (request.user_id) {
      const uid: string = request.user_id;

      const { data: paths, error: pathsError } = await admin.rpc(
        "account_deletion_storage_paths",
        { uid },
      );
      if (pathsError) throw new Error("storage_paths");

      const byBucket = new Map<string, string[]>();
      for (const row of (paths ?? []) as { bucket: string; path: string }[]) {
        if (!BUCKETS.has(row.bucket) || !row.path) continue;
        byBucket.set(row.bucket, [...(byBucket.get(row.bucket) ?? []), row.path]);
      }
      for (const [bucket, files] of byBucket) {
        // Removing a file that no longer exists is not an error.
        const { error } = await admin.storage.from(bucket).remove(files);
        if (error) throw new Error(`storage_remove:${bucket}`);
      }

      const { error: dataError } = await admin.rpc("delete_user_data", { uid });
      if (dataError) throw new Error("delete_user_data");

      const { error: authError } = await admin.auth.admin.deleteUser(uid);
      // Already deleted by an earlier attempt: treat as success.
      if (authError && authError.status !== 404) throw new Error("delete_user");
    }

    const { error: doneError } = await admin
      .from("account_deletion_requests")
      .update({ status: "completed", completed_at: new Date().toISOString() })
      .eq("id", request.id);
    if (doneError) throw new Error("mark_completed");

    return json(200, { status: "completed" });
  } catch (e) {
    console.error("account deletion failed", requestId, (e as Error).message);
    await markFailed();
    return json(500, { status: "failed", step: (e as Error).message });
  }
});
