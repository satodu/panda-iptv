class VodCategory {
  final String categoryId;
  final String categoryName;
  final int parentId;

  const VodCategory({
    required this.categoryId,
    required this.categoryName,
    this.parentId = 0,
  });

  factory VodCategory.fromJson(Map<String, dynamic> json) {
    return VodCategory(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? 'Sem Categoria',
      parentId: int.tryParse(json['parent_id']?.toString() ?? '0') ?? 0,
    );
  }
}
