import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'favorite_item.dart';

class FavoritesService {
  static const String _storageKey = 'panda_favorites_v1';

  static final ValueNotifier<List<FavoriteItem>> favoritesNotifier =
      ValueNotifier<List<FavoriteItem>>([]);

  /// Carrega os favoritos salvos
  static Future<List<FavoriteItem>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];

    final List<FavoriteItem> items = [];
    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          items.add(FavoriteItem.fromJson(decoded));
        }
      } catch (_) {}
    }

    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    favoritesNotifier.value = items;
    return items;
  }

  /// Verifica de forma síncrona se um item está nos favoritos já carregados
  static bool isFavoriteSync(String id) {
    return favoritesNotifier.value.any((item) => item.id == id);
  }

  /// Verifica de forma assíncrona garantindo leitura do storage
  static Future<bool> isFavorite(String id) async {
    final items = await loadFavorites();
    return items.any((item) => item.id == id);
  }

  /// Alterna o estado de favorito (adiciona se não existir, remove se existir)
  /// Retorna true se foi adicionado, false se foi removido
  static Future<bool> toggleFavorite(FavoriteItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await loadFavorites();

    final index = items.indexWhere((element) => element.id == item.id);
    final bool isNowFavorite;

    if (index >= 0) {
      items.removeAt(index);
      isNowFavorite = false;
    } else {
      items.insert(0, item);
      isNowFavorite = true;
    }

    final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, encodedList);
    favoritesNotifier.value = List.unmodifiable(items);
    return isNowFavorite;
  }

  /// Remove um item específico dos favoritos
  static Future<void> removeFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await loadFavorites();

    items.removeWhere((item) => item.id == id);

    final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, encodedList);
    favoritesNotifier.value = List.unmodifiable(items);
  }

  /// Limpa todos os favoritos
  static Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    favoritesNotifier.value = [];
  }
}
