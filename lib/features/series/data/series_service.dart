import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/xtream_http_client.dart';
import '../../auth/models/xtream_account.dart';
import '../models/series_category.dart';
import '../models/series_detail.dart';
import '../models/series_item.dart';

class SeriesService {
  final http.Client _client;

  SeriesService({http.Client? client}) : _client = client ?? XtreamHttpClient();

  String _buildUrl(XtreamAccount account, String action, [Map<String, String>? params]) {
    final queryParams = {
      'username': account.username,
      'password': account.password,
      'action': action,
      if (params != null) ...params,
    };
    final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '${account.serverUrl}/player_api.php?$queryString';
  }

  Future<List<SeriesCategory>> getCategories(XtreamAccount account) async {
    final url = _buildUrl(account, 'get_series_categories');
    final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Falha ao obter categorias de séries (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => SeriesCategory.fromJson(json))
        .toList();
  }

  Future<List<SeriesItem>> getSeries(XtreamAccount account, {String? categoryId}) async {
    final params = <String, String>{};
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      params['category_id'] = categoryId;
    }

    final url = _buildUrl(account, 'get_series', params);
    final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Falha ao obter catálogo de séries (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => SeriesItem.fromJson(json))
        .toList();
  }

  Future<SeriesDetail> getSeriesInfo(XtreamAccount account, int seriesId) async {
    final url = _buildUrl(account, 'get_series_info', {'series_id': seriesId.toString()});
    final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Falha ao obter informações da série (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Formato inválido das informações da série');
    }

    return SeriesDetail.fromJson(data);
  }

  String buildStreamUrl(XtreamAccount account, String episodeId, String extension) {
    var ext = extension.replaceAll('.', '').trim();
    if (ext.isEmpty || ext.toLowerCase() == 'null') ext = 'mp4';
    return '${account.serverUrl}/series/${account.username}/${account.password}/$episodeId.$ext';
  }
}
