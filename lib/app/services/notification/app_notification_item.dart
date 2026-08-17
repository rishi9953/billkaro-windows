enum AppNotificationType {
  kitchenReady,
  newOrder,
  sync,
  download,
}

class AppNotificationItem {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? orderId;
  final String? billNumber;
  final String? tableNumber;
  final String createdAtIso;
  final bool read;

  AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.billNumber,
    this.tableNumber,
    required this.createdAtIso,
    this.read = false,
  });

  DateTime get createdAt =>
      DateTime.tryParse(createdAtIso) ?? DateTime.now();

  AppNotificationItem copyWith({bool? read}) {
    return AppNotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      billNumber: billNumber,
      tableNumber: tableNumber,
      createdAtIso: createdAtIso,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'orderId': orderId,
        'billNumber': billNumber,
        'tableNumber': tableNumber,
        'createdAtIso': createdAtIso,
        'read': read,
      };

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString() ?? 'kitchenReady';
    return AppNotificationItem(
      id: json['id']?.toString() ?? '',
      type: AppNotificationType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => AppNotificationType.kitchenReady,
      ),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      billNumber: json['billNumber']?.toString(),
      tableNumber: json['tableNumber']?.toString(),
      createdAtIso: json['createdAtIso']?.toString() ??
          DateTime.now().toUtc().toIso8601String(),
      read: json['read'] == true,
    );
  }
}
