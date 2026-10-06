/// Item de playlist para reprodução contínua (ex: episódios em sequência)
class PlaylistItem {
  final String id;
  final String title;
  final String? subtitle;
  final String streamUrl;
  final String? cover;
  final String mediaType; // 'series' ou 'movie'

  const PlaylistItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.streamUrl,
    this.cover,
    this.mediaType = 'series',
  });
}
