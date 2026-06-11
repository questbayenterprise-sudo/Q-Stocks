// lib/models/booking.dart
class Booking {
  final String? id;
  final String userId;
  final int courtId;
  final int slotId;

  Booking({
    this.id,
    required this.userId,
    required this.courtId,
    required this.slotId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'court_id': courtId,
      'slot_id': slotId,
    };
  }
}
