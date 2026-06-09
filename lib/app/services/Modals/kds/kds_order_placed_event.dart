class KdsOrderPlacedEvent {
  final String orderId;
  final String billNumber;
  final String? tableNumber;
  final String? orderFrom;
  final double totalAmount;
  final String? paymentReceivedIn;
  final String placedAt;
  final String outletId;

  KdsOrderPlacedEvent({
    required this.orderId,
    required this.billNumber,
    this.tableNumber,
    this.orderFrom,
    required this.totalAmount,
    this.paymentReceivedIn,
    required this.placedAt,
    required this.outletId,
  });

  factory KdsOrderPlacedEvent.fromJson(Map<String, dynamic> json) {
    return KdsOrderPlacedEvent(
      orderId: json['orderId']?.toString() ?? '',
      billNumber: json['billNumber']?.toString() ?? '',
      tableNumber: json['tableNumber']?.toString(),
      orderFrom: json['orderFrom']?.toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentReceivedIn: json['paymentReceivedIn']?.toString(),
      placedAt: json['placedAt']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
    );
  }

  String get dedupeKey => '$orderId|$placedAt';

  bool get isQrMenuOrder =>
      (orderFrom ?? '').trim().toLowerCase() == 'qr menu';
}
