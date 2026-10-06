import 'package:flutter/foundation.dart';
import '../../auth/models/xtream_account.dart';
import '../data/live_service.dart';
import '../models/live_category.dart';
import '../models/live_stream_item.dart';

class LiveProvider extends ChangeNotifier {
  final LiveService _liveService;

  LiveProvider({LiveService? liveService}) : _liveService = liveService ?? LiveService();

  bool _isLoadingCategories = false;
  bool _isLoadingChannels = false;
  String? _error;

  List<LiveCategory> _categories = [];
  String? _selectedCategoryId;

  List<LiveStreamItem> _channels = [];
  String _searchQuery = '';

  bool get isLoading => _isLoadingCategories || _isLoadingChannels;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingChannels => _isLoadingChannels;
  String? get error => _error;
  List<LiveCategory> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  List<LiveStreamItem> get filteredChannels {
    if (_searchQuery.trim().isEmpty) {
      return _channels;
    }
    final query = _searchQuery.toLowerCase().trim();
    return _channels.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  Future<void> init(XtreamAccount account) async {
    _selectedCategoryId = 'all';
    _searchQuery = '';
    await loadCategories(account);
    await loadChannels(account, categoryId: 'all');
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
      _channels = await _liveService.getStreams(
        account,
        categoryId: categoryId,
        categoryName: categoryName,
      );
    } catch (e) {
      _error = 'Erro ao carregar canais: $e';
    } finally {
      _isLoadingChannels = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  String buildStreamUrl(XtreamAccount account, int streamId) {
    return _liveService.buildStreamUrl(account, streamId);
  }
}
