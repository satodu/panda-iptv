class VodDetail {
  final int streamId;
  final String name;
  final String? cover;
  final String? backdrop;
  final String? plot;
  final String? director;
  final String? cast;
  final String? genre;
  final String? releaseDate;
  final String? duration;
  final double rating;
  final String containerExtension;
  final String? youtubeTrailer;
  final int? tmdbId;

  const VodDetail({
    required this.streamId,
    required this.name,
    this.cover,
    this.backdrop,
    this.plot,
    this.director,
    this.cast,
    this.genre,
    this.releaseDate,
    this.duration,
    this.rating = 0.0,
    this.containerExtension = 'mp4',
    this.youtubeTrailer,
    this.tmdbId,
  });

  factory VodDetail.fromJson(Map<String, dynamic> json) {
    final info = json['info'] is Map<String, dynamic> ? json['info'] as Map<String, dynamic> : <String, dynamic>{};
    final movieData = json['movie_data'] is Map<String, dynamic> ? json['movie_data'] as Map<String, dynamic> : <String, dynamic>{};

    String? backdropUrl;
    final rawBackdrop = info['backdrop_path'];
    if (rawBackdrop is List && rawBackdrop.isNotEmpty) {
      backdropUrl = rawBackdrop.first?.toString();
    } else if (rawBackdrop is String && rawBackdrop.isNotEmpty) {
      backdropUrl = rawBackdrop;
    }

    final rawRating = info['rating'] ?? info['rating_5based'];
    double parsedRating = 0.0;
    if (rawRating != null) {
      parsedRating = double.tryParse(rawRating.toString()) ?? 0.0;
    }

    final rawTmdb = info['tmdb_id'] ?? movieData['tmdb_id'] ?? info['tmdb'];
    int? parsedTmdb;
    if (rawTmdb != null) {
      parsedTmdb = int.tryParse(rawTmdb.toString());
    }

    String? cleanDuration;
    final rawDurationSecs = info['duration_secs'] ?? movieData['duration_secs'];
    if (rawDurationSecs != null) {
      final secs = (rawDurationSecs as num).toInt();
      if (secs > 60) {
        final m = secs ~/ 60;
        final h = m ~/ 60;
        final remM = m % 60;
        cleanDuration = h > 0 ? '${h}h ${remM}m' : '${m}m';
      }
    }
    if (cleanDuration == null) {
      final rawDur = info['duration']?.toString() ?? movieData['duration']?.toString();
      if (rawDur != null &&
          rawDur.trim().isNotEmpty &&
          rawDur != '0' &&
          rawDur != '00:00:00' &&
          rawDur != '0:00' &&
          rawDur != '0m') {
        cleanDuration = rawDur.trim();
      }
    }

    return VodDetail(
      streamId: int.tryParse(movieData['stream_id']?.toString() ?? info['stream_id']?.toString() ?? '0') ?? 0,
      name: movieData['name']?.toString() ?? info['name']?.toString() ?? 'Sem título',
      cover: info['movie_image']?.toString() ?? info['cover_big']?.toString(),
      backdrop: backdropUrl,
      plot: info['description']?.toString() ?? info['plot']?.toString(),
      director: info['director']?.toString(),
      cast: info['actors']?.toString() ?? info['cast']?.toString(),
      genre: info['genre']?.toString(),
      releaseDate: info['releasedate']?.toString() ?? info['release_date']?.toString(),
      duration: cleanDuration,
      rating: parsedRating,
      containerExtension: movieData['container_extension']?.toString() ?? info['container_extension']?.toString() ?? 'mp4',
      youtubeTrailer: info['youtube_trailer']?.toString(),
      tmdbId: parsedTmdb,
    );
  }
}
