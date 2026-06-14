import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../booking/domain/repositories/i_booking_repository.dart';
import '../../../booking/domain/entities/booking_info.dart';

class BookingRepositoryImpl implements IBookingRepository {
  final String baseUrl = AppConfig.baseUrl;

  // 1. Implementation for Booking History (role-based)
  @override
  Future<List<dynamic>?> fetchBookingHistory(String? userId, {String? userType}) async {
    final url = Uri.parse('$baseUrl/GetMyBookingHistory');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "user_type": userType ?? "user",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Suggestion: Map to a Model here instead of returning dynamic
        if (data['success'] == true) return data['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint("History Repo Error: $e");
    }
    return null;
  }
  
  @override
  Future<void> submitBooking(BookingInfo info) async {
    // For now, redirect to the primary booking flow or provide a clear log
    debugPrint("SubmitBooking called in History Repo for: ${info.email}");
    // If this specific repository isn't meant to handle new bookings, 
    // consider refactoring the interface or returning a specialized failure.
    return; 
  }

  @override
  Future<bool> checkAvailability(String d, String s, String e, String v) async => false;

  @override
  Future<List<Map<String, dynamic>>> fetchVenueSlots(String venueId) async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchExistingBookings(String v, String d) async => [];

  @override
  Future<Map<String, dynamic>?> fetchBookingQRDetails(int bookingId) async => null;
}