import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

/// Provider reativo para gerenciamento e persistência do idioma ativo
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_locale';

  Locale _locale = const Locale('pt', 'BR');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey);
    if (savedCode != null) {
      final parts = savedCode.split('_');
      if (parts.length == 2) {
        _locale = Locale(parts[0], parts[1]);
      } else {
        _locale = Locale(parts[0]);
      }
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!AppLocalizations.supportedLocales.any((l) => l.languageCode == newLocale.languageCode)) {
      return;
    }

    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final codeString = '${newLocale.languageCode}_${newLocale.countryCode ?? ''}';
    await prefs.setString(_prefKey, codeString);
  }

  Future<void> setPortuguese() => setLocale(const Locale('pt', 'BR'));
  Future<void> setEnglish() => setLocale(const Locale('en', 'US'));
  Future<void> setSpanish() => setLocale(const Locale('es', 'ES'));
}
