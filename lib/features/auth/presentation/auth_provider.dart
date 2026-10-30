import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/xtream_service.dart';
import '../models/xtream_account.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final XtreamService _service = XtreamService();

  AuthStatus _status = AuthStatus.initial;
  XtreamAccount? _currentAccount;
  String? _errorMessage;
  String? _errorKey;
  Map<String, String>? _errorArgs;

  AuthStatus get status => _status;
  XtreamAccount? get currentAccount => _currentAccount;
  String? get errorMessage => _errorMessage;
  String? get errorKey => _errorKey;
  Map<String, String>? get errorArgs => _errorArgs;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Retorna a mensagem de erro amigável e internacionalizada
  String getLocalizedError(BuildContext context) {
    if (_errorKey != null) {
      final translated = context.tr(_errorKey!, args: _errorArgs);
      if (translated != _errorKey) return translated;
    }
    if (_errorMessage != null && _errorMessage!.isNotEmpty) {
      final msg = _errorMessage!;
      if (msg.contains('<') ||
          msg.contains('FormatException') ||
          msg.contains('Unexpected character') ||
          msg.contains('html')) {
        return context.tr('auth.server_invalid_response');
      }
      return msg;
    }
    return context.tr('auth.invalid_credentials');
  }

  /// Limpa qualquer estado de erro anterior
  void clearError() {
    if (_status == AuthStatus.error || _errorMessage != null || _errorKey != null) {
      _errorMessage = null;
      _errorKey = null;
      _errorArgs = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Tenta auto-login com credenciais salvas
  Future<void> checkSavedSession() async {
    final creds = await _service.getSavedCredentials();
    if (creds != null) {
      await login(
        serverUrl: creds['server']!,
        username: creds['username']!,
        password: creds['password']!,
      );
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Realiza login manual
  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    _errorKey = null;
    _errorArgs = null;
    notifyListeners();

    try {
      _currentAccount = await _service.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
        rememberMe: rememberMe,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorKey = e.key;
      _errorArgs = e.args;
      _errorMessage = e.fallback ?? e.key;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorKey = 'auth.server_invalid_response';
      _errorMessage = null;
      notifyListeners();
      return false;
    }
  }

  /// Recupera informações do último login para pré-preencher tela
  Future<Map<String, String>?> getLastSessionInfo() => _service.getLastSessionInfo();

  /// Desconectar
  Future<void> logout() async {
    await _service.logout();
    _currentAccount = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
