class Slide {
  final String title;
  final String description;
  final String imagePath;
  String? darkImagePath;
  String? buttonText;

  Slide({
    required this.title,
    required this.description,
    required this.imagePath,
    this.darkImagePath,
    this.buttonText,
  });
}
