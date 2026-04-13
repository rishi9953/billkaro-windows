import 'package:json_annotation/json_annotation.dart';

part 'categories_response.g.dart';

@JsonSerializable()
class CategoryResponse {
  final String status;

  @JsonKey(name: 'data')
  final List<CategoryData> categories;

  CategoryResponse({required this.status, required this.categories});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryResponseToJson(this);
}

@JsonSerializable()
class CategoryData {
  final String id; // UUID → String
  final String userId; // Added because API returns it
  final String outletId;
  final String categoryName;
  final String imageURL; // Optional field for category image URL
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryData({
    required this.id,
    required this.userId,
    required this.outletId,
    required this.categoryName,
    required this.imageURL,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) =>
      _$CategoryDataFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryDataToJson(this);
}
