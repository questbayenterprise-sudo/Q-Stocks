import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

class LikesRepository {
  final String _baseUrl = AppConfig.baseUrl;

  Future<bool> toggleLike(int userId, int venueId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ToggleVenueLike'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "venue_id": venueId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['liked'] ?? false;
      }
    } catch (e) {
      debugPrint("LikesRepo.toggle error: $e");
    }
    return false;
  }

  Future<bool> checkLike(int userId, int venueId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/CheckVenueLike'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "venue_id": venueId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['liked'] ?? false;
      }
    } catch (e) {
      debugPrint("LikesRepo.check error: $e");
    }
    return false;
  }

  Future<int> getLikeCount(int venueId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/GetVenueLikeCount'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"venue_id": venueId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
    } catch (e) {
      debugPrint("LikesRepo.count error: $e");
    }
    return 0;
  }

  Future<List<dynamic>?> getLikedVenues(String userId, String userType) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/GetLikedVenues'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "user_type": userType}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'];
      }
    } catch (e) {
      debugPrint("LikesRepo.getLiked error: $e");
    }
    return null;
  }
}
