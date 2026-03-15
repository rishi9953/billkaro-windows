import 'package:billkaro/app/modules/Menu/menu_controller.dart';
import 'package:billkaro/app/services/PrinterService2/printer_screen2.dart';
import 'package:billkaro/app/Widgets/logout_dialog.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:intl/intl.dart';

class MenuScreen extends StatelessWidget {
  MenuScreen({super.key});
  final controller = Get.put(MenusController());

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.menu,
          style: const TextStyle(
            color: AppColor.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Restaurant Profile Card - Enhanced
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () => Get.toNamed(AppRoute.businessDetails),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xff083c6b),
                              const Color(0xff083c6b).withOpacity(0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff083c6b).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:
                                  controller
                                      .appPref
                                      .selectedOutlet!
                                      .logo!
                                      .isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: controller
                                            .appPref
                                            .selectedOutlet!
                                            .logo!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        controller
                                            .appPref
                                            .selectedOutlet!
                                            .businessName!
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff083c6b),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Obx(() {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.busineesssName.value.isEmpty
                                          ? loc
                                                .enter_restaurant_name
                                                .capitalize!
                                          : controller
                                                .busineesssName
                                                .value
                                                .capitalize!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          controller.mobile.value,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Subscription Details Card (only when outlet has subscription)
                  _buildSubscriptionCard(context, loc),

                  const SizedBox(height: 24),

                  // Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      loc.settings,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Menu Items - Enhanced
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.people_outline,
                            title: loc.regular_customers,
                            subtitle: loc.manage_your_loyal_customers,
                            iconColor: const Color(0xff083c6b),
                            onTap: () => Get.toNamed(AppRoute.regularCustomer),
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.phone_android_outlined,
                            title: loc.whatsapp_marketing,
                            subtitle: loc.send_bulk_messages,
                            iconColor: const Color(0xff25D366),
                            onTap: () =>
                                Get.toNamed(AppRoute.bulkWhatssMessage),
                          ),
                          // _buildDivider(),
                          // _buildSwitchMenuItem(
                          //   icon: Icons.sync_outlined,
                          //   title: loc.sync_devices,
                          //   subtitle: loc.sync_across_multiple_devices,
                          //   controller: controller,
                          // ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.people_alt_outlined,
                            title: loc.manage_staff,
                            subtitle: loc.add_and_manage_staff_members,
                            iconColor: const Color(0xffFF6B6B),
                            onTap: () {
                              // Navigate to manage staff
                              Get.toNamed(AppRoute.staffDetailsScreen);
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.print_outlined,
                            title: loc.printer,
                            subtitle: loc.configure_printer_settings,
                            iconColor: const Color(0xff4ECDC4),

                            onTap: () {
                              Get.to(() => PrinterScreen2());
                            },
                            // onTap: () => Get.to(() => PrinterPage()),
                            // onTap: () => Get.toNamed(AppRoute.printerScreen),
                          ),
                          // _buildDivider(),
                          // _buildMenuItem(
                          //   icon: Icons.language,
                          //   title: loc.language,
                          //   subtitle: loc.change_app_language,
                          //   iconColor: const Color(0xff9B59B6),
                          //   onTap: () => Get.toNamed(AppRoute.changeLanguage),
                          // ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.settings_outlined,
                            title: loc.settings,
                            subtitle: 'Change App Settings',
                            iconColor: const Color(0xff9B59B6),
                            onTap: () => Get.toNamed(AppRoute.appSettings),
                          ),
                          _buildDivider(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Support & Account Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      loc.support_and_account,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.headset_mic_outlined,
                            title: loc.support,
                            subtitle: loc.get_help_and_support,
                            iconColor: const Color(0xff3498DB),
                            onTap: () => controller.onSupportTap(),
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.logout_outlined,
                            title: loc.logout,
                            subtitle: loc.sign_out_of_your_account,
                            iconColor: Colors.red,
                            showTrailing: false,
                            onTap: () => showLogoutDialog(context, loc),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Buy Table Gold Button - Enhanced
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    // Navigate to buy table gold
                    Get.toNamed(AppRoute.subscriptions);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      // gradient: const LinearGradient(
                      //   begin: Alignment.centerLeft,
                      //   end: Alignment.centerRight,
                      //   colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      // ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            color: Color(0xFFFFA500),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upgrade to Premium',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                loc.unlock_premium_features,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, AppLocalizations loc) {
    final outlet = controller.appPref.selectedOutlet;
    final subscriptions = outlet?.subscriptions;
    final activeSubscription = subscriptions != null && subscriptions.isNotEmpty
        ? subscriptions.first
        : null;
    final endDateStr = activeSubscription?.endDate;
    DateTime? expiryDate;
    if (endDateStr != null && endDateStr.isNotEmpty) {
      expiryDate = tryParseDateTimeLoose(endDateStr);
    }
    final hasActive = activeSubscription != null && expiryDate != null;

    if (!hasActive) return const SizedBox.shrink();

    final SubscriptionPlan? plan = activeSubscription.subscription;
    final duration = plan?.duration ?? 0;
    final planName = _planNameFromDuration(duration);
    final validUntilStr = DateFormat('d MMMM, yyyy').format(expiryDate);

    const primaryBlue = Color(0xff083c6b);
    final lighterBlue = primaryBlue.withOpacity(0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoute.subscriptions),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, lighterBlue],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: diamond icon, plan name, Active badge, arrow
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.diamond,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      planName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFA500),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[300],
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Valid until row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white.withOpacity(0.95),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Valid until ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  Text(
                    validUntilStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Time Remaining nested card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white.withOpacity(0.95),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Remaining',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Obx(() {
                            controller.subscriptionTick.value;
                            return Text(
                              _formatTimeRemaining(expiryDate!),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _planNameFromDuration(int duration) {
    if (duration <= 0) return 'Subscription';
    if (duration == 1) return 'Monthly Plan';
    if (duration == 12) return 'Yearly Plan';
    return '$duration Months Plan';
  }

  String _formatTimeRemaining(DateTime expiryDate) {
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) return 'Expired';
    final diff = expiryDate.difference(now);
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    return '${d}d ${h}h ${m}m ${s}s';
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? iconColor,
    bool showTrailing = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xff083c6b)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? const Color(0xff083c6b),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            if (showTrailing)
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchMenuItem({
    required IconData icon,
    required String title,
    required MenusController controller,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff083c6b).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xff083c6b), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          Obx(
            () => Switch(
              value: controller.isSyncEnabled.value,
              onChanged: controller.toggleSync,
              activeColor: const Color(0xff083c6b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
    );
  }
}
