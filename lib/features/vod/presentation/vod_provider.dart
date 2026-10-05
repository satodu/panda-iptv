import 'package:flutter/foundation.dart';
import '../../auth/models/xtream_account.dart';
import '../data/vod_service.dart';
import '../models/vod_category.dart';
import '../models/vod_detail.dart';
import '../models/vod_item.dart';

class VodProvider extends ChangeNotifier {
  final VodService _vodService;

  VodProvider({VodService? vodService}) : _vodService = vodService ?? VodService();

  bool _isLoadingCategories = false;
  bool _isLoadingMovies = false;
  String? _error;

  List<VodCategory> _categories = [];
  String? _selectedCategoryId;

  List<VodItem> _movies = [];
  String _searchQuery = '';

  bool get isLoading => _isLoadingCategories || _isLoadingMovies;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingMovies => _isLoadingMovies;
  String? get error => _error;
  List<VodCategory> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  List<VodItem> get filteredMovies {
    if (_searchQuery.trim().isEmpty) {
      return _movies;
    }
    final query = _searchQuery.toLowerCase().trim();
    return _movies.where((m) => m.name.toLowerCase().contains(query)).toList();
  }

  Future<void> init(XtreamAccount account) async {
    _selectedCategoryId = 'all';
    _searchQuery = '';
    await loadCategories(account);
    await loadMovies(account, categoryId: 'all');
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
    await loadMovies(account, categoryId: categoryId);
  }

  Future<void> loadMovies(XtreamAccount account, {String? categoryId}) async {
    _isLoadingMovies = true;
    _error = null;
    notifyListeners();

    try {
      _movies = await _vodService.getStreams(account, categoryId: categoryId);
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
