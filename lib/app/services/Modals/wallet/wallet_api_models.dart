import 'wallet_transaction.dart';

class WalletCardModel {
  const WalletCardModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.bonusAmount,
    required this.cardColor,
    this.description,
    this.sortOrder = 0,
    this.active = true,
  });

  final String id;
  final String title;
  final double amount;
  final double bonusAmount;
  final String cardColor;
  final String? description;
  final int sortOrder;
  final bool active;

  double get totalCredit => amount + bonusAmount;

  factory WalletCardModel.fromJson(Map<String, dynamic> json) {
    return WalletCardModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      bonusAmount: (json['bonusAmount'] as num?)?.toDouble() ?? 0,
      cardColor: json['cardColor']?.toString() ?? '#1976D2',
      description: json['description']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }
}

class WalletData {
  const WalletData({
    required this.balance,
    required this.transactions,
    this.lowBalanceThreshold = 50,
  });

  final double balance;
  final List<WalletTransaction> transactions;
  final double lowBalanceThreshold;

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final txList = (json['transactions'] as List<dynamic>? ?? [])
        .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
    return WalletData(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      transactions: txList,
      lowBalanceThreshold:
          (json['lowBalanceThreshold'] as num?)?.toDouble() ?? 50,
    );
  }
}
