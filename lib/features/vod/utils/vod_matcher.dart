import 'package:flutter/foundation.dart';
import '../../../core/utils/fuzzy_search_util.dart';
import '../models/vod_item.dart';

/// Algoritmo de correspondência de alta precisão entre títulos do TMDB e catálogo da IPTV.
/// Elimina falsos-positivos de substrings curtas (ex: 'Nó' dando match com 'Retorno').
class VodMatcher {
  static final RegExp _tagRegex = RegExp(
    r'(\[[^\]]*\]|\([^\)]*\)|4k|uhd|fhd|hd|1080p|720p|dublado|legendado|dub|leg|dual|nacional)',
    caseSensitive: false,
  );

  static final RegExp _yearRegex = RegExp(r'\b(19\d\d|20\d\d)\b');

  static final Set<String> _stopWords = {
    'o', 'a', 'os', 'as', 'um', 'uma', 'uns', 'umas',
    'de', 'do', 'da', 'dos', 'das', 'em', 'no', 'na', 'nos', 'nas',
    'por', 'pelo', 'pela', 'pelos', 'pelas', 'para', 'com', 'sem',
    'e', 'ou', 'the', 'an', 'and', 'or', 'of', 'in', 'on', 'at', 'to', 'for', 'with',
  };

  /// Limpa o título removendo tags como [FHD], (Dublado), qualidade, etc.
  static String cleanTitle(String raw) {
    var title = raw.replaceAll(_tagRegex, ' ');
    title = FuzzySearchUtil.normalize(title);
    title = title.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return title.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Extrai o ano em 4 dígitos do texto
  static int? extractYear(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final m = _yearRegex.firstMatch(text);
    if (m != null) return int.tryParse(m.group(0)!);
    return null;
  }

  /// Encontra o melhor match de um filme TMDB dentro da lista de filmes IPTV
  static VodItem? findBestMatch({
    required String tmdbTitle,
    String? tmdbReleaseDate,
    required Iterable<VodItem> iptvCatalog,
  }) {
    final cleanTmdb = cleanTitle(tmdbTitle);
    if (cleanTmdb.isEmpty) return null;

    final tmdbYear = extractYear(tmdbReleaseDate);
    final tmdbTokens = cleanTmdb
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();

    if (tmdbTokens.isEmpty) return null;

    // Tokens significativos (remove stopwords se houver mais de um token)
    final significantTmdbTokens = tmdbTokens.length > 1
        ? tmdbTokens.where((t) => !_stopWords.contains(t) && t.length > 1).toList()
        : tmdbTokens;
    final effectiveTmdbTokens = significantTmdbTokens.isNotEmpty ? significantTmdbTokens : tmdbTokens;

    VodItem? bestItem;
    double bestScore = 0.0;

    for (final item in iptvCatalog) {
      final cleanIptv = cleanTitle(item.name);
      if (cleanIptv.isEmpty) continue;

      // 1. MATCH EXATO DE TÍTULO LIMPO
      if (cleanIptv == cleanTmdb) {
        if (tmdbYear != null && item.year != null && tmdbYear == item.year) {
          return item; // 100% perfeito
        }
        if (bestScore < 95.0) {
          bestScore = 95.0;
          bestItem = item;
        }
        continue;
      }

      // Proteção rigorosa para títulos muito curtos (ex: 'Nó', 'Up', 'It', '1917', 'Her')
      // Títulos com 3 caracteres ou menos NUNCA aceitam correspondência parcial.
      if (cleanTmdb.length <= 3 || (tmdbTokens.length == 1 && tmdbTokens.first.length <= 3)) {
        if (cleanIptv == cleanTmdb) {
          return item;
        }
        continue;
      }

      final iptvTokens = cleanIptv
          .split(' ')
          .where((t) => t.isNotEmpty)
          .toSet();

      // 2. CONTAGEM DE PALAVRAS COINCIDENTES (palavras completas)
      int matchedTokens = 0;
      for (final token in effectiveTmdbTokens) {
        if (iptvTokens.contains(token)) {
          matchedTokens++;
        }
      }

      final ratio = matchedTokens / effectiveTmdbTokens.length;

      // Exige que no mínimo 75% das palavras coincidam
      if (ratio >= 0.75) {
        double score = ratio * 70.0;

        // Bônus se todas as palavras significativas baterem
        if (matchedTokens == effectiveTmdbTokens.length) {
          score += 15.0;
        }

        // Bônus/Penalidade de Ano de Lançamento
        if (tmdbYear != null && item.year != null) {
          if (tmdbYear == item.year) {
            score += 15.0;
          } else if ((tmdbYear - item.year!).abs() > 1) {
            score -= 25.0; // Anos divergentes por mais de 1 ano
          }
        }

        if (score > bestScore && score >= 70.0) {
          bestScore = score;
          bestItem = item;
        }
      }
    }

    return bestItem;
  }

  /// Executa o matching em segundo plano via Isolate (compute) para evitar qualquer
  /// travamento (jank) na UI thread durante a navegação.
  static Future<Map<int, VodItem>> matchAllAsync({
    required List<VodMatchQuery> queries,
    required List<VodItem> catalog,
  }) async {
    if (queries.isEmpty || catalog.isEmpty) return {};
    return compute(
      _matchAllIsolated,
      _VodMatchTaskParams(queries: queries, catalog: catalog),
    );
  }
}

class VodMatchQuery {
  final int id;
  final String title;
  final String? releaseDate;

  const VodMatchQuery({
    required this.id,
    required this.title,
    this.releaseDate,
  });
}

class _VodMatchTaskParams {
  final List<VodMatchQuery> queries;
  final List<VodItem> catalog;

  const _VodMatchTaskParams({required this.queries, required this.catalog});
}

Map<int, VodItem> _matchAllIsolated(_VodMatchTaskParams params) {
  final matches = <int, VodItem>{};
  for (final q in params.queries) {
    final match = VodMatcher.findBestMatch(
      tmdbTitle: q.title,
      tmdbReleaseDate: q.releaseDate,
      iptvCatalog: params.catalog,
    );
    if (match != null) {
      matches[q.id] = match;
    }
  }
  return matches;
}
