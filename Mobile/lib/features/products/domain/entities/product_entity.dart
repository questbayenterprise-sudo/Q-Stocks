class ProductEntity {
  final String id;
  final String name;
  final String categoryId;
  final String uom; // KG, Piece, Tray
  final double basePrice;
  final String imageUrl;

  ProductEntity({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.uom,
    required this.basePrice,
    required this.imageUrl,
  });
}