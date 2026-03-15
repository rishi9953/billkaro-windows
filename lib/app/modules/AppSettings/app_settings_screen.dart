import 'package:billkaro/app/modules/AppSettings/app_settings_controller.dart';
import 'package:billkaro/config/config.dart';

class AppSettingsScreen extends StatelessWidget {
  AppSettingsScreen({super.key});
  late final controller = Get.put(AppSettingsController());

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.settings,
          style: const TextStyle(
            color: AppColor.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General'),
            const Gap(8),
            _buildSectionCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.view_list_rounded,
                  title: 'Billing list view',
                  subtitle: 'Show orders as list instead of image grid',
                  value: controller.isListView,
                  onChanged: controller.setListView,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.qr_code_2_outlined,
                  title: 'Show QR on bill',
                  subtitle: 'Show UPI scan-to-pay QR on invoice and print',
                  value: controller.showQrOnBill,
                  onChanged: controller.setShowQrOnBill,
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.tour_outlined,
                  title: 'Show onboarding again',
                  subtitle: 'Replay the app intro and tips',
                  onTap: () {
                    controller.resetOnboarding();
                    Get.back();
                  },
                ),
              ],
            ),
            const Gap(24),
            _buildSectionHeader('Notifications'),
            const Gap(8),
            _buildSectionCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Order and reminder notifications',
                  value: controller.notificationsEnabled,
                  onChanged: controller.setNotificationsEnabled,
                ),
              ],
            ),
            const Gap(24),
            _buildSectionHeader('Sound & feedback'),
            const Gap(8),
            _buildSectionCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.volume_up_outlined,
                  title: 'Sound',
                  subtitle: 'Play sounds for actions',
                  value: controller.soundEnabled,
                  onChanged: controller.setSoundEnabled,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.vibration_outlined,
                  title: 'Haptic feedback',
                  subtitle: 'Vibration on tap',
                  value: controller.hapticEnabled,
                  onChanged: controller.setHapticEnabled,
                ),
              ],
            ),
            const Gap(24),
            _buildSectionHeader('Language & region'),
            const Gap(8),
            _buildSectionCard(
              children: [
                _buildNavigationTile(
                  icon: Icons.language,
                  title: loc.language,
                  subtitle: loc.change_app_language,
                  onTap: () => Get.toNamed(AppRoute.changeLanguage),
                ),
              ],
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey[200]),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required RxBool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColor.primary, size: 22),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Switch(
              value: value.value,
              onChanged: onChanged,
              activeColor: AppColor.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColor.primary, size: 22),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColor.primary, size: 22),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
