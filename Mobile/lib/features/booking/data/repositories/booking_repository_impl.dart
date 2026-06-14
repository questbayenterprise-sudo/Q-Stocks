import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../domain/entities/booked_slot.dart';
import '../../domain/entities/booking_info.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/repositories/i_booking_repository.dart';
import '../models/booking_info_model.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements IBookingRepository {
    final String baseUrl = AppConfig.baseUrl;

  @override
  Future<void> submitBooking(BookingInfo info) async {
    final model = BookingInfoModel(
      firstName: info.firstName,
      lastName: info.lastName,
      email: info.email,
      phoneNumber: info.phoneNumber,
    );

    // CALL GOLANG BACKEND
final response = await http.post(
  Uri.parse("$baseUrl/validate-user"),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(model.toJson()),
);


    if (response.statusCode != 200) {
      throw Exception('Failed to validate user');
    }
  }

  @override
  Future<List<dynamic>?> fetchBookingHistory(String? userId, {String? userType}) async {
    return null; // Placeholder for history logic in this repository
  }

  Future<Map<String, dynamic>?> createBooking(BookingRequest request) async {
    final url = Uri.parse("$baseUrl/Selected_venue_booking");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          BookingModel(
            userName: request.userName,
            email: request.email,
            phone: request.phone,
            bookingDate: request.bookingDate,
            timeSlot: request.timeSlot,
            venue_id: request.venue_id,
            court_id: request.court_id,
            slot_id: request.slot_id,
            priceperslot: request.priceperslot,
            CusUserId: request.CusUserId,
          ).toJson(),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? "Failed to save booking");
        }
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }
  // Update IBookingRepository first, then implement here:
// lib/features/booking/data/repositories/booking_repository_impl.dart

@override
Future<bool> checkAvailability(String date, String start, String end, String venueId) async {
final response = await http.post(
  Uri.parse("$baseUrl/api/check-availability"),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'date': date,
    'start_time': start,
    'end_time': end,
    'venue_id': venueId,
  }),
);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['available'] ?? false;
  }
  return false;
}

Future<List<BookedSlot>> _getMockBookings(String date, String venueId) async {
  // Mocking API call for existing bookings
  return [
    BookedSlot(startTime: "09:00 AM", endTime: "10:00 AM", userName: "Rahul"),
    BookedSlot(startTime: "02:00 PM", endTime: "03:30 PM", userName: "Subhash"),
  ];
}
 @override
  Future<List<Map<String, dynamic>>> fetchVenueSlots(String venueId) async {
 final url = Uri.parse('$baseUrl/GetVenueSlots');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": venueId,
        }),
      );
 
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Convert the dynamic list from JSON to a List of Maps
          return List<Map<String, dynamic>>.from(data['slots']);
        } else {
          throw Exception(data['message'] ?? "Failed to fetch slots");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("fetchVenueSlots Error: $e");
      return []; 
    }
  }
 // lib/features/booking/data/repositories/booking_repository_impl.dart

@override
Future<List<Map<String, dynamic>>> fetchExistingBookings(String venueId, String date) async {
  final url = Uri.parse('$baseUrl/GetExistingBookings');
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "venue_id": venueId, // Ensure key matches Go struct
        "date": date
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Backend returns { "success": true, "data": [...] }
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    }
  } catch (e) {
    debugPrint("fetchExistingBookings Error: $e");
    rethrow; // Better to rethrow so the Bloc/Provider can show an error state
  }
  return []; 
}
/// Initiate booking — handles both payment-enabled and direct confirmation.
/// Returns response with `is_payment_enabled`, `payment_url` (if applicable),
/// `booking_id`, and `status`.
Future<Map<String, dynamic>?> initiateBooking(BookingRequest request) async {
  final url = Uri.parse('$baseUrl/InitiateBooking');
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "venue_id": request.venue_id,
        "date": request.bookingDate,
        "slot_id": request.slot_id,
        "CusUserId": request.CusUserId,
        "court_id": request.court_id,
        "start_time": request.timeSlot.split(' - ').first.trim(),
        "end_time": request.timeSlot.split(' - ').last.trim(),
        "sports_id": request.sports_id,
        "amount": request.priceperslot,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      // Return the error response so UI can show the actual message
      debugPrint("Booking Error [${response.statusCode}]: ${response.body}");
      return {
        "success": false,
        "message": data['message'] ?? "Server error: ${response.statusCode}",
      };
    }
  } catch (e) {
    debugPrint("Booking Init Error: $e");
    return {
      "success": false,
      "message": "Connection error: $e",
    };
  }
}

/// Notify backend of payment result
Future<Map<String, dynamic>?> paymentCallback({
  required int bookingId,
  required String transactionId,
  required String status, // "Success" or "Failed"
}) async {
  final url = Uri.parse('$baseUrl/Payment_Callback');
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "booking_id": bookingId,
        "transaction_id": transactionId,
        "status": status,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
  } catch (e) {
    debugPrint("Payment Callback Error: $e");
  }
  return null;
}

@override
Future<Map<String, dynamic>?> fetchBookingQRDetails(int bookingId) async {
  final url = Uri.parse('$baseUrl/GetBookingQRData');
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "booking_id": bookingId, // Ensure key matches Go struct
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Backend returns { "success": true, "data": [...] }
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['row']); // single object
      }
    }
  } catch (e) {
    debugPrint("Repository Error: $e");
  }
  return null;
}

// ── Hold Slot APIs ──

Future<void> holdSlot({
  required String venueId,
  required String date,
  required String timeSlot,
  required String userId,
}) async {
  final url = Uri.parse('$baseUrl/HoldSlot');
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "venue_id": venueId,
        "date": date,
        "time_slot": timeSlot,
        "user_id": userId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? "Failed to hold slot");
      }
    } else {
      throw Exception("Server Error: ${response.statusCode}");
    }
  } catch (e) {
    rethrow;
  }
}

Future<void> releaseHold({
  required String venueId,
  required String date,
  required String timeSlot,
  required String userId,
}) async {
  final url = Uri.parse('$baseUrl/ReleaseHold');
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "venue_id": venueId,
        "date": date,
        "time_slot": timeSlot,
        "user_id": userId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? "Failed to release hold");
      }
    } else {
      throw Exception("Server Error: ${response.statusCode}");
    }
  } catch (e) {
    rethrow;
  }
}
}