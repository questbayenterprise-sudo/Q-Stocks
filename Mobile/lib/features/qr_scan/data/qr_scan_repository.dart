import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

class QrScanRepository {
  final String _baseUrl = AppConfig.baseUrl;

  /// Validate scanned QR and get booking details
  Future<Map<String, dynamic>?> validateScan({
    String? bookingRef,
    int? bookingId,
    required int scannerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ValidateScanQR'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          if (bookingRef != null) "booking_ref": bookingRef,
          if (bookingId != null) "booking_id": bookingId,
          "scanner_id": scannerId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 404) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("QrScanRepo.validate error: $e");
    }
    return null;
  }

  /// Update booking status
  Future<Map<String, dynamic>?> updateBookingStatus({
    required int bookingId,
    required String status,
    required int updatedBy,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/UpdateBookingStatus'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "booking_id": bookingId,
          "status": status,
          "updated_by": updatedBy,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 400) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("QrScanRepo.updateStatus error: $e");
    }
    return null;
  }
}
