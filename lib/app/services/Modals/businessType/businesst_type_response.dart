import 'package:json_annotation/json_annotation.dart';

part 'businesst_type_response.g.dart';

@JsonSerializable()
class BusinesstTypeResponse {
  final String status;
  final List<BusinessType> data;

  BusinesstTypeResponse({required this.status, required this.data});

  factory BusinesstTypeResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinesstTypeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BusinesstTypeResponseToJson(this);
}

@JsonSerializable()
class BusinessType {
  final String id;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  final String name;
  final String value;
  final bool active;

  BusinessType({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.value,
    required this.active,
  });

  factory BusinessType.fromJson(Map<String, dynamic> json) =>
      _$BusinessTypeFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessTypeToJson(this);
}
