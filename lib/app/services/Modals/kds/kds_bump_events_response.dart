class KdsBumpEventsResponse {
  final String status;
  final String message;
  final KdsBumpEventsData data;

  KdsBumpEventsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory KdsBumpEventsResponse.fromJson(Map<String, dynamic> json) {
    return KdsBumpEventsResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: KdsBumpEventsData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class KdsBumpEventsData {
  final List<KdsBumpEvent> events;

  KdsBumpEventsData({required this.events});

  factory KdsBumpEventsData.fromJson(Map<String, dynamic> json) {
    final raw = json['events'];
    if (raw is! List) return KdsBumpEventsData(events: const []);
    return KdsBumpEventsData(
      events: raw
          .whereType<Map>()
          .map((e) => KdsBumpEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class KdsBumpEvent {
  final String orderId;
  final String billNumber;
  final String? tableNumber;
  final String bumpedAt;
  final String outletId;

  KdsBumpEvent({
    required this.orderId,
    required this.billNumber,
    this.tableNumber,
    required this.bumpedAt,
    required this.outletId,
  });

  factory KdsBumpEvent.fromJson(Map<String, dynamic> json) {
    return KdsBumpEvent(
      orderId: json['orderId']?.toString() ?? '',
      billNumber: json['billNumber']?.toString() ?? '',
      tableNumber: json['tableNumber']?.toString(),
      bumpedAt: json['bumpedAt']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
    );
  }

  String get dedupeKey => '$orderId|$bumpedAt';
}
