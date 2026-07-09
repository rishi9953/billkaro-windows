enum WalletTransactionType { credit, debit }

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.paymentId,
  });

  final String id;
  final WalletTransactionType type;
  final double amount;
  final String description;
  final DateTime createdAt;
  final String? paymentId;

  bool get isCredit => type == WalletTransactionType.credit;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'paymentId': paymentId,
      };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().toLowerCase() ?? 'credit';
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      type: WalletTransactionType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => WalletTransactionType.credit,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      paymentId: json['paymentId']?.toString() ?? json['payment_id']?.toString(),
    );
  }
}
