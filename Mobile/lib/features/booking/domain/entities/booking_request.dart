import 'package:equatable/equatable.dart';

class BookingRequest extends Equatable {
  final String userName;
  final String email;
  final String phone;
  final String bookingDate;
  final String timeSlot;
  final String venue_id;
  final String court_id;
  final String slot_id;
  final String priceperslot;
  final String CusUserId;
  final String sports_id;

  const BookingRequest({
    required this.userName,
    required this.email,
    required this.phone,
    required this.bookingDate,
    required this.timeSlot,
    required this.venue_id,
    required this.court_id,
    required this.slot_id,
    required this.priceperslot,
    required this.CusUserId,
    this.sports_id = '0',
  });

  @override
  List<Object?> get props => [
    userName,
    email,
    phone,
    bookingDate,
    timeSlot,
    venue_id,
    court_id,
    slot_id,
    priceperslot,
    CusUserId,
    sports_id,
  ];
}
