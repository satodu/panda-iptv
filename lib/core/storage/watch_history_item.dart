class WatchHistoryItem {
  final String id;
  final String title;
  final String? subtitle;
  final String streamUrl;
  final String? cover;
  final int positionMs;
  final int durationMs;
  final DateTime updatedAt;
  final String type; // 'movie' or 'series'

  const WatchHistoryItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.streamUrl,
    this.cover,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
    this.type = 'movie',
  });

  double get progress {
    if (durationMs <= 0) return 0.0;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }

  int get remainingMinutes {
    final remainingMs = durationMs - positionMs;
    if (remainingMs <= 0) return 0;
    return (remainingMs / 60000).ceil();
  }

  int? get seriesId {
    if (type == 'series') {
      final parts = id.split('_');
      if (parts.length >= 2) {
        return int.tryParse(parts[1]);
      }
    }
    return null;
  }

  int? get episodeId {
    if (type == 'series') {
      final parts = id.split('_');
      if (parts.length >= 3) {
        return int.tryParse(parts[2]);
      }
    }
    return null;
  }

  int? get vodStreamId {
    if (type == 'movie') {
      final parts = id.split('_');
      if (parts.length >= 2) {
        return int.tryParse(parts[1]);
      }
      return int.tryParse(id);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'streamUrl': streamUrl,
      'cover': cover,
      'positionMs': positionMs,
      'durationMs': durationMs,
      'updatedAt': updatedAt.toIso8601String(),
      'type': type,
    };
  }

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return WatchHistoryItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sem título',
      subtitle: json['subtitle'] as String?,
      streamUrl: json['streamUrl'] as String? ?? '',
      cover: json['cover'] as String?,
      positionMs: json['positionMs'] as int? ?? 0,
      durationMs: json['durationMs'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      type: json['type'] as String? ?? 'movie',
    );
  }
}
