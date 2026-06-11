import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:q_play/features/auth/Session/user_session.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/venue.dart';
import '../models/venue_model.dart';

class VenueRepository {
  final String baseUrl = AppConfig.baseUrl;

  get _slots => null;

  Future<List<VenueEntity>> fetchVenues({double? latitude, double? longitude, int? cityId}) async {
    final url = Uri.parse('$baseUrl/Venue_overall_list');
    final session = UserSession();
    try {
      final body = <String, dynamic>{
        "search": "",
        "pageno": 1,
        "pagesize": 20,
        "distancebetween": 0,
        "rating": 0,
        "sortby": "id",
        "user_id": session.userId ?? "",
        "user_type": session.userType?.name ?? "user",
      };
      if (latitude != null && longitude != null) {
        body["latitude"] = latitude;
        body["longitude"] = longitude;
      }
      if (cityId != null) {
        body["city_id"] = cityId;
      }
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
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

  Future<void> saveVenueToServer(VenueEntity venue, {String? id}) async {
     final bool isUpdate = venue.id != null && venue.id.isNotEmpty;

  final url = Uri.parse(
    isUpdate 
      ? '$baseUrl/UpdateVenue'
      : '$baseUrl/InsertVenue'
  );

  try {
    var request = http.MultipartRequest('POST', url);

    if (isUpdate) {
      request.fields['id'] = venue.id; // only for update
    }
      request.fields['name'] = venue.name;
      request.fields['location'] = venue.locationName;
      request.fields['price'] = venue.price.toString();
      request.fields['description'] = venue.about;
      request.fields['userid'] = UserSession().userId!;
      // Add this line inside saveVenueToServer before request.send()
      // if (_slots.isNotEmpty) {
      //   request.fields['slots'] = jsonEncode(
      //     _slots.map((s) => s.toJson()).toList(),
      //   );
      // }
      if (venue.slots.isNotEmpty) {
        final formattedSlots = venue.slots.map((s) => s.toApiJson()).toList();
        // If API expects a list of slot objects:
        request.fields['slots'] = jsonEncode(formattedSlots);

        // Note: If the API expects only the FIRST selected slot as a single object:
        // request.fields['slots'] = jsonEncode(formattedSlots.first);
      }
     if (venue.imageUrl.isNotEmpty) {
  final file = File(venue.imageUrl);
  
  // 1. Check if the path is a local file on the device
  if (file.existsSync()) {
    request.files.add(
      await http.MultipartFile.fromPath('image', venue.imageUrl),
    );
  } else {
    // 2. If it's NOT a local file, it's a server path (from Edit mode)
    // We send the existing path as a text field so the server knows which image to keep
    request.fields['existing_image'] = venue.imageUrl;
  }
}

      // 1. Get the streamed response
      final streamedResponse = await request.send();

      // 2. Convert to standard response to read the body
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return; // Success!
        } else {
          throw Exception(data['message'] ?? "Server failed to save turf");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Repo Error: $e");
      rethrow;
    }
  }

  // Add Delete API
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

  // Add Edit (Fetch Detail) API
  Future<VenueEntity> fetchVenueById(String id) async {
    final url = Uri.parse('$baseUrl/EditVenue'); // Or specific detail endpoint
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id}),
    );
    final data = jsonDecode(response.body);
    return VenueModel.fromJson(data['data'] ?? data['rows'][0]);
  }
}
