import 'package:flutter/foundation.dart';
import '../../auth/models/xtream_account.dart';
import '../../../core/models/content_filter_state.dart';
import '../../../core/storage/watched_service.dart';
import '../../../core/utils/fuzzy_search_util.dart';
import '../data/series_service.dart';
import '../models/series_category.dart';
import '../models/series_detail.dart';
import '../models/series_item.dart';

class SeriesProvider extends ChangeNotifier {
  final SeriesService _seriesService;

  SeriesProvider({SeriesService? seriesService}) : _seriesService = seriesService ?? SeriesService();

  bool _isInitialized = false;
  bool _isLoadingCategories = false;
  bool _isLoadingSeries = false;
  String? _error;

  List<SeriesCategory> _categories = [];
  String? _selectedCategoryId;

  // Cache em memória durante a sessão por categoria para carregamento instantâneo
  final Map<String, List<SeriesItem>> _seriesCache = {};
  // Cache de detalhes das séries (temporadas e episódios)
  final Map<int, SeriesDetail> _seriesDetailCache = {};

  List<SeriesItem> _seriesList = [];
  String _searchQuery = '';
  ContentFilterState _filterState = ContentFilterState.initial;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoadingCategories || _isLoadingSeries;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingSeries => _isLoadingSeries;
  String? get error => _error;
  List<SeriesCategory> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  ContentFilterState get filterState => _filterState;

  String? getCategoryName(String catId) {
    for (final c in _categories) {
      if (c.categoryId == catId) return c.categoryName;
    }
    return null;
  }

  List<SeriesItem> get seriesList => _seriesList;
  List<SeriesItem> get filteredSeries {
    var result = List<SeriesItem>.from(_seriesList);

    // 1. Filtro de Estilo / Gênero
    if (_filterState.genre != null && _filterState.genre != 'all') {
      final targetGenre = _filterState.genre!;
      result = result.where((s) {
        return s.matchesGenre(targetGenre, categoryName: getCategoryName(s.categoryId));
      }).toList();
    }

    // 2. Filtro de lançamentos recentes
    if (_filterState.onlyRecentReleases) {
      result = result.where((s) => s.isRecentRelease).toList();
    }

    // 3. Filtro de áudio (Dublado / Legendado)
    if (_filterState.audioOption == ContentAudioOption.dubbed) {
      result = result.where((s) => s.isDubbed).toList();
    } else if (_filterState.audioOption == ContentAudioOption.subtitled) {
      result = result.where((s) => s.isSubtitled).toList();
    }

    // 4. Filtro de qualidade
    if (_filterState.qualityOption == ContentQualityOption.q4k) {
      result = result.where((s) => s.is4K).toList();
    }

    // 5. Filtro de assistidos / não assistidos
    if (_filterState.watchedOption == ContentWatchedOption.watched) {
      result = result.where((s) => WatchedService.isWatchedSync('series_${s.seriesId}')).toList();
    } else if (_filterState.watchedOption == ContentWatchedOption.unwatched) {
      result = result.where((s) => !WatchedService.isWatchedSync('series_${s.seriesId}')).toList();
    }

    // 6. Busca Difusa Inteligente (Fuzzy Search com Ranking de Relevância)
    if (_searchQuery.trim().isNotEmpty) {
      result = FuzzySearchUtil.search<SeriesItem>(
        query: _searchQuery,
        items: result,
        titleSelector: (s) => s.name,
        secondarySelector: (s) => s.genre ?? getCategoryName(s.categoryId) ?? '',
      );
    } else {
      // 7. Ordenação padrão quando não há termo de busca ativo
      switch (_filterState.sortOption) {
        case ContentSortOption.recentYear:
          result.sort((a, b) {
            final yearA = a.year ?? 0;
            final yearB = b.year ?? 0;
            if (yearB != yearA) return yearB.compareTo(yearA);
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          break;
        case ContentSortOption.addedServer:
          result.sort((a, b) {
            final addedA = a.addedTimestamp;
            final addedB = b.addedTimestamp;
            if (addedB != addedA) return addedB.compareTo(addedA);
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          break;
        case ContentSortOption.rating:
          result.sort((a, b) {
            if (b.rating != a.rating) return b.rating.compareTo(a.rating);
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          break;
        case ContentSortOption.alphaAsc:
          result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case ContentSortOption.alphaDesc:
          result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
      }
    }

    return result;
  }

  void setFilterState(ContentFilterState state) {
    _filterState = state;
    notifyListeners();
  }

  void resetFilterState() {
    _filterState = ContentFilterState.initial;
    notifyListeners();
  }

  Future<void> init(XtreamAccount account, {bool forceRefresh = false}) async {
    // Se já estiver inicializado em memória e não for recarregamento forçado, preserva o catálogo
    if (_isInitialized && !forceRefresh && _categories.isNotEmpty && _seriesList.isNotEmpty) {
      return;
    }

    _selectedCategoryId = 'all';
    _searchQuery = '';

    if (forceRefresh) {
      _seriesCache.clear();
      _categories = [];
      _seriesList = [];
    }

    await loadCategories(account);
    await loadSeries(account, categoryId: 'all');
    _isInitialized = true;
  }

  Future<void> refresh(XtreamAccount account) async {
    await init(account, forceRefresh: true);
  }

  void clear() {
    _isInitialized = false;
    _isLoadingCategories = false;
    _isLoadingSeries = false;
    _error = null;
    _categories.clear();
    _seriesList.clear();
    _seriesCache.clear();
    _seriesDetailCache.clear();
    _selectedCategoryId = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> loadCategories(XtreamAccount account) async {
    _isLoadingCategories = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _seriesService.getCategories(account);
    } catch (e) {
      _error = 'Erro ao carregar categorias: $e';
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(XtreamAccount account, String? categoryId) async {
    _selectedCategoryId = categoryId;
    final catKey = categoryId ?? 'all';

    // Se já temos a categoria em cache nesta sessão, restaura instantaneamente
    if (_seriesCache.containsKey(catKey)) {
      _seriesList = _seriesCache[catKey]!;
      _isLoadingSeries = false;
      _error = null;
      notifyListeners();
      return;
    }

    await loadSeries(account, categoryId: categoryId);
  }

  Future<void> loadSeries(XtreamAccount account, {String? categoryId}) async {
    _isLoadingSeries = true;
    _error = null;
    notifyListeners();

    try {
      final items = await _seriesService.getSeries(account, categoryId: categoryId);
      _seriesList = items;
      _seriesCache[categoryId ?? 'all'] = items;
    } catch (e) {
      _error = 'Erro ao carregar séries: $e';
    } finally {
      _isLoadingSeries = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<SeriesDetail?> loadSeriesDetail(XtreamAccount account, int seriesId) async {
    if (_seriesDetailCache.containsKey(seriesId)) {
      return _seriesDetailCache[seriesId];
    }
    try {
      final detail = await _seriesService.getSeriesInfo(account, seriesId);
      _seriesDetailCache[seriesId] = detail;
      return detail;
    } catch (e) {
      return null;
    }
  }

  String buildStreamUrl(XtreamAccount account, String episodeId, String extension) {
    return _seriesService.buildStreamUrl(account, episodeId, extension);
  }
}
