import '../entities/booking_info.dart';

abstract class IBookingRepository {
  Future<void> submitBooking(BookingInfo info);
}
