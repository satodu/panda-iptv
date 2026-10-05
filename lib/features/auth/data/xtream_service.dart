import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/xtream_account.dart';

/// Serviço de integração com o protocolo Xtream Codes
class XtreamService {
  /// Limpa a URL do servidor removendo barras finais
  static String formatServerUrl(String url) {
    var clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  /// Realiza a autenticação no servidor Xtream Codes
  Future<XtreamAccount> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final cleanUrl = formatServerUrl(serverUrl);
    final endpoint = Uri.parse('$cleanUrl/player_api.php?username=$username&password=$password');

    try {
      final response = await http.get(endpoint).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Falha ao conectar ao servidor (HTTP ${response.statusCode})');
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw Exception('Resposta do servidor em formato inválido');
      }

      final userInfoJson = data['user_info'];
      if (userInfoJson == null || userInfoJson['auth'] == 0 || userInfoJson['status'] == 'Disabled') {
        throw Exception('Credenciais inválidas ou conta desativada');
      }

      final userInfo = XtreamUserInfo.fromJson(userInfoJson);
      final serverInfo = XtreamServerInfo.fromJson(data['server_info'] ?? {});

      // Salva sessão localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('xtream_server', cleanUrl);
      await prefs.setString('xtream_user', username);
      await prefs.setString('xtream_pass', password);

      return XtreamAccount(
        serverUrl: cleanUrl,
        username: username,
        password: password,
        userInfo: userInfo,
        serverInfo: serverInfo,
      );
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        throw Exception('Não foi possível alcançar o servidor. Verifique a URL e sua conexão.');
      }
      rethrow;
    }
  }

  /// Recupera a sessão salva se existir
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString('xtream_server');
    final user = prefs.getString('xtream_user');
    final pass = prefs.getString('xtream_pass');

    if (server != null && user != null && pass != null) {
      return {'server': server, 'username': user, 'password': pass};
    }
    return null;
  }

  /// Desconecta a conta atual
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('xtream_server');
    await prefs.remove('xtream_user');
    await prefs.remove('xtream_pass');
  }
}
