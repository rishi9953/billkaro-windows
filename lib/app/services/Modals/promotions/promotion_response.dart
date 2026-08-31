class PromotionFreeItem {
  const PromotionFreeItem({
    required this.itemId,
    this.variantId,
    this.label,
  });

  final String itemId;
  final String? variantId;
  final String? label;

  factory PromotionFreeItem.fromJson(Map<String, dynamic> json) {
    return PromotionFreeItem(
      itemId: json['itemId']?.toString() ?? '',
      variantId: json['variantId']?.toString(),
      label: json['label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    if (variantId != null && variantId!.isNotEmpty) 'variantId': variantId,
    if (label != null && label!.isNotEmpty) 'label': label,
  };

  String displayLabel(String fallback) =>
      (label?.trim().isNotEmpty == true) ? label!.trim() : fallback;
}

class PromotionConditions {
  const PromotionConditions({
    this.minOrderAmount = 0,
    this.amountBasis = 'subtotal',
    this.categoryName,
    this.buyQuantity = 0,
    this.itemId,
    this.variantId,
    this.startTime,
    this.endTime,
    this.daysOfWeek = const [],
  });

  final double minOrderAmount;
  final String amountBasis;
  final String? categoryName;
  final int buyQuantity;
  final String? itemId;
  final String? variantId;
  final String? startTime;
  final String? endTime;
  final List<int> daysOfWeek;

  bool get hasCategoryScope {
    final category = categoryName?.trim();
    return category != null && category.isNotEmpty;
  }

  factory PromotionConditions.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['daysOfWeek'];
    return PromotionConditions(
      minOrderAmount: _toDouble(json['minOrderAmount']),
      amountBasis: json['amountBasis']?.toString() ?? 'subtotal',
      categoryName: json['categoryName']?.toString(),
      buyQuantity: _toInt(json['buyQuantity']),
      itemId: json['itemId']?.toString(),
      variantId: json['variantId']?.toString(),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      daysOfWeek: daysRaw is List
          ? daysRaw.map((e) => _toInt(e)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    if (minOrderAmount > 0) 'minOrderAmount': minOrderAmount,
    'amountBasis': amountBasis,
    if (categoryName != null && categoryName!.trim().isNotEmpty)
      'categoryName': categoryName!.trim(),
    if (buyQuantity > 0) 'buyQuantity': buyQuantity,
    if (itemId != null && itemId!.trim().isNotEmpty) 'itemId': itemId!.trim(),
    if (variantId != null && variantId!.trim().isNotEmpty)
      'variantId': variantId!.trim(),
    if (startTime != null && startTime!.trim().isNotEmpty)
      'startTime': startTime!.trim(),
    if (endTime != null && endTime!.trim().isNotEmpty)
      'endTime': endTime!.trim(),
    if (daysOfWeek.isNotEmpty) 'daysOfWeek': daysOfWeek,
  };
}

class PromotionRewards {
  const PromotionRewards({
    this.rewardKind = 'free_item',
    this.choiceMode = 'pick_one',
    this.quantity = 1,
    this.getQuantity = 1,
    this.freeItems = const [],
    this.flatAmount = 0,
    this.percent = 0,
    this.maxDiscount = 0,
    this.sameAsTrigger = false,
    this.deductStock = true,
  });

  final String rewardKind;
  final String choiceMode;
  final int quantity;
  final int getQuantity;
  final List<PromotionFreeItem> freeItems;
  final double flatAmount;
  final double percent;
  final double maxDiscount;
  final bool sameAsTrigger;
  final bool deductStock;

  factory PromotionRewards.fromJson(Map<String, dynamic> json) {
    final raw = json['freeItems'];
    return PromotionRewards(
      rewardKind: json['rewardKind']?.toString() ?? 'free_item',
      choiceMode: json['choiceMode']?.toString() ?? 'pick_one',
      quantity: _toInt(json['quantity'], fallback: 1),
      getQuantity: _toInt(json['getQuantity'], fallback: 1),
      freeItems: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => PromotionFreeItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
      flatAmount: _toDouble(json['flatAmount']),
      percent: _toDouble(json['percent']),
      maxDiscount: _toDouble(json['maxDiscount']),
      sameAsTrigger: json['sameAsTrigger'] == true,
      deductStock: json['deductStock'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'rewardKind': rewardKind,
    'choiceMode': choiceMode,
    'quantity': quantity,
    'getQuantity': getQuantity,
    'freeItems': freeItems.map((e) => e.toJson()).toList(),
    if (flatAmount > 0) 'flatAmount': flatAmount,
    if (percent > 0) 'percent': percent,
    if (maxDiscount > 0) 'maxDiscount': maxDiscount,
    if (sameAsTrigger) 'sameAsTrigger': true,
    'deductStock': deductStock,
  };
}

class PromotionData {
  const PromotionData({
    required this.id,
    required this.userId,
    required this.outletId,
    required this.name,
    required this.type,
    required this.active,
    required this.conditions,
    required this.rewards,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String outletId;
  final String name;
  final String type;
  final bool active;
  final PromotionConditions conditions;
  final PromotionRewards rewards;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PromotionData.fromJson(Map<String, dynamic> json) {
    final conditionsRaw = json['conditions'];
    final rewardsRaw = json['rewards'];
    return PromotionData(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SPEND_THRESHOLD_FREE_ITEM',
      active: json['active'] == true,
      conditions: conditionsRaw is Map
          ? PromotionConditions.fromJson(Map<String, dynamic>.from(conditionsRaw))
          : const PromotionConditions(),
      rewards: rewardsRaw is Map
          ? PromotionRewards.fromJson(Map<String, dynamic>.from(rewardsRaw))
          : const PromotionRewards(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'outletId': outletId,
    'name': name,
    'type': type,
    'active': active,
    'conditions': conditions.toJson(),
    'rewards': rewards.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class PromotionResponse {
  const PromotionResponse({required this.status, required this.data});

  final String status;
  final List<PromotionData> data;

  factory PromotionResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    return PromotionResponse(
      status: json['status']?.toString() ?? '',
      data: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => PromotionData.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
