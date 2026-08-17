/// How an outlet unlocks BillKaro features.
///
/// - [subscription]: trial or paid plan (flat fee, no per-bill wallet cut)
/// - [wallet]: prepaid pay-as-you-go (platform fee deducted per closed bill)
enum BillingAccessMode {
  subscription,
  wallet,
}

extension BillingAccessModeX on BillingAccessMode {
  String get storageValue => name;

  bool get isSubscription => this == BillingAccessMode.subscription;

  bool get isWallet => this == BillingAccessMode.wallet;

  /// Parses prefs / API values. Unknown or empty → [BillingAccessMode.wallet].
  static BillingAccessMode fromStorage(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return BillingAccessMode.wallet;
    }
    for (final mode in BillingAccessMode.values) {
      if (mode.name == value) return mode;
    }
    return BillingAccessMode.wallet;
  }
}
