import 'package:json_annotation/json_annotation.dart';

part 'tables_response.g.dart';

@JsonSerializable()
class TablesResponse {
  final String status;
  final String message;
  final List<TableData> data;

  TablesResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TablesResponse.fromJson(Map<String, dynamic> json) =>
      _$TablesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TablesResponseToJson(this);
}

int _tableSeatingCapacityFromJson(dynamic json) {
  const defaultValue = 4;
  if (json == null) return defaultValue;
  if (json is int) return json > 0 ? json : defaultValue;
  if (json is num) {
    final n = json.toInt();
    return n > 0 ? n : defaultValue;
  }
  if (json is String) {
    final n = int.tryParse(json.trim());
    return (n != null && n > 0) ? n : defaultValue;
  }
  return defaultValue;
}

@JsonSerializable()
class TableData {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String outletId;
  final String tableNumber;
  final String status;
  final String? currentBillNumber;
  final String? qrToken;
  final String? qrMenuUrl;
  final bool? qrEnabled;
  final String? mergedIntoTableId;
  @JsonKey(name: 'seatingcapacity', fromJson: _tableSeatingCapacityFromJson, defaultValue: 4)
  final int seatingCapacity;
  @JsonKey(defaultValue: <String>[])
  final List<String> mergedTableNumbers;

  TableData({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.outletId,
    required this.tableNumber,
    required this.status,
    this.currentBillNumber,
    this.qrToken,
    this.qrMenuUrl,
    this.qrEnabled,
    this.mergedIntoTableId,
    this.seatingCapacity = 4,
    this.mergedTableNumbers = const [],
  });

  factory TableData.fromJson(Map<String, dynamic> json) =>
      _$TableDataFromJson(json);

  Map<String, dynamic> toJson() => _$TableDataToJson(this);
}

/// UI model for a table (from API or default). Used by TableScreen/TableController.
class TableModel {
  final String id;
  final String tableNumber;
  final String status;
  final String? currentBillNumber;
  final String? qrToken;
  final String? qrMenuUrl;
  final bool qrEnabled;
  final String? mergedIntoTableId;
  final List<String> mergedTableNumbers;
  final int seatingCapacity;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.status,
    this.currentBillNumber,
    this.qrToken,
    this.qrMenuUrl,
    this.qrEnabled = true,
    this.mergedIntoTableId,
    this.mergedTableNumbers = const [],
    this.seatingCapacity = 4,
  });

  String get displayName =>
      tableNumber.toLowerCase().startsWith('table ')
          ? tableNumber
          : 'Table $tableNumber';

  String get combinedDisplayName {
    if (mergedTableNumbers.isEmpty) return displayName;
    final extras = mergedTableNumbers
        .map(
          (n) => n.toLowerCase().startsWith('table ') ? n : 'Table $n',
        )
        .join(', ');
    return '$displayName + $extras';
  }

  bool get isMergedSecondary =>
      mergedIntoTableId != null && mergedIntoTableId!.isNotEmpty;

  bool get hasMergedTables => mergedTableNumbers.isNotEmpty;

  bool get isAvailableFromApi =>
      status.toLowerCase() == 'available' || status.isEmpty;

  factory TableModel.fromTableData(TableData d) {
    return TableModel(
      id: d.id,
      tableNumber: d.tableNumber,
      status: d.status,
      currentBillNumber: d.currentBillNumber,
      qrToken: d.qrToken,
      qrMenuUrl: d.qrMenuUrl,
      qrEnabled: d.qrEnabled ?? true,
      mergedIntoTableId: d.mergedIntoTableId,
      mergedTableNumbers: d.mergedTableNumbers,
      seatingCapacity: d.seatingCapacity,
    );
  }
}
