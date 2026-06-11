class VenueGame {
  final int? id;
  final String game;

  const VenueGame({this.id, required this.game});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'game': game};
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory VenueGame.fromJson(Map<String, dynamic> json) {
    return VenueGame(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      game: json['game'] ?? '',
    );
  }
}
