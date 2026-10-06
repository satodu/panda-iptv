import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/models/xtream_account.dart';
import '../models/live_category.dart';
import '../models/live_stream_item.dart';

class LiveService {
  final http.Client _client;

  LiveService({http.Client? client}) : _client = client ?? http.Client();

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

  /// Busca as categorias de canais ao vivo
  Future<List<LiveCategory>> getCategories(XtreamAccount account) async {
    final url = _buildUrl(account, 'get_live_categories');
    final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Falha ao obter categorias de TV ao vivo (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => LiveCategory.fromJson(json))
        .toList();
  }

  /// Busca os canais ao vivo (opcionalmente filtrados por categoria)
  Future<List<LiveStreamItem>> getStreams(XtreamAccount account, {String? categoryId, String? categoryName}) async {
    final params = <String, String>{};
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      params['category_id'] = categoryId;
    }

    final url = _buildUrl(account, 'get_live_streams', params);
    final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Falha ao obter lista de canais ao vivo (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => LiveStreamItem.fromJson(json, categoryName: categoryName))
        .toList();
  }

  /// Constrói a URL do stream ao vivo para reprodução no media_kit
  String buildStreamUrl(XtreamAccount account, int streamId, {String extension = 'ts'}) {
    return '${account.serverUrl}/live/${account.username}/${account.password}/$streamId.$extension';
  }
}
