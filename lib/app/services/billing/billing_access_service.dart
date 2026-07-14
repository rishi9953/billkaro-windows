import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/billing/billing_access_mode.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:get/get.dart';

/// Single source of truth for subscription ↔ wallet mode.
///
/// Persist per outlet via [AppPref]. Access rules:
/// - Active trial → always allowed
/// - [BillingAccessMode.subscription] → active outlet subscription required
/// - [BillingAccessMode.wallet] → mode itself unlocks gated features
///   (per-bill fee / low-balance checks stay separate from this gate)
class BillingAccessService {
  BillingAccessService(this._appPref);

  final AppPref _appPref;

  /// Convenience when GetX already holds [AppPref].
  factory BillingAccessService.of() =>
      BillingAccessService(Get.find<AppPref>());

  String? get _outletId => _appPref.selectedOutlet?.id;

  BillingAccessMode modeForOutlet(String? outletId) =>
      BillingAccessModeX.fromStorage(
        _appPref.billingAccessModeRawForOutlet(outletId),
      );

  BillingAccessMode get mode => modeForOutlet(_outletId);

  void setMode(BillingAccessMode mode, {String? outletId}) {
    _appPref.setBillingAccessModeRawForOutlet(
      outletId ?? _outletId,
      mode.storageValue,
    );
  }

  /// Whether gated features may run under the current mode.
  ///
  /// Prefer calling [hasTrialOrSubscription] from UI; this mirrors that logic
  /// for callers that already hold a [BillingAccessService].
  bool hasAccess({String? outletId}) {
    final user = _appPref.user;
    if (user == null) return false;

    if (_isActiveTrial(user)) return true;

    final resolvedOutletId = outletId ?? _outletId;
    switch (modeForOutlet(resolvedOutletId)) {
      case BillingAccessMode.subscription:
        return _hasActiveSubscription();
      case BillingAccessMode.wallet:
        return true;
    }
  }

  bool _isActiveTrial(User user) {
    if (user.isTrial != true) return false;
    final end = trialEndDate(_appPref.selectedOutlet, user);
    if (end == null) return true;
    return DateTime.now().isBefore(end);
  }

  bool _hasActiveSubscription() {
    final selectedOutlet = _appPref.selectedOutlet;
    if (outletHasAnyActiveSubscription(selectedOutlet)) return true;

    final outlets = _appPref.user?.outletData;
    if (outlets == null || outlets.isEmpty) return false;

    if (selectedOutlet?.id != null && selectedOutlet!.id!.trim().isNotEmpty) {
      final selectedId = selectedOutlet.id!.trim();
      for (final outlet in outlets) {
        if (outlet.id == selectedId) {
          return outletHasAnyActiveSubscription(outlet);
        }
      }
    }

    for (final outlet in outlets) {
      if (outletHasAnyActiveSubscription(outlet)) return true;
    }
    return false;
  }
}
