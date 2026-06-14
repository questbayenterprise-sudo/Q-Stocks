class CustomerModel {
  final String id;
  final String name;
  final String phone;

  CustomerModel({required this.id, required this.name, this.phone = ""});

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}