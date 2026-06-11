import '../../domain/entities/booking_request.dart';

class BookingModel extends BookingRequest {
  const BookingModel({
    required super.userName,
    required super.email,
    required super.phone,
    required super.bookingDate,
    required super.timeSlot,
    required super.venue_id,
    required super.court_id,
    required super.slot_id,
    required super.priceperslot,
    required super.CusUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_name': userName,
      'email': email,
      'phone': phone,
      'booking_date': bookingDate,
      'time_slot': timeSlot,
      'venue_id': venue_id,
      'court_id': court_id,
      'slot_id': slot_id,
      'priceperslot': priceperslot,
      'CusUserId': CusUserId,
    };
  }
}
