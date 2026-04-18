import 'dart:typed_data';

class BusinessImageData {
  final Uint8List bytes;
  final String fileName;
  final String? mimeType;

  const BusinessImageData({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });
}
