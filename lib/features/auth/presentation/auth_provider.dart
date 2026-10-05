import 'package:flutter/material.dart';
import '../data/xtream_service.dart';
import '../models/xtream_account.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final XtreamService _service = XtreamService();

  AuthStatus _status = AuthStatus.initial;
  XtreamAccount? _currentAccount;
  String? _errorMessage;

  AuthStatus get status => _status;
  XtreamAccount? get currentAccount => _currentAccount;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

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
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
