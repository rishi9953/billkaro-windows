import 'package:json_annotation/json_annotation.dart';

part 'bulk_delete_request.g.dart';

@JsonSerializable()
class BulkDeleteRequest {
  final String outletId;
  final List<String> itemIds;

  BulkDeleteRequest({
    required this.outletId,
    required this.itemIds,
  });

  factory BulkDeleteRequest.fromJson(Map<String, dynamic> json) =>
      _$BulkDeleteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BulkDeleteRequestToJson(this);
}
