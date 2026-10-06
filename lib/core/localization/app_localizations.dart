import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gerenciador de Localização e Traduções do Panda IPTV
/// Suporta carregamento dinâmico via JSON em assets/i18n/{code}.json
class AppLocalizations {
  final Locale locale;
  Map<String, String> _translations = {};

  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// Carrega o arquivo JSON do idioma selecionado
  Future<bool> load() async {
    final fileName = '${locale.languageCode}_${locale.countryCode ?? ''}';
    String jsonString;
    try {
      jsonString = await rootBundle.loadString('assets/i18n/$fileName.json');
    } catch (_) {
      try {
        jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
      } catch (_) {
        jsonString = await rootBundle.loadString('assets/i18n/pt_BR.json');
      }
    }

    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _translations = _flattenTranslations(jsonMap);
    return true;
  }

  /// Achata mapas aninhados em chaves pontuadas (ex: {"auth": {"server": "X"}} -> "auth.server": "X")
  Map<String, String> _flattenTranslations(Map<String, dynamic> json, [String prefix = '']) {
    final result = <String, String>{};
    json.forEach((key, value) {
      final newKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        result.addAll(_flattenTranslations(value, newKey));
      } else {
        result[newKey] = value.toString();
      }
    });
    return result;
  }

  /// Obtém o texto traduzido para a chave informada
  /// Suporta interpolação: tr('hello', args: {'name': 'Panda'}) substitui {name}
  String tr(String key, {Map<String, String>? args}) {
    var text = _translations[key] ?? key;
    if (args != null && args.isNotEmpty) {
      args.forEach((placeholder, value) {
        text = text.replaceAll('{$placeholder}', value);
      });
    }
    return text;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['pt', 'en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extensão ergonômica para chamada rápida de traduções
extension BuildContextLocalizationExtension on BuildContext {
  String tr(String key, {Map<String, String>? args}) {
    return AppLocalizations.of(this)?.tr(key, args: args) ?? key;
  }
}
