import 'package:flutter/foundation.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// How an image is resized and encoded before it leaves the device.
///
/// Every upload goes through one of these presets so quality and size limits
/// live in a single place instead of being repeated in each feature.
class ImageCompressionProfile {
  /// Longest side, in pixels. Larger images are scaled down, never up.
  final int maxDimension;

  /// WebP quality, 1-100.
  final int quality;

  const ImageCompressionProfile({
    required this.maxDimension,
    required this.quality,
  });

  /// Business listing photos (cover and gallery): shown full width on a phone.
  static const business = ImageCompressionProfile(
    maxDimension: 1600,
    quality: 80,
  );

  /// Profile photos: displayed small, so a low resolution is enough.
  static const avatar = ImageCompressionProfile(maxDimension: 512, quality: 85);

  /// Feedback screenshots: only need to stay legible for the team.
  static const attachment = ImageCompressionProfile(
    maxDimension: 1280,
    quality: 75,
  );
}

/// The compressed image, always WebP.
class CompressedImage {
  final Uint8List bytes;

  const CompressedImage(this.bytes);

  static const String contentType = 'image/webp';
  static const String extension = 'webp';
}

/// Thrown when the platform could not produce a WebP image.
class ImageCompressionException implements Exception {
  final String message;

  const ImageCompressionException(this.message);

  @override
  String toString() => 'ImageCompressionException: $message';
}

/// Platform call that encodes [bytes] as WebP. Injectable so tests do not need
/// the native plugin.
typedef WebpEncoder =
    Future<Uint8List> Function(
      Uint8List bytes, {
      required int maxDimension,
      required int quality,
    });

Future<Uint8List> _nativeWebpEncoder(
  Uint8List bytes, {
  required int maxDimension,
  required int quality,
}) {
  return FlutterImageCompress.compressWithList(
    bytes,
    minWidth: maxDimension,
    minHeight: maxDimension,
    quality: quality,
    format: CompressFormat.webp,
    keepExif: false,
  );
}

/// Compresses and converts every image to WebP before it is uploaded to
/// Supabase Storage. It is the only place that decides quality and size.
class ImageCompressionService {
  final WebpEncoder _encode;

  ImageCompressionService({WebpEncoder? encoder})
    : _encode = encoder ?? _nativeWebpEncoder;

  /// Returns [source] resized to [profile] and encoded as WebP.
  ///
  /// Throws [ImageCompressionException] when [source] is empty, cannot be
  /// decoded, or the platform returns nothing. An original is never uploaded
  /// as a fallback, so Storage only ever holds WebP.
  Future<CompressedImage> compress(
    Uint8List source, {
    ImageCompressionProfile profile = ImageCompressionProfile.business,
  }) async {
    if (source.isEmpty) {
      throw const ImageCompressionException('empty image');
    }
    final Uint8List result;
    try {
      result = await _encode(
        source,
        maxDimension: profile.maxDimension,
        quality: profile.quality,
      );
    } catch (e) {
      debugPrint('Image compression failed: $e');
      throw ImageCompressionException('encoder failed: $e');
    }
    if (result.isEmpty) {
      throw const ImageCompressionException('encoder returned no data');
    }
    return CompressedImage(result);
  }
}
