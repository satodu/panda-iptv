class FavoriteItem {
  final String id;
  final String title;
  final String type; // 'movie', 'series' or 'live'
  final String? cover;
  final double? rating;
  final String? genre;
  final String? streamUrl;
  final String? channelNumber;
  final DateTime addedAt;

  const FavoriteItem({
    required this.id,
    required this.title,
    required this.type,
    this.cover,
    this.rating,
    this.genre,
    this.streamUrl,
    this.channelNumber,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'cover': cover,
      'rating': rating,
      'genre': genre,
      'streamUrl': streamUrl,
      'channelNumber': channelNumber,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sem título',
      type: json['type'] as String? ?? 'movie',
      cover: json['cover'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      genre: json['genre'] as String?,
      streamUrl: json['streamUrl'] as String?,
      channelNumber: json['channelNumber'] as String?,
      addedAt: DateTime.tryParse(json['addedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
