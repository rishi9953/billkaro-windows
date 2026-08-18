import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';

/// Client-side IDs generated while offline must not be sent to the API.
bool isClientGeneratedId(String? id) {
  if (id == null || id.isEmpty) return false;
  return id.startsWith('temp_') || id.startsWith('local_');
}

bool shouldCreateOnServer(String id) => isClientGeneratedId(id);

/// Remote rows must not overwrite local orders waiting to sync.
void mergeRemoteOrders(
  Map<String, OrderModel> target,
  Iterable<OrderModel> remote, {
  Set<String> unsyncedIds = const {},
}) {
  for (final order in remote) {
    if (unsyncedIds.contains(order.id)) continue;
    target[order.id] = order;
  }
}

/// Builds a server-safe order payload (strips local-only IDs and billNumber).
Map<String, dynamic> buildOrderSyncPayload(OrderModel order) {
  final payload = Map<String, dynamic>.from(order.toJson());

  if (isClientGeneratedId(order.id)) {
    payload.remove('id');
  }

  // Backend always assigns bill numbers; sending one can cause conflicts.
  payload.remove('billNumber');

  final items = payload['items'];
  if (items is List) {
    payload['items'] = items.map((raw) {
      if (raw is! Map) return raw;
      final item = Map<String, dynamic>.from(raw);
      if (isClientGeneratedId(item['itemId']?.toString())) {
        item.remove('itemId');
      }
      return item;
    }).toList();
  }

  return payload;
}

/// Parses the server order from a successful [addOrder] response.
OrderModel? parseSyncedOrderFromResponse(
  dynamic response,
  OrderModel localFallback,
) {
  if (response is! Map) return null;
  if (response['status']?.toString() != 'success') return null;

  final data = response['data'];
  if (data is! Map) return null;

  final map = Map<String, dynamic>.from(data);
  if (map['outletId'] == null) {
    map['outletId'] = localFallback.outletId;
  }
  if (map['userId'] == null) {
    map['userId'] = localFallback.userId;
  }
  if (map['items'] == null) {
    map['items'] = localFallback.items.map((e) => e.toJson()).toList();
  }

  try {
    return OrderModel.fromJson(map);
  } catch (_) {
    final serverId = map['id']?.toString();
    if (serverId == null || serverId.isEmpty) return null;

    return OrderModel(
      id: serverId,
      createdAt: map['createdAt']?.toString() ?? localFallback.createdAt,
      updatedAt: map['updatedAt']?.toString() ?? localFallback.updatedAt,
      billNumber: map['billNumber']?.toString() ?? localFallback.billNumber,
      userId: map['userId']?.toString() ?? localFallback.userId,
      tableNumber: map['tableNumber']?.toString() ?? localFallback.tableNumber,
      outletId: map['outletId']?.toString() ?? localFallback.outletId,
      customerName:
          map['customerName']?.toString() ?? localFallback.customerName,
      phoneNumber: map['phoneNumber']?.toString() ?? localFallback.phoneNumber,
      subtotal:
          (map['subtotal'] as num?)?.toDouble() ?? localFallback.subtotal,
      totalTax:
          (map['totalTax'] as num?)?.toDouble() ?? localFallback.totalTax,
      discount:
          (map['discount'] as num?)?.toDouble() ?? localFallback.discount,
      serviceCharge: (map['serviceCharge'] as num?)?.toDouble() ??
          localFallback.serviceCharge,
      totalAmount:
          (map['totalAmount'] as num?)?.toDouble() ?? localFallback.totalAmount,
      paymentReceivedIn: map['paymentReceivedIn']?.toString() ??
          localFallback.paymentReceivedIn,
      splitPayments: localFallback.splitPayments,
      status: map['status']?.toString() ?? localFallback.status,
      orderFrom: map['orderFrom']?.toString() ?? localFallback.orderFrom,
      items: localFallback.items,
      specialInstructions: map['specialInstructions']?.toString() ??
          localFallback.specialInstructions,
    );
  }
}
