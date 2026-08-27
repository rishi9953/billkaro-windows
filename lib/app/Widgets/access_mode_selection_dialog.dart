import 'dart:async';

import 'package:billkaro/app/services/billing/access_mode_refresh.dart';
import 'package:billkaro/app/services/billing/billing_access_mode.dart';
import 'package:billkaro/app/Widgets/billing_mode_selector.dart';
import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:billkaro/config/config.dart';

/// Blocking dialog for new users to pick subscription (1-week trial) or wallet (₹100 credits).
class AccessModeSelectionDialog extends StatefulWidget {
  const AccessModeSelectionDialog({
    super.key,
    required this.onCompleted,
  });

  final ValueChanged<BillingAccessMode> onCompleted;

  /// Overlay below [WindowsDesktopTitleBar] so min/max/close stay clickable.
  /// Uses [OverlayEntry] (same as app loader) — not a dialog route — so the
  /// title bar is not covered by a full-screen modal barrier.
  static Future<BillingAccessMode?> show(BuildContext? context) {
    final completer = Completer<BillingAccessMode?>();

    // Prefer overlayContext (same as showAppLoader); Get.context often has no Overlay.
    final overlayContext = Get.overlayContext ?? context;
    if (overlayContext == null || !overlayContext.mounted) {
      return Future.value(null);
    }

    late OverlayEntry entry;

    void close([BillingAccessMode? result]) {
      try {
        if (entry.mounted) entry.remove();
      } catch (_) {}
      if (!completer.isCompleted) completer.complete(result);
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final topInset = desktopOverlayTopInset();
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: topInset,
                left: 0,
                right: 0,
                bottom: 0,
                child: const ModalBarrier(
                  dismissible: false,
                  color: Colors.black54,
                ),
              ),
              Positioned(
                top: topInset,
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: AccessModeSelectionDialog(
                    onCompleted: close,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      Overlay.of(overlayContext, rootOverlay: true).insert(entry);
    } catch (e, st) {
      debugPrint('AccessModeSelectionDialog overlay insert failed: $e\n$st');
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }

  @override
  State<AccessModeSelectionDialog> createState() =>
      _AccessModeSelectionDialogState();
}

class _AccessModeSelectionDialogState extends State<AccessModeSelectionDialog> {
  BillingAccessMode _selected = BillingAccessMode.subscription;
  bool _submitting = false;

  Future<void> _confirm() async {
    if (_submitting) return;

    final appPref = Get.find<AppPref>();
    final user = appPref.user;
    final userId = user?.userId ?? user?.id;
    final outletId = appPref.selectedOutlet?.id;

    if (userId == null || userId.isEmpty || outletId == null || outletId.isEmpty) {
      showError(description: 'Unable to select access mode. Please try again.');
      return;
    }

    setState(() => _submitting = true);

    final apiClient = Get.find<ApiClient>();
    final response = await callApi(
      apiClient.chooseAccessMode(userId, {
        'mode': _selected.storageValue,
        'outletId': outletId,
      }),
      showLoader: false,
    );

    if (!mounted) return;

    if (response == null) {
      setState(() => _submitting = false);
      return;
    }

    // Apply mode + reload trial/wallet into live UI before closing.
    await refreshAfterAccessModeChoice(_selected);

    if (!mounted) return;
    setState(() => _submitting = false);

    final message = _selected.isSubscription
        ? 'Subscription mode selected. Enjoy 1 week free access.'
        : 'Wallet mode selected. ₹100 free credits added to your outlet.';
    showSuccess(description: message);

    widget.onCompleted(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 24, 8, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 40, color: AppColor.primary),
                const Gap(12),
                const Text(
                  'Choose your access mode',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Gap(6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Pick how you want to use BillKaro. This is a one-time choice for your welcome offer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                ),
                const Gap(8),
                BillingModeSelector(
                  selected: _selected,
                  onSelected: (mode) => setState(() => _selected = mode),
                  subscriptionTitle: 'Subscription',
                  subscriptionSubtitle:
                      'Get 1 week free access to all features',
                  walletTitle: 'Wallet',
                  walletSubtitle:
                      'Get ₹100 free credits for your outlet (no free trial)',
                  enabled: !_submitting,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the one-time access-mode dialog when the owner has not chosen yet.
Future<BillingAccessMode?> showAccessModeSelectionIfNeeded() async {
  final appPref = Get.find<AppPref>();
  if (appPref.isStaffSession) return null;

  final user = appPref.user;
  if (user == null) return null;

  if (user.accessModeChosen != false) return null;

  final outletId = appPref.selectedOutlet?.id;
  if (outletId == null || outletId.isEmpty) return null;

  // Wait a frame so overlayContext exists after home shell mounts.
  await Future<void>.delayed(Duration.zero);
  await WidgetsBinding.instance.endOfFrame;

  final context = Get.overlayContext ?? Get.context;
  if (context == null || !context.mounted) {
    debugPrint('AccessModeSelectionDialog: no overlay context available');
    return null;
  }

  return AccessModeSelectionDialog.show(context);
}
