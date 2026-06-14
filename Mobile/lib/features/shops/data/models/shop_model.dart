import '../../domain/entities/shop_entity.dart';

class ShopModel extends ShopEntity {
  ShopModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    required super.locationName,
    required super.price,
    required super.description,
    super.createdBy,
  });

  // Convert SQLite Map or JSON to ShopModel
  factory ShopModel.fromMap(Map<String, dynamic> map) {
    return ShopModel(
      id: map['id']?.toString() ?? '0',
      name: map['name'] ?? '',
      imageUrl: map['image_url'] ?? '',
      locationName: map['location'] ?? '', // SQLite uses 'location'
      price: double.tryParse(map['price']?.toString() ?? '0.0') ?? 0.0,
      description: map['description'] ?? '',
      createdBy: map['created_by']?.toString(),
    );
  }

  // Convert ShopModel to Map for SQLite Save
  Map<String, dynamic> toMap() {
    return {
      // Don't include ID if it's autoincrement in SQLite
      'name': name,
      'location': locationName,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'created_by': createdBy,
      'is_active': 1,
    };
  }
}