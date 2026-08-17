class TableReservationModel {
  final String id;
  final String outletId;
  final String tableId;
  final String? tableNumber;
  final String customerName;
  final String? customerPhone;
  final int partySize;
  final String reservationDate;
  final String reservationTime;
  final String status;
  final String source;
  final String? notes;

  TableReservationModel({
    required this.id,
    required this.outletId,
    required this.tableId,
    this.tableNumber,
    required this.customerName,
    this.customerPhone,
    required this.partySize,
    required this.reservationDate,
    required this.reservationTime,
    required this.status,
    required this.source,
    this.notes,
  });

  bool get isActive {
    final s = status.toLowerCase();
    return s == 'pending' || s == 'confirmed';
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  /// Normalizes DATEONLY / ISO datetime values to `YYYY-MM-DD`.
  static String asDateOnly(dynamic value) {
    final raw = _asString(value);
    if (raw.isEmpty) return '';
    if (raw.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
      return raw.substring(0, 10);
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }

  /// Normalizes times like `19:00:00` or `7:00 PM` to `HH:mm`.
  static String asTimeHm(dynamic value) {
    final raw = _asString(value);
    if (raw.isEmpty) return '';
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) return raw;
    final hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = match.group(2)!;
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  factory TableReservationModel.fromJson(Map<String, dynamic> json) {
    final nestedTable = json['table'];
    final nestedTableMap =
        nestedTable is Map ? Map<String, dynamic>.from(nestedTable) : null;

    return TableReservationModel(
      id: _asString(json['id']),
      outletId: _asString(json['outletId']),
      tableId: _asString(json['tableId'] ?? nestedTableMap?['id']),
      tableNumber: () {
        final direct = _asString(json['tableNumber']);
        if (direct.isNotEmpty) return direct;
        final nested = _asString(nestedTableMap?['tableNumber']);
        return nested.isEmpty ? null : nested;
      }(),
      customerName: _asString(json['customerName']),
      customerPhone: () {
        final phone = _asString(json['customerPhone']);
        return phone.isEmpty ? null : phone;
      }(),
      partySize: (json['partySize'] as num?)?.toInt() ?? 2,
      reservationDate: asDateOnly(json['reservationDate']),
      reservationTime: asTimeHm(json['reservationTime']),
      status: _asString(json['status']).isEmpty
          ? 'confirmed'
          : _asString(json['status']),
      source: _asString(json['source']).isEmpty
          ? 'pos'
          : _asString(json['source']),
      notes: () {
        final notes = _asString(json['notes']);
        return notes.isEmpty ? null : notes;
      }(),
    );
  }
}
