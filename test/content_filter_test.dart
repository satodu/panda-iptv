import 'package:flutter_test/flutter_test.dart';
import 'package:panda_iptv/core/models/content_filter_state.dart';
import 'package:panda_iptv/core/utils/fuzzy_search_util.dart';
import 'package:panda_iptv/features/live/models/live_stream_item.dart';
import 'package:panda_iptv/features/series/models/series_item.dart';
import 'package:panda_iptv/features/vod/models/vod_item.dart';

void main() {
  group('FuzzySearchUtil', () {
    test('normalizes diacritics and symbols', () {
      expect(FuzzySearchUtil.normalize('Pokémon & Ação!'), 'pokemon & acao!');
      expect(FuzzySearchUtil.normalize('Cão, Maçã, Café'), 'cao, maca, cafe');
    });

    test('exact and prefix match have highest scores', () {
      final scoreExact = FuzzySearchUtil.calculateScore('batman', 'Batman');
      final scorePrefix = FuzzySearchUtil.calculateScore('batman', 'Batman Begins');
      final scoreContains = FuzzySearchUtil.calculateScore('batman', 'The Lego Batman Movie');

      expect(scoreExact, greaterThan(scorePrefix));
      expect(scorePrefix, greaterThan(scoreContains));
      expect(scoreContains, greaterThan(0));
    });

    test('matches tokens in any order and ignores case/accents', () {
      expect(FuzzySearchUtil.matches('aranha homem', 'Homem-Aranha: Sem Volta para Casa'), isTrue);
      expect(FuzzySearchUtil.matches('furiosos velozes 10', 'Velozes & Furiosos 10 (2023)'), isTrue);
      expect(FuzzySearchUtil.matches('deadpool 2024', 'Deadpool & Wolverine 2024'), isTrue);
    });

    test('tolerates minor typos in words with length >= 4', () {
      expect(FuzzySearchUtil.matches('batmam', 'Batman'), isTrue);
      expect(FuzzySearchUtil.matches('vigadores', 'Vingadores: Ultimato'), isTrue);
      expect(FuzzySearchUtil.matches('interstellar', 'Interstelar'), isTrue);
    });

    test('ranks search results by relevance', () {
      final movies = [
        'A Lego Batman Movie',
        'Batman (1989)',
        'Superman vs Batman',
        'Batman Begins',
      ];

      final results = FuzzySearchUtil.search<String>(
        query: 'batman',
        items: movies,
        titleSelector: (m) => m,
      );

      // Batman Begins / Batman (1989) start with 'batman', so they rank before 'Superman vs Batman'
      expect(results.first, startsWith('Batman'));
    });
  });

  group('ContentFilterState with Genre', () {
    test('initial state has no active filters', () {
      const state = ContentFilterState.initial;
      expect(state.hasActiveFilters, isFalse);
      expect(state.activeFiltersCount, 0);
    });

    test('genre filter activates state', () {
      final state = ContentFilterState.initial.copyWith(
        genre: 'Ação',
      );
      expect(state.hasActiveFilters, isTrue);
      expect(state.genre, 'Ação');
      expect(state.activeFiltersCount, 1);
    });
  });

  group('Genre Matching', () {
    test('VodItem matches genre from categoryName or name', () {
      final movie = VodItem.fromJson({
        'stream_id': 101,
        'name': 'Duro de Matar',
        'category_id': '1',
      });

      expect(movie.matchesGenre('Ação', categoryName: 'FILMES | AÇÃO'), isTrue);
      expect(movie.matchesGenre('Terror', categoryName: 'FILMES | AÇÃO'), isFalse);
      expect(movie.matchesGenre('all'), isTrue);
    });

    test('SeriesItem matches genre from genre field or categoryName', () {
      final series = SeriesItem.fromJson({
        'series_id': 202,
        'name': 'Stranger Things',
        'category_id': '2',
        'genre': 'Ficção Científica, Suspense, Drama',
      });

      expect(series.matchesGenre('Ficção Científica'), isTrue);
      expect(series.matchesGenre('Suspense'), isTrue);
      expect(series.matchesGenre('Comédia'), isFalse);
      expect(series.matchesGenre('all'), isTrue);
    });
  });

  group('LiveFilterState', () {
    test('initial live filter has no active filters', () {
      const state = LiveFilterState.initial;
      expect(state.hasActiveFilters, isFalse);
      expect(state.activeFiltersCount, 0);
    });

    test('copyWith updates live sort and filter options', () {
      final state = LiveFilterState.initial.copyWith(
        sortOption: LiveSortOption.channelNumber,
        filterOption: LiveFilterOption.withEpg,
      );
      expect(state.hasActiveFilters, isTrue);
      expect(state.sortOption, LiveSortOption.channelNumber);
      expect(state.filterOption, LiveFilterOption.withEpg);
      expect(state.activeFiltersCount, 2);
    });
  });

  group('LiveStreamItem filter detection', () {
    test('detects resolution and epg', () {
      final channel = LiveStreamItem.fromJson({
        'num': 10,
        'name': 'HBO FHD',
        'stream_id': 303,
        'category_id': '2',
        'epg_channel_id': 'hbo.br',
      });

      expect(channel.isFhd, isTrue);
      expect(channel.is4K, isFalse);
      expect(channel.hasEpg, isTrue);
      expect(channel.formattedNumber, '#010');
    });
  });
}
