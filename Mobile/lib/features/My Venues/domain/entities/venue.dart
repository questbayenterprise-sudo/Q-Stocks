import 'venue_slot.dart';
import 'venue_game.dart';

class MyVenueEntity {
  final String id;
  final String name;
  final String imageUrl;
  final String locationName;
  final String fullAddress;
  final double distance;
  final double price;
  final double rating;
  final int reviewsCount;
  final bool isBookable;
  final List<String> sportsIcons;
  final List<String> sports;
  final String about;
  final List<String> amenities;
  final List<VenueSlot> slots;
  final List<VenueGame> games;

  MyVenueEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.locationName,
    this.fullAddress = "",
    this.distance = 0.0,
    required this.price,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.isBookable = true,
    this.sportsIcons = const [],
    this.sports = const [],
    required this.about,
    this.amenities = const [],
    this.slots = const [],
    this.games = const [],
  });
}
