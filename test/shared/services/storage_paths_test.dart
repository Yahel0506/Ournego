import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/shared/services/storage_paths.dart';

void main() {
  const businessId = '00000000-0000-0000-0000-00000000a0b1';
  const userId = '00000000-0000-0000-0000-0000000000a1';
  const objectId = '11111111-1111-1111-1111-111111111111';

  test('business photos live in the business folder as WebP', () {
    final path = StoragePaths.businessImage(businessId, objectId);

    expect(path, '$businessId/$objectId.webp');
    // Shape required by the server rule private.owns_listing_image.
    expect(path, matches(RegExp(r'^[0-9a-fA-F-]{36}/[^/]+$')));
  });

  test('the avatar has a fixed name derived from the user id', () {
    expect(StoragePaths.userAvatar(userId), '$userId.webp');
    // Shape required by account_deletion_storage_paths.
    expect(
      StoragePaths.userAvatar(userId),
      matches(RegExp('^$userId\\.[^/]+\$')),
    );
  });

  test('legacy avatar paths are the old extensions of the same user', () {
    final legacy = StoragePaths.legacyAvatarPaths(userId);

    expect(legacy, contains('$userId.jpg'));
    expect(legacy, contains('$userId.png'));
    expect(legacy, isNot(contains(StoragePaths.userAvatar(userId))));
  });

  test('feedback attachments are grouped by user', () {
    expect(
      StoragePaths.feedbackAttachment(userId, objectId),
      '$userId/$objectId.webp',
    );
  });

  group('objectPathFromPublicUrl', () {
    const base = 'https://x.supabase.co/storage/v1/object/public';

    test('extracts the path of new and legacy photos', () {
      expect(
        StoragePaths.objectPathFromPublicUrl(
          '$base/businesses_pictures/$businessId/$objectId.webp',
          StoragePaths.businessesBucket,
        ),
        '$businessId/$objectId.webp',
      );
      expect(
        StoragePaths.objectPathFromPublicUrl(
          '$base/businesses_pictures/$businessId/my%20photo.jpg',
          StoragePaths.businessesBucket,
        ),
        '$businessId/my photo.jpg',
      );
    });

    test('returns null for other buckets or malformed input', () {
      expect(
        StoragePaths.objectPathFromPublicUrl(
          '$base/profile_pictures/$userId.webp',
          StoragePaths.businessesBucket,
        ),
        isNull,
      );
      expect(
        StoragePaths.objectPathFromPublicUrl(
          '$base/businesses_pictures',
          StoragePaths.businessesBucket,
        ),
        isNull,
      );
      expect(
        StoragePaths.objectPathFromPublicUrl('', StoragePaths.businessesBucket),
        isNull,
      );
    });
  });
}
