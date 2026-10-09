import 'package:flutter/foundation.dart';
import '../../auth/models/xtream_account.dart';
import '../../../core/models/content_filter_state.dart';
import '../../../core/utils/fuzzy_search_util.dart';
import '../data/live_service.dart';
import '../models/live_category.dart';
import '../models/live_epg_item.dart';
import '../models/live_stream_item.dart';

class LiveProvider extends ChangeNotifier {
  final LiveService _liveService;

  LiveProvider({LiveService? liveService}) : _liveService = liveService ?? LiveService();

  bool _isInitialized = false;
  bool _isLoadingCategories = false;
  bool _isLoadingChannels = false;
  String? _error;

  List<LiveCategory> _categories = [];
  String? _selectedCategoryId;

  // Cache em memória durante a sessão por categoria para carregamento instantâneo
  final Map<String, List<LiveStreamItem>> _channelsCache = {};

  List<LiveStreamItem> _channels = [];
  List<LiveStreamItem> _filteredChannels = [];
  String _searchQuery = '';
  LiveFilterState _filterState = LiveFilterState.initial;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoadingCategories || _isLoadingChannels;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingChannels => _isLoadingChannels;
  String? get error => _error;
  List<LiveCategory> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  LiveFilterState get filterState => _filterState;

  List<LiveStreamItem> get channels => _channels;
  List<LiveStreamItem> get filteredChannels => _filteredChannels;

  void _recomputeFilteredChannels() {
    var result = List<LiveStreamItem>.from(_channels);

    // 1. Filtro por busca difusa inteligente
    if (_searchQuery.trim().isNotEmpty) {
      result = FuzzySearchUtil.search<LiveStreamItem>(
        query: _searchQuery,
        items: result,
        titleSelector: (c) => c.name,
      );
    }

    // 2. Filtro rápido de canal
    switch (_filterState.filterOption) {
      case LiveFilterOption.withEpg:
        result = result.where((c) => c.hasEpg).toList();
        break;
      case LiveFilterOption.q4k:
        result = result.where((c) => c.is4K).toList();
        break;
      case LiveFilterOption.qFhd:
        result = result.where((c) => c.isFhd).toList();
        break;
      case LiveFilterOption.qHd:
        result = result.where((c) => c.isHd).toList();
        break;
      case LiveFilterOption.all:
      case LiveFilterOption.recent:
        break;
    }

    // 3. Ordenação
    switch (_filterState.sortOption) {
      case LiveSortOption.defaultProvider:
        break;
      case LiveSortOption.channelNumber:
        result.sort((a, b) => a.num.compareTo(b.num));
        break;
      case LiveSortOption.alphaAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    _filteredChannels = result;
  }

  void setFilterState(LiveFilterState state) {
    _filterState = state;
    _recomputeFilteredChannels();
    notifyListeners();
  }

  void resetFilterState() {
    _filterState = LiveFilterState.initial;
    _recomputeFilteredChannels();
    notifyListeners();
  }

  Future<void> init(XtreamAccount account, {bool forceRefresh = false}) async {
    // Se já estiver inicializado em memória e não for recarregamento forçado, preserva a lista
    if (_isInitialized && !forceRefresh && _categories.isNotEmpty && _channels.isNotEmpty) {
      return;
    }

    _selectedCategoryId = 'all';
    _searchQuery = '';

    if (forceRefresh) {
      _channelsCache.clear();
      _categories = [];
      _channels = [];
    }

    await loadCategories(account);
    await loadChannels(account, categoryId: 'all');
    _isInitialized = true;
  }

  Future<void> refresh(XtreamAccount account) async {
    await init(account, forceRefresh: true);
  }

  void clear() {
    _isInitialized = false;
    _isLoadingCategories = false;
    _isLoadingChannels = false;
    _error = null;
    _categories.clear();
    _channels.clear();
    _filteredChannels.clear();
    _channelsCache.clear();
    _selectedCategoryId = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> loadCategories(XtreamAccount account) async {
    _isLoadingCategories = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _liveService.getCategories(account);
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
    if (_channelsCache.containsKey(catKey)) {
      _channels = _channelsCache[catKey]!;
      _isLoadingChannels = false;
      _error = null;
      _recomputeFilteredChannels();
      notifyListeners();
      return;
    }

    await loadChannels(account, categoryId: categoryId);
  }

  Future<void> loadChannels(XtreamAccount account, {String? categoryId}) async {
    _isLoadingChannels = true;
    _error = null;
    notifyListeners();

    try {
      String? categoryName;
      if (categoryId != null && categoryId != 'all') {
        final match = _categories.where((c) => c.categoryId == categoryId);
        if (match.isNotEmpty) {
          categoryName = match.first.categoryName;
        }
      }
      final items = await _liveService.getStreams(
        account,
        categoryId: categoryId,
        categoryName: categoryName,
      );
      _channels = items;
      _channelsCache[categoryId ?? 'all'] = items;
      _recomputeFilteredChannels();
    } catch (e) {
      _error = 'Erro ao carregar canais: $e';
    } finally {
      _isLoadingChannels = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _recomputeFilteredChannels();
    notifyListeners();
  }

  String buildStreamUrl(XtreamAccount account, int streamId) {
    return _liveService.buildStreamUrl(account, streamId);
  }

  final Map<int, List<LiveEpgItem>> _epgCache = {};

  Future<List<LiveEpgItem>> loadChannelEpg(XtreamAccount account, int streamId) async {
    if (_epgCache.containsKey(streamId)) {
      return _epgCache[streamId]!;
    }
    try {
      final items = await _liveService.getShortEpg(account, streamId);
      _epgCache[streamId] = items;
      return items;
    } catch (_) {
      return [];
    }
  }

  List<LiveStreamItem> getChannelsForCategory(String categoryId) {
    if (_channelsCache.containsKey(categoryId)) {
      return _channelsCache[categoryId]!;
    }
    if (categoryId == 'all') {
      return _channels;
    }
    return _channels.where((c) => c.categoryId == categoryId).toList();
  }
}
