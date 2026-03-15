import 'package:billkaro/app/modules/OrderPrefrences/order_prefrences_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';

class OrderPreferencesScreen extends StatelessWidget {
  OrderPreferencesScreen({super.key});

  final OrderPreferencesController controller = Get.put(
    OrderPreferencesController(),
  );

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          controller.syncPreferencesToAddOrderOnPop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.order_preferences,
          style: TextStyle(
            color: AppColor.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // KOT Mode Section
                _buildPreferenceItem(
                  title: loc.kot_mode,
                  subtitle: loc.how_does_this_work,
                  value: controller.kotModeEnabled,
                  onChanged: controller.toggleKotMode,
                  subtitleColor: AppColor.primary,
                  onSubtitleTap: controller.showKotModeBottomSheet,
                ),
                Gap(10),
                _billingView(),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _billingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing View',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildViewOption(
                    title: 'Image View',
                    icon: Icons.grid_view,
                    isSelected: !controller.isListView.value,
                    onTap: () {
                      controller.selectBillingView(false);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildViewOption(
                    title: 'List View',
                    icon: Icons.list,
                    isSelected: controller.isListView.value,
                    onTap: () {
                      controller.selectBillingView(true);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primary.withOpacity(0.1)
              : AppColor.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColor.primary : AppColor.primary,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              Positioned(
                right: 8,
                top: 8,
                child: Icon(
                  Icons.check_circle,
                  color: AppColor.primary,
                  size: 24,
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: AppColor.primary),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColor.primary : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem({
    required String title,
    required String subtitle,
    required RxBool value,
    required Function(bool) onChanged,
    Color? subtitleColor,
    VoidCallback? onSubtitleTap,
    bool isSubtitleClickable = false,
    bool enabled = true,
  }) {
    final effectiveSubtitleColor = subtitleColor ?? Colors.black54;
    final isClickable = onSubtitleTap != null || isSubtitleClickable;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildSubtitle(
                        subtitle: subtitle,
                        color: effectiveSubtitleColor,
                        isClickable: isClickable,
                        onTap: enabled ? onSubtitleTap : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Obx(
                  () => Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: value.value,
                      onChanged: enabled ? onChanged : null,
                      activeColor: Colors.white,
                      activeTrackColor: AppColor.primary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey[300],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildSubtitle({
    required String subtitle,
    required Color color,
    required bool isClickable,
    VoidCallback? onTap,
  }) {
    final textWidget = Text(
      subtitle,
      style: TextStyle(
        fontSize: 13,
        color: color,
        fontWeight: isClickable ? FontWeight.w600 : FontWeight.w400,
        decoration: isClickable ? TextDecoration.underline : null,
        decorationColor: color,
      ),
    );

    if (!isClickable || onTap == null) {
      return textWidget;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: textWidget,
      ),
    );
  }
}
