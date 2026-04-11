class Slide {
  final String title;
  final String description;
  final String imagePath;
  final String? darkImagePath;
  final String? buttonText;

  const Slide({
    required this.title,
    required this.description,
    required this.imagePath,
    this.darkImagePath,
    this.buttonText,
  });
}
