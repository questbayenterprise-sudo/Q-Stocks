import 'venue_slot.dart'; // Add this import

class VenueEntity {
  final String id;
  final String name;
  final String imageUrl;
  final String locationName;
  final String fullAddress;
  final double distance; // Added
  final double price;
  final double rating;
  final int reviewsCount; // Added
  final bool isBookable; // Added
  final List<String> sportsIcons; // Added
  final List<String> sports; // Games available at the venue
  final List<Map<String, dynamic>> sportsData; // {id, name} pairs for booking
  final String about;
  final List<String> amenities;
  final List<VenueSlot> slots;

  VenueEntity({
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
    this.sportsData = const [],
    required this.about,
    this.amenities = const [],
    this.slots = const [],
  });
}
