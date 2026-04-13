import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/app/modules/Staff/staff_list_screen.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class StaffDetailsScreen extends StatelessWidget {
  const StaffDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StaffDetailsController());
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: Color(0xFFE8EEF7),
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.staffList.isNotEmpty) {
        return const StaffListScreen();
      }

      return Scaffold(
        backgroundColor: const Color(0xFFE8EEF7),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFE8EEF7),
          elevation: 0,
          leading: null,
          leadingWidth: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadStaffList,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 50),
                    Center(
                      child: Container(
                        color: Colors.white60,
                        child: Lottie.asset(
                          'assets/lottie/staff.json',
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildFeaturesList(),
                    footerSection(),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context),
          ],
        ),
      );
    });
  }

  Widget _buildTitle() {
    var loc = AppLocalizations.of(Get.context!)!;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          height: 1.2,
        ),
        children: [
          TextSpan(text: "${loc.work_smarter_together} "),
          TextSpan(text: '✨'),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    var loc = AppLocalizations.of(Get.context!)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildFeatureItem(
            icon: Icons.star,
            title: loc.access_anytime_anywhere,
            description: loc.your_outlet_always_with_you,
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.star,
            title: loc.add_staff_share_work,
            description: loc.let_team_take_orders,
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.star,
            title: loc.safe_cloud_data,
            description: loc.even_if_phone_lost,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          margin: EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: const Icon(Icons.star, color: Colors.blue, size: 3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () async {
            await Modular.to.pushNamed(HomeMainRoutes.addStaffScreen);
            await Get.find<StaffDetailsController>().loadStaffList();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            loc.invite_staff,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
