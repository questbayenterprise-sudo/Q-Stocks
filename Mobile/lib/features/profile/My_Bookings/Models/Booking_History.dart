class Booking {
  final int id;
  final String venueName;
  final String startTime;
  final String endTime;
  final String status;
  final double price;
  final String bookingRef;
  final String venueImage;
  final String userName;
  final String bookedAt;

  Booking({
    required this.id,
    required this.venueName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.price,
    required this.bookingRef,
    required this.venueImage,
    required this.userName,
    required this.bookedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? 0,
      venueName: json['venue_name'] ?? 'Unknown Venue',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? 'Pending',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      bookingRef: json['booking_ref'] ?? '#BK-000',
      venueImage: json['venue_image'] ?? '',
      userName: json['user_name'] ?? '',
      bookedAt: json['booked_at'] ?? '',
    );
  }
}
