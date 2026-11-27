import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/shared/services/image_compression_service.dart';

void main() {
  final source = Uint8List.fromList(List.filled(2000, 7));

  test('returns the encoder output with the profile limits', () async {
    int? seenDimension;
    int? seenQuality;
    final service = ImageCompressionService(
      encoder: (bytes, {required maxDimension, required quality}) async {
        seenDimension = maxDimension;
        seenQuality = quality;
        return Uint8List.fromList([1, 2, 3]);
      },
    );

    final result = await service.compress(
      source,
      profile: ImageCompressionProfile.avatar,
    );

    expect(result.bytes, [1, 2, 3]);
    expect(seenDimension, ImageCompressionProfile.avatar.maxDimension);
    expect(seenQuality, ImageCompressionProfile.avatar.quality);
    expect(CompressedImage.contentType, 'image/webp');
    expect(CompressedImage.extension, 'webp');
  });

  test('uses the business profile by default', () async {
    int? seenDimension;
    final service = ImageCompressionService(
      encoder: (bytes, {required maxDimension, required quality}) async {
        seenDimension = maxDimension;
        return Uint8List.fromList([1]);
      },
    );

    await service.compress(source);

    expect(seenDimension, ImageCompressionProfile.business.maxDimension);
  });

  test('rejects empty input without calling the encoder', () async {
    var called = false;
    final service = ImageCompressionService(
      encoder: (bytes, {required maxDimension, required quality}) async {
        called = true;
        return Uint8List.fromList([1]);
      },
    );

    await expectLater(
      service.compress(Uint8List(0)),
      throwsA(isA<ImageCompressionException>()),
    );
    expect(called, isFalse);
  });

  test('wraps encoder failures and empty output', () async {
    final failing = ImageCompressionService(
      encoder: (bytes, {required maxDimension, required quality}) async =>
          throw StateError('boom'),
    );
    final empty = ImageCompressionService(
      encoder: (bytes, {required maxDimension, required quality}) async =>
          Uint8List(0),
    );

    await expectLater(
      failing.compress(source),
      throwsA(isA<ImageCompressionException>()),
    );
    await expectLater(
      empty.compress(source),
      throwsA(isA<ImageCompressionException>()),
    );
  });

  test('profiles keep sane limits', () {
    for (final profile in [
      ImageCompressionProfile.business,
      ImageCompressionProfile.avatar,
      ImageCompressionProfile.attachment,
    ]) {
      expect(profile.quality, inInclusiveRange(60, 90));
      expect(profile.maxDimension, inInclusiveRange(256, 2048));
    }
    expect(
      ImageCompressionProfile.avatar.maxDimension,
      lessThan(ImageCompressionProfile.business.maxDimension),
    );
  });
}
