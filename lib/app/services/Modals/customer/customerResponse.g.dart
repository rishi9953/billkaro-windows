// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customerResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerResponse _$CustomerResponseFromJson(Map<String, dynamic> json) =>
    CustomerResponse(
      status: json['status'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => CustomerData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CustomerResponseToJson(CustomerResponse instance) =>
    <String, dynamic>{'status': instance.status, 'data': instance.data};

CustomerData _$CustomerDataFromJson(Map<String, dynamic> json) => CustomerData(
  id: json['id'] as String,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  userId: json['userId'] as String,
  outletId: json['outletId'] as String,
  customerName: json['customerName'] as String,
  phoneNumber: json['phoneNumber'] as String,
  loyalityDiscount: (json['loyalityDiscount'] as num).toInt(),
);

Map<String, dynamic> _$CustomerDataToJson(CustomerData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'userId': instance.userId,
      'outletId': instance.outletId,
      'customerName': instance.customerName,
      'phoneNumber': instance.phoneNumber,
      'loyalityDiscount': instance.loyalityDiscount,
    };

CustomerDetailsResponse _$CustomerDetailsResponseFromJson(
  Map<String, dynamic> json,
) => CustomerDetailsResponse(
  status: json['status'] as String,
  data: CustomerDetailsData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CustomerDetailsResponseToJson(
  CustomerDetailsResponse instance,
) => <String, dynamic>{'status': instance.status, 'data': instance.data};

CustomerDetailsData _$CustomerDetailsDataFromJson(Map<String, dynamic> json) =>
    CustomerDetailsData(
      customer: CustomerData.fromJson(json['customer'] as Map<String, dynamic>),
      stats: CustomerStats.fromJson(json['stats'] as Map<String, dynamic>),
      orders: (json['orders'] as List<dynamic>)
          .map((e) => CustomerLastOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: CustomerOrdersPagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
      lastOrder: json['lastOrder'] == null
          ? null
          : CustomerLastOrder.fromJson(
              json['lastOrder'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CustomerDetailsDataToJson(
  CustomerDetailsData instance,
) => <String, dynamic>{
  'customer': instance.customer,
  'stats': instance.stats,
  'orders': instance.orders,
  'lastOrder': instance.lastOrder,
  'pagination': instance.pagination,
};

CustomerOrdersPagination _$CustomerOrdersPaginationFromJson(
  Map<String, dynamic> json,
) => CustomerOrdersPagination(
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  totalOrders: (json['totalOrders'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$CustomerOrdersPaginationToJson(
  CustomerOrdersPagination instance,
) => <String, dynamic>{
  'page': instance.page,
  'limit': instance.limit,
  'totalOrders': instance.totalOrders,
  'totalPages': instance.totalPages,
};

CustomerStats _$CustomerStatsFromJson(Map<String, dynamic> json) =>
    CustomerStats(
      avgOrder: (json['avgOrder'] as num).toDouble(),
      totalDiscount: (json['totalDiscount'] as num).toDouble(),
      totalVisits: (json['totalVisits'] as num).toInt(),
      orderValue: (json['orderValue'] as num).toDouble(),
    );

Map<String, dynamic> _$CustomerStatsToJson(CustomerStats instance) =>
    <String, dynamic>{
      'avgOrder': instance.avgOrder,
      'totalDiscount': instance.totalDiscount,
      'totalVisits': instance.totalVisits,
      'orderValue': instance.orderValue,
    };

CustomerLastOrder _$CustomerLastOrderFromJson(Map<String, dynamic> json) =>
    CustomerLastOrder(
      id: json['id'] as String,
      billNumber: json['billNumber'] as String,
      orderDate: json['orderDate'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentType: json['paymentType'] as String,
      status: json['status'] as String? ?? 'pending',
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$CustomerLastOrderToJson(CustomerLastOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'billNumber': instance.billNumber,
      'orderDate': instance.orderDate,
      'totalAmount': instance.totalAmount,
      'paymentType': instance.paymentType,
      'status': instance.status,
      'discount': instance.discount,
    };

CustomerLookupResponse _$CustomerLookupResponseFromJson(
  Map<String, dynamic> json,
) => CustomerLookupResponse(
  status: json['status'] as String,
  data: json['data'] == null
      ? null
      : CustomerData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CustomerLookupResponseToJson(
  CustomerLookupResponse instance,
) => <String, dynamic>{'status': instance.status, 'data': instance.data};
