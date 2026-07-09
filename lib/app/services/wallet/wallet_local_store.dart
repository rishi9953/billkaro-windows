import 'dart:convert';

import 'package:billkaro/app/services/Modals/wallet/wallet_transaction.dart';
import 'package:billkaro/config/app_pref.dart';

/// Local-only wallet storage (demo — no backend).
class WalletLocalStore {
  WalletLocalStore(this._appPref);

  final AppPref _appPref;

  static const double lowBalanceThreshold = 50;

  String? get _outletId => _appPref.selectedOutlet?.id;

  double get balance => _appPref.walletBalanceForOutlet(_outletId);

  List<WalletTransaction> get transactions {
    final raw = _appPref.walletHistoryJsonForOutlet(_outletId);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  bool get isLowBalance => balance > 0 && balance < lowBalanceThreshold;

  void ensureInitialized() {
    if (_appPref.isWalletInitializedForOutlet(_outletId)) return;
    _appPref.setWalletInitializedForOutlet(_outletId, true);
  }

  void credit(
    double amount, {
    required String description,
    String? paymentId,
  }) {
    if (amount <= 0) return;
    final updated = balance + amount;
    _appPref.setWalletBalanceForOutlet(_outletId, updated);
    _appendTransaction(
      WalletTransaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: WalletTransactionType.credit,
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
        paymentId: paymentId,
      ),
    );
  }

  void debit(double amount, {required String description}) {
    if (amount <= 0) return;
    final updated = (balance - amount).clamp(0, double.infinity);
    _appPref.setWalletBalanceForOutlet(_outletId, updated.toDouble());
    _appendTransaction(
      WalletTransaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: WalletTransactionType.debit,
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _appendTransaction(WalletTransaction tx) {
    final list = transactions..insert(0, tx);
    _appPref.setWalletHistoryJsonForOutlet(
      _outletId,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }
}
