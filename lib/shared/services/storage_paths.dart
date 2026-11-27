/// Buckets and object names used in Supabase Storage.
///
/// The bucket says what the file is and the first folder (or the file name,
/// for avatars) says who owns it, so any object can be traced to its entity:
///
/// * `businesses_pictures/<businessId>/<uuid>.webp`
/// * `profile_pictures/<userId>.webp`
/// * `feedback_attachments/<userId>/<uuid>.webp`
///
/// Server rules depend on these shapes (`owns_listing_image` needs
/// `<businessId>/<file>`, `account_deletion_storage_paths` needs
/// `<userId>.<ext>`), so change them together with the SQL.
class StoragePaths {
  StoragePaths._();

  static const String businessesBucket = 'businesses_pictures';
  static const String profilesBucket = 'profile_pictures';
  static const String feedbackBucket = 'feedback_attachments';

  /// Extension of every object written by the app.
  static const String extension = 'webp';

  /// Extensions the avatar was stored with before WebP; see [legacyAvatarPaths].
  static const List<String> legacyAvatarExtensions = [
    'jpg',
    'jpeg',
    'png',
    'heic',
  ];

  /// New business photo. [objectId] is a fresh UUID so photos never overwrite
  /// each other.
  static String businessImage(String businessId, String objectId) =>
      '$businessId/$objectId.$extension';

  /// The one avatar of a user. Fixed name: a new photo overwrites the old one.
  static String userAvatar(String userId) => '$userId.$extension';

  /// Avatars uploaded before WebP (`<userId>.jpg`, ...), to delete when the
  /// new one is stored.
  static List<String> legacyAvatarPaths(String userId) => [
    for (final ext in legacyAvatarExtensions) '$userId.$ext',
  ];

  /// Feedback screenshot, grouped by the user that sent it.
  static String feedbackAttachment(String userId, String objectId) =>
      '$userId/$objectId.$extension';

  /// Object path inside [bucket] from a Storage public URL, or `null` when
  /// [url] does not point into that bucket.
  static String? objectPathFromPublicUrl(String url, String bucket) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(bucket);
    if (bucketIndex < 0 || bucketIndex == segments.length - 1) return null;
    // pathSegments is already percent-decoded.
    return segments.skip(bucketIndex + 1).join('/');
  }
}
