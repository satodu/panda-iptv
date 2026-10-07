import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'watch_history_item.dart';
import 'watch_history_service.dart';

/// Histórico Completo de Filmes e Séries assistidos.
/// Mantém o registro mesmo após a conclusão do vídeo, permitindo ao usuário
/// voltar a assistir ou navegar para a série/filme e gerenciar o histórico.
class FullWatchHistoryService {
  static const String _storageKey = 'panda_full_watch_history_v1';
  static const int _maxItems = 100;

  static final ValueNotifier<List<WatchHistoryItem>> historyNotifier =
      ValueNotifier<List<WatchHistoryItem>>([]);

  static String _seriesKey(String id, String title) {
    if (id.startsWith('series_')) {
      final parts = id.split('_');
      if (parts.length >= 2) {
        return 'series_${parts[1]}';
      }
    }
    return 'title_${title.trim().toLowerCase()}';
  }

  /// Carrega todo o histórico salvo
  static Future<List<WatchHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey);

    final List<WatchHistoryItem> items = [];

    final migrated = prefs.getBool('panda_full_history_migrated_v1') ?? false;

    if (rawList != null && rawList.isNotEmpty) {
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            items.add(WatchHistoryItem.fromJson(decoded));
          }
        } catch (_) {}
      }
    } else if (!migrated) {
      await prefs.setBool('panda_full_history_migrated_v1', true);
      // Se estiver vazio no primeiro acesso, importa itens já existentes em WatchHistoryService
      final existing = await WatchHistoryService.loadHistory();
      if (existing.isNotEmpty) {
        items.addAll(existing);
        final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
        await prefs.setStringList(_storageKey, encodedList);
      }
    }

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    historyNotifier.value = List.unmodifiable(items);
    return items;
  }

  /// Registra ou atualiza um item no histórico completo
  static Future<void> recordItem(WatchHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = (await loadHistory()).toList();

    final isSeries = item.type == 'series';
    final targetSeriesKey = isSeries ? _seriesKey(item.id, item.title) : null;

    // Remove versão anterior se já existia (para séries, atualiza para o episódio mais recente)
    items.removeWhere((existing) {
      if (existing.id == item.id) return true;
      if (isSeries && existing.type == 'series' && _seriesKey(existing.id, existing.title) == targetSeriesKey) {
        return true;
      }
      return false;
    });

    items.insert(0, item);

    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }

    final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, encodedList);
    historyNotifier.value = List.unmodifiable(items);
  }

  /// Remove um item específico do histórico
  static Future<void> removeItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = (await loadHistory()).toList();

    items.removeWhere((item) => item.id == id);

    final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, encodedList);
    historyNotifier.value = List.unmodifiable(items);

    // Também sincroniza a remoção em WatchHistoryService se estiver lá
    await WatchHistoryService.removeItem(id);
  }

  /// Limpa todo o histórico de visualizações
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, []);
    await prefs.setBool('panda_full_history_migrated_v1', true);
    historyNotifier.value = [];
  }
}
