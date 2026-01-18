class Product {
  final String id;
  final String name;
  final String imageUrl;
  double? discount;
  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.discount,
  });
}
