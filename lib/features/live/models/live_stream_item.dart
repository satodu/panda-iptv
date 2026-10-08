class LiveStreamItem {
  final int num;
  final String name;
  final String streamType;
  final int streamId;
  final String? streamIcon;
  final String? epgChannelId;
  final String categoryId;
  final String? categoryName;

  const LiveStreamItem({
    required this.num,
    required this.name,
    this.streamType = 'live',
    required this.streamId,
    this.streamIcon,
    this.epgChannelId,
    required this.categoryId,
    this.categoryName,
  });

  factory LiveStreamItem.fromJson(Map<String, dynamic> json, {String? categoryName}) {
    return LiveStreamItem(
      num: int.tryParse(json['num']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Canal sem nome',
      streamType: json['stream_type']?.toString() ?? 'live',
      streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
      streamIcon: json['stream_icon']?.toString(),
      epgChannelId: json['epg_channel_id']?.toString(),
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: categoryName,
    );
  }

  /// Retorna o número do canal formatado (ex: #001)
  String get formattedNumber => '#${num.toString().padLeft(3, '0')}';

  /// Detecta a qualidade do stream a partir do nome
  String get resolutionTag {
    final upper = name.toUpperCase();
    if (upper.contains('4K') || upper.contains('UHD')) return '4K';
    if (upper.contains('FHD') || upper.contains('1080')) return 'FHD';
    if (upper.contains('HD') || upper.contains('720')) return 'HD';
    if (upper.contains('SD') || upper.contains('480')) return 'SD';
    return 'LIVE';
  }

  bool get is4K => resolutionTag == '4K';
  bool get isFhd => resolutionTag == 'FHD';
  bool get isHd => resolutionTag == 'HD';
  bool get hasEpg => epgChannelId != null && epgChannelId!.trim().isNotEmpty;
}
