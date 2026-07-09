class InventoryDashboardData {
  final int totalRawMaterials;
  final int lowStockCount;
  final double totalStockValue;
  final double todayConsumption;
  final int activeSuppliers;
  final int pendingPurchaseOrders;
  final int trackedMenuItems;
  final int lowStockMenuItems;
  final List<LowStockMaterial> lowStockMaterials;

  InventoryDashboardData({
    required this.totalRawMaterials,
    required this.lowStockCount,
    required this.totalStockValue,
    required this.todayConsumption,
    required this.activeSuppliers,
    required this.pendingPurchaseOrders,
    required this.trackedMenuItems,
    required this.lowStockMenuItems,
    required this.lowStockMaterials,
  });

  factory InventoryDashboardData.fromJson(Map<String, dynamic> json) {
    return InventoryDashboardData(
      totalRawMaterials: (json['totalRawMaterials'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      totalStockValue: (json['totalStockValue'] as num?)?.toDouble() ?? 0,
      todayConsumption: (json['todayConsumption'] as num?)?.toDouble() ?? 0,
      activeSuppliers: (json['activeSuppliers'] as num?)?.toInt() ?? 0,
      pendingPurchaseOrders:
          (json['pendingPurchaseOrders'] as num?)?.toInt() ?? 0,
      trackedMenuItems: (json['trackedMenuItems'] as num?)?.toInt() ?? 0,
      lowStockMenuItems: (json['lowStockMenuItems'] as num?)?.toInt() ?? 0,
      lowStockMaterials: (json['lowStockMaterials'] as List<dynamic>? ?? [])
          .map((e) => LowStockMaterial.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LowStockMaterial {
  final String id;
  final String name;
  final double currentStock;
  final double minStock;
  final String unit;

  LowStockMaterial({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.minStock,
    required this.unit,
  });

  factory LowStockMaterial.fromJson(Map<String, dynamic> json) {
    return LowStockMaterial(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0,
      minStock: (json['minStock'] as num?)?.toDouble() ?? 0,
      unit: json['unit']?.toString() ?? '',
    );
  }
}

class RawMaterialData {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double minStock;
  final double purchasePrice;
  final String? supplierId;
  final bool isActive;
  final String materialCode;
  final String hsnSacCode;
  final double taxRate;

  RawMaterialData({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.minStock,
    required this.purchasePrice,
    this.supplierId,
    required this.isActive,
    this.materialCode = '',
    this.hsnSacCode = '',
    this.taxRate = 18,
  });

  factory RawMaterialData.fromJson(Map<String, dynamic> json) {
    return RawMaterialData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'PIECE',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0,
      minStock: (json['minStock'] as num?)?.toDouble() ?? 0,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
      supplierId: json['supplierId']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      materialCode: json['materialCode']?.toString() ?? '',
      hsnSacCode: json['hsnSacCode']?.toString() ?? '',
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 18,
    );
  }

  bool get isLowStock => currentStock <= minStock;
  double get stockValue => currentStock * purchasePrice;
}

class SupplierData {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final String? vendorNo;
  final String? contactPerson;
  final bool isActive;

  SupplierData({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.vendorNo,
    this.contactPerson,
    required this.isActive,
  });

  factory SupplierData.fromJson(Map<String, dynamic> json) {
    return SupplierData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      gstNumber: json['gstNumber']?.toString(),
      vendorNo: json['vendorNo']?.toString(),
      contactPerson: json['contactPerson']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class StockTransactionData {
  final String id;
  final String rawMaterialId;
  final String type;
  final double quantity;
  final double unitPrice;
  final double? stockBefore;
  final double? stockAfter;
  final String? reference;
  final String? notes;
  final String createdAt;

  StockTransactionData({
    required this.id,
    required this.rawMaterialId,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    this.stockBefore,
    this.stockAfter,
    this.reference,
    this.notes,
    required this.createdAt,
  });

  factory StockTransactionData.fromJson(Map<String, dynamic> json) {
    return StockTransactionData(
      id: json['id']?.toString() ?? '',
      rawMaterialId: json['rawMaterialId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      stockBefore: (json['stockBefore'] as num?)?.toDouble(),
      stockAfter: (json['stockAfter'] as num?)?.toDouble(),
      reference: json['reference']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PoSupplierInfo {
  final String vendorNo;
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String gstNumber;
  final String contactPerson;
  final String phone;

  PoSupplierInfo({
    required this.vendorNo,
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.gstNumber,
    required this.contactPerson,
    required this.phone,
  });

  factory PoSupplierInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PoSupplierInfo(
        vendorNo: '',
        name: '',
        addressLine1: '',
        addressLine2: '',
        gstNumber: '',
        contactPerson: '',
        phone: '',
      );
    }
    return PoSupplierInfo(
      vendorNo: json['vendorNo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString() ?? '',
      addressLine2: json['addressLine2']?.toString() ?? '',
      gstNumber: json['gstNumber']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class PurchaseOrderData {
  final String id;
  final String supplierId;
  final String supplierName;
  final PoSupplierInfo? supplier;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String? notes;
  final String? expectedDate;
  final String? receivedAt;
  final String createdAt;
  final List<PurchaseOrderLineData> items;
  final int version;
  final String currency;
  final String paymentTerms;
  final String? validityDate;
  final String? referenceNo;
  final String documentType;
  final String? billingName;
  final String? billingAddressLine1;
  final String? billingAddressLine2;
  final String? billingPinCode;
  final String? billingState;
  final String? billingContact;
  final String? billingGstNo;
  final String? shippingName;
  final String? shippingAddressLine1;
  final String? shippingAddressLine2;
  final String? shippingPinCode;
  final String? shippingState;
  final String? shippingContact;
  final String? shippingGstNo;
  final String? registeredOfficeAddress;
  final String? termsAndConditions;
  final double subTotal;
  final double totalTax;
  final double grossTotal;

  PurchaseOrderData({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    this.supplier,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.expectedDate,
    this.receivedAt,
    required this.createdAt,
    required this.items,
    this.version = 0,
    this.currency = 'INR',
    this.paymentTerms = 'Within 25 days',
    this.validityDate,
    this.referenceNo,
    this.documentType = 'Purchase Order',
    this.billingName,
    this.billingAddressLine1,
    this.billingAddressLine2,
    this.billingPinCode,
    this.billingState,
    this.billingContact,
    this.billingGstNo,
    this.shippingName,
    this.shippingAddressLine1,
    this.shippingAddressLine2,
    this.shippingPinCode,
    this.shippingState,
    this.shippingContact,
    this.shippingGstNo,
    this.registeredOfficeAddress,
    this.termsAndConditions,
    this.subTotal = 0,
    this.totalTax = 0,
    this.grossTotal = 0,
  });

  factory PurchaseOrderData.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .asMap()
        .entries
        .map(
          (e) => PurchaseOrderLineData.fromJson(
            e.value as Map<String, dynamic>,
            lineIndex: e.key,
          ),
        )
        .toList();
    final computedSub =
        items.fold(0.0, (sum, line) => sum + line.basicAmount);
    final computedTax =
        items.fold(0.0, (sum, line) => sum + line.taxAmount);
    final computedGross = computedSub + computedTax;

    return PurchaseOrderData(
      id: json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      supplier: json['supplier'] is Map
          ? PoSupplierInfo.fromJson(
              Map<String, dynamic>.from(json['supplier'] as Map),
            )
          : null,
      orderNumber: json['orderNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
      expectedDate: json['expectedDate']?.toString(),
      receivedAt: json['receivedAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      items: items,
      version: (json['version'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      paymentTerms: json['paymentTerms']?.toString() ?? 'Within 25 days',
      validityDate: json['validityDate']?.toString(),
      referenceNo: json['referenceNo']?.toString(),
      documentType: json['documentType']?.toString() ?? 'Purchase Order',
      billingName: json['billingName']?.toString(),
      billingAddressLine1: json['billingAddressLine1']?.toString(),
      billingAddressLine2: json['billingAddressLine2']?.toString(),
      billingPinCode: json['billingPinCode']?.toString(),
      billingState: json['billingState']?.toString(),
      billingContact: json['billingContact']?.toString(),
      billingGstNo: json['billingGstNo']?.toString(),
      shippingName: json['shippingName']?.toString(),
      shippingAddressLine1: json['shippingAddressLine1']?.toString(),
      shippingAddressLine2: json['shippingAddressLine2']?.toString(),
      shippingPinCode: json['shippingPinCode']?.toString(),
      shippingState: json['shippingState']?.toString(),
      shippingContact: json['shippingContact']?.toString(),
      shippingGstNo: json['shippingGstNo']?.toString(),
      registeredOfficeAddress: json['registeredOfficeAddress']?.toString(),
      termsAndConditions: json['termsAndConditions']?.toString(),
      subTotal: _poAmount(json['subTotal'], computedSub),
      totalTax: _poAmount(json['totalTax'], computedTax),
      grossTotal: _poAmount(
        json['grossTotal'] ?? json['totalAmount'],
        computedGross > 0
            ? computedGross
            : ((json['totalAmount'] as num?)?.toDouble() ?? 0),
      ),
    );
  }

  static double _poAmount(dynamic stored, double fallback) {
    final value = (stored as num?)?.toDouble();
    if (value == null || value == 0) return fallback;
    return value;
  }
}

class PurchaseOrderLineData {
  final String id;
  final String rawMaterialId;
  final String rawMaterialName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double receivedQuantity;
  final int lineNumber;
  final String materialCode;
  final String description;
  final String hsnSacCode;
  final double taxRate;
  final double basicAmount;
  final double taxAmount;
  final double grossAmount;
  final String? deliveryDate;
  final String plant;

  PurchaseOrderLineData({
    required this.id,
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.receivedQuantity,
    this.lineNumber = 0,
    this.materialCode = '',
    this.description = '',
    this.hsnSacCode = '',
    this.taxRate = 18,
    this.basicAmount = 0,
    this.taxAmount = 0,
    this.grossAmount = 0,
    this.deliveryDate,
    this.plant = '',
  });

  factory PurchaseOrderLineData.fromJson(
    Map<String, dynamic> json, {
    int lineIndex = 0,
  }) {
    final qty = (json['quantity'] as num?)?.toDouble() ?? 0;
    final rate = (json['unitPrice'] as num?)?.toDouble() ?? 0;
    final taxRate = (json['taxRate'] as num?)?.toDouble() ?? 18;
    final computedBasic = qty * rate;
    final basic = _poAmount(json['basicAmount'], computedBasic);
    final computedTax = basic * taxRate / 100;
    final taxAmt = _poAmount(json['taxAmount'], computedTax);
    final gross = _poAmount(json['grossAmount'], basic + taxAmt);
    final lineNo = (json['lineNumber'] as num?)?.toInt() ?? 0;
    return PurchaseOrderLineData(
      id: json['id']?.toString() ?? '',
      rawMaterialId: json['rawMaterialId']?.toString() ?? '',
      rawMaterialName: json['rawMaterialName']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: qty,
      unitPrice: rate,
      receivedQuantity: (json['receivedQuantity'] as num?)?.toDouble() ?? 0,
      lineNumber: lineNo > 0 ? lineNo : (lineIndex + 1) * 10,
      materialCode: json['materialCode']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      hsnSacCode: json['hsnSacCode']?.toString() ?? '',
      taxRate: taxRate,
      basicAmount: basic,
      taxAmount: taxAmt,
      grossAmount: gross,
      deliveryDate: json['deliveryDate']?.toString(),
      plant: json['plant']?.toString() ?? '',
    );
  }

  static double _poAmount(dynamic stored, double fallback) {
    final value = (stored as num?)?.toDouble();
    if (value == null || value == 0) return fallback;
    return value;
  }
}

class RecipeData {
  final String id;
  final String itemId;
  final String itemName;
  final String rawMaterialId;
  final String rawMaterialName;
  final String rawMaterialUnit;
  final double quantity;

  RecipeData({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.rawMaterialUnit,
    required this.quantity,
  });

  factory RecipeData.fromJson(Map<String, dynamic> json) {
    return RecipeData(
      id: json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      rawMaterialId: json['rawMaterialId']?.toString() ?? '',
      rawMaterialName: json['rawMaterialName']?.toString() ?? '',
      rawMaterialUnit: json['rawMaterialUnit']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PoLineSuggestion {
  final String rawMaterialId;
  final double quantity;
  final double unitPrice;

  PoLineSuggestion({
    required this.rawMaterialId,
    required this.quantity,
    required this.unitPrice,
  });
}

class InventoryListResponse<T> {
  final String status;
  final List<T> data;

  InventoryListResponse({required this.status, required this.data});
}
