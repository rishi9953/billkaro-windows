// activity_response_model.dart

import 'package:json_annotation/json_annotation.dart';

part 'activities_response.g.dart';

@JsonSerializable()
class ActivityResponseModel {
  @JsonKey(readValue: _readOptionalStringTop)
  final String status;
  @JsonKey(readValue: _readOptionalStringTop)
  final String message;
  @JsonKey(fromJson: _activityListFromJson)
  final List<ActivityModel> data;
  @JsonKey(fromJson: _paginationFromJson)
  final PaginationModel pagination;

  ActivityResponseModel({
    required this.status,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory ActivityResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityResponseModelToJson(this);

  static Object? _readOptionalStringTop(
    Map<dynamic, dynamic> json,
    String key,
  ) {
    final v = json[key];
    return v == null ? '' : '$v';
  }

  static List<ActivityModel> _activityListFromJson(dynamic value) {
    if (value == null || value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => ActivityModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static PaginationModel _paginationFromJson(dynamic value) {
    if (value == null || value is! Map) {
      return PaginationModel(
        currentPage: 1,
        totalPages: 1,
        totalItems: 0,
        itemsPerPage: 20,
      );
    }
    final m = Map<String, dynamic>.from(value);
    return PaginationModel(
      currentPage: (m['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (m['totalPages'] as num?)?.toInt() ?? 1,
      totalItems: (m['totalItems'] as num?)?.toInt() ?? 0,
      itemsPerPage: (m['itemsPerPage'] as num?)?.toInt() ?? 20,
    );
  }
}

@JsonSerializable()
class ActivityModel {
  @JsonKey(readValue: _readId)
  final String id;
  @JsonKey(readValue: _readOptionalString)
  final String createdAt;
  @JsonKey(readValue: _readOptionalString)
  final String updatedAt;
  @JsonKey(readValue: _readOptionalString)
  final String type;
  @JsonKey(readValue: _readOptionalString)
  final String userId;
  @JsonKey(readValue: _readCreatedByName)
  final String createdByName;
  @JsonKey(readValue: _readOptionalString)
  final String outletId;
  @JsonKey(readValue: _readOptionalString)
  final String entityId;
  @JsonKey(readValue: _readOptionalString)
  final String entityName;
  @JsonKey(readValue: _readOptionalString)
  final String description;
  @JsonKey(fromJson: _detailsFromJson)
  final ActivityDetails details;

  ActivityModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.userId,
    required this.createdByName,
    required this.outletId,
    required this.entityId,
    required this.entityName,
    required this.details,
    required this.description,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityModelToJson(this);

  static Object? _readId(Map<dynamic, dynamic> json, String key) =>
      json['_id'] ?? json['id'] ?? '';

  static Object? _readCreatedByName(Map<dynamic, dynamic> json, String key) {
    final candidates = <dynamic>[
      json['createdByName'],
      json['created_by_name'],
      json['staffName'],
      json['staff_name'],
      json['userName'],
      json['user_name'],
      json['performedBy'],
      json['performed_by'],
    ];

    final user = json['user'];
    if (user is Map) {
      candidates.addAll([
        user['name'],
        user['userName'],
        user['fullName'],
        user['firstName'],
      ]);
    }

    final createdBy = json['createdBy'];
    if (createdBy is Map) {
      candidates.addAll([
        createdBy['name'],
        createdBy['userName'],
        createdBy['fullName'],
        createdBy['firstName'],
      ]);
    }

    for (final value in candidates) {
      if (value != null && '$value'.trim().isNotEmpty) {
        return '$value'.trim();
      }
    }
    return '';
  }

  static Object? _readOptionalString(Map<dynamic, dynamic> json, String key) {
    final direct = json[key];
    if (direct != null && '$direct'.trim().isNotEmpty) return direct;
    final snake = _snakeCase(key);
    if (snake != key && json[snake] != null) return json[snake];
    return '';
  }

  static String _snakeCase(String camel) {
    return camel.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }

  static ActivityDetails _detailsFromJson(dynamic value) {
    if (value == null) return ActivityDetails();
    if (value is Map<String, dynamic>) {
      return ActivityDetails.fromJson(value);
    }
    if (value is Map) {
      return ActivityDetails.fromJson(Map<String, dynamic>.from(value));
    }
    return ActivityDetails();
  }
}

@JsonSerializable()
class ActivityDetails {
  final int? gst;
  final bool? withTax;
  final String? category;
  final int? salePrice;

  ActivityDetails({this.gst, this.withTax, this.category, this.salePrice});

  factory ActivityDetails.fromJson(Map<String, dynamic> json) =>
      _$ActivityDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityDetailsToJson(this);
}

@JsonSerializable()
class PaginationModel {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PaginationModel({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationModelToJson(this);
}
