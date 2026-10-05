class VodItem {
  final int streamId;
  final String name;
  final String? streamIcon;
  final double rating;
  final String categoryId;
  final String containerExtension;
  final String? added;

  const VodItem({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.rating = 0.0,
    required this.categoryId,
    this.containerExtension = 'mp4',
    this.added,
  });

  factory VodItem.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'] ?? json['rating_5based'];
    double parsedRating = 0.0;
    if (rawRating != null) {
      parsedRating = double.tryParse(rawRating.toString()) ?? 0.0;
    }

    return VodItem(
      streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Sem título',
      streamIcon: json['stream_icon']?.toString(),
      rating: parsedRating,
      categoryId: json['category_id']?.toString() ?? '',
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
      added: json['added']?.toString(),
    );
  }
}
