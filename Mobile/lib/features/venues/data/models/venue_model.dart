import 'package:flutter/material.dart'; // Required for TimeOfDay
import 'package:intl/intl.dart';          // Required for DateFormat
import '../../domain/entities/venue.dart';
import '../../domain/entities/venue_slot.dart';

class VenueModel extends VenueEntity {
  VenueModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    required super.locationName,
    required super.price,
    required super.about,
    required List<VenueSlot> slots,
    List<String> sports = const [],
    List<Map<String, dynamic>> sportsData = const [],
    double distanceKm = 0.0,
  }) : super(
         fullAddress: locationName,
         distance: distanceKm,
         rating: 4.5,
         reviewsCount: 120,
         isBookable: true,
         sportsIcons: ['soccer'],
         amenities: ['Parking', 'Water', 'Washroom'],
         slots: slots,
         sports: sports,
         sportsData: sportsData,
       );

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    var slotsList = <VenueSlot>[];

    if (json['slots'] != null) {
      slotsList = (json['slots'] as List).map((s) {
        // Helper function to convert "6:00AM" to TimeOfDay
        TimeOfDay stringToTime(String timeStr) {
          try {
            final format = DateFormat("h:mma");
            final dateTime = format.parse(timeStr.trim().toUpperCase());
            return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
          } catch (e) {
            return const TimeOfDay(hour: 0, minute: 0);
          }
        }

        return VenueSlot(
          startTime: stringToTime(s['ST'] ?? ""),
          endTime: stringToTime(s['ET'] ?? ""),
          price: double.tryParse(s['PR'].toString()) ?? 0.0,
        );
      }).toList();
    }

    // Parse sports list
    List<String> sportsList = [];
    if (json['sports'] != null) {
      sportsList = List<String>.from(json['sports']);
    }

    // Parse sports data (id + name)
    List<Map<String, dynamic>> sportsDataList = [];
    if (json['sports_data'] != null && json['sports_data'] is List) {
      sportsDataList = (json['sports_data'] as List)
          .where((s) => s != null)
          .map<Map<String, dynamic>>((s) => {'id': s['id'] ?? 0, 'name': s['name'] ?? ''})
          .toList();
    }

    return VenueModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      locationName: json['location'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      about: json['description'] ?? '',
      slots: slotsList,
      sports: sportsList,
      sportsData: sportsDataList,
      distanceKm: double.tryParse(json['distance_km'].toString()) ?? 0.0,
    );
  }
}