import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TmdbMovie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double rating;
  final String? releaseDate;

  TmdbMovie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.rating = 0.0,
    this.releaseDate,
  });

  String? get posterUrl => posterPath != null && posterPath!.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : null;

  String? get backdropUrl => backdropPath != null && backdropPath!.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : null;

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    return TmdbMovie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String?,
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'] as String? ?? json['first_air_date'] as String?,
    );
  }
}

class TmdbActor {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  TmdbActor({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  String? get profileUrl => profilePath != null && profilePath!.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w300$profilePath'
      : null;

  factory TmdbActor.fromJson(Map<String, dynamic> json) {
    return TmdbActor(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      character: json['character'] as String?,
      profilePath: json['profile_path'] as String?,
    );
  }
}

class TmdbActorDetail {
  final int id;
  final String name;
  final String? biography;
  final String? profilePath;
  final String? birthday;
  final String? placeOfBirth;
  final List<TmdbMovie> filmography;

  TmdbActorDetail({
    required this.id,
    required this.name,
    this.biography,
    this.profilePath,
    this.birthday,
    this.placeOfBirth,
    required this.filmography,
  });

  String? get profileUrl => profilePath != null && profilePath!.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w500$profilePath'
      : null;
}

class TmdbService {
  // Chave passada via --dart-define=TMDB_API_KEY=... ou fallback para a chave de desenvolvimento
  static const String apiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: 'd839aab0186e37fc42d8ed75154e8177',
  );

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static bool get hasKey => apiKey.isNotEmpty;

  /// Busca o ID do filme no TMDB a partir do título e ano
  static Future<int?> searchMovieId(String title, {String? year}) async {
    if (!hasKey) return null;
    try {
      final cleanTitle = title.replaceAll(RegExp(r'\[.*?\]|\(.*?\)|4K|FHD|HD', caseSensitive: false), '').trim();
      final queryParams = {
        'api_key': apiKey,
        'query': cleanTitle,
        'language': 'pt-BR',
      };
      if (year != null && year.isNotEmpty) {
        final parsedYear = RegExp(r'\d{4}').firstMatch(year)?.group(0);
        if (parsedYear != null) queryParams['year'] = parsedYear;
      }

      final uri = Uri.parse('$_baseUrl/search/movie').replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          return results.first['id'] as int?;
        }
      }
    } catch (e) {
      debugPrint('[TMDB SEARCH ERROR] $e');
    }
    return null;
  }

  /// Busca a duração oficial em minutos de um filme no TMDB
  static Future<int?> getMovieRuntime(int movieId) async {
    if (!hasKey) return null;
    try {
      final uri = Uri.parse('$_baseUrl/movie/$movieId').replace(queryParameters: {
        'api_key': apiKey,
        'language': 'pt-BR',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final runtime = data['runtime'] as int?;
        if (runtime != null && runtime > 0) {
          return runtime;
        }
      }
    } catch (e) {
      debugPrint('[TMDB RUNTIME ERROR] $e');
    }
    return null;
  }

  /// Busca o ID da série no TMDB a partir do título e ano
  static Future<int?> searchTvId(String title, {String? year}) async {
    if (!hasKey) return null;
    try {
      final cleanTitle = title
          .replaceAll(RegExp(r'\[.*?\]|\(.*?\)|4K|FHD|HD|TEMPORADA.*|TEMP.*|S\d+.*', caseSensitive: false), '')
          .trim();
      final queryParams = {
        'api_key': apiKey,
        'query': cleanTitle,
        'language': 'pt-BR',
      };
      if (year != null && year.isNotEmpty) {
        final parsedYear = RegExp(r'\d{4}').firstMatch(year)?.group(0);
        if (parsedYear != null) queryParams['first_air_date_year'] = parsedYear;
      }

      final uri = Uri.parse('$_baseUrl/search/tv').replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          return results.first['id'] as int?;
        }
      }
    } catch (e) {
      debugPrint('[TMDB SEARCH TV ERROR] $e');
    }
    return null;
  }

  /// Busca filmes semelhantes pelo ID do TMDB
  static Future<List<TmdbMovie>> getSimilarMovies(int tmdbId) async {
    if (!hasKey) return [];
    try {
      final uri = Uri.parse('$_baseUrl/movie/$tmdbId/recommendations?api_key=$apiKey&language=pt-BR');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = (data['results'] as List<dynamic>? ?? [])
            .map((item) => TmdbMovie.fromJson(item as Map<String, dynamic>))
            .where((m) => m.title.isNotEmpty)
            .toList();
        if (results.isNotEmpty) return results;
      }

      // Fallback para similar se recommendations vier vazio
      final similarUri = Uri.parse('$_baseUrl/movie/$tmdbId/similar?api_key=$apiKey&language=pt-BR');
      final simRes = await http.get(similarUri).timeout(const Duration(seconds: 6));
      if (simRes.statusCode == 200) {
        final data = jsonDecode(simRes.body);
        return (data['results'] as List<dynamic>? ?? [])
            .map((item) => TmdbMovie.fromJson(item as Map<String, dynamic>))
            .where((m) => m.title.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('[TMDB SIMILAR ERROR] $e');
    }
    return [];
  }

  /// Busca séries semelhantes pelo ID do TMDB
  static Future<List<TmdbMovie>> getSimilarTv(int tmdbId) async {
    if (!hasKey) return [];
    try {
      final uri = Uri.parse('$_baseUrl/tv/$tmdbId/recommendations?api_key=$apiKey&language=pt-BR');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = (data['results'] as List<dynamic>? ?? [])
            .map((item) => TmdbMovie.fromJson(item as Map<String, dynamic>))
            .where((m) => m.title.isNotEmpty)
            .toList();
        if (results.isNotEmpty) return results;
      }

      // Fallback para similar se recommendations vier vazio
      final similarUri = Uri.parse('$_baseUrl/tv/$tmdbId/similar?api_key=$apiKey&language=pt-BR');
      final simRes = await http.get(similarUri).timeout(const Duration(seconds: 6));
      if (simRes.statusCode == 200) {
        final data = jsonDecode(simRes.body);
        return (data['results'] as List<dynamic>? ?? [])
            .map((item) => TmdbMovie.fromJson(item as Map<String, dynamic>))
            .where((m) => m.title.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('[TMDB SIMILAR TV ERROR] $e');
    }
    return [];
  }

  /// Busca o elenco de um filme no TMDB
  static Future<List<TmdbActor>> getMovieCredits(int tmdbId) async {
    if (!hasKey) return [];
    try {
      final uri = Uri.parse('$_baseUrl/movie/$tmdbId/credits?api_key=$apiKey&language=pt-BR');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cast = (data['cast'] as List<dynamic>? ?? [])
            .map((item) => TmdbActor.fromJson(item as Map<String, dynamic>))
            .take(15)
            .toList();
        return cast;
      }
    } catch (e) {
      debugPrint('[TMDB CREDITS ERROR] $e');
    }
    return [];
  }

  /// Busca informações detalhadas de um ator e seus filmes
  static Future<TmdbActorDetail?> getActorDetail(int actorId) async {
    if (!hasKey) return null;
    try {
      final detailUri = Uri.parse('$_baseUrl/person/$actorId?api_key=$apiKey&language=pt-BR');
      final creditsUri = Uri.parse('$_baseUrl/person/$actorId/movie_credits?api_key=$apiKey&language=pt-BR');

      final detailRes = await http.get(detailUri).timeout(const Duration(seconds: 6));
      final creditsRes = await http.get(creditsUri).timeout(const Duration(seconds: 6));

      if (detailRes.statusCode == 200) {
        final detailData = jsonDecode(detailRes.body);
        List<TmdbMovie> filmography = [];

        if (creditsRes.statusCode == 200) {
          final creditsData = jsonDecode(creditsRes.body);
          final castList = (creditsData['cast'] as List<dynamic>? ?? [])
              .map((item) => TmdbMovie.fromJson(item as Map<String, dynamic>))
              .where((m) => m.title.isNotEmpty)
              .toList();
          // Ordena pelos mais bem avaliados ou com poster
          castList.sort((a, b) => b.rating.compareTo(a.rating));
          filmography = castList;
        }

        return TmdbActorDetail(
          id: detailData['id'] as int? ?? actorId,
          name: detailData['name'] as String? ?? 'Ator',
          biography: detailData['biography'] as String?,
          profilePath: detailData['profile_path'] as String?,
          birthday: detailData['birthday'] as String?,
          placeOfBirth: detailData['place_of_birth'] as String?,
          filmography: filmography,
        );
      }
    } catch (e) {
      debugPrint('[TMDB ACTOR DETAIL ERROR] $e');
    }
    return null;
  }
}
