import '../../domain/entities/booking_info.dart';

class BookingInfoModel extends BookingInfo {
  BookingInfoModel({
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile': phoneNumber,
    };
  }
}
