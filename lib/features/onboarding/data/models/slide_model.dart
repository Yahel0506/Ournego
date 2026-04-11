import 'package:ournego/features/onboarding/domain/entities/slide.dart';

class SlideModel extends Slide {
  const SlideModel({
    required super.title,
    required super.description,
    required super.imagePath,
    super.darkImagePath,
    super.buttonText,
  });

  factory SlideModel.fromJson(Map<String, dynamic> json) {
    return SlideModel(
      title: json['title'] as String,
      description: json['description'] as String,
      imagePath: json['image_path'] as String,
      darkImagePath: json['dark_image_path'] as String?,
      buttonText: json['button_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'image_path': imagePath,
      'dark_image_path': darkImagePath,
      'button_text': buttonText,
    };
  }
}
