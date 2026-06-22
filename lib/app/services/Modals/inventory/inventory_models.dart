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
  final bool isActive;

  SupplierData({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
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

class PurchaseOrderData {
  final String id;
  final String supplierId;
  final String supplierName;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String? notes;
  final String? expectedDate;
  final String? receivedAt;
  final String createdAt;
  final List<PurchaseOrderLineData> items;

  PurchaseOrderData({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.expectedDate,
    this.receivedAt,
    required this.createdAt,
    required this.items,
  });

  factory PurchaseOrderData.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderData(
      id: json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
      expectedDate: json['expectedDate']?.toString(),
      receivedAt: json['receivedAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PurchaseOrderLineData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
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

  PurchaseOrderLineData({
    required this.id,
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.receivedQuantity,
  });

  factory PurchaseOrderLineData.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderLineData(
      id: json['id']?.toString() ?? '',
      rawMaterialId: json['rawMaterialId']?.toString() ?? '',
      rawMaterialName: json['rawMaterialName']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      receivedQuantity: (json['receivedQuantity'] as num?)?.toDouble() ?? 0,
    );
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

class InventoryListResponse<T> {
  final String status;
  final List<T> data;

  InventoryListResponse({required this.status, required this.data});
}
