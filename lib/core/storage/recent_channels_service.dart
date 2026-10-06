import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recent_channel_item.dart';

class RecentChannelsService {
  static const String _storageKey = 'panda_recent_channels_v1';
  static const int _maxRecentChannels = 25;

  static final ValueNotifier<List<RecentChannelItem>> recentChannelsNotifier =
      ValueNotifier<List<RecentChannelItem>>([]);

  /// Carrega os canais recentes salvos
  static Future<List<RecentChannelItem>> loadChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];

    final List<RecentChannelItem> items = [];
    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          items.add(RecentChannelItem.fromJson(decoded));
        }
      } catch (_) {}
    }

    items.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
    recentChannelsNotifier.value = List.unmodifiable(items);
    return items;
  }

  /// Registra ou atualiza um canal como recentemente assistido
  static Future<void> recordChannelWatched({
    required int streamId,
    required String name,
    String? streamIcon,
    String? categoryName,
    String? channelNumber,
    required String streamUrl,
  }) async {
    if (streamId <= 0 || streamUrl.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final items = List<RecentChannelItem>.from(await loadChannels());

    // Remove ocorrência anterior do mesmo canal para evitar duplicados
    items.removeWhere((item) => item.streamId == streamId);

    // Insere no início
    items.insert(
      0,
      RecentChannelItem(
        streamId: streamId,
        name: name,
        streamIcon: streamIcon,
        categoryName: categoryName,
        channelNumber: channelNumber,
        streamUrl: streamUrl,
        lastWatched: DateTime.now(),
      ),
    );

    // Mantém no máximo o limite estipulado
    if (items.length > _maxRecentChannels) {
      items.removeRange(_maxRecentChannels, items.length);
    }

    final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, encodedList);
    recentChannelsNotifier.value = List.unmodifiable(items);
  }

  /// Remove um canal específico da lista de recentes
  static Future<void> removeChannel(int streamId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = List<RecentChannelItem>.from(await loadChannels());

    items.removeWhere((item) => item.streamId == streamId);

    final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, encodedList);
    recentChannelsNotifier.value = List.unmodifiable(items);
  }

  /// Limpa todos os canais recentes
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    recentChannelsNotifier.value = [];
  }
}
