abstract class IBookingRepository {
  Future<List<dynamic>?> fetchBookingHistory(String? userId, {String? userType});
}
