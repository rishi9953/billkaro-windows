class KdsQueueResponse {
  final String status;
  final String message;
  final KdsQueueData data;

  KdsQueueResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory KdsQueueResponse.fromJson(Map<String, dynamic> json) {
    return KdsQueueResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: KdsQueueData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class KdsQueueData {
  final KdsQueueSummary summary;
  final List<KdsTicket> tickets;

  KdsQueueData({required this.summary, required this.tickets});

  factory KdsQueueData.fromJson(Map<String, dynamic> json) {
    return KdsQueueData(
      summary: KdsQueueSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
      tickets: (json['tickets'] as List<dynamic>? ?? [])
          .map((e) => KdsTicket.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class KdsQueueSummary {
  final int newCount;
  final int preparing;
  final int ready;
  final int total;

  KdsQueueSummary({
    required this.newCount,
    required this.preparing,
    required this.ready,
    required this.total,
  });

  factory KdsQueueSummary.fromJson(Map<String, dynamic> json) {
    return KdsQueueSummary(
      newCount: (json['new'] as num?)?.toInt() ?? 0,
      preparing: (json['preparing'] as num?)?.toInt() ?? 0,
      ready: (json['ready'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class KdsTicket {
  final String orderId;
  final String billNumber;
  final String? tableNumber;
  final String? orderFrom;
  final String? customerName;
  final String? specialInstructions;
  final String kitchenStatus;
  final String firedAt;
  final int elapsedSeconds;
  final String urgency;
  final List<KdsTicketItem> items;
  final int pendingItemCount;
  final int estimatedPrepMinutes;
  final int remainingPrepSeconds;
  final bool overEstimate;

  KdsTicket({
    required this.orderId,
    required this.billNumber,
    this.tableNumber,
    this.orderFrom,
    this.customerName,
    this.specialInstructions,
    required this.kitchenStatus,
    required this.firedAt,
    required this.elapsedSeconds,
    required this.urgency,
    required this.items,
    required this.pendingItemCount,
    this.estimatedPrepMinutes = 0,
    this.remainingPrepSeconds = 0,
    this.overEstimate = false,
  });

  factory KdsTicket.fromJson(Map<String, dynamic> json) {
    return KdsTicket(
      orderId: json['orderId']?.toString() ?? '',
      billNumber: json['billNumber']?.toString() ?? '',
      tableNumber: json['tableNumber']?.toString(),
      orderFrom: json['orderFrom']?.toString(),
      customerName: json['customerName']?.toString(),
      specialInstructions: json['specialInstructions']?.toString(),
      kitchenStatus: json['kitchenStatus']?.toString() ?? 'new',
      firedAt: json['firedAt']?.toString() ?? '',
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      urgency: json['urgency']?.toString() ?? 'normal',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => KdsTicketItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingItemCount: (json['pendingItemCount'] as num?)?.toInt() ?? 0,
      estimatedPrepMinutes:
          (json['estimatedPrepMinutes'] as num?)?.toInt() ?? 0,
      remainingPrepSeconds:
          (json['remainingPrepSeconds'] as num?)?.toInt() ?? 0,
      overEstimate: json['overEstimate'] == true,
    );
  }
}

class KdsTicketItem {
  final String itemId;
  final String itemName;
  final String category;
  final int quantity;
  final int kotSentQuantity;
  final String kitchenLineStatus;
  final int prepTimeMinutes;
  final int estimatedMinutes;
  final String? itemRemark;

  KdsTicketItem({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.kotSentQuantity,
    required this.kitchenLineStatus,
    this.prepTimeMinutes = 15,
    this.estimatedMinutes = 15,
    this.itemRemark,
  });

  factory KdsTicketItem.fromJson(Map<String, dynamic> json) {
    return KdsTicketItem(
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      kotSentQuantity: (json['kotSentQuantity'] as num?)?.toInt() ?? 0,
      kitchenLineStatus: json['kitchenLineStatus']?.toString() ?? 'pending',
      prepTimeMinutes: (json['prepTimeMinutes'] as num?)?.toInt() ?? 15,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 15,
      itemRemark: json['itemRemark']?.toString(),
    );
  }

  bool get isReady => kitchenLineStatus == 'ready';
  bool get isPreparing => kitchenLineStatus == 'preparing';
}
