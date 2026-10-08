import 'package:flutter/foundation.dart';
import '../../auth/models/xtream_account.dart';
import '../../../core/models/content_filter_state.dart';
import '../../../core/storage/watched_service.dart';
import '../../../core/utils/fuzzy_search_util.dart';
import '../data/vod_service.dart';
import '../models/vod_category.dart';
import '../models/vod_detail.dart';
import '../models/vod_item.dart';

class VodProvider extends ChangeNotifier {
  final VodService _vodService;

  VodProvider({VodService? vodService}) : _vodService = vodService ?? VodService();

  bool _isInitialized = false;
  bool _isLoadingCategories = false;
  bool _isLoadingMovies = false;
  String? _error;

  List<VodCategory> _categories = [];
  String? _selectedCategoryId;

  // Cache em memória durante a sessão por categoria para carregamento instantâneo
  final Map<String, List<VodItem>> _moviesCache = {};

  List<VodItem> _movies = [];
  String _searchQuery = '';
  ContentFilterState _filterState = ContentFilterState.initial;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoadingCategories || _isLoadingMovies;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingMovies => _isLoadingMovies;
  String? get error => _error;
  List<VodCategory> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  ContentFilterState get filterState => _filterState;

  String? getCategoryName(String catId) {
    for (final c in _categories) {
      if (c.categoryId == catId) return c.categoryName;
    }
    return null;
  }

  List<VodItem> get filteredMovies {
    var result = List<VodItem>.from(_movies);

    // 1. Filtro de Estilo / Gênero
    if (_filterState.genre != null && _filterState.genre != 'all') {
      final targetGenre = _filterState.genre!;
      result = result.where((m) {
        return m.matchesGenre(targetGenre, categoryName: getCategoryName(m.categoryId));
      }).toList();
    }

    // 2. Filtro de lançamentos recentes
    if (_filterState.onlyRecentReleases) {
      result = result.where((m) => m.isRecentRelease).toList();
    }

    // 3. Filtro de áudio (Dublado / Legendado)
    if (_filterState.audioOption == ContentAudioOption.dubbed) {
      result = result.where((m) => m.isDubbed).toList();
    } else if (_filterState.audioOption == ContentAudioOption.subtitled) {
      result = result.where((m) => m.isSubtitled).toList();
    }

    // 4. Filtro de qualidade
    if (_filterState.qualityOption == ContentQualityOption.q4k) {
      result = result.where((m) => m.is4K).toList();
    } else if (_filterState.qualityOption == ContentQualityOption.qFhd) {
      result = result.where((m) => m.isFhd).toList();
    } else if (_filterState.qualityOption == ContentQualityOption.qHd) {
      result = result.where((m) => m.isHd).toList();
    }

    // 5. Filtro de assistidos / não assistidos
    if (_filterState.watchedOption == ContentWatchedOption.watched) {
      result = result.where((m) => WatchedService.isWatchedSync('movie_${m.streamId}')).toList();
    } else if (_filterState.watchedOption == ContentWatchedOption.unwatched) {
      result = result.where((m) => !WatchedService.isWatchedSync('movie_${m.streamId}')).toList();
    }

    // 6. Busca Difusa Inteligente (Fuzzy Search com Ranking de Relevância)
    if (_searchQuery.trim().isNotEmpty) {
      result = FuzzySearchUtil.search<VodItem>(
        query: _searchQuery,
        items: result,
        titleSelector: (m) => m.name,
        secondarySelector: (m) => m.genre ?? getCategoryName(m.categoryId) ?? '',
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
    if (_isInitialized && !forceRefresh && _categories.isNotEmpty && _movies.isNotEmpty) {
      return;
    }

    _selectedCategoryId = 'all';
    _searchQuery = '';

    if (forceRefresh) {
      _moviesCache.clear();
      _categories = [];
      _movies = [];
    }

    await loadCategories(account);
    await loadMovies(account, categoryId: 'all');
    _isInitialized = true;
  }

  Future<void> refresh(XtreamAccount account) async {
    await init(account, forceRefresh: true);
  }

  void clear() {
    _isInitialized = false;
    _isLoadingCategories = false;
    _isLoadingMovies = false;
    _error = null;
    _categories.clear();
    _movies.clear();
    _moviesCache.clear();
    _selectedCategoryId = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> loadCategories(XtreamAccount account) async {
    _isLoadingCategories = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _vodService.getCategories(account);
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
    if (_moviesCache.containsKey(catKey)) {
      _movies = _moviesCache[catKey]!;
      _isLoadingMovies = false;
      _error = null;
      notifyListeners();
      return;
    }

    await loadMovies(account, categoryId: categoryId);
  }

  Future<void> loadMovies(XtreamAccount account, {String? categoryId}) async {
    _isLoadingMovies = true;
    _error = null;
    notifyListeners();

    try {
      final items = await _vodService.getStreams(account, categoryId: categoryId);
      _movies = items;
      _moviesCache[categoryId ?? 'all'] = items;
    } catch (e) {
      _error = 'Erro ao carregar filmes: $e';
    } finally {
      _isLoadingMovies = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<VodDetail?> loadVodDetail(XtreamAccount account, int vodId) async {
    try {
      return await _vodService.getVodInfo(account, vodId);
    } catch (e) {
      return null;
    }
  }

  String buildStreamUrl(XtreamAccount account, int streamId, String extension) {
    return _vodService.buildStreamUrl(account, streamId, extension);
  }
}
