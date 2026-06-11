import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/venue.dart';
import '../../domain/entities/venue_slot.dart';
import '../../domain/entities/venue_game.dart';

class VenueModel extends MyVenueEntity {
  VenueModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    required super.locationName,
    required super.price,
    required super.about,
    required List<VenueSlot> slots,
    List<VenueGame> games = const [],
    List<String> sports = const [],
  }) : super(
         fullAddress: locationName,
         distance: 1.2,
         rating: 4.5,
         reviewsCount: 120,
         isBookable: true,
         sportsIcons: ['soccer'],
         amenities: ['Parking', 'Water', 'Washroom'],
         slots: slots,
         games: games,
         sports: sports,
       );

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    var slotsList = <VenueSlot>[];

    if (json['slots'] != null) {
      slotsList = (json['slots'] as List).map((s) {
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

    var gamesList = <VenueGame>[];
    if (json['games'] != null) {
      gamesList = (json['games'] as List)
          .map((g) => VenueGame.fromJson(g as Map<String, dynamic>))
          .toList();
    }

    List<String> sportsList = [];
    if (json['sports'] != null) {
      sportsList = List<String>.from(json['sports']);
    }

    return VenueModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      locationName: json['location'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      about: json['description'] ?? '',
      slots: slotsList,
      games: gamesList,
      sports: sportsList,
    );
  }
}
