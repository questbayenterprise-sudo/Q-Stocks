import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.id,
    required super.name,
    required super.categoryId,
    required super.uom,
    required super.basePrice,
    required super.imageUrl,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
  return ProductModel(
    id: map['id']?.toString() ?? '0',
    name: map['name'] ?? '',
    categoryId: map['category_id']?.toString() ?? '1',
    uom: map['uom'] ?? 'KG',
    basePrice: (map['base_price'] as num?)?.toDouble() ?? 0.0, 
    imageUrl: map['image_url'] ?? '',
  );
}

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category_id': int.tryParse(categoryId) ?? 1,
      'uom': uom,
      'base_price': basePrice,
      'image_url': imageUrl,
      'is_active': 1,
    };
  }
}