import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Lets the person choose a photo from the gallery and crop it to a square.
abstract class ProfilePhotoPicker {
  /// Returns the cropped photo, or `null` when the person cancels either step.
  Future<File?> pickSquarePhoto();
}

class GalleryProfilePhotoPicker implements ProfilePhotoPicker {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<File?> pickSquarePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
          hideBottomControls: true,
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          toolbarTitle: '',
          backgroundColor: Colors.black,
        ),
        IOSUiSettings(aspectRatioLockEnabled: true),
      ],
    );
    return cropped == null ? null : File(cropped.path);
  }
}
