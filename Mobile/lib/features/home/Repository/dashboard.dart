import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../Models/home_data.dart';

class HomeRepository {
  final String baseUrl = AppConfig.baseUrl;
  
Future<TurfAnalytics> fetchAnalytics(String userId, String userType) async {
  final response = await http.post(
    Uri.parse('$baseUrl/GetShopAnalytics'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"user_id": userId, "user_type": userType}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      return TurfAnalytics.fromJson(data['data'] ?? {});
    }

    throw Exception(data['message'] ?? "Failed to fetch analytics");
  }

  throw Exception("Server Error: ${response.statusCode}");
}
  Future<List<RecentBooking>> fetchRecentSales(String userId, String userType) async {
  final response = await http.post(
    Uri.parse('$baseUrl/GetRecentSales'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"user_id": userId, "user_type": userType, "limit": 6}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      // Use "as List?" and the null-aware operator "?? []"
      final listData = data['data'] as List? ?? []; 
      return listData.map((e) => RecentBooking.fromJson(e)).toList();
    }
  }
  return [];
}
}