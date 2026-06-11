class TrainerEntity {
  final String id;
  final String name;
  final String imageUrl;
  final String location;
  final List<String> targetGroups; // e.g., ["Adults", "Kids"]
  final double? rating;

  TrainerEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.location,
    required this.targetGroups,
    this.rating,
  });
}
