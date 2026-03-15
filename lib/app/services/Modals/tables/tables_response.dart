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

@JsonSerializable()
class TableData {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String outletId;
  final String tableNumber;
  final String status;
  final String? currentBillNumber;

  TableData({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.outletId,
    required this.tableNumber,
    required this.status,
    this.currentBillNumber,
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

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.status,
    this.currentBillNumber,
  });

  String get displayName =>
      tableNumber.toLowerCase().startsWith('table ')
          ? tableNumber
          : 'Table $tableNumber';

  bool get isAvailableFromApi =>
      status.toLowerCase() == 'available' || status.isEmpty;

  factory TableModel.fromTableData(TableData d) {
    return TableModel(
      id: d.id,
      tableNumber: d.tableNumber,
      status: d.status,
      currentBillNumber: d.currentBillNumber,
    );
  }
}
