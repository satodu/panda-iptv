class RecentChannelItem {
  final int streamId;
  final String name;
  final String? streamIcon;
  final String? categoryName;
  final String? channelNumber;
  final String streamUrl;
  final DateTime lastWatched;

  const RecentChannelItem({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.categoryName,
    this.channelNumber,
    required this.streamUrl,
    required this.lastWatched,
  });

  Map<String, dynamic> toJson() {
    return {
      'streamId': streamId,
      'name': name,
      'streamIcon': streamIcon,
      'categoryName': categoryName,
      'channelNumber': channelNumber,
      'streamUrl': streamUrl,
      'lastWatched': lastWatched.toIso8601String(),
    };
  }

  factory RecentChannelItem.fromJson(Map<String, dynamic> json) {
    return RecentChannelItem(
      streamId: int.tryParse(json['streamId']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Canal sem nome',
      streamIcon: json['streamIcon']?.toString(),
      categoryName: json['categoryName']?.toString(),
      channelNumber: json['channelNumber']?.toString(),
      streamUrl: json['streamUrl']?.toString() ?? '',
      lastWatched: DateTime.tryParse(json['lastWatched']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
