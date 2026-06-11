import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';
import '../../domain/entities/venue.dart';
import '../models/venue_model.dart';

class MyVenueRepository {
  final String baseUrl = AppConfig.baseUrl;

  Future<List<MyVenueEntity>> fetchVenues() async {
    final session = UserSession();
    final url = Uri.parse('$baseUrl/Venue_overall_list');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "search": "",
          "pageno": 1,
          "pagesize": 20,
          "distancebetween": 0,
          "rating": 0,
          "sortby": "id",
          "user_id": session.userId ?? "",
          "user_type": session.userType?.name ?? "user",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List rows = data['rows'] ?? [];
          return rows.map((json) => VenueModel.fromJson(json)).toList();
        }
      }
      throw Exception("Failed to load venues");
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveVenueToServer(MyVenueEntity venue, {String? id}) async {
    final bool isUpdate = venue.id != null && venue.id.isNotEmpty;

    final url = Uri.parse(
      isUpdate
        ? '$baseUrl/UpdateVenue'
        : '$baseUrl/InsertVenue'
    );

    try {
      var request = http.MultipartRequest('POST', url);

      if (isUpdate) {
        request.fields['id'] = venue.id;
      }
      final session = UserSession();
      if (session.userId != null && session.userId!.isNotEmpty) {
        request.fields['userid'] = session.userId!;
      }
      request.fields['name'] = venue.name;
      request.fields['location'] = venue.locationName;
      request.fields['price'] = venue.price.toString();
      request.fields['description'] = venue.about;
      if (venue.slots.isNotEmpty) {
        final formattedSlots = venue.slots.map((s) => s.toApiJson()).toList();
        request.fields['slots'] = jsonEncode(formattedSlots);
      }
      if (venue.games.isNotEmpty) {
        final formattedGames = venue.games.map((g) => g.toJson()).toList();
        request.fields['games'] = jsonEncode(formattedGames);
      }
      if (venue.imageUrl.isNotEmpty) {
        final file = File(venue.imageUrl);
        if (file.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath('image', venue.imageUrl),
          );
        } else {
          request.fields['existing_image'] = venue.imageUrl;
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return;
        } else {
          throw Exception(data['message'] ?? "Server failed to save turf");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVenue(String id) async {
    final url = Uri.parse('$baseUrl/DeleteVenue');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id}),
    );
    if (jsonDecode(response.body)['success'] != true)
      throw Exception("Delete Failed");
  }

  Future<MyVenueEntity> fetchVenueById(String id) async {
    final url = Uri.parse('$baseUrl/EditVenue');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id}),
    );
    final data = jsonDecode(response.body);
    return VenueModel.fromJson(data['data'] ?? data['rows'][0]);
  }
}
