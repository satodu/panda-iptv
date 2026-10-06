import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'watch_history_item.dart';

class WatchHistoryService {
  static const String _storageKey = 'panda_watch_history_v1';
  static const int _maxItems = 25;

  static final ValueNotifier<List<WatchHistoryItem>> historyNotifier =
      ValueNotifier<List<WatchHistoryItem>>([]);

  /// Identifica a série de maneira unificada:
  /// Se o id segue o formato padrão 'series_{seriesId}_{episodeId}', agrupa por 'series_{seriesId}'.
  /// Caso contrário, agrupa pelo título limpo da série.
  static String _seriesKey(String id, String title) {
    if (id.startsWith('series_')) {
      final parts = id.split('_');
      if (parts.length >= 3) {
        return 'series_${parts[1]}';
      }
    }
    return 'title_${title.trim().toLowerCase()}';
  }

  /// Carrega o histórico salvo, garantindo apenas o episódio mais recente de cada série
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

    // Deduplica séries: mantém apenas o episódio assistido mais recente de cada série
    final Set<String> seenSeries = {};
    final List<WatchHistoryItem> deduplicated = [];
    bool hadDuplicates = false;

    for (final item in items) {
      if (item.type == 'series') {
        final key = _seriesKey(item.id, item.title);
        if (seenSeries.contains(key)) {
          hadDuplicates = true;
          continue; // Ignora episódios mais antigos da mesma série
        }
        seenSeries.add(key);
      }
      deduplicated.add(item);
    }

    // Se encontramos duplicatas antigas salvas, limpa o SharedPreferences
    if (hadDuplicates) {
      final encodedList = deduplicated.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_storageKey, encodedList);
    }

    historyNotifier.value = List.unmodifiable(deduplicated);
    return deduplicated;
  }

  /// Salva ou atualiza o progresso de um item
  /// Para séries: substitui qualquer episódio anterior pelo episódio assistido mais recente
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

    final isSeries = type == 'series';
    final targetSeriesKey = isSeries ? _seriesKey(id, title) : null;

    // Se assistiu mais de 93% do vídeo, considera finalizado e remove
    if (durationMs > 0 && (positionMs / durationMs) >= 0.93) {
      items.removeWhere((item) {
        if (item.id == id) return true;
        if (isSeries && item.type == 'series' && _seriesKey(item.id, item.title) == targetSeriesKey) {
          return true;
        }
        return false;
      });
      final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_storageKey, encodedList);
      historyNotifier.value = List.unmodifiable(items);
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

    // Remove versão anterior se já existia:
    // Para séries, remove qualquer outro episódio da mesma série (garante que apenas o último visto permaneça)
    items.removeWhere((item) {
      if (item.id == id) return true;
      if (isSeries && item.type == 'series' && _seriesKey(item.id, item.title) == targetSeriesKey) {
        return true;
      }
      return false;
    });

    // Insere o novo episódio no topo
    items.insert(0, newItem);

    // Limita tamanho máximo do histórico
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
