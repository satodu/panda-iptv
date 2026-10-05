class SeriesItem {
  final int seriesId;
  final String name;
  final String? cover;
  final String? plot;
  final String? genre;
  final String? releaseDate;
  final double rating;
  final String categoryId;

  const SeriesItem({
    required this.seriesId,
    required this.name,
    this.cover,
    this.plot,
    this.genre,
    this.releaseDate,
    this.rating = 0.0,
    required this.categoryId,
  });

  factory SeriesItem.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'] ?? json['rating_5based'];
    double parsedRating = 0.0;
    if (rawRating != null) {
      parsedRating = double.tryParse(rawRating.toString()) ?? 0.0;
    }

    return SeriesItem(
      seriesId: int.tryParse(json['series_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Sem título',
      cover: json['cover']?.toString(),
      plot: json['plot']?.toString(),
      genre: json['genre']?.toString(),
      releaseDate: json['releaseDate']?.toString() ?? json['release_date']?.toString(),
      rating: parsedRating,
      categoryId: json['category_id']?.toString() ?? '',
    );
  }
}
