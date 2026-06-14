class ShopEntity {
  final String id;
  final String name;
  final String imageUrl;
  final String locationName;
  final double price;
  final String description;
  final String? createdBy;

  ShopEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.locationName,
    required this.price,
    required this.description,
    this.createdBy,
  });
}