// Removes from Storage the files queued in public.storage_cleanup_queue (for
// example the photos of a deleted business), then marks them as done.
//
// Deployed with verify_jwt = true; only the service role key is accepted, so
// it can be called from pg_cron/pg_net, a scheduled task or by hand:
//   POST { "batch_size": 100 }   (Authorization: Bearer <service role key>)
// Removing a file that no longer exists is not an error, so it is safe to
// retry or to run twice.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const BUCKETS = new Set([
  "profile_pictures",
  "businesses_pictures",
  "feedback_attachments",
]);

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const bearer = (req.headers.get("authorization") ?? "").replace(
    /^Bearer\s+/i,
    "",
  );
  if (bearer !== serviceKey) return json(401, { error: "unauthorized" });

  let batchSize = 100;
  try {
    const body = await req.json();
    if (Number.isInteger(body.batch_size)) batchSize = body.batch_size;
  } catch (_) {
    // default batch size
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await admin.rpc("claim_storage_cleanup", {
    batch_size: batchSize,
  });
  if (error) return json(500, { error: "claim_failed" });

  const rows = (data ?? []) as { id: number; bucket: string; path: string }[];
  const byBucket = new Map<string, { ids: number[]; paths: string[] }>();
  for (const row of rows) {
    if (!BUCKETS.has(row.bucket) || !row.path) continue;
    const entry = byBucket.get(row.bucket) ?? { ids: [], paths: [] };
    entry.ids.push(row.id);
    entry.paths.push(row.path);
    byBucket.set(row.bucket, entry);
  }

  let removed = 0;
  const failedBuckets: string[] = [];
  for (const [bucket, { ids, paths }] of byBucket) {
    const { error: removeError } = await admin.storage.from(bucket).remove(paths);
    if (removeError) {
      failedBuckets.push(bucket);
      continue;
    }
    const { error: doneError } = await admin.rpc("complete_storage_cleanup", {
      ids,
    });
    if (doneError) failedBuckets.push(bucket);
    else removed += ids.length;
  }

  return json(failedBuckets.length ? 500 : 200, {
    claimed: rows.length,
    removed,
    failed_buckets: failedBuckets,
  });
});
