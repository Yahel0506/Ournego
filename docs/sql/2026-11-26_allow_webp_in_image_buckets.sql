-- WebP uploads: the image buckets only allowed jpg/jpeg/png, so every
-- compressed upload would have been rejected. feedback_attachments has no
-- mime restriction.
update storage.buckets
set allowed_mime_types = (select array(select distinct unnest(allowed_mime_types || array['image/webp'])))
where id in ('businesses_pictures', 'profile_pictures');
