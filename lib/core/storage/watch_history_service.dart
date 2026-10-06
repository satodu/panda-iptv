import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'watch_history_item.dart';

class WatchHistoryService {
  static const String _storageKey = 'panda_watch_history_v1';
  static const int _maxItems = 25;

  static final ValueNotifier<List<WatchHistoryItem>> historyNotifier =
      ValueNotifier<List<WatchHistoryItem>>([]);

  /// Carrega o histórico salvo
  static Future<List<WatchHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];

    final List<WatchHistoryItem> items = [];
    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          items.add(WatchHistoryItem.fromJson(decoded));
        }
      } catch (_) {}
    }

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    historyNotifier.value = items;
    return items;
  }

  /// Salva ou atualiza o progresso de um item
  static Future<void> saveProgress({
    required String id,
    required String title,
    String? subtitle,
    required String streamUrl,
    String? cover,
    required int positionMs,
    required int durationMs,
    String type = 'movie',
  }) async {
    // Se assistiu menos de 10 segundos, não salva no histórico
    if (positionMs < 10000) return;

    final prefs = await SharedPreferences.getInstance();
    final items = await loadHistory();

    // Se assistiu mais de 93% do vídeo, considera finalizado e remove
    if (durationMs > 0 && (positionMs / durationMs) >= 0.93) {
      await removeItem(id);
      return;
    }

    final newItem = WatchHistoryItem(
      id: id,
      title: title,
      subtitle: subtitle,
      streamUrl: streamUrl,
      cover: cover,
      positionMs: positionMs,
      durationMs: durationMs,
      updatedAt: DateTime.now(),
      type: type,
    );

    // Remove versão anterior se já existia
    items.removeWhere((item) => item.id == id);
    // Insere no topo
    items.insert(0, newItem);

    // Limita tamanho
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
    final items = await loadHistory();

    items.removeWhere((item) => item.id == id);

    final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, encodedList);
    historyNotifier.value = List.unmodifiable(items);
  }

  /// Limpa todo o histórico
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    historyNotifier.value = [];
  }
}
