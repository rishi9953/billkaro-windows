class BulkDeleteCategoriesRequest {
  final List<String> categoryIds;

  BulkDeleteCategoriesRequest({required this.categoryIds});

  Map<String, dynamic> toJson() => {
        'categoryIds': categoryIds,
      };
}
