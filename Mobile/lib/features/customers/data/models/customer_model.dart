class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final double currentBalance;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.currentBalance = 0.0,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}