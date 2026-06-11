import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:q_play/features/profile/My_Bookings/Repository/IBooking_repository.dart';

import '../../../../core/config/app_config.dart';

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
        if (data['success'] == true) return data['data'];
      }
    } catch (e) {
      debugPrint("History Repo Error: $e");
    }
    return null;
  }

}