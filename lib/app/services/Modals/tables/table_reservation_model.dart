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

  factory TableReservationModel.fromJson(Map<String, dynamic> json) {
    return TableReservationModel(
      id: json['id'] as String,
      outletId: json['outletId'] as String,
      tableId: json['tableId'] as String,
      tableNumber: json['tableNumber'] as String?,
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String?,
      partySize: (json['partySize'] as num?)?.toInt() ?? 2,
      reservationDate: json['reservationDate'] as String? ?? '',
      reservationTime: json['reservationTime'] as String? ?? '',
      status: json['status'] as String? ?? 'confirmed',
      source: json['source'] as String? ?? 'pos',
      notes: json['notes'] as String?,
    );
  }
}
