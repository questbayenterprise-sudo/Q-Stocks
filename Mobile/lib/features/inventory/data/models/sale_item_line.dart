import '../../../products/data/models/product_model.dart';

class SaleItemLine {
  ProductModel? product;
  double quantity;
  double unitPrice;

  SaleItemLine({
    this.product,
    this.quantity = 0.0,
    this.unitPrice = 0.0,
  });

  // Business Logic: Calculate total for this specific row
  double get lineTotal => quantity * unitPrice;
}