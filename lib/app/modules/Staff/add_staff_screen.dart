import 'package:billkaro/app/modules/Staff/add_staff_controller.dart';
import 'package:billkaro/config/config.dart';

class AddStaffScreen extends StatelessWidget {
  AddStaffScreen({super.key});

  final controller = Get.put(AddStaffController());

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        title: Text(
          loc.add_staff,
          style: TextStyle(
            color: AppColor.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Name Field
                  RichText(
                    text: TextSpan(
                      text: '${loc.user_name} ',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.userNameController,
                    decoration: InputDecoration(
                      hintText: loc.tap_to_enter,
                      hintStyle: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email Field
                  RichText(
                    text: TextSpan(
                      text: '${loc.email} ',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: loc.tap_to_enter,
                      hintStyle: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Phone Number Field
                  RichText(
                    text: TextSpan(
                      text: '${loc.user_phone_number} ',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.phoneNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: loc.tap_to_enter,
                      hintStyle: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Role Field
                  Text(
                    loc.user_role,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => InkWell(
                      onTap: controller.showRolePicker,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                controller.selectedRole.value ==
                                        'Secondary Admin'
                                    ? loc.secondary_admin
                                    : controller.selectedRole.value == 'Biller'
                                    ? loc.biller
                                    : controller.selectedRole.value,
                                style: TextStyle(
                                  color: const Color(0xFF374151),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey.shade600,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Obx(
                    () => controller.selectedRole.value == 'Biller'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              checkbox(
                                'Allow biller to create menu items',
                                controller.canManageBills.value,
                                (val) => controller.canManageBills.value =
                                    val ?? false,
                              ),
                              checkbox(
                                'Allow biller to edit existing menu items',
                                controller.canEditMenuItems.value,
                                (val) => controller.canEditMenuItems.value =
                                    val ?? false,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  // Role overview: show biller overview when Biller, else Secondary Admin overview
                  Obx(
                    () => controller.selectedRole.value == 'Biller'
                        ? billerOverView(context)
                        : secondaryAdminOverView(context),
                  ),
                ],
              ),
            ),
          ),

          // Send Invite Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.sendInvite,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  loc.send_invite,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget secondaryAdminOverView(context) {
    var loc = AppLocalizations.of(Get.context!)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'Role Overview',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          Gap(10),

          Text(
            loc.staff_access_info,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget billerOverView(context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Overview',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          Gap(10),
          overView(1, 'Create and print orders and KOT.'),
          overView(2, 'View all items and use them for billing.'),
          overView(3, 'Cannot delete any orders (self or others).'),
          overView(4, 'Cannot access orders created by other members.'),
        ],
      ),
    );
  }

  Widget overView(int num, String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$num.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget checkbox(String title, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
      ],
    );
  }
}
