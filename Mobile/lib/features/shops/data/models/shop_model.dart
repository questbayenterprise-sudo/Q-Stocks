import '../../domain/entities/shop_entity.dart';

class ShopModel extends ShopEntity {
  ShopModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    required super.locationName,
    required super.description,
    super.createdBy,
  });

  factory ShopModel.fromMap(Map<String, dynamic> map) {
    return ShopModel(
      id: map['id']?.toString() ?? '0',
      name: map['name'] ?? '',
      imageUrl: map['image_url'] ?? '',
      locationName: map['location'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': locationName,
      'description': description,
      'image_url': imageUrl,
      'created_by': createdBy,
      'is_active': 1,
    }; // "price" column removed from here
  }
}