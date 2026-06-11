// lib/features/bookings/domain/entities/booking.dart
enum BookingStatus { confirmed, pending, cancelled }

class AdminBooking {
  final String id;
  final String userName;
  final String turfName;
  final DateTime dateTime;
  final double amount;
  final BookingStatus status;

  AdminBooking({
    required this.id, required this.userName, required this.turfName,
    required this.dateTime, required this.amount, required this.status,
  });
}