// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billNumberMeta = const VerificationMeta(
    'billNumber',
  );
  @override
  late final GeneratedColumn<String> billNumber = GeneratedColumn<String>(
    'bill_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outletIdMeta = const VerificationMeta(
    'outletId',
  );
  @override
  late final GeneratedColumn<String> outletId = GeneratedColumn<String>(
    'outlet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableNumberMeta = const VerificationMeta(
    'tableNumber',
  );
  @override
  late final GeneratedColumn<String> tableNumber = GeneratedColumn<String>(
    'table_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalTaxMeta = const VerificationMeta(
    'totalTax',
  );
  @override
  late final GeneratedColumn<double> totalTax = GeneratedColumn<double>(
    'total_tax',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountMeta = const VerificationMeta(
    'discount',
  );
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
    'discount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceChargeMeta = const VerificationMeta(
    'serviceCharge',
  );
  @override
  late final GeneratedColumn<double> serviceCharge = GeneratedColumn<double>(
    'service_charge',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentReceivedInMeta = const VerificationMeta(
    'paymentReceivedIn',
  );
  @override
  late final GeneratedColumn<String> paymentReceivedIn =
      GeneratedColumn<String>(
        'payment_received_in',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _splitPaymentsMeta = const VerificationMeta(
    'splitPayments',
  );
  @override
  late final GeneratedColumn<String> splitPayments = GeneratedColumn<String>(
    'split_payments',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderFromMeta = const VerificationMeta(
    'orderFrom',
  );
  @override
  late final GeneratedColumn<String> orderFrom = GeneratedColumn<String>(
    'order_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncMeta = const VerificationMeta('isSync');
  @override
  late final GeneratedColumn<String> isSync = GeneratedColumn<String>(
    'is_sync',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderJsonMeta = const VerificationMeta(
    'orderJson',
  );
  @override
  late final GeneratedColumn<String> orderJson = GeneratedColumn<String>(
    'order_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    billNumber,
    userId,
    outletId,
    tableNumber,
    customerName,
    phoneNumber,
    subtotal,
    totalTax,
    discount,
    serviceCharge,
    totalAmount,
    paymentReceivedIn,
    splitPayments,
    status,
    orderFrom,
    isSync,
    orderJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Order> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('bill_number')) {
      context.handle(
        _billNumberMeta,
        billNumber.isAcceptableOrUnknown(data['bill_number']!, _billNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_billNumberMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('outlet_id')) {
      context.handle(
        _outletIdMeta,
        outletId.isAcceptableOrUnknown(data['outlet_id']!, _outletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outletIdMeta);
    }
    if (data.containsKey('table_number')) {
      context.handle(
        _tableNumberMeta,
        tableNumber.isAcceptableOrUnknown(
          data['table_number']!,
          _tableNumberMeta,
        ),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('total_tax')) {
      context.handle(
        _totalTaxMeta,
        totalTax.isAcceptableOrUnknown(data['total_tax']!, _totalTaxMeta),
      );
    } else if (isInserting) {
      context.missing(_totalTaxMeta);
    }
    if (data.containsKey('discount')) {
      context.handle(
        _discountMeta,
        discount.isAcceptableOrUnknown(data['discount']!, _discountMeta),
      );
    } else if (isInserting) {
      context.missing(_discountMeta);
    }
    if (data.containsKey('service_charge')) {
      context.handle(
        _serviceChargeMeta,
        serviceCharge.isAcceptableOrUnknown(
          data['service_charge']!,
          _serviceChargeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serviceChargeMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('payment_received_in')) {
      context.handle(
        _paymentReceivedInMeta,
        paymentReceivedIn.isAcceptableOrUnknown(
          data['payment_received_in']!,
          _paymentReceivedInMeta,
        ),
      );
    }
    if (data.containsKey('split_payments')) {
      context.handle(
        _splitPaymentsMeta,
        splitPayments.isAcceptableOrUnknown(
          data['split_payments']!,
          _splitPaymentsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('order_from')) {
      context.handle(
        _orderFromMeta,
        orderFrom.isAcceptableOrUnknown(data['order_from']!, _orderFromMeta),
      );
    } else if (isInserting) {
      context.missing(_orderFromMeta);
    }
    if (data.containsKey('is_sync')) {
      context.handle(
        _isSyncMeta,
        isSync.isAcceptableOrUnknown(data['is_sync']!, _isSyncMeta),
      );
    } else if (isInserting) {
      context.missing(_isSyncMeta);
    }
    if (data.containsKey('order_json')) {
      context.handle(
        _orderJsonMeta,
        orderJson.isAcceptableOrUnknown(data['order_json']!, _orderJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      billNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_number'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      outletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outlet_id'],
      )!,
      tableNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_number'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      totalTax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_tax'],
      )!,
      discount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount'],
      )!,
      serviceCharge: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}service_charge'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      paymentReceivedIn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_received_in'],
      ),
      splitPayments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_payments'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      orderFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_from'],
      )!,
      isSync: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}is_sync'],
      )!,
      orderJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_json'],
      ),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String billNumber;
  final String userId;

  /// 🔹 IMPORTANT: outletId column
  final String outletId;
  final String? tableNumber;
  final String? customerName;
  final String? phoneNumber;
  final double subtotal;
  final double totalTax;
  final double discount;
  final double serviceCharge;
  final double totalAmount;
  final String? paymentReceivedIn;
  final String? splitPayments;
  final String status;
  final String orderFrom;
  final String isSync;

  /// Full OrderModel JSON so offline \u2192 online sync keeps variants, remarks, etc.
  final String? orderJson;
  const Order({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.billNumber,
    required this.userId,
    required this.outletId,
    this.tableNumber,
    this.customerName,
    this.phoneNumber,
    required this.subtotal,
    required this.totalTax,
    required this.discount,
    required this.serviceCharge,
    required this.totalAmount,
    this.paymentReceivedIn,
    this.splitPayments,
    required this.status,
    required this.orderFrom,
    required this.isSync,
    this.orderJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['bill_number'] = Variable<String>(billNumber);
    map['user_id'] = Variable<String>(userId);
    map['outlet_id'] = Variable<String>(outletId);
    if (!nullToAbsent || tableNumber != null) {
      map['table_number'] = Variable<String>(tableNumber);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['total_tax'] = Variable<double>(totalTax);
    map['discount'] = Variable<double>(discount);
    map['service_charge'] = Variable<double>(serviceCharge);
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || paymentReceivedIn != null) {
      map['payment_received_in'] = Variable<String>(paymentReceivedIn);
    }
    if (!nullToAbsent || splitPayments != null) {
      map['split_payments'] = Variable<String>(splitPayments);
    }
    map['status'] = Variable<String>(status);
    map['order_from'] = Variable<String>(orderFrom);
    map['is_sync'] = Variable<String>(isSync);
    if (!nullToAbsent || orderJson != null) {
      map['order_json'] = Variable<String>(orderJson);
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      billNumber: Value(billNumber),
      userId: Value(userId),
      outletId: Value(outletId),
      tableNumber: tableNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNumber),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      subtotal: Value(subtotal),
      totalTax: Value(totalTax),
      discount: Value(discount),
      serviceCharge: Value(serviceCharge),
      totalAmount: Value(totalAmount),
      paymentReceivedIn: paymentReceivedIn == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentReceivedIn),
      splitPayments: splitPayments == null && nullToAbsent
          ? const Value.absent()
          : Value(splitPayments),
      status: Value(status),
      orderFrom: Value(orderFrom),
      isSync: Value(isSync),
      orderJson: orderJson == null && nullToAbsent
          ? const Value.absent()
          : Value(orderJson),
    );
  }

  factory Order.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      billNumber: serializer.fromJson<String>(json['billNumber']),
      userId: serializer.fromJson<String>(json['userId']),
      outletId: serializer.fromJson<String>(json['outletId']),
      tableNumber: serializer.fromJson<String?>(json['tableNumber']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      totalTax: serializer.fromJson<double>(json['totalTax']),
      discount: serializer.fromJson<double>(json['discount']),
      serviceCharge: serializer.fromJson<double>(json['serviceCharge']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paymentReceivedIn: serializer.fromJson<String?>(
        json['paymentReceivedIn'],
      ),
      splitPayments: serializer.fromJson<String?>(json['splitPayments']),
      status: serializer.fromJson<String>(json['status']),
      orderFrom: serializer.fromJson<String>(json['orderFrom']),
      isSync: serializer.fromJson<String>(json['isSync']),
      orderJson: serializer.fromJson<String?>(json['orderJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'billNumber': serializer.toJson<String>(billNumber),
      'userId': serializer.toJson<String>(userId),
      'outletId': serializer.toJson<String>(outletId),
      'tableNumber': serializer.toJson<String?>(tableNumber),
      'customerName': serializer.toJson<String?>(customerName),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'subtotal': serializer.toJson<double>(subtotal),
      'totalTax': serializer.toJson<double>(totalTax),
      'discount': serializer.toJson<double>(discount),
      'serviceCharge': serializer.toJson<double>(serviceCharge),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paymentReceivedIn': serializer.toJson<String?>(paymentReceivedIn),
      'splitPayments': serializer.toJson<String?>(splitPayments),
      'status': serializer.toJson<String>(status),
      'orderFrom': serializer.toJson<String>(orderFrom),
      'isSync': serializer.toJson<String>(isSync),
      'orderJson': serializer.toJson<String?>(orderJson),
    };
  }

  Order copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? billNumber,
    String? userId,
    String? outletId,
    Value<String?> tableNumber = const Value.absent(),
    Value<String?> customerName = const Value.absent(),
    Value<String?> phoneNumber = const Value.absent(),
    double? subtotal,
    double? totalTax,
    double? discount,
    double? serviceCharge,
    double? totalAmount,
    Value<String?> paymentReceivedIn = const Value.absent(),
    Value<String?> splitPayments = const Value.absent(),
    String? status,
    String? orderFrom,
    String? isSync,
    Value<String?> orderJson = const Value.absent(),
  }) => Order(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    billNumber: billNumber ?? this.billNumber,
    userId: userId ?? this.userId,
    outletId: outletId ?? this.outletId,
    tableNumber: tableNumber.present ? tableNumber.value : this.tableNumber,
    customerName: customerName.present ? customerName.value : this.customerName,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    subtotal: subtotal ?? this.subtotal,
    totalTax: totalTax ?? this.totalTax,
    discount: discount ?? this.discount,
    serviceCharge: serviceCharge ?? this.serviceCharge,
    totalAmount: totalAmount ?? this.totalAmount,
    paymentReceivedIn: paymentReceivedIn.present
        ? paymentReceivedIn.value
        : this.paymentReceivedIn,
    splitPayments: splitPayments.present
        ? splitPayments.value
        : this.splitPayments,
    status: status ?? this.status,
    orderFrom: orderFrom ?? this.orderFrom,
    isSync: isSync ?? this.isSync,
    orderJson: orderJson.present ? orderJson.value : this.orderJson,
  );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      billNumber: data.billNumber.present
          ? data.billNumber.value
          : this.billNumber,
      userId: data.userId.present ? data.userId.value : this.userId,
      outletId: data.outletId.present ? data.outletId.value : this.outletId,
      tableNumber: data.tableNumber.present
          ? data.tableNumber.value
          : this.tableNumber,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      totalTax: data.totalTax.present ? data.totalTax.value : this.totalTax,
      discount: data.discount.present ? data.discount.value : this.discount,
      serviceCharge: data.serviceCharge.present
          ? data.serviceCharge.value
          : this.serviceCharge,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      paymentReceivedIn: data.paymentReceivedIn.present
          ? data.paymentReceivedIn.value
          : this.paymentReceivedIn,
      splitPayments: data.splitPayments.present
          ? data.splitPayments.value
          : this.splitPayments,
      status: data.status.present ? data.status.value : this.status,
      orderFrom: data.orderFrom.present ? data.orderFrom.value : this.orderFrom,
      isSync: data.isSync.present ? data.isSync.value : this.isSync,
      orderJson: data.orderJson.present ? data.orderJson.value : this.orderJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('billNumber: $billNumber, ')
          ..write('userId: $userId, ')
          ..write('outletId: $outletId, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('customerName: $customerName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('subtotal: $subtotal, ')
          ..write('totalTax: $totalTax, ')
          ..write('discount: $discount, ')
          ..write('serviceCharge: $serviceCharge, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentReceivedIn: $paymentReceivedIn, ')
          ..write('splitPayments: $splitPayments, ')
          ..write('status: $status, ')
          ..write('orderFrom: $orderFrom, ')
          ..write('isSync: $isSync, ')
          ..write('orderJson: $orderJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    billNumber,
    userId,
    outletId,
    tableNumber,
    customerName,
    phoneNumber,
    subtotal,
    totalTax,
    discount,
    serviceCharge,
    totalAmount,
    paymentReceivedIn,
    splitPayments,
    status,
    orderFrom,
    isSync,
    orderJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.billNumber == this.billNumber &&
          other.userId == this.userId &&
          other.outletId == this.outletId &&
          other.tableNumber == this.tableNumber &&
          other.customerName == this.customerName &&
          other.phoneNumber == this.phoneNumber &&
          other.subtotal == this.subtotal &&
          other.totalTax == this.totalTax &&
          other.discount == this.discount &&
          other.serviceCharge == this.serviceCharge &&
          other.totalAmount == this.totalAmount &&
          other.paymentReceivedIn == this.paymentReceivedIn &&
          other.splitPayments == this.splitPayments &&
          other.status == this.status &&
          other.orderFrom == this.orderFrom &&
          other.isSync == this.isSync &&
          other.orderJson == this.orderJson);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> billNumber;
  final Value<String> userId;
  final Value<String> outletId;
  final Value<String?> tableNumber;
  final Value<String?> customerName;
  final Value<String?> phoneNumber;
  final Value<double> subtotal;
  final Value<double> totalTax;
  final Value<double> discount;
  final Value<double> serviceCharge;
  final Value<double> totalAmount;
  final Value<String?> paymentReceivedIn;
  final Value<String?> splitPayments;
  final Value<String> status;
  final Value<String> orderFrom;
  final Value<String> isSync;
  final Value<String?> orderJson;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.billNumber = const Value.absent(),
    this.userId = const Value.absent(),
    this.outletId = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.customerName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.totalTax = const Value.absent(),
    this.discount = const Value.absent(),
    this.serviceCharge = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paymentReceivedIn = const Value.absent(),
    this.splitPayments = const Value.absent(),
    this.status = const Value.absent(),
    this.orderFrom = const Value.absent(),
    this.isSync = const Value.absent(),
    this.orderJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String billNumber,
    required String userId,
    required String outletId,
    this.tableNumber = const Value.absent(),
    this.customerName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    required double subtotal,
    required double totalTax,
    required double discount,
    required double serviceCharge,
    required double totalAmount,
    this.paymentReceivedIn = const Value.absent(),
    this.splitPayments = const Value.absent(),
    required String status,
    required String orderFrom,
    required String isSync,
    this.orderJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       billNumber = Value(billNumber),
       userId = Value(userId),
       outletId = Value(outletId),
       subtotal = Value(subtotal),
       totalTax = Value(totalTax),
       discount = Value(discount),
       serviceCharge = Value(serviceCharge),
       totalAmount = Value(totalAmount),
       status = Value(status),
       orderFrom = Value(orderFrom),
       isSync = Value(isSync);
  static Insertable<Order> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? billNumber,
    Expression<String>? userId,
    Expression<String>? outletId,
    Expression<String>? tableNumber,
    Expression<String>? customerName,
    Expression<String>? phoneNumber,
    Expression<double>? subtotal,
    Expression<double>? totalTax,
    Expression<double>? discount,
    Expression<double>? serviceCharge,
    Expression<double>? totalAmount,
    Expression<String>? paymentReceivedIn,
    Expression<String>? splitPayments,
    Expression<String>? status,
    Expression<String>? orderFrom,
    Expression<String>? isSync,
    Expression<String>? orderJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (billNumber != null) 'bill_number': billNumber,
      if (userId != null) 'user_id': userId,
      if (outletId != null) 'outlet_id': outletId,
      if (tableNumber != null) 'table_number': tableNumber,
      if (customerName != null) 'customer_name': customerName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (subtotal != null) 'subtotal': subtotal,
      if (totalTax != null) 'total_tax': totalTax,
      if (discount != null) 'discount': discount,
      if (serviceCharge != null) 'service_charge': serviceCharge,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paymentReceivedIn != null) 'payment_received_in': paymentReceivedIn,
      if (splitPayments != null) 'split_payments': splitPayments,
      if (status != null) 'status': status,
      if (orderFrom != null) 'order_from': orderFrom,
      if (isSync != null) 'is_sync': isSync,
      if (orderJson != null) 'order_json': orderJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? billNumber,
    Value<String>? userId,
    Value<String>? outletId,
    Value<String?>? tableNumber,
    Value<String?>? customerName,
    Value<String?>? phoneNumber,
    Value<double>? subtotal,
    Value<double>? totalTax,
    Value<double>? discount,
    Value<double>? serviceCharge,
    Value<double>? totalAmount,
    Value<String?>? paymentReceivedIn,
    Value<String?>? splitPayments,
    Value<String>? status,
    Value<String>? orderFrom,
    Value<String>? isSync,
    Value<String?>? orderJson,
    Value<int>? rowid,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      billNumber: billNumber ?? this.billNumber,
      userId: userId ?? this.userId,
      outletId: outletId ?? this.outletId,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      subtotal: subtotal ?? this.subtotal,
      totalTax: totalTax ?? this.totalTax,
      discount: discount ?? this.discount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentReceivedIn: paymentReceivedIn ?? this.paymentReceivedIn,
      splitPayments: splitPayments ?? this.splitPayments,
      status: status ?? this.status,
      orderFrom: orderFrom ?? this.orderFrom,
      isSync: isSync ?? this.isSync,
      orderJson: orderJson ?? this.orderJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (billNumber.present) {
      map['bill_number'] = Variable<String>(billNumber.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (outletId.present) {
      map['outlet_id'] = Variable<String>(outletId.value);
    }
    if (tableNumber.present) {
      map['table_number'] = Variable<String>(tableNumber.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (totalTax.present) {
      map['total_tax'] = Variable<double>(totalTax.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (serviceCharge.present) {
      map['service_charge'] = Variable<double>(serviceCharge.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paymentReceivedIn.present) {
      map['payment_received_in'] = Variable<String>(paymentReceivedIn.value);
    }
    if (splitPayments.present) {
      map['split_payments'] = Variable<String>(splitPayments.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (orderFrom.present) {
      map['order_from'] = Variable<String>(orderFrom.value);
    }
    if (isSync.present) {
      map['is_sync'] = Variable<String>(isSync.value);
    }
    if (orderJson.present) {
      map['order_json'] = Variable<String>(orderJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('billNumber: $billNumber, ')
          ..write('userId: $userId, ')
          ..write('outletId: $outletId, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('customerName: $customerName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('subtotal: $subtotal, ')
          ..write('totalTax: $totalTax, ')
          ..write('discount: $discount, ')
          ..write('serviceCharge: $serviceCharge, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentReceivedIn: $paymentReceivedIn, ')
          ..write('splitPayments: $splitPayments, ')
          ..write('status: $status, ')
          ..write('orderFrom: $orderFrom, ')
          ..write('isSync: $isSync, ')
          ..write('orderJson: $orderJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderItemsTable extends OrderItems
    with TableInfo<$OrderItemsTable, OrderItemEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _autoIdMeta = const VerificationMeta('autoId');
  @override
  late final GeneratedColumn<int> autoId = GeneratedColumn<int>(
    'auto_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES orders (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salePriceMeta = const VerificationMeta(
    'salePrice',
  );
  @override
  late final GeneratedColumn<double> salePrice = GeneratedColumn<double>(
    'sale_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gstMeta = const VerificationMeta('gst');
  @override
  late final GeneratedColumn<double> gst = GeneratedColumn<double>(
    'gst',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    autoId,
    orderId,
    itemId,
    itemName,
    category,
    quantity,
    salePrice,
    gst,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderItemEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('auto_id')) {
      context.handle(
        _autoIdMeta,
        autoId.isAcceptableOrUnknown(data['auto_id']!, _autoIdMeta),
      );
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('sale_price')) {
      context.handle(
        _salePriceMeta,
        salePrice.isAcceptableOrUnknown(data['sale_price']!, _salePriceMeta),
      );
    } else if (isInserting) {
      context.missing(_salePriceMeta);
    }
    if (data.containsKey('gst')) {
      context.handle(
        _gstMeta,
        gst.isAcceptableOrUnknown(data['gst']!, _gstMeta),
      );
    } else if (isInserting) {
      context.missing(_gstMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {autoId};
  @override
  OrderItemEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderItemEntity(
      autoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      salePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sale_price'],
      )!,
      gst: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gst'],
      )!,
    );
  }

  @override
  $OrderItemsTable createAlias(String alias) {
    return $OrderItemsTable(attachedDatabase, alias);
  }
}

class OrderItemEntity extends DataClass implements Insertable<OrderItemEntity> {
  final int autoId;
  final String orderId;
  final String itemId;
  final String itemName;
  final String category;
  final int quantity;
  final double salePrice;
  final double gst;
  const OrderItemEntity({
    required this.autoId,
    required this.orderId,
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.salePrice,
    required this.gst,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['auto_id'] = Variable<int>(autoId);
    map['order_id'] = Variable<String>(orderId);
    map['item_id'] = Variable<String>(itemId);
    map['item_name'] = Variable<String>(itemName);
    map['category'] = Variable<String>(category);
    map['quantity'] = Variable<int>(quantity);
    map['sale_price'] = Variable<double>(salePrice);
    map['gst'] = Variable<double>(gst);
    return map;
  }

  OrderItemsCompanion toCompanion(bool nullToAbsent) {
    return OrderItemsCompanion(
      autoId: Value(autoId),
      orderId: Value(orderId),
      itemId: Value(itemId),
      itemName: Value(itemName),
      category: Value(category),
      quantity: Value(quantity),
      salePrice: Value(salePrice),
      gst: Value(gst),
    );
  }

  factory OrderItemEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderItemEntity(
      autoId: serializer.fromJson<int>(json['autoId']),
      orderId: serializer.fromJson<String>(json['orderId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemName: serializer.fromJson<String>(json['itemName']),
      category: serializer.fromJson<String>(json['category']),
      quantity: serializer.fromJson<int>(json['quantity']),
      salePrice: serializer.fromJson<double>(json['salePrice']),
      gst: serializer.fromJson<double>(json['gst']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'autoId': serializer.toJson<int>(autoId),
      'orderId': serializer.toJson<String>(orderId),
      'itemId': serializer.toJson<String>(itemId),
      'itemName': serializer.toJson<String>(itemName),
      'category': serializer.toJson<String>(category),
      'quantity': serializer.toJson<int>(quantity),
      'salePrice': serializer.toJson<double>(salePrice),
      'gst': serializer.toJson<double>(gst),
    };
  }

  OrderItemEntity copyWith({
    int? autoId,
    String? orderId,
    String? itemId,
    String? itemName,
    String? category,
    int? quantity,
    double? salePrice,
    double? gst,
  }) => OrderItemEntity(
    autoId: autoId ?? this.autoId,
    orderId: orderId ?? this.orderId,
    itemId: itemId ?? this.itemId,
    itemName: itemName ?? this.itemName,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    salePrice: salePrice ?? this.salePrice,
    gst: gst ?? this.gst,
  );
  OrderItemEntity copyWithCompanion(OrderItemsCompanion data) {
    return OrderItemEntity(
      autoId: data.autoId.present ? data.autoId.value : this.autoId,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      category: data.category.present ? data.category.value : this.category,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      salePrice: data.salePrice.present ? data.salePrice.value : this.salePrice,
      gst: data.gst.present ? data.gst.value : this.gst,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemEntity(')
          ..write('autoId: $autoId, ')
          ..write('orderId: $orderId, ')
          ..write('itemId: $itemId, ')
          ..write('itemName: $itemName, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('salePrice: $salePrice, ')
          ..write('gst: $gst')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    autoId,
    orderId,
    itemId,
    itemName,
    category,
    quantity,
    salePrice,
    gst,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItemEntity &&
          other.autoId == this.autoId &&
          other.orderId == this.orderId &&
          other.itemId == this.itemId &&
          other.itemName == this.itemName &&
          other.category == this.category &&
          other.quantity == this.quantity &&
          other.salePrice == this.salePrice &&
          other.gst == this.gst);
}

class OrderItemsCompanion extends UpdateCompanion<OrderItemEntity> {
  final Value<int> autoId;
  final Value<String> orderId;
  final Value<String> itemId;
  final Value<String> itemName;
  final Value<String> category;
  final Value<int> quantity;
  final Value<double> salePrice;
  final Value<double> gst;
  const OrderItemsCompanion({
    this.autoId = const Value.absent(),
    this.orderId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.category = const Value.absent(),
    this.quantity = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.gst = const Value.absent(),
  });
  OrderItemsCompanion.insert({
    this.autoId = const Value.absent(),
    required String orderId,
    required String itemId,
    required String itemName,
    required String category,
    required int quantity,
    required double salePrice,
    required double gst,
  }) : orderId = Value(orderId),
       itemId = Value(itemId),
       itemName = Value(itemName),
       category = Value(category),
       quantity = Value(quantity),
       salePrice = Value(salePrice),
       gst = Value(gst);
  static Insertable<OrderItemEntity> custom({
    Expression<int>? autoId,
    Expression<String>? orderId,
    Expression<String>? itemId,
    Expression<String>? itemName,
    Expression<String>? category,
    Expression<int>? quantity,
    Expression<double>? salePrice,
    Expression<double>? gst,
  }) {
    return RawValuesInsertable({
      if (autoId != null) 'auto_id': autoId,
      if (orderId != null) 'order_id': orderId,
      if (itemId != null) 'item_id': itemId,
      if (itemName != null) 'item_name': itemName,
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (salePrice != null) 'sale_price': salePrice,
      if (gst != null) 'gst': gst,
    });
  }

  OrderItemsCompanion copyWith({
    Value<int>? autoId,
    Value<String>? orderId,
    Value<String>? itemId,
    Value<String>? itemName,
    Value<String>? category,
    Value<int>? quantity,
    Value<double>? salePrice,
    Value<double>? gst,
  }) {
    return OrderItemsCompanion(
      autoId: autoId ?? this.autoId,
      orderId: orderId ?? this.orderId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice ?? this.salePrice,
      gst: gst ?? this.gst,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (autoId.present) {
      map['auto_id'] = Variable<int>(autoId.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (salePrice.present) {
      map['sale_price'] = Variable<double>(salePrice.value);
    }
    if (gst.present) {
      map['gst'] = Variable<double>(gst.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemsCompanion(')
          ..write('autoId: $autoId, ')
          ..write('orderId: $orderId, ')
          ..write('itemId: $itemId, ')
          ..write('itemName: $itemName, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('salePrice: $salePrice, ')
          ..write('gst: $gst')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outletIdMeta = const VerificationMeta(
    'outletId',
  );
  @override
  late final GeneratedColumn<String> outletId = GeneratedColumn<String>(
    'outlet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salePriceMeta = const VerificationMeta(
    'salePrice',
  );
  @override
  late final GeneratedColumn<double> salePrice = GeneratedColumn<double>(
    'sale_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _withTaxMeta = const VerificationMeta(
    'withTax',
  );
  @override
  late final GeneratedColumn<bool> withTax = GeneratedColumn<bool>(
    'with_tax',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("with_tax" IN (0, 1))',
    ),
  );
  static const VerificationMeta _gstMeta = const VerificationMeta('gst');
  @override
  late final GeneratedColumn<int> gst = GeneratedColumn<int>(
    'gst',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemImageMeta = const VerificationMeta(
    'itemImage',
  );
  @override
  late final GeneratedColumn<String> itemImage = GeneratedColumn<String>(
    'item_image',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _orderFromMeta = const VerificationMeta(
    'orderFrom',
  );
  @override
  late final GeneratedColumn<String> orderFrom = GeneratedColumn<String>(
    'order_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variantsJsonMeta = const VerificationMeta(
    'variantsJson',
  );
  @override
  late final GeneratedColumn<String> variantsJson = GeneratedColumn<String>(
    'variants_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _showItemMeta = const VerificationMeta(
    'showItem',
  );
  @override
  late final GeneratedColumn<bool> showItem = GeneratedColumn<bool>(
    'show_item',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_item" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncMeta = const VerificationMeta('isSync');
  @override
  late final GeneratedColumn<String> isSync = GeneratedColumn<String>(
    'is_sync',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _itemJsonMeta = const VerificationMeta(
    'itemJson',
  );
  @override
  late final GeneratedColumn<String> itemJson = GeneratedColumn<String>(
    'item_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    outletId,
    itemName,
    salePrice,
    withTax,
    gst,
    category,
    createdAt,
    updatedAt,
    itemImage,
    orderFrom,
    variantsJson,
    barcode,
    sku,
    showItem,
    isDeleted,
    isSync,
    itemJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('outlet_id')) {
      context.handle(
        _outletIdMeta,
        outletId.isAcceptableOrUnknown(data['outlet_id']!, _outletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outletIdMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('sale_price')) {
      context.handle(
        _salePriceMeta,
        salePrice.isAcceptableOrUnknown(data['sale_price']!, _salePriceMeta),
      );
    } else if (isInserting) {
      context.missing(_salePriceMeta);
    }
    if (data.containsKey('with_tax')) {
      context.handle(
        _withTaxMeta,
        withTax.isAcceptableOrUnknown(data['with_tax']!, _withTaxMeta),
      );
    } else if (isInserting) {
      context.missing(_withTaxMeta);
    }
    if (data.containsKey('gst')) {
      context.handle(
        _gstMeta,
        gst.isAcceptableOrUnknown(data['gst']!, _gstMeta),
      );
    } else if (isInserting) {
      context.missing(_gstMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('item_image')) {
      context.handle(
        _itemImageMeta,
        itemImage.isAcceptableOrUnknown(data['item_image']!, _itemImageMeta),
      );
    }
    if (data.containsKey('order_from')) {
      context.handle(
        _orderFromMeta,
        orderFrom.isAcceptableOrUnknown(data['order_from']!, _orderFromMeta),
      );
    }
    if (data.containsKey('variants_json')) {
      context.handle(
        _variantsJsonMeta,
        variantsJson.isAcceptableOrUnknown(
          data['variants_json']!,
          _variantsJsonMeta,
        ),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('show_item')) {
      context.handle(
        _showItemMeta,
        showItem.isAcceptableOrUnknown(data['show_item']!, _showItemMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('is_sync')) {
      context.handle(
        _isSyncMeta,
        isSync.isAcceptableOrUnknown(data['is_sync']!, _isSyncMeta),
      );
    }
    if (data.containsKey('item_json')) {
      context.handle(
        _itemJsonMeta,
        itemJson.isAcceptableOrUnknown(data['item_json']!, _itemJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      outletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outlet_id'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      salePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sale_price'],
      )!,
      withTax: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}with_tax'],
      )!,
      gst: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gst'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      itemImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_image'],
      )!,
      orderFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_from'],
      ),
      variantsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variants_json'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      showItem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_item'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      isSync: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}is_sync'],
      )!,
      itemJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_json'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final String id;
  final String userId;
  final String outletId;
  final String itemName;
  final double salePrice;
  final bool withTax;
  final int gst;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String itemImage;
  final String? orderFrom;
  final String variantsJson;
  final String barcode;
  final String sku;
  final bool showItem;
  final bool isDeleted;
  final String isSync;
  final String? itemJson;
  const Item({
    required this.id,
    required this.userId,
    required this.outletId,
    required this.itemName,
    required this.salePrice,
    required this.withTax,
    required this.gst,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.itemImage,
    this.orderFrom,
    required this.variantsJson,
    required this.barcode,
    required this.sku,
    required this.showItem,
    required this.isDeleted,
    required this.isSync,
    this.itemJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['outlet_id'] = Variable<String>(outletId);
    map['item_name'] = Variable<String>(itemName);
    map['sale_price'] = Variable<double>(salePrice);
    map['with_tax'] = Variable<bool>(withTax);
    map['gst'] = Variable<int>(gst);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['item_image'] = Variable<String>(itemImage);
    if (!nullToAbsent || orderFrom != null) {
      map['order_from'] = Variable<String>(orderFrom);
    }
    map['variants_json'] = Variable<String>(variantsJson);
    map['barcode'] = Variable<String>(barcode);
    map['sku'] = Variable<String>(sku);
    map['show_item'] = Variable<bool>(showItem);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_sync'] = Variable<String>(isSync);
    if (!nullToAbsent || itemJson != null) {
      map['item_json'] = Variable<String>(itemJson);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      userId: Value(userId),
      outletId: Value(outletId),
      itemName: Value(itemName),
      salePrice: Value(salePrice),
      withTax: Value(withTax),
      gst: Value(gst),
      category: Value(category),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      itemImage: Value(itemImage),
      orderFrom: orderFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(orderFrom),
      variantsJson: Value(variantsJson),
      barcode: Value(barcode),
      sku: Value(sku),
      showItem: Value(showItem),
      isDeleted: Value(isDeleted),
      isSync: Value(isSync),
      itemJson: itemJson == null && nullToAbsent
          ? const Value.absent()
          : Value(itemJson),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      outletId: serializer.fromJson<String>(json['outletId']),
      itemName: serializer.fromJson<String>(json['itemName']),
      salePrice: serializer.fromJson<double>(json['salePrice']),
      withTax: serializer.fromJson<bool>(json['withTax']),
      gst: serializer.fromJson<int>(json['gst']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      itemImage: serializer.fromJson<String>(json['itemImage']),
      orderFrom: serializer.fromJson<String?>(json['orderFrom']),
      variantsJson: serializer.fromJson<String>(json['variantsJson']),
      barcode: serializer.fromJson<String>(json['barcode']),
      sku: serializer.fromJson<String>(json['sku']),
      showItem: serializer.fromJson<bool>(json['showItem']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isSync: serializer.fromJson<String>(json['isSync']),
      itemJson: serializer.fromJson<String?>(json['itemJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'outletId': serializer.toJson<String>(outletId),
      'itemName': serializer.toJson<String>(itemName),
      'salePrice': serializer.toJson<double>(salePrice),
      'withTax': serializer.toJson<bool>(withTax),
      'gst': serializer.toJson<int>(gst),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'itemImage': serializer.toJson<String>(itemImage),
      'orderFrom': serializer.toJson<String?>(orderFrom),
      'variantsJson': serializer.toJson<String>(variantsJson),
      'barcode': serializer.toJson<String>(barcode),
      'sku': serializer.toJson<String>(sku),
      'showItem': serializer.toJson<bool>(showItem),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isSync': serializer.toJson<String>(isSync),
      'itemJson': serializer.toJson<String?>(itemJson),
    };
  }

  Item copyWith({
    String? id,
    String? userId,
    String? outletId,
    String? itemName,
    double? salePrice,
    bool? withTax,
    int? gst,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? itemImage,
    Value<String?> orderFrom = const Value.absent(),
    String? variantsJson,
    String? barcode,
    String? sku,
    bool? showItem,
    bool? isDeleted,
    String? isSync,
    Value<String?> itemJson = const Value.absent(),
  }) => Item(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    outletId: outletId ?? this.outletId,
    itemName: itemName ?? this.itemName,
    salePrice: salePrice ?? this.salePrice,
    withTax: withTax ?? this.withTax,
    gst: gst ?? this.gst,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    itemImage: itemImage ?? this.itemImage,
    orderFrom: orderFrom.present ? orderFrom.value : this.orderFrom,
    variantsJson: variantsJson ?? this.variantsJson,
    barcode: barcode ?? this.barcode,
    sku: sku ?? this.sku,
    showItem: showItem ?? this.showItem,
    isDeleted: isDeleted ?? this.isDeleted,
    isSync: isSync ?? this.isSync,
    itemJson: itemJson.present ? itemJson.value : this.itemJson,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      outletId: data.outletId.present ? data.outletId.value : this.outletId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      salePrice: data.salePrice.present ? data.salePrice.value : this.salePrice,
      withTax: data.withTax.present ? data.withTax.value : this.withTax,
      gst: data.gst.present ? data.gst.value : this.gst,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      itemImage: data.itemImage.present ? data.itemImage.value : this.itemImage,
      orderFrom: data.orderFrom.present ? data.orderFrom.value : this.orderFrom,
      variantsJson: data.variantsJson.present
          ? data.variantsJson.value
          : this.variantsJson,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      sku: data.sku.present ? data.sku.value : this.sku,
      showItem: data.showItem.present ? data.showItem.value : this.showItem,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isSync: data.isSync.present ? data.isSync.value : this.isSync,
      itemJson: data.itemJson.present ? data.itemJson.value : this.itemJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('outletId: $outletId, ')
          ..write('itemName: $itemName, ')
          ..write('salePrice: $salePrice, ')
          ..write('withTax: $withTax, ')
          ..write('gst: $gst, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('itemImage: $itemImage, ')
          ..write('orderFrom: $orderFrom, ')
          ..write('variantsJson: $variantsJson, ')
          ..write('barcode: $barcode, ')
          ..write('sku: $sku, ')
          ..write('showItem: $showItem, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSync: $isSync, ')
          ..write('itemJson: $itemJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    outletId,
    itemName,
    salePrice,
    withTax,
    gst,
    category,
    createdAt,
    updatedAt,
    itemImage,
    orderFrom,
    variantsJson,
    barcode,
    sku,
    showItem,
    isDeleted,
    isSync,
    itemJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.outletId == this.outletId &&
          other.itemName == this.itemName &&
          other.salePrice == this.salePrice &&
          other.withTax == this.withTax &&
          other.gst == this.gst &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.itemImage == this.itemImage &&
          other.orderFrom == this.orderFrom &&
          other.variantsJson == this.variantsJson &&
          other.barcode == this.barcode &&
          other.sku == this.sku &&
          other.showItem == this.showItem &&
          other.isDeleted == this.isDeleted &&
          other.isSync == this.isSync &&
          other.itemJson == this.itemJson);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> outletId;
  final Value<String> itemName;
  final Value<double> salePrice;
  final Value<bool> withTax;
  final Value<int> gst;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> itemImage;
  final Value<String?> orderFrom;
  final Value<String> variantsJson;
  final Value<String> barcode;
  final Value<String> sku;
  final Value<bool> showItem;
  final Value<bool> isDeleted;
  final Value<String> isSync;
  final Value<String?> itemJson;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.outletId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.withTax = const Value.absent(),
    this.gst = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.itemImage = const Value.absent(),
    this.orderFrom = const Value.absent(),
    this.variantsJson = const Value.absent(),
    this.barcode = const Value.absent(),
    this.sku = const Value.absent(),
    this.showItem = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSync = const Value.absent(),
    this.itemJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String userId,
    required String outletId,
    required String itemName,
    required double salePrice,
    required bool withTax,
    required int gst,
    required String category,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.itemImage = const Value.absent(),
    this.orderFrom = const Value.absent(),
    this.variantsJson = const Value.absent(),
    this.barcode = const Value.absent(),
    this.sku = const Value.absent(),
    this.showItem = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSync = const Value.absent(),
    this.itemJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       outletId = Value(outletId),
       itemName = Value(itemName),
       salePrice = Value(salePrice),
       withTax = Value(withTax),
       gst = Value(gst),
       category = Value(category),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Item> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? outletId,
    Expression<String>? itemName,
    Expression<double>? salePrice,
    Expression<bool>? withTax,
    Expression<int>? gst,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? itemImage,
    Expression<String>? orderFrom,
    Expression<String>? variantsJson,
    Expression<String>? barcode,
    Expression<String>? sku,
    Expression<bool>? showItem,
    Expression<bool>? isDeleted,
    Expression<String>? isSync,
    Expression<String>? itemJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (outletId != null) 'outlet_id': outletId,
      if (itemName != null) 'item_name': itemName,
      if (salePrice != null) 'sale_price': salePrice,
      if (withTax != null) 'with_tax': withTax,
      if (gst != null) 'gst': gst,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (itemImage != null) 'item_image': itemImage,
      if (orderFrom != null) 'order_from': orderFrom,
      if (variantsJson != null) 'variants_json': variantsJson,
      if (barcode != null) 'barcode': barcode,
      if (sku != null) 'sku': sku,
      if (showItem != null) 'show_item': showItem,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isSync != null) 'is_sync': isSync,
      if (itemJson != null) 'item_json': itemJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? outletId,
    Value<String>? itemName,
    Value<double>? salePrice,
    Value<bool>? withTax,
    Value<int>? gst,
    Value<String>? category,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? itemImage,
    Value<String?>? orderFrom,
    Value<String>? variantsJson,
    Value<String>? barcode,
    Value<String>? sku,
    Value<bool>? showItem,
    Value<bool>? isDeleted,
    Value<String>? isSync,
    Value<String?>? itemJson,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      outletId: outletId ?? this.outletId,
      itemName: itemName ?? this.itemName,
      salePrice: salePrice ?? this.salePrice,
      withTax: withTax ?? this.withTax,
      gst: gst ?? this.gst,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemImage: itemImage ?? this.itemImage,
      orderFrom: orderFrom ?? this.orderFrom,
      variantsJson: variantsJson ?? this.variantsJson,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      showItem: showItem ?? this.showItem,
      isDeleted: isDeleted ?? this.isDeleted,
      isSync: isSync ?? this.isSync,
      itemJson: itemJson ?? this.itemJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (outletId.present) {
      map['outlet_id'] = Variable<String>(outletId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (salePrice.present) {
      map['sale_price'] = Variable<double>(salePrice.value);
    }
    if (withTax.present) {
      map['with_tax'] = Variable<bool>(withTax.value);
    }
    if (gst.present) {
      map['gst'] = Variable<int>(gst.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (itemImage.present) {
      map['item_image'] = Variable<String>(itemImage.value);
    }
    if (orderFrom.present) {
      map['order_from'] = Variable<String>(orderFrom.value);
    }
    if (variantsJson.present) {
      map['variants_json'] = Variable<String>(variantsJson.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (showItem.present) {
      map['show_item'] = Variable<bool>(showItem.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isSync.present) {
      map['is_sync'] = Variable<String>(isSync.value);
    }
    if (itemJson.present) {
      map['item_json'] = Variable<String>(itemJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('outletId: $outletId, ')
          ..write('itemName: $itemName, ')
          ..write('salePrice: $salePrice, ')
          ..write('withTax: $withTax, ')
          ..write('gst: $gst, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('itemImage: $itemImage, ')
          ..write('orderFrom: $orderFrom, ')
          ..write('variantsJson: $variantsJson, ')
          ..write('barcode: $barcode, ')
          ..write('sku: $sku, ')
          ..write('showItem: $showItem, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSync: $isSync, ')
          ..write('itemJson: $itemJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTableTable extends CategoriesTable
    with TableInfo<$CategoriesTableTable, CategoriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outletIdMeta = const VerificationMeta(
    'outletId',
  );
  @override
  late final GeneratedColumn<String> outletId = GeneratedColumn<String>(
    'outlet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageURLMeta = const VerificationMeta(
    'imageURL',
  );
  @override
  late final GeneratedColumn<String> imageURL = GeneratedColumn<String>(
    'image_u_r_l',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    outletId,
    categoryName,
    imageURL,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('outlet_id')) {
      context.handle(
        _outletIdMeta,
        outletId.isAcceptableOrUnknown(data['outlet_id']!, _outletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outletIdMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('image_u_r_l')) {
      context.handle(
        _imageURLMeta,
        imageURL.isAcceptableOrUnknown(data['image_u_r_l']!, _imageURLMeta),
      );
    } else if (isInserting) {
      context.missing(_imageURLMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      outletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outlet_id'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      imageURL: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_u_r_l'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTableTable createAlias(String alias) {
    return $CategoriesTableTable(attachedDatabase, alias);
  }
}

class CategoriesTableData extends DataClass
    implements Insertable<CategoriesTableData> {
  /// 🔹 UUID from API
  final String id;

  /// 🔹 User who created the category
  final String userId;
  final String outletId;

  /// 🔹 Category name
  final String categoryName;
  final String imageURL;

  /// 🔹 Timestamps (stored as ISO string)
  final DateTime createdAt;
  final DateTime updatedAt;
  const CategoriesTableData({
    required this.id,
    required this.userId,
    required this.outletId,
    required this.categoryName,
    required this.imageURL,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['outlet_id'] = Variable<String>(outletId);
    map['category_name'] = Variable<String>(categoryName);
    map['image_u_r_l'] = Variable<String>(imageURL);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoriesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      outletId: Value(outletId),
      categoryName: Value(categoryName),
      imageURL: Value(imageURL),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      outletId: serializer.fromJson<String>(json['outletId']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      imageURL: serializer.fromJson<String>(json['imageURL']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'outletId': serializer.toJson<String>(outletId),
      'categoryName': serializer.toJson<String>(categoryName),
      'imageURL': serializer.toJson<String>(imageURL),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoriesTableData copyWith({
    String? id,
    String? userId,
    String? outletId,
    String? categoryName,
    String? imageURL,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CategoriesTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    outletId: outletId ?? this.outletId,
    categoryName: categoryName ?? this.categoryName,
    imageURL: imageURL ?? this.imageURL,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoriesTableData copyWithCompanion(CategoriesTableCompanion data) {
    return CategoriesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      outletId: data.outletId.present ? data.outletId.value : this.outletId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      imageURL: data.imageURL.present ? data.imageURL.value : this.imageURL,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('outletId: $outletId, ')
          ..write('categoryName: $categoryName, ')
          ..write('imageURL: $imageURL, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    outletId,
    categoryName,
    imageURL,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.outletId == this.outletId &&
          other.categoryName == this.categoryName &&
          other.imageURL == this.imageURL &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesTableCompanion extends UpdateCompanion<CategoriesTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> outletId;
  final Value<String> categoryName;
  final Value<String> imageURL;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CategoriesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.outletId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.imageURL = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesTableCompanion.insert({
    required String id,
    required String userId,
    required String outletId,
    required String categoryName,
    required String imageURL,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       outletId = Value(outletId),
       categoryName = Value(categoryName),
       imageURL = Value(imageURL),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoriesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? outletId,
    Expression<String>? categoryName,
    Expression<String>? imageURL,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (outletId != null) 'outlet_id': outletId,
      if (categoryName != null) 'category_name': categoryName,
      if (imageURL != null) 'image_u_r_l': imageURL,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? outletId,
    Value<String>? categoryName,
    Value<String>? imageURL,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      outletId: outletId ?? this.outletId,
      categoryName: categoryName ?? this.categoryName,
      imageURL: imageURL ?? this.imageURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (outletId.present) {
      map['outlet_id'] = Variable<String>(outletId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (imageURL.present) {
      map['image_u_r_l'] = Variable<String>(imageURL.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('outletId: $outletId, ')
          ..write('categoryName: $categoryName, ')
          ..write('imageURL: $imageURL, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromotionRulesTableTable extends PromotionRulesTable
    with TableInfo<$PromotionRulesTableTable, PromotionRulesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromotionRulesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outletIdMeta = const VerificationMeta(
    'outletId',
  );
  @override
  late final GeneratedColumn<String> outletId = GeneratedColumn<String>(
    'outlet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _ruleJsonMeta = const VerificationMeta(
    'ruleJson',
  );
  @override
  late final GeneratedColumn<String> ruleJson = GeneratedColumn<String>(
    'rule_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    outletId,
    name,
    type,
    active,
    ruleJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'promotion_rules_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PromotionRulesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('outlet_id')) {
      context.handle(
        _outletIdMeta,
        outletId.isAcceptableOrUnknown(data['outlet_id']!, _outletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outletIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('rule_json')) {
      context.handle(
        _ruleJsonMeta,
        ruleJson.isAcceptableOrUnknown(data['rule_json']!, _ruleJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PromotionRulesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromotionRulesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      outletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outlet_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      ruleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PromotionRulesTableTable createAlias(String alias) {
    return $PromotionRulesTableTable(attachedDatabase, alias);
  }
}

class PromotionRulesTableData extends DataClass
    implements Insertable<PromotionRulesTableData> {
  final String id;
  final String userId;
  final String outletId;
  final String name;
  final String type;
  final bool active;
  final String ruleJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PromotionRulesTableData({
    required this.id,
    required this.userId,
    required this.outletId,
    required this.name,
    required this.type,
    required this.active,
    required this.ruleJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['outlet_id'] = Variable<String>(outletId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['active'] = Variable<bool>(active);
    map['rule_json'] = Variable<String>(ruleJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PromotionRulesTableCompanion toCompanion(bool nullToAbsent) {
    return PromotionRulesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      outletId: Value(outletId),
      name: Value(name),
      type: Value(type),
      active: Value(active),
      ruleJson: Value(ruleJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PromotionRulesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromotionRulesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      outletId: serializer.fromJson<String>(json['outletId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      active: serializer.fromJson<bool>(json['active']),
      ruleJson: serializer.fromJson<String>(json['ruleJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'outletId': serializer.toJson<String>(outletId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'active': serializer.toJson<bool>(active),
      'ruleJson': serializer.toJson<String>(ruleJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PromotionRulesTableData copyWith({
    String? id,
    String? userId,
    String? outletId,
    String? name,
    String? type,
    bool? active,
    String? ruleJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PromotionRulesTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    outletId: outletId ?? this.outletId,
    name: name ?? this.name,
    type: type ?? this.type,
    active: active ?? this.active,
    ruleJson: ruleJson ?? this.ruleJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PromotionRulesTableData copyWithCompanion(PromotionRulesTableCompanion data) {
    return PromotionRulesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      outletId: data.outletId.present ? data.outletId.value : this.outletId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      active: data.active.present ? data.active.value : this.active,
      ruleJson: data.ruleJson.present ? data.ruleJson.value : this.ruleJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromotionRulesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('outletId: $outletId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('active: $active, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    outletId,
    name,
    type,
    active,
    ruleJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromotionRulesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.outletId == this.outletId &&
          other.name == this.name &&
          other.type == this.type &&
          other.active == this.active &&
          other.ruleJson == this.ruleJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PromotionRulesTableCompanion
    extends UpdateCompanion<PromotionRulesTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> outletId;
  final Value<String> name;
  final Value<String> type;
  final Value<bool> active;
  final Value<String> ruleJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PromotionRulesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.outletId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.active = const Value.absent(),
    this.ruleJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromotionRulesTableCompanion.insert({
    required String id,
    required String userId,
    required String outletId,
    required String name,
    required String type,
    required bool active,
    required String ruleJson,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       outletId = Value(outletId),
       name = Value(name),
       type = Value(type),
       active = Value(active),
       ruleJson = Value(ruleJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PromotionRulesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? outletId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<bool>? active,
    Expression<String>? ruleJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (outletId != null) 'outlet_id': outletId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (active != null) 'active': active,
      if (ruleJson != null) 'rule_json': ruleJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromotionRulesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? outletId,
    Value<String>? name,
    Value<String>? type,
    Value<bool>? active,
    Value<String>? ruleJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PromotionRulesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      outletId: outletId ?? this.outletId,
      name: name ?? this.name,
      type: type ?? this.type,
      active: active ?? this.active,
      ruleJson: ruleJson ?? this.ruleJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (outletId.present) {
      map['outlet_id'] = Variable<String>(outletId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (ruleJson.present) {
      map['rule_json'] = Variable<String>(ruleJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromotionRulesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('outletId: $outletId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('active: $active, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderItemsTable orderItems = $OrderItemsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $CategoriesTableTable categoriesTable = $CategoriesTableTable(
    this,
  );
  late final $PromotionRulesTableTable promotionRulesTable =
      $PromotionRulesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    orders,
    orderItems,
    items,
    categoriesTable,
    promotionRulesTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'orders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('order_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$OrdersTableCreateCompanionBuilder =
    OrdersCompanion Function({
      required String id,
      required String createdAt,
      required String updatedAt,
      required String billNumber,
      required String userId,
      required String outletId,
      Value<String?> tableNumber,
      Value<String?> customerName,
      Value<String?> phoneNumber,
      required double subtotal,
      required double totalTax,
      required double discount,
      required double serviceCharge,
      required double totalAmount,
      Value<String?> paymentReceivedIn,
      Value<String?> splitPayments,
      required String status,
      required String orderFrom,
      required String isSync,
      Value<String?> orderJson,
      Value<int> rowid,
    });
typedef $$OrdersTableUpdateCompanionBuilder =
    OrdersCompanion Function({
      Value<String> id,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String> billNumber,
      Value<String> userId,
      Value<String> outletId,
      Value<String?> tableNumber,
      Value<String?> customerName,
      Value<String?> phoneNumber,
      Value<double> subtotal,
      Value<double> totalTax,
      Value<double> discount,
      Value<double> serviceCharge,
      Value<double> totalAmount,
      Value<String?> paymentReceivedIn,
      Value<String?> splitPayments,
      Value<String> status,
      Value<String> orderFrom,
      Value<String> isSync,
      Value<String?> orderJson,
      Value<int> rowid,
    });

final class $$OrdersTableReferences
    extends BaseReferences<_$AppDatabase, $OrdersTable, Order> {
  $$OrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrderItemsTable, List<OrderItemEntity>>
  _orderItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.orderItems,
    aliasName: $_aliasNameGenerator(db.orders.id, db.orderItems.orderId),
  );

  $$OrderItemsTableProcessedTableManager get orderItemsRefs {
    final manager = $$OrderItemsTableTableManager(
      $_db,
      $_db.orderItems,
    ).filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billNumber => $composableBuilder(
    column: $table.billNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalTax => $composableBuilder(
    column: $table.totalTax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get serviceCharge => $composableBuilder(
    column: $table.serviceCharge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentReceivedIn => $composableBuilder(
    column: $table.paymentReceivedIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitPayments => $composableBuilder(
    column: $table.splitPayments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderFrom => $composableBuilder(
    column: $table.orderFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isSync => $composableBuilder(
    column: $table.isSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderJson => $composableBuilder(
    column: $table.orderJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> orderItemsRefs(
    Expression<bool> Function($$OrderItemsTableFilterComposer f) f,
  ) {
    final $$OrderItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderItems,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderItemsTableFilterComposer(
            $db: $db,
            $table: $db.orderItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billNumber => $composableBuilder(
    column: $table.billNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalTax => $composableBuilder(
    column: $table.totalTax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get serviceCharge => $composableBuilder(
    column: $table.serviceCharge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentReceivedIn => $composableBuilder(
    column: $table.paymentReceivedIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitPayments => $composableBuilder(
    column: $table.splitPayments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderFrom => $composableBuilder(
    column: $table.orderFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isSync => $composableBuilder(
    column: $table.isSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderJson => $composableBuilder(
    column: $table.orderJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get billNumber => $composableBuilder(
    column: $table.billNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get outletId =>
      $composableBuilder(column: $table.outletId, builder: (column) => column);

  GeneratedColumn<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get totalTax =>
      $composableBuilder(column: $table.totalTax, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<double> get serviceCharge => $composableBuilder(
    column: $table.serviceCharge,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentReceivedIn => $composableBuilder(
    column: $table.paymentReceivedIn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get splitPayments => $composableBuilder(
    column: $table.splitPayments,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get orderFrom =>
      $composableBuilder(column: $table.orderFrom, builder: (column) => column);

  GeneratedColumn<String> get isSync =>
      $composableBuilder(column: $table.isSync, builder: (column) => column);

  GeneratedColumn<String> get orderJson =>
      $composableBuilder(column: $table.orderJson, builder: (column) => column);

  Expression<T> orderItemsRefs<T extends Object>(
    Expression<T> Function($$OrderItemsTableAnnotationComposer a) f,
  ) {
    final $$OrderItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderItems,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.orderItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTable,
          Order,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (Order, $$OrdersTableReferences),
          Order,
          PrefetchHooks Function({bool orderItemsRefs})
        > {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> billNumber = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> outletId = const Value.absent(),
                Value<String?> tableNumber = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> totalTax = const Value.absent(),
                Value<double> discount = const Value.absent(),
                Value<double> serviceCharge = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> paymentReceivedIn = const Value.absent(),
                Value<String?> splitPayments = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> orderFrom = const Value.absent(),
                Value<String> isSync = const Value.absent(),
                Value<String?> orderJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                billNumber: billNumber,
                userId: userId,
                outletId: outletId,
                tableNumber: tableNumber,
                customerName: customerName,
                phoneNumber: phoneNumber,
                subtotal: subtotal,
                totalTax: totalTax,
                discount: discount,
                serviceCharge: serviceCharge,
                totalAmount: totalAmount,
                paymentReceivedIn: paymentReceivedIn,
                splitPayments: splitPayments,
                status: status,
                orderFrom: orderFrom,
                isSync: isSync,
                orderJson: orderJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String billNumber,
                required String userId,
                required String outletId,
                Value<String?> tableNumber = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                required double subtotal,
                required double totalTax,
                required double discount,
                required double serviceCharge,
                required double totalAmount,
                Value<String?> paymentReceivedIn = const Value.absent(),
                Value<String?> splitPayments = const Value.absent(),
                required String status,
                required String orderFrom,
                required String isSync,
                Value<String?> orderJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                billNumber: billNumber,
                userId: userId,
                outletId: outletId,
                tableNumber: tableNumber,
                customerName: customerName,
                phoneNumber: phoneNumber,
                subtotal: subtotal,
                totalTax: totalTax,
                discount: discount,
                serviceCharge: serviceCharge,
                totalAmount: totalAmount,
                paymentReceivedIn: paymentReceivedIn,
                splitPayments: splitPayments,
                status: status,
                orderFrom: orderFrom,
                isSync: isSync,
                orderJson: orderJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$OrdersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({orderItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (orderItemsRefs) db.orderItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (orderItemsRefs)
                    await $_getPrefetchedData<
                      Order,
                      $OrdersTable,
                      OrderItemEntity
                    >(
                      currentTable: table,
                      referencedTable: $$OrdersTableReferences
                          ._orderItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$OrdersTableReferences(db, table, p0).orderItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.orderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTable,
      Order,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (Order, $$OrdersTableReferences),
      Order,
      PrefetchHooks Function({bool orderItemsRefs})
    >;
typedef $$OrderItemsTableCreateCompanionBuilder =
    OrderItemsCompanion Function({
      Value<int> autoId,
      required String orderId,
      required String itemId,
      required String itemName,
      required String category,
      required int quantity,
      required double salePrice,
      required double gst,
    });
typedef $$OrderItemsTableUpdateCompanionBuilder =
    OrderItemsCompanion Function({
      Value<int> autoId,
      Value<String> orderId,
      Value<String> itemId,
      Value<String> itemName,
      Value<String> category,
      Value<int> quantity,
      Value<double> salePrice,
      Value<double> gst,
    });

final class $$OrderItemsTableReferences
    extends BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItemEntity> {
  $$OrderItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders.createAlias(
    $_aliasNameGenerator(db.orderItems.orderId, db.orders.id),
  );

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<String>('order_id')!;

    final manager = $$OrdersTableTableManager(
      $_db,
      $_db.orders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OrderItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get autoId => $composableBuilder(
    column: $table.autoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salePrice => $composableBuilder(
    column: $table.salePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gst => $composableBuilder(
    column: $table.gst,
    builder: (column) => ColumnFilters(column),
  );

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableFilterComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get autoId => $composableBuilder(
    column: $table.autoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salePrice => $composableBuilder(
    column: $table.salePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gst => $composableBuilder(
    column: $table.gst,
    builder: (column) => ColumnOrderings(column),
  );

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableOrderingComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get autoId =>
      $composableBuilder(column: $table.autoId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get salePrice =>
      $composableBuilder(column: $table.salePrice, builder: (column) => column);

  GeneratedColumn<double> get gst =>
      $composableBuilder(column: $table.gst, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderItemsTable,
          OrderItemEntity,
          $$OrderItemsTableFilterComposer,
          $$OrderItemsTableOrderingComposer,
          $$OrderItemsTableAnnotationComposer,
          $$OrderItemsTableCreateCompanionBuilder,
          $$OrderItemsTableUpdateCompanionBuilder,
          (OrderItemEntity, $$OrderItemsTableReferences),
          OrderItemEntity,
          PrefetchHooks Function({bool orderId})
        > {
  $$OrderItemsTableTableManager(_$AppDatabase db, $OrderItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> autoId = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> salePrice = const Value.absent(),
                Value<double> gst = const Value.absent(),
              }) => OrderItemsCompanion(
                autoId: autoId,
                orderId: orderId,
                itemId: itemId,
                itemName: itemName,
                category: category,
                quantity: quantity,
                salePrice: salePrice,
                gst: gst,
              ),
          createCompanionCallback:
              ({
                Value<int> autoId = const Value.absent(),
                required String orderId,
                required String itemId,
                required String itemName,
                required String category,
                required int quantity,
                required double salePrice,
                required double gst,
              }) => OrderItemsCompanion.insert(
                autoId: autoId,
                orderId: orderId,
                itemId: itemId,
                itemName: itemName,
                category: category,
                quantity: quantity,
                salePrice: salePrice,
                gst: gst,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OrderItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({orderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (orderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.orderId,
                                referencedTable: $$OrderItemsTableReferences
                                    ._orderIdTable(db),
                                referencedColumn: $$OrderItemsTableReferences
                                    ._orderIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OrderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderItemsTable,
      OrderItemEntity,
      $$OrderItemsTableFilterComposer,
      $$OrderItemsTableOrderingComposer,
      $$OrderItemsTableAnnotationComposer,
      $$OrderItemsTableCreateCompanionBuilder,
      $$OrderItemsTableUpdateCompanionBuilder,
      (OrderItemEntity, $$OrderItemsTableReferences),
      OrderItemEntity,
      PrefetchHooks Function({bool orderId})
    >;
typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      required String id,
      required String userId,
      required String outletId,
      required String itemName,
      required double salePrice,
      required bool withTax,
      required int gst,
      required String category,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String> itemImage,
      Value<String?> orderFrom,
      Value<String> variantsJson,
      Value<String> barcode,
      Value<String> sku,
      Value<bool> showItem,
      Value<bool> isDeleted,
      Value<String> isSync,
      Value<String?> itemJson,
      Value<int> rowid,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> outletId,
      Value<String> itemName,
      Value<double> salePrice,
      Value<bool> withTax,
      Value<int> gst,
      Value<String> category,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> itemImage,
      Value<String?> orderFrom,
      Value<String> variantsJson,
      Value<String> barcode,
      Value<String> sku,
      Value<bool> showItem,
      Value<bool> isDeleted,
      Value<String> isSync,
      Value<String?> itemJson,
      Value<int> rowid,
    });

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salePrice => $composableBuilder(
    column: $table.salePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get withTax => $composableBuilder(
    column: $table.withTax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gst => $composableBuilder(
    column: $table.gst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemImage => $composableBuilder(
    column: $table.itemImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderFrom => $composableBuilder(
    column: $table.orderFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantsJson => $composableBuilder(
    column: $table.variantsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showItem => $composableBuilder(
    column: $table.showItem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isSync => $composableBuilder(
    column: $table.isSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemJson => $composableBuilder(
    column: $table.itemJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salePrice => $composableBuilder(
    column: $table.salePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get withTax => $composableBuilder(
    column: $table.withTax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gst => $composableBuilder(
    column: $table.gst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemImage => $composableBuilder(
    column: $table.itemImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderFrom => $composableBuilder(
    column: $table.orderFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantsJson => $composableBuilder(
    column: $table.variantsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showItem => $composableBuilder(
    column: $table.showItem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isSync => $composableBuilder(
    column: $table.isSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemJson => $composableBuilder(
    column: $table.itemJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get outletId =>
      $composableBuilder(column: $table.outletId, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<double> get salePrice =>
      $composableBuilder(column: $table.salePrice, builder: (column) => column);

  GeneratedColumn<bool> get withTax =>
      $composableBuilder(column: $table.withTax, builder: (column) => column);

  GeneratedColumn<int> get gst =>
      $composableBuilder(column: $table.gst, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get itemImage =>
      $composableBuilder(column: $table.itemImage, builder: (column) => column);

  GeneratedColumn<String> get orderFrom =>
      $composableBuilder(column: $table.orderFrom, builder: (column) => column);

  GeneratedColumn<String> get variantsJson => $composableBuilder(
    column: $table.variantsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<bool> get showItem =>
      $composableBuilder(column: $table.showItem, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get isSync =>
      $composableBuilder(column: $table.isSync, builder: (column) => column);

  GeneratedColumn<String> get itemJson =>
      $composableBuilder(column: $table.itemJson, builder: (column) => column);
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
          Item,
          PrefetchHooks Function()
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> outletId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<double> salePrice = const Value.absent(),
                Value<bool> withTax = const Value.absent(),
                Value<int> gst = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> itemImage = const Value.absent(),
                Value<String?> orderFrom = const Value.absent(),
                Value<String> variantsJson = const Value.absent(),
                Value<String> barcode = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<bool> showItem = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> isSync = const Value.absent(),
                Value<String?> itemJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                userId: userId,
                outletId: outletId,
                itemName: itemName,
                salePrice: salePrice,
                withTax: withTax,
                gst: gst,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                itemImage: itemImage,
                orderFrom: orderFrom,
                variantsJson: variantsJson,
                barcode: barcode,
                sku: sku,
                showItem: showItem,
                isDeleted: isDeleted,
                isSync: isSync,
                itemJson: itemJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String outletId,
                required String itemName,
                required double salePrice,
                required bool withTax,
                required int gst,
                required String category,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> itemImage = const Value.absent(),
                Value<String?> orderFrom = const Value.absent(),
                Value<String> variantsJson = const Value.absent(),
                Value<String> barcode = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<bool> showItem = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> isSync = const Value.absent(),
                Value<String?> itemJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                userId: userId,
                outletId: outletId,
                itemName: itemName,
                salePrice: salePrice,
                withTax: withTax,
                gst: gst,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                itemImage: itemImage,
                orderFrom: orderFrom,
                variantsJson: variantsJson,
                barcode: barcode,
                sku: sku,
                showItem: showItem,
                isDeleted: isDeleted,
                isSync: isSync,
                itemJson: itemJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
      Item,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableTableCreateCompanionBuilder =
    CategoriesTableCompanion Function({
      required String id,
      required String userId,
      required String outletId,
      required String categoryName,
      required String imageURL,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableTableUpdateCompanionBuilder =
    CategoriesTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> outletId,
      Value<String> categoryName,
      Value<String> imageURL,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageURL => $composableBuilder(
    column: $table.imageURL,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageURL => $composableBuilder(
    column: $table.imageURL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get outletId =>
      $composableBuilder(column: $table.outletId, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageURL =>
      $composableBuilder(column: $table.imageURL, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTableTable,
          CategoriesTableData,
          $$CategoriesTableTableFilterComposer,
          $$CategoriesTableTableOrderingComposer,
          $$CategoriesTableTableAnnotationComposer,
          $$CategoriesTableTableCreateCompanionBuilder,
          $$CategoriesTableTableUpdateCompanionBuilder,
          (
            CategoriesTableData,
            BaseReferences<
              _$AppDatabase,
              $CategoriesTableTable,
              CategoriesTableData
            >,
          ),
          CategoriesTableData,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableTableManager(
    _$AppDatabase db,
    $CategoriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> outletId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<String> imageURL = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesTableCompanion(
                id: id,
                userId: userId,
                outletId: outletId,
                categoryName: categoryName,
                imageURL: imageURL,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String outletId,
                required String categoryName,
                required String imageURL,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesTableCompanion.insert(
                id: id,
                userId: userId,
                outletId: outletId,
                categoryName: categoryName,
                imageURL: imageURL,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTableTable,
      CategoriesTableData,
      $$CategoriesTableTableFilterComposer,
      $$CategoriesTableTableOrderingComposer,
      $$CategoriesTableTableAnnotationComposer,
      $$CategoriesTableTableCreateCompanionBuilder,
      $$CategoriesTableTableUpdateCompanionBuilder,
      (
        CategoriesTableData,
        BaseReferences<
          _$AppDatabase,
          $CategoriesTableTable,
          CategoriesTableData
        >,
      ),
      CategoriesTableData,
      PrefetchHooks Function()
    >;
typedef $$PromotionRulesTableTableCreateCompanionBuilder =
    PromotionRulesTableCompanion Function({
      required String id,
      required String userId,
      required String outletId,
      required String name,
      required String type,
      required bool active,
      required String ruleJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PromotionRulesTableTableUpdateCompanionBuilder =
    PromotionRulesTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> outletId,
      Value<String> name,
      Value<String> type,
      Value<bool> active,
      Value<String> ruleJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PromotionRulesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PromotionRulesTableTable> {
  $$PromotionRulesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleJson => $composableBuilder(
    column: $table.ruleJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PromotionRulesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PromotionRulesTableTable> {
  $$PromotionRulesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleJson => $composableBuilder(
    column: $table.ruleJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PromotionRulesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromotionRulesTableTable> {
  $$PromotionRulesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get outletId =>
      $composableBuilder(column: $table.outletId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get ruleJson =>
      $composableBuilder(column: $table.ruleJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PromotionRulesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromotionRulesTableTable,
          PromotionRulesTableData,
          $$PromotionRulesTableTableFilterComposer,
          $$PromotionRulesTableTableOrderingComposer,
          $$PromotionRulesTableTableAnnotationComposer,
          $$PromotionRulesTableTableCreateCompanionBuilder,
          $$PromotionRulesTableTableUpdateCompanionBuilder,
          (
            PromotionRulesTableData,
            BaseReferences<
              _$AppDatabase,
              $PromotionRulesTableTable,
              PromotionRulesTableData
            >,
          ),
          PromotionRulesTableData,
          PrefetchHooks Function()
        > {
  $$PromotionRulesTableTableTableManager(
    _$AppDatabase db,
    $PromotionRulesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromotionRulesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromotionRulesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PromotionRulesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> outletId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> ruleJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromotionRulesTableCompanion(
                id: id,
                userId: userId,
                outletId: outletId,
                name: name,
                type: type,
                active: active,
                ruleJson: ruleJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String outletId,
                required String name,
                required String type,
                required bool active,
                required String ruleJson,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PromotionRulesTableCompanion.insert(
                id: id,
                userId: userId,
                outletId: outletId,
                name: name,
                type: type,
                active: active,
                ruleJson: ruleJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PromotionRulesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromotionRulesTableTable,
      PromotionRulesTableData,
      $$PromotionRulesTableTableFilterComposer,
      $$PromotionRulesTableTableOrderingComposer,
      $$PromotionRulesTableTableAnnotationComposer,
      $$PromotionRulesTableTableCreateCompanionBuilder,
      $$PromotionRulesTableTableUpdateCompanionBuilder,
      (
        PromotionRulesTableData,
        BaseReferences<
          _$AppDatabase,
          $PromotionRulesTableTable,
          PromotionRulesTableData
        >,
      ),
      PromotionRulesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db, _db.orderItems);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(_db, _db.categoriesTable);
  $$PromotionRulesTableTableTableManager get promotionRulesTable =>
      $$PromotionRulesTableTableTableManager(_db, _db.promotionRulesTable);
}
