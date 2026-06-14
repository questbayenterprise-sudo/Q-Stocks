class SaleModel {
  final String shopId;
  final String customerId;
  final String productId;
  final double weight;
  final double rate;
  final double totalAmount;
  final double paidAmount;
  final int paymodeId;

  SaleModel({
    required this.shopId,
    required this.customerId,
    required this.productId,
    required this.weight,
    required this.rate,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymodeId,
  });
}