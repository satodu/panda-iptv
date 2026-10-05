class EpisodeItem {
  final String id;
  final int episodeNum;
  final String title;
  final String containerExtension;
  final String? plot;
  final String? duration;
  final double rating;
  final String? image;

  const EpisodeItem({
    required this.id,
    required this.episodeNum,
    required this.title,
    this.containerExtension = 'mp4',
    this.plot,
    this.duration,
    this.rating = 0.0,
    this.image,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    final info = json['info'] is Map<String, dynamic> ? json['info'] as Map<String, dynamic> : <String, dynamic>{};
    final rawRating = info['rating'] ?? json['rating'];
    double parsedRating = 0.0;
    if (rawRating != null) {
      parsedRating = double.tryParse(rawRating.toString()) ?? 0.0;
    }

    return EpisodeItem(
      id: json['id']?.toString() ?? '',
      episodeNum: int.tryParse(json['episode_num']?.toString() ?? '1') ?? 1,
      title: json['title']?.toString() ?? 'Episódio ${json['episode_num'] ?? ''}',
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
      plot: info['plot']?.toString() ?? info['description']?.toString(),
      duration: info['duration']?.toString() ?? info['duration_secs']?.toString(),
      rating: parsedRating,
      image: info['movie_image']?.toString(),
    );
  }
}

class SeriesDetail {
  final int seriesId;
  final String name;
  final String? cover;
  final String? backdrop;
  final String? plot;
  final String? director;
  final String? cast;
  final String? genre;
  final String? releaseDate;
  final double rating;
  final List<String> seasonNumbers;
  final Map<String, List<EpisodeItem>> episodesBySeason;

  const SeriesDetail({
    required this.seriesId,
    required this.name,
    this.cover,
    this.backdrop,
    this.plot,
    this.director,
    this.cast,
    this.genre,
    this.releaseDate,
    this.rating = 0.0,
    required this.seasonNumbers,
    required this.episodesBySeason,
  });

  factory SeriesDetail.fromJson(Map<String, dynamic> json) {
    final info = json['info'] is Map<String, dynamic> ? json['info'] as Map<String, dynamic> : <String, dynamic>{};

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

    final Map<String, List<EpisodeItem>> episodesMap = {};
    final rawEpisodes = json['episodes'];
    if (rawEpisodes is Map<String, dynamic>) {
      rawEpisodes.forEach((seasonKey, epsList) {
        if (epsList is List) {
          episodesMap[seasonKey] = epsList
              .whereType<Map<String, dynamic>>()
              .map((ep) => EpisodeItem.fromJson(ep))
              .toList()
            ..sort((a, b) => a.episodeNum.compareTo(b.episodeNum));
        }
      });
    }

    final seasonKeys = episodesMap.keys.toList()
      ..sort((a, b) {
        final intA = int.tryParse(a) ?? 0;
        final intB = int.tryParse(b) ?? 0;
        return intA.compareTo(intB);
      });

    return SeriesDetail(
      seriesId: int.tryParse(info['series_id']?.toString() ?? '0') ?? 0,
      name: info['name']?.toString() ?? 'Sem título',
      cover: info['cover']?.toString(),
      backdrop: backdropUrl,
      plot: info['plot']?.toString() ?? info['description']?.toString(),
      director: info['director']?.toString(),
      cast: info['cast']?.toString(),
      genre: info['genre']?.toString(),
      releaseDate: info['releaseDate']?.toString() ?? info['release_date']?.toString(),
      rating: parsedRating,
      seasonNumbers: seasonKeys,
      episodesBySeason: episodesMap,
    );
  }
}
