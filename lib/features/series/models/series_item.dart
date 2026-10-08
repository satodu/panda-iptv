class SeriesItem {
  final int seriesId;
  final String name;
  final String? cover;
  final String? plot;
  final String? genre;
  final String? releaseDate;
  final double rating;
  final String categoryId;
  final String? lastModified;

  const SeriesItem({
    required this.seriesId,
    required this.name,
    this.cover,
    this.plot,
    this.genre,
    this.releaseDate,
    this.rating = 0.0,
    required this.categoryId,
    this.lastModified,
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
      releaseDate: json['releaseDate']?.toString() ??
          json['releasedate']?.toString() ??
          json['release_date']?.toString() ??
          json['year']?.toString(),
      rating: parsedRating,
      categoryId: json['category_id']?.toString() ?? '',
      lastModified: json['last_modified']?.toString() ?? json['added']?.toString(),
    );
  }

  /// Extrai o ano em 4 dígitos do campo releaseDate ou do próprio título
  String? get displayYear {
    if (releaseDate != null && releaseDate!.trim().isNotEmpty) {
      final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(releaseDate!);
      if (match != null) return match.group(0);
    }
    final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(name);
    if (match != null) return match.group(0);
    return null;
  }

  int? get year => displayYear != null ? int.tryParse(displayYear!) : null;

  int get addedTimestamp => int.tryParse(lastModified ?? '') ?? 0;

  bool get isDubbed {
    final up = name.toUpperCase();
    return up.contains('DUB') || up.contains('DUBLADO') || up.contains('DUBLADA');
  }

  bool get isSubtitled {
    final up = name.toUpperCase();
    return up.contains('LEG') || up.contains('LEGENDADO') || up.contains('LEGENDADA') || up.contains('[SUB]');
  }

  bool get is4K {
    final up = name.toUpperCase();
    return up.contains('4K') || up.contains('UHD') || up.contains('2160');
  }

  bool get isRecentRelease {
    final y = displayYear;
    if (y != null) {
      final parsed = int.tryParse(y);
      if (parsed != null && parsed >= 2024) return true;
    }
    final up = name.toUpperCase();
    return up.contains('LANÇAMENTO') || up.contains('ESTREIA') || up.contains('2024') || up.contains('2025');
  }

  bool matchesGenre(String targetGenre, {String? categoryName}) {
    if (targetGenre.isEmpty || targetGenre.toLowerCase() == 'all') return true;
    final tg = targetGenre.toLowerCase();
    if (genre != null && genre!.toLowerCase().contains(tg)) return true;
    if (categoryName != null && categoryName.toLowerCase().contains(tg)) return true;
    if (name.toLowerCase().contains(tg)) return true;
    return false;
  }
}
