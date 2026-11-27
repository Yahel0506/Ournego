# Image uploads

All images sent to Supabase Storage go through two shared services in
`lib/shared/services/`; features must not compress or name files themselves.

| Service | Responsibility |
| --- | --- |
| `ImageCompressionService` | Resizes (longest side) and encodes to WebP with `flutter_image_compress`. Profiles: `business` 1600 px / q80, `avatar` 512 px / q85, `attachment` 1280 px / q75. Never falls back to the original: on failure it throws `ImageCompressionException`. EXIF is dropped (removes GPS data from photos). |
| `StoragePaths` | Buckets and object names. |

## Upload points

| Where | Bucket / object | Notes |
| --- | --- | --- |
| Business submit (`submitBusinessListing`) | `businesses_pictures/<businessId>/<uuid>.webp` | File removed if the RPC fails. |
| Gallery add (`insertBusinessImage`) | same | `upsert: false`, new UUID each time; removed if the row update fails. |
| Gallery delete (`deleteBusinessImage`) | removes the object derived from the URL | Works for legacy names too. |
| Avatar (`updateProfilePicture`) | `profile_pictures/<userId>.webp` | Fixed name, overwritten; legacy `<userId>.jpg/jpeg/png/heic` removed. |
| Feedback screenshot | `feedback_attachments/<userId>/<uuid>.webp` | Removed if the `feedback` insert fails. |

The bucket says what the file is; the first folder (or the file name for
avatars) says who owns it. We kept `<businessId>/...` and `<userId>.<ext>`
instead of a `businesses/` or `users/` prefix inside the bucket because the
server rules `private.owns_listing_image` (needs `<uuid>/<file>`) and
`account_deletion_storage_paths` (needs `<uid>.<ext>`) already depend on those
shapes, and the bucket already carries the entity type.

## Legacy files

Before this change files kept the picker's name (`<businessId>/<fileName>`,
possibly `.jpg`/`.png`/`.heic`) and avatars were `<userId>.<ext>`. They are
not migrated: they keep working (URLs are stored) and are removed by the same
flows (gallery delete, account deletion, cleanup queue). A replaced avatar
removes its legacy twin. Re-encoding old files is optional and out of scope.

## Cascade deletion (where it lives)

Deleting rows from `storage.objects` with SQL does not delete the file, so a
pure SQL trigger is not enough. The cascade is split by what the app controls:

* **Account deletion**: already handled by the Edge Function
  `execute-account-deletion`, which lists the user's files with
  `account_deletion_storage_paths(uid)` and removes them through the Storage
  API before `delete_user_data`. New names fit the existing path rules, so it
  needed no change.
* **Business deleted by any other route** (admin, SQL, future feature):
  `docs/sql/2026-11-26_storage_cleanup_queue.sql` adds a trigger on
  `businesses` that queues the photos (folder + URLs in `images`) in
  `storage_cleanup_queue`; the Edge Function `purge-storage-queue` removes
  them with the Storage API and marks them done. Retry-safe.
* **Replaced/removed single image**: handled in the datasource (see table).

Tests: `test/shared/services/*` and
`docs/sql/tests/2026-11-26_storage_cleanup_queue_test.sql`.

## Applied on the remote project (2026-11-26)

* `docs/sql/2026-11-26_allow_webp_in_image_buckets.sql`: the buckets only
  accepted jpg/png, so WebP uploads would have failed.
* `docs/sql/2026-11-26_storage_cleanup_queue.sql` (trigger, queue and RPCs) and
  the Edge Function `purge-storage-queue` (verify_jwt on, service role only).
* Existing files were converted with the same profiles and renamed to the new
  scheme (3 business photos, 7 avatars, 4 feedback screenshots, 13 MB -> under
  1 MB). `businesses.images` and `feedback.attachment` were updated, `owner` /
  `owner_id` of the new objects were copied from the old ones (the Storage
  policies and `owns_listing_image` depend on them) and the old files were
  removed through the Storage API. A temporary Edge Function did the transfer;
  it was replaced by a stub (`tmp-image-migration`, answers 410) and can be
  deleted from the dashboard.

Notes:

* The trigger `on_profile_picture_upload` sets `users.avatar_url` on INSERT
  into `profile_pictures`, so a user's first WebP upload updates it; an
  overwrite is an UPDATE and keeps the URL (the app's cache version handles it).
  Every `avatar_url` was NULL before the migration and still is.
* The `feedback_attachments` bucket is private, so its public URL does not
  open without a signed URL (pre-existing).

## Still pending

1. Schedule `purge-storage-queue` (pg_cron + pg_net or a scheduled task) with
   the service role key; until then queued files are removed only when it is
   invoked by hand.
2. Test on a real device that the WebP compression works (unit tests use a
   fake encoder); native builds need `flutter pub get`.
