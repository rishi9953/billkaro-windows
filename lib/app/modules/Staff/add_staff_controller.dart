// Controller
import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AddStaffController extends BaseController {
  StaffMember? editingStaff;

  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final selectedRole = 'Secondary Admin'.obs;
  final canManageBills = false.obs;
  final canEditMenuItems = false.obs;

  static const List<String> roleOptions = ['Secondary Admin', 'Biller'];

  bool get isEditMode => editingStaff != null;

  @override
  void onInit() {
    _hydrateFromArgs();
    super.onInit();
  }

  @override
  void onClose() {
    userNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    super.onClose();
  }

  void _hydrateFromArgs() {
    final dynamic rawArgs = Get.arguments ?? Modular.args.data;
    if (rawArgs is StaffMember) {
      editingStaff = rawArgs;
      userNameController.text = rawArgs.name;
      emailController.text = rawArgs.email;
      phoneNumberController.text = _normalizePhone(rawArgs.phone);
      selectedRole.value = _normalizeRole(rawArgs.role);
      final permissions =
          rawArgs.permissions.map((item) => item.trim()).toSet();
      canManageBills.value = permissions.contains('create_bill');
      canEditMenuItems.value = permissions.contains('edit_menu');
    }
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
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }

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
    final permissions = _buildPermissions(role);

    final response = await callApi(
      apiClient.addStaff(outletId, {
        'userName': name,
        'email': email,
        'userPhoneNumber': '+91$phone',
        'userRole': role,
        'permissions': permissions,
      }),
    );

    if (response == null) return;
    _popWithResult({'created': true, 'message': 'Invite sent successfully'});
  }

  Future<void> onUpdateStaff() async {
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }

    final name = userNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneNumberController.text.trim();
    final staffId = editingStaff?.id.trim() ?? '';

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

    if (staffId.isEmpty) {
      showError(description: 'Unable to update staff member');
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
    final permissions = _buildPermissions(role);

    final response = await callApi(
      apiClient.updateStaff(outletId, staffId, {
        'userName': name,
        'email': email,
        'userPhoneNumber': '+91$phone',
        'userRole': role,
        'permissions': permissions,
      }),
    );
    if (response == null) return;
    _popWithResult({
      'updated': true,
      'message': 'Staff member updated successfully',
    });
  }

  void _popWithResult(Map<String, dynamic> result) {
    if (Modular.to.canPop()) {
      Modular.to.pop(result);
    } else {
      Get.back(result: result);
    }
  }

  String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase().replaceAll('_', ' ');
    if (normalized == 'secondary admin') return 'Secondary Admin';
    if (normalized == 'biller') return 'Biller';
    return role.isEmpty ? 'Secondary Admin' : role;
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  List<String> _buildPermissions(String role) {
    if (role == 'secondary_admin') {
      return <String>['create_bill', 'view_reports'];
    }

    final permissions = <String>[];
    if (canManageBills.value) {
      permissions.add('create_bill');
    }
    if (canEditMenuItems.value) {
      permissions.add('edit_menu');
    }
    return permissions;
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
