import 'package:flutter/foundation.dart';
import '../../auth/models/xtream_account.dart';
import '../data/series_service.dart';
import '../models/series_category.dart';
import '../models/series_detail.dart';
import '../models/series_item.dart';

class SeriesProvider extends ChangeNotifier {
  final SeriesService _seriesService;

  SeriesProvider({SeriesService? seriesService}) : _seriesService = seriesService ?? SeriesService();

  bool _isLoadingCategories = false;
  bool _isLoadingSeries = false;
  String? _error;

  List<SeriesCategory> _categories = [];
  String? _selectedCategoryId;

  List<SeriesItem> _seriesList = [];
  String _searchQuery = '';

  bool get isLoading => _isLoadingCategories || _isLoadingSeries;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingSeries => _isLoadingSeries;
  String? get error => _error;
  List<SeriesCategory> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  List<SeriesItem> get seriesList => _seriesList;
  List<SeriesItem> get filteredSeries {
    if (_searchQuery.trim().isEmpty) {
      return _seriesList;
    }
    final query = _searchQuery.toLowerCase().trim();
    return _seriesList.where((s) => s.name.toLowerCase().contains(query)).toList();
  }

  Future<void> init(XtreamAccount account) async {
    _selectedCategoryId = 'all';
    _searchQuery = '';
    await loadCategories(account);
    await loadSeries(account, categoryId: 'all');
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
    await loadSeries(account, categoryId: categoryId);
  }

  Future<void> loadSeries(XtreamAccount account, {String? categoryId}) async {
    _isLoadingSeries = true;
    _error = null;
    notifyListeners();

    try {
      _seriesList = await _seriesService.getSeries(account, categoryId: categoryId);
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
    try {
      return await _seriesService.getSeriesInfo(account, seriesId);
    } catch (e) {
      return null;
    }
  }

  String buildStreamUrl(XtreamAccount account, String episodeId, String extension) {
    return _seriesService.buildStreamUrl(account, episodeId, extension);
  }
}
