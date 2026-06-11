enum BookingStatus { confirmed, pending, cancelled, unknown }

class WeeklyTrend {
  final String day;
  final int count;

  WeeklyTrend({required this.day, required this.count});

  factory WeeklyTrend.fromJson(Map<String, dynamic> json) {
    return WeeklyTrend(
      day: json['day'] ?? '',
      // Use toInt() just in case the API sends it as a number format
      count: (json['count'] ?? 0).toInt(),
    );
  }
}
class TurfAnalytics {
  final int totalBookings;
  final double totalRevenue;
  final double occupancy;
  final List<WeeklyTrend> weeklyTrend;

  TurfAnalytics({
    required this.totalBookings,
    required this.totalRevenue,
    required this.occupancy,
    required this.weeklyTrend,
  });

  factory TurfAnalytics.fromJson(Map<String, dynamic> json) {
  return TurfAnalytics(
    totalBookings: _toInt(json['total_bookings']),
    totalRevenue: _toDouble(json['total_revenue']),
    occupancy: _toDouble(json['occupancy']),
weeklyTrend: (json['weekly_trend'] as List? ?? [])
    .map((i) => WeeklyTrend.fromJson(i))
    .toList(),    );
}

  // ---------- Safe Parsers ----------

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

 static List<WeeklyTrend> _parseWeeklyTrend(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .map((e) => WeeklyTrend.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }
  return [];
}
}
class RecentBooking {
  final int id;
  final String courtName;
  final String userName;
  final String bookingRef;
  final double price;
  final BookingStatus status;
  final String startTime;

  RecentBooking({
    required this.id,
    required this.courtName,
    required this.userName,
    required this.bookingRef,
    required this.price,
    required this.status,
    required this.startTime,
  });

  factory RecentBooking.fromJson(Map<String, dynamic> json) {
    // Map the String from Go to the Dart Enum
    BookingStatus parseStatus(String? status) {
      switch (status?.toUpperCase()) {
        case 'CONFIRMED': return BookingStatus.confirmed;
        case 'PENDING': return BookingStatus.pending;
        case 'CANCELLED': return BookingStatus.cancelled;
        default: return BookingStatus.unknown;
      }
    }

    return RecentBooking(
      id: json['id'] ?? 0,
      courtName: json['court_name'] ?? '',
      userName: json['user_name'] ?? '',
      bookingRef: json['booking_ref'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      status: parseStatus(json['status']),
      startTime: json['start_time'] ?? '',
    );
  }
}

class HomeCategory {
  final String title;
  final String description;
  final String route;
  HomeCategory({required this.title, required this.description, required this.route});
}