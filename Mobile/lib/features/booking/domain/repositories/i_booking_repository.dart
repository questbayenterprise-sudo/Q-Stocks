import '../entities/booking_info.dart';

abstract class IBookingRepository {
  Future<void> submitBooking(BookingInfo info);
  Future<List<dynamic>?> fetchBookingHistory(String? userId, {String? userType});
  Future<bool> checkAvailability(String date, String start, String end, String venueId);
  Future<List<Map<String, dynamic>>> fetchVenueSlots(String venueId);
  Future<List<Map<String, dynamic>>> fetchExistingBookings(String venueId, String date);
  Future<Map<String, dynamic>?> fetchBookingQRDetails(int bookingId);
}
