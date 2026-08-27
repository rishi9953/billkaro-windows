import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/Widgets/searchable_string_dropdown.dart';
import 'package:billkaro/app/modules/Staff/add_staff_controller.dart';
import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/app/modules/Staff/widgets/staff_permissions_section.dart';
import 'package:billkaro/config/config.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart' show Image;
import 'package:flutter_modular/flutter_modular.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  late final AddStaffController controller;
  final ScrollController _scrollController = ScrollController();

  static const double _maxFormWidth = 1080;
  static const _pageBg = Color(0xFFE8EEF7);
  static const _fieldFill = Color(0xFFF8FAFC);
  static const _labelColor = Color(0xFF64748B);
  static const _hintColor = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AddStaffController>()) {
      Get.delete<AddStaffController>(force: true);
    }
    controller = Get.put(AddStaffController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareScreen());
  }

  void _prepareScreen() {
    if (!mounted) return;
    final rawArgs = Get.arguments ?? Modular.args.data;
    controller.prepareScreen(rawArgs is StaffMember ? rawArgs : null);
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isEditMode = controller.isEditMode;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 48,
        title: Text(
          isEditMode ? loc.edit_staff : loc.add_staff,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960;

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: _maxFormWidth),
                        child: Form(
                          key: controller.formKey,
                          autovalidateMode: AutovalidateMode.disabled,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PageHeader(
                                isEditMode: isEditMode,
                                title: isEditMode
                                    ? loc.edit_staff
                                    : loc.add_staff,
                                subtitle: isEditMode
                                    ? loc.update_team_member_subtitle
                                    : loc.invite_team_member_subtitle,
                              ),
                              const SizedBox(height: 18),
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildLeftColumn(loc)),
                                    const SizedBox(width: 18),
                                    Expanded(child: _buildRightColumn(loc)),
                                  ],
                                )
                              else ...[
                                _buildLeftColumn(loc),
                                const SizedBox(height: 18),
                                _buildRightColumn(loc),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _FooterBar(
            cancelLabel: loc.cancel,
            submitLabel: isEditMode ? loc.update_staff : loc.send_invite,
            onCancel: () => Modular.to.pop(),
            onSubmit: isEditMode
                ? () => controller.onUpdateStaff(context)
                : () => controller.sendInvite(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfilePhotoCard(controller: controller, loc: loc),
        const SizedBox(height: 14),
        _SectionCard(
          icon: Icons.badge_outlined,
          title: 'Basic details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(loc.name_label, required: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.userNameController,
                validator: controller.validateUserName,
                decoration: _decoration(loc.tap_to_enter),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          icon: Icons.contact_mail_outlined,
          title: 'Contact',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmailField(loc),
              const SizedBox(height: 16),
              _FieldLabel(loc.mobile_number, required: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.phoneNumberController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: controller.validatePhone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration(loc.tap_to_enter).copyWith(
                  counterText: '',
                  prefixText: '+91 ',
                  prefixStyle: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          icon: Icons.location_on_outlined,
          title: loc.address_label,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(loc.address_label, required: true),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                controller: controller.addressController,
                validator: controller.validateAddress,
                decoration: _decoration(loc.tap_to_enter),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final location = controller.locationPicker;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(loc.state_label, required: true),
                    const SizedBox(height: 8),
                    SearchableStringDropdown(
                      items: location.stateNames,
                      value: location.selectedStateName.value,
                      isLoading: location.isLoadingStates.value,
                      hintText: loc.tap_to_enter,
                      searchHint: loc.state_label,
                      decoration: _decoration(loc.tap_to_enter),
                      validator: controller.validateState,
                      onChanged: location.onStateNameChanged,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(loc.district_label, required: true),
                    const SizedBox(height: 8),
                    SearchableStringDropdown(
                      items: location.cityNames,
                      value: location.selectedCityName.value,
                      isLoading: location.isLoadingCities.value,
                      enabled: location.hasStateSelected,
                      hintText: loc.tap_to_enter,
                      searchHint: loc.district_label,
                      decoration: _decoration(loc.tap_to_enter),
                      validator: controller.validateDistrict,
                      onChanged: location.selectCity,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(loc.pincode_label, required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.pincodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: controller.validatePincode,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _decoration(loc.tap_to_enter).copyWith(
                        counterText: '',
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          icon: Icons.person_outline,
          title: 'Personal',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(loc.date_of_birth, required: true),
                        const SizedBox(height: 8),
                        _DobField(controller: controller, loc: loc),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(loc.gender_label, required: true),
                        const SizedBox(height: 8),
                        Obx(() {
                          final showErrors =
                              controller.showValidationErrors.value;
                          final genderError = showErrors
                              ? controller.validateGender(
                                  controller.selectedGender.value.isEmpty
                                      ? null
                                      : controller.selectedGender.value,
                                )
                              : null;
                          return AppDropdownFormField2<String>(
                            value: controller.selectedGender.value.isEmpty
                                ? null
                                : controller.selectedGender.value,
                            hint: Text(
                              loc.select_gender,
                              style: const TextStyle(color: _hintColor),
                            ),
                            decoration: _decoration(loc.select_gender).copyWith(
                              errorText: genderError,
                            ),
                            items: AddStaffController.genderOptions
                                .map(
                                  (gender) => DropdownItem(
                                    value: gender,
                                    child: Text(_genderLabel(loc, gender)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              controller.selectedGender.value = value ?? '';
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          icon: Icons.workspace_premium_outlined,
          title: loc.user_role,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0;
                          i < controller.availableRoleOptions.length;
                          i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _RoleCard(
                            title: _roleLabel(
                              loc,
                              controller.availableRoleOptions[i],
                            ),
                            subtitle:
                                controller.availableRoleOptions[i] ==
                                    'Secondary Admin'
                                ? 'Full outlet management'
                                : 'POS & billing focused',
                            icon: controller.availableRoleOptions[i] ==
                                    'Secondary Admin'
                                ? Icons.admin_panel_settings_outlined
                                : Icons.point_of_sale_outlined,
                            selected: controller.selectedRole.value ==
                                controller.availableRoleOptions[i],
                            onTap: controller.canChangeStaffRole
                                ? () => controller.onRoleChanged(
                                      controller.availableRoleOptions[i],
                                    )
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => _RoleOverview(
                  isBiller: controller.selectedRole.value == 'Biller',
                  loc: loc,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Obx(
          () {
            if (controller.selectedRole.value == 'Secondary Admin') {
              return const StaffPermissionsSection(hasFullAccess: true);
            }
            final permissionError = controller.showValidationErrors.value
                ? controller.validatePermissions()
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StaffPermissionsSection(
                  hasFullAccess: false,
                  selected: controller.selectedPermissions,
                  onToggle: controller.togglePermission,
                  onSelectAll: controller.selectAllPermissions,
                  onDeselectAll: controller.deselectAllPermissions,
                ),
                // Simple error: permissions should not be empty
                if (permissionError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    permissionError,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmailField(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(loc.email, required: true),
        const SizedBox(height: 8),
        Obx(() {
          final Widget? suffixIcon;
          final String? helperText;
          Color helperColor = Colors.grey.shade600;

          if (controller.isEmailChecking.value) {
            suffixIcon = Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColor.primary,
                ),
              ),
            );
            helperText = 'Checking email availability...';
          } else if (controller.isEmailAvailable.value == true) {
            suffixIcon = const Icon(
              Icons.check_circle_rounded,
              color: AppColor.lightgreen,
            );
            helperText = 'Email is available';
            helperColor = AppColor.lightgreen;
          } else if (controller.emailVerificationError.value != null) {
            suffixIcon = Icon(
              Icons.info_outline_rounded,
              color: Colors.orange.shade700,
            );
            helperText = controller.emailVerificationError.value;
            helperColor = Colors.orange.shade700;
          } else if (controller.isEmailAvailable.value == false) {
            suffixIcon = Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            );
            helperText =
                'This email is already registered. Please use a different email.';
            helperColor = Theme.of(context).colorScheme.error;
          } else {
            suffixIcon = null;
            helperText = null;
          }

          return TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            validator: controller.validateEmail,
            onChanged: controller.onEmailChanged,
            decoration: _decoration(loc.tap_to_enter).copyWith(
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              helperText: helperText,
              helperStyle: TextStyle(color: helperColor, fontSize: 12),
            ),
          );
        }),
      ],
    );
  }

  String _roleLabel(AppLocalizations loc, String role) {
    return role == 'Secondary Admin' ? loc.secondary_admin : loc.biller;
  }

  String _genderLabel(AppLocalizations loc, String gender) {
    switch (gender) {
      case 'Male':
        return loc.male;
      case 'Female':
        return loc.female;
      case 'Other':
        return loc.other_gender;
      default:
        return gender;
    }
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
      filled: true,
      fillColor: _fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: AppColor.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isEditMode,
    required this.title,
    required this.subtitle,
  });

  final bool isEditMode;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEditMode ? Icons.edit_outlined : Icons.group_add_outlined,
              color: AppColor.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColor.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: _AddStaffScreenState._labelColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhotoCard extends StatelessWidget {
  const _ProfilePhotoCard({
    required this.controller,
    required this.loc,
  });

  final AddStaffController controller;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Obx(() {
        final file = controller.selectedImage.value;
        final url = resolvedMediaUrl(controller.imageUrl.value);
        final uploading = controller.isUploadingImage.value;
        final hasImage = controller.hasStaffImage;

        return Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: uploading ? null : controller.pickStaffImage,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF1F5F9),
                      border: Border.all(
                        color: AppColor.primary.withValues(alpha: 0.2),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: uploading
                          ? const Center(child: CircularProgressIndicator())
                          : file != null
                              ? Image.file(file, fit: BoxFit.cover)
                              : url.isNotEmpty
                                  ? AppCachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          _placeholder(),
                                    )
                                  : _placeholder(),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: AppColor.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: uploading ? null : controller.pickStaffImage,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.staff_image,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.tap_to_upload_image,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (hasImage && !uploading) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: controller.removeStaffImage,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(loc.remove_image),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.person_outline, size: 40, color: Colors.grey.shade400),
    );
  }
}

class _DobField extends StatelessWidget {
  const _DobField({required this.controller, required this.loc});

  final AddStaffController controller;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final showErrors = controller.showValidationErrors.value;
      final dobError = showErrors ? controller.validateDateOfBirth() : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: controller.pickDateOfBirth,
              borderRadius: BorderRadius.circular(11),
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _AddStaffScreenState._fieldFill,
                  errorText: dobError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(
                      color: dobError != null
                          ? Colors.red.shade300
                          : _AddStaffScreenState._border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(
                      color: dobError != null
                          ? Colors.red.shade300
                          : _AddStaffScreenState._border,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ),
                child: Text(
                  controller.dateOfBirthLabel.isEmpty
                      ? loc.dd_mm_yyyy
                      : controller.dateOfBirthLabel,
                  style: TextStyle(
                    color: controller.dateOfBirthLabel.isEmpty
                        ? _AddStaffScreenState._hintColor
                        : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColor.primary.withValues(alpha: 0.06)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColor.primary : Colors.grey.shade300,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColor.primary : Colors.grey.shade600,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColor.primary : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOverview extends StatelessWidget {
  const _RoleOverview({required this.isBiller, required this.loc});

  final bool isBiller;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColor.primary),
              const SizedBox(width: 6),
              Text(
                loc.role_overview,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColor.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isBiller)
            Text(
              loc.staff_access_info,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.45,
              ),
            )
          else ...[
            _bullet(loc.biller_overview_create_orders),
            _bullet(loc.biller_overview_view_items),
            _bullet(loc.biller_overview_cannot_delete),
            _bullet(loc.biller_overview_cannot_access_others),
          ],
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.cancelLabel,
    required this.submitLabel,
    required this.onCancel,
    required this.onSubmit,
  });

  final String cancelLabel;
  final String submitLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _AddStaffScreenState._maxFormWidth,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  side: BorderSide(
                    color: AppColor.primary.withValues(alpha: 0.35),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(cancelLabel),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    submitLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
