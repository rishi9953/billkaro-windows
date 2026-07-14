import 'package:billkaro/app/services/billing/billing_access_mode.dart';
import 'package:billkaro/config/config.dart';

/// Reusable subscription ↔ wallet mode picker for settings screens.
///
/// Parent owns persistence and confirmation; this widget only renders state.
class BillingModeSelector extends StatelessWidget {
  const BillingModeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.subscriptionTitle,
    required this.subscriptionSubtitle,
    required this.walletTitle,
    required this.walletSubtitle,
    this.enabled = true,
  });

  final BillingAccessMode selected;
  final ValueChanged<BillingAccessMode> onSelected;
  final String subscriptionTitle;
  final String subscriptionSubtitle;
  final String walletTitle;
  final String walletSubtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          _ModeOption(
            icon: Icons.workspace_premium_outlined,
            title: subscriptionTitle,
            subtitle: subscriptionSubtitle,
            selected: selected.isSubscription,
            enabled: enabled,
            onTap: () => onSelected(BillingAccessMode.subscription),
          ),
          const Gap(10),
          _ModeOption(
            icon: Icons.account_balance_wallet_outlined,
            title: walletTitle,
            subtitle: walletSubtitle,
            selected: selected.isWallet,
            enabled: enabled,
            onTap: () => onSelected(BillingAccessMode.wallet),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColor.primary
        : Colors.grey.shade300;
    final background = selected
        ? AppColor.primary.withValues(alpha: 0.06)
        : Colors.grey.shade50;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColor.primary.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected ? AppColor.primary : Colors.grey.shade700,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColor.primary
                              : Colors.black87,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color: selected ? AppColor.primary : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
