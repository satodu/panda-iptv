import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de persistência para mídias e episódios já assistidos (Vistos)
class WatchedService {
  static const String _storageKey = 'panda_watched_ids_v1';

  static final ValueNotifier<Set<String>> watchedNotifier =
      ValueNotifier<Set<String>>({});

  /// Carrega o conjunto de IDs de conteúdos marcados como vistos
  static Future<Set<String>> loadWatched() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];
    final set = rawList.toSet();
    watchedNotifier.value = set;
    return set;
  }

  /// Verifica de forma síncrona pelo cache em memória
  static bool isWatchedSync(String id) {
    return watchedNotifier.value.contains(id);
  }

  /// Verifica de forma assíncrona
  static Future<bool> isWatched(String id) async {
    final set = await loadWatched();
    return set.contains(id);
  }

  /// Marca um conteúdo como visto
  static Future<void> markAsWatched(String id) async {
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_storageKey) ?? []).toSet();
    if (set.add(id)) {
      await prefs.setStringList(_storageKey, set.toList());
      watchedNotifier.value = Set.unmodifiable(set);
    }
  }

  /// Remove a marcação de visto
  static Future<void> unmarkWatched(String id) async {
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_storageKey) ?? []).toSet();
    if (set.remove(id)) {
      await prefs.setStringList(_storageKey, set.toList());
      watchedNotifier.value = Set.unmodifiable(set);
    }
  }

  /// Alterna entre visto e não visto. Retorna true se agora está visto.
  static Future<bool> toggleWatched(String id) async {
    if (id.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_storageKey) ?? []).toSet();
    final bool isNowWatched;
    if (set.contains(id)) {
      set.remove(id);
      isNowWatched = false;
    } else {
      set.add(id);
      isNowWatched = true;
    }
    await prefs.setStringList(_storageKey, set.toList());
    watchedNotifier.value = Set.unmodifiable(set);
    return isNowWatched;
  }

  /// Limpa todos os vistos
  static Future<void> clearWatched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    watchedNotifier.value = {};
  }
}
