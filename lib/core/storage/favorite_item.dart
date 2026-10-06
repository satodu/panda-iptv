class FavoriteItem {
  final String id;
  final String title;
  final String type; // 'movie' or 'series'
  final String? cover;
  final double? rating;
  final String? genre;
  final DateTime addedAt;

  const FavoriteItem({
    required this.id,
    required this.title,
    required this.type,
    this.cover,
    this.rating,
    this.genre,
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
      addedAt: DateTime.tryParse(json['addedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
