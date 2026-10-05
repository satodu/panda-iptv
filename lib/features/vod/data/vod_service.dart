import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/models/xtream_account.dart';
import '../models/vod_category.dart';
import '../models/vod_detail.dart';
import '../models/vod_item.dart';

class VodService {
  final http.Client _client;

  VodService({http.Client? client}) : _client = client ?? http.Client();

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

  Future<List<VodCategory>> getCategories(XtreamAccount account) async {
    final url = _buildUrl(account, 'get_vod_categories');
    final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Falha ao obter categorias de filmes (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => VodCategory.fromJson(json))
        .toList();
  }

  Future<List<VodItem>> getStreams(XtreamAccount account, {String? categoryId}) async {
    final params = <String, String>{};
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      params['category_id'] = categoryId;
    }

    final url = _buildUrl(account, 'get_vod_streams', params);
    final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Falha ao obter lista de filmes (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => VodItem.fromJson(json))
        .toList();
  }

  Future<VodDetail> getVodInfo(XtreamAccount account, int vodId) async {
    final url = _buildUrl(account, 'get_vod_info', {'vod_id': vodId.toString()});
    final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Falha ao obter detalhes do filme (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Formato inválido dos detalhes do filme');
    }

    return VodDetail.fromJson(data);
  }

  String buildStreamUrl(XtreamAccount account, int streamId, String extension) {
    var ext = extension.replaceAll('.', '').trim();
    if (ext.isEmpty || ext.toLowerCase() == 'null') ext = 'mp4';
    return '${account.serverUrl}/movie/${account.username}/${account.password}/$streamId.$ext';
  }
}
