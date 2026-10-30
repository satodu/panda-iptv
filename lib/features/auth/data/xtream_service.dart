import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/xtream_http_client.dart';
import '../models/xtream_account.dart';

/// Exceção estruturada de autenticação com chave de internacionalização
class AuthException implements Exception {
  final String key;
  final Map<String, String>? args;
  final String? fallback;

  const AuthException(this.key, {this.args, this.fallback});

  @override
  String toString() => fallback ?? key;
}

/// Serviço de integração com o protocolo Xtream Codes
class XtreamService {
  final http.Client _client;

  XtreamService({http.Client? client}) : _client = client ?? XtreamHttpClient();
  /// Normaliza a URL do servidor:
  /// - Remove espaços nas extremidades
  /// - Adiciona http:// se faltar protocolo
  /// - Remove todas as barras finais ('/')
  /// - Remove endpoints acidentais colados como '/player_api.php' ou '/get.php'
  static String formatServerUrl(String url) {
    var clean = url.trim();
    if (clean.isEmpty) return clean;

    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }

    // Remove barras no final repetidas
    clean = clean.replaceAll(RegExp(r'/+$'), '');

    // Remove sufixos comuns caso o usuário tenha colado a URL completa de login/m3u
    if (clean.endsWith('/player_api.php')) {
      clean = clean.substring(0, clean.length - '/player_api.php'.length);
      clean = clean.replaceAll(RegExp(r'/+$'), '');
    } else if (clean.endsWith('/get.php')) {
      clean = clean.substring(0, clean.length - '/get.php'.length);
      clean = clean.replaceAll(RegExp(r'/+$'), '');
    }

    return clean;
  }

  /// Realiza a autenticação no servidor Xtream Codes
  Future<XtreamAccount> login({
    required String serverUrl,
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    final cleanUrl = formatServerUrl(serverUrl);
    final endpoint = Uri.parse('$cleanUrl/player_api.php?username=$username&password=$password');

    try {
      final response = await _client.get(endpoint).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AuthException('auth.invalid_credentials');
      }

      if (response.statusCode != 200) {
        throw AuthException('auth.server_http_error', args: {'code': '${response.statusCode}'});
      }

      final body = response.body.trim();
      if (body.isEmpty) {
        throw const AuthException('auth.server_invalid_response');
      }

      // Servidores como XUI.one ou outros retornam páginas HTML quando o painel responde erro, debug ou restrição
      if (body.startsWith('<') || body.toLowerCase().contains('<html') || body.toLowerCase().contains('xui.one')) {
        throw const AuthException('auth.invalid_credentials_or_server');
      }

      dynamic data;
      try {
        data = jsonDecode(body);
      } on FormatException {
        throw const AuthException('auth.server_invalid_response');
      }

      if (data is! Map<String, dynamic>) {
        throw const AuthException('auth.server_invalid_response');
      }

      final userInfoJson = data['user_info'];
      if (userInfoJson == null || userInfoJson['auth'] == 0) {
        throw const AuthException('auth.invalid_credentials');
      }

      final status = userInfoJson['status']?.toString().toLowerCase();
      if (status == 'disabled' || status == 'expired' || status == 'banned') {
        throw const AuthException('auth.account_disabled');
      }

      final userInfo = XtreamUserInfo.fromJson(userInfoJson);
      final serverInfo = XtreamServerInfo.fromJson(data['server_info'] ?? {});

      // Salva dados localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('xtream_server', cleanUrl);
      await prefs.setString('xtream_user', username);
      await prefs.setBool('remember_me', rememberMe);
      if (rememberMe) {
        await prefs.setString('xtream_pass', password);
      } else {
        await prefs.remove('xtream_pass');
      }

      return XtreamAccount(
        serverUrl: cleanUrl,
        username: username,
        password: password,
        userInfo: userInfo,
        serverInfo: serverInfo,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is TimeoutException) {
        throw const AuthException('auth.server_timeout');
      }
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('failed host lookup') ||
          errStr.contains('connection refused') ||
          errStr.contains('network is unreachable') ||
          errStr.contains('socketexception') ||
          errStr.contains('clientexception')) {
        throw const AuthException('auth.server_connection_error');
      }
      if (errStr.contains('formatexception') ||
          errStr.contains('unexpected character') ||
          errStr.contains('<html')) {
        throw const AuthException('auth.invalid_credentials_or_server');
      }
      throw AuthException(
        'auth.server_connection_error',
        fallback: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Recupera a sessão salva se existir para auto-login
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? true;
    if (!remember) return null;

    final server = prefs.getString('xtream_server');
    final user = prefs.getString('xtream_user');
    final pass = prefs.getString('xtream_pass');

    if (server != null && user != null && pass != null) {
      return {'server': server, 'username': user, 'password': pass};
    }
    return null;
  }

  /// Recupera informações do último login para preencher campos da tela
  Future<Map<String, String>?> getLastSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString('xtream_server');
    final user = prefs.getString('xtream_user');
    final pass = prefs.getString('xtream_pass');
    final remember = prefs.getBool('remember_me') ?? true;

    if (server != null || user != null) {
      return {
        'server': server ?? 'http://',
        'username': user ?? '',
        'password': pass ?? '',
        'remember_me': remember.toString(),
      };
    }
    return null;
  }

  /// Desconecta a conta atual (remove a senha salva para evitar auto-login indesejado)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('xtream_pass');
  }
}
