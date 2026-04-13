// Controller
import 'package:billkaro/config/config.dart';

class AddStaffController extends BaseController {
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final selectedRole = 'Secondary Admin'.obs;
  final canManageBills = false.obs;
  final canEditMenuItems = false.obs;

  static const List<String> roleOptions = ['Secondary Admin', 'Biller'];

  @override
  void onClose() {
    userNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    super.onClose();
  }

  void selectRole(String role) {
    selectedRole.value = role;
    Get.back();
  }

  void showRolePicker() {
    final context = Get.context!;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    if (isWindows) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _RolePickerBottomSheet(controller: this, isDialog: true),
          ),
        ),
      );
    } else {
      Get.bottomSheet(
        _RolePickerBottomSheet(controller: this),
        isScrollControlled: true,
      );
    }
  }

  Future<void> sendInvite() async {
    final name = userNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneNumberController.text.trim();

    if (name.isEmpty) {
      showError(description: 'Please enter user name');
      return;
    }

    if (email.isEmpty) {
      showError(description: 'Please enter email');
      return;
    }

    final emailRegex = RegExp(r'^[\w\-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      showError(description: 'Please enter a valid email address');
      return;
    }

    if (phone.isEmpty) {
      showError(description: 'Please enter phone number');
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      showError(description: 'Please enter a valid 10-digit phone number');
      return;
    }

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null || outletId.isEmpty) {
      showError(description: 'No outlet selected');
      return;
    }

    final role = selectedRole.value == 'Secondary Admin'
        ? 'secondary_admin'
        : 'biller';

    final response = await callApi(
      apiClient.addStaff(outletId, {
        'userName': name,
        'email': email,
        'userPhoneNumber': '+91$phone',
        'userRole': role,
      }),
    );

    if (response == null) return;
    showSuccess(description: 'Invite sent successfully');
    Get.back();
  }
}

class _RolePickerBottomSheet extends StatelessWidget {
  const _RolePickerBottomSheet({
    required this.controller,
    this.isDialog = false,
  });
  final AddStaffController controller;
  final bool isDialog;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Obx(() {
      final currentRole = controller.selectedRole.value;
      final roleTiles = AddStaffController.roleOptions.map((role) {
        final selected = currentRole == role;
        return ListTile(
          selected: selected,
          tileColor: selected ? null : Colors.transparent,
          selectedTileColor: AppColor.primary.withValues(alpha: 0.15),
          title: Text(
            role == 'Secondary Admin'
                ? loc.secondary_admin
                : role == 'Biller'
                ? loc.biller
                : role,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : null,
              color: selected ? AppColor.primary : null,
            ),
          ),
          trailing: selected
              ? Icon(Icons.check_circle, color: AppColor.primary, size: 22)
              : null,
          onTap: () => controller.selectRole(role),
        );
      }).toList();

      if (isDialog) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'Select ${loc.user_role}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.grey.shade700),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...roleTiles,
              ],
            ),
          ),
        );
      }

      return Material(
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: Colors.grey.shade700),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select ${loc.user_role}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...roleTiles,
            ],
          ),
        ),
      );
    });
  }
}
