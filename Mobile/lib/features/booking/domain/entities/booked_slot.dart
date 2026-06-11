// lib/features/booking/domain/entities/booked_slot.dart
class BookedSlot {
  final String startTime;
  final String endTime;
  final String userName;

  BookedSlot({required this.startTime, required this.endTime, required this.userName});
}