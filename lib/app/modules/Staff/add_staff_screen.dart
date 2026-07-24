import 'package:billkaro/app/Widgets/app_dropdowns.dart';
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

  bool _isWindows(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.windows;

  static const double _windowsMaxFormWidth = 920;

  @override
  void initState() {
    super.initState();
    // Recreate controller on each open so the form always starts fresh.
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

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    required bool isWin,
  }) {
    final theme = Theme.of(context);
    if (isWin) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      );
    }
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 16),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _labelRequired(AppLocalizations loc, String label) {
    return RichText(
      text: TextSpan(
        text: '$label ',
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: const [
          TextSpan(
            text: '*',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(
    BuildContext context,
    AppLocalizations loc,
    bool isWin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelRequired(loc, loc.email),
        const SizedBox(height: 8),
        Obx(() {
          final Widget? suffixIcon;
          final String? helperText;

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
          } else if (controller.emailVerificationError.value != null) {
            suffixIcon = Icon(
              Icons.info_outline_rounded,
              color: Colors.orange.shade700,
            );
            helperText = controller.emailVerificationError.value;
          } else if (controller.isEmailAvailable.value == false) {
            suffixIcon = Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            );
            helperText =
                'This email is already registered. Please use a different email.';
          } else {
            suffixIcon = null;
            helperText = null;
          }

          return TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            validator: controller.validateEmail,
            onChanged: controller.onEmailChanged,
            decoration: _fieldDecoration(
              context,
              hint: loc.tap_to_enter,
              isWin: isWin,
            ).copyWith(
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              helperText: helperText,
              helperStyle: TextStyle(
                color: controller.isEmailAvailable.value == false
                    ? Theme.of(context).colorScheme.error
                    : controller.emailVerificationError.value != null
                    ? Colors.orange.shade700
                    : controller.isEmailAvailable.value == true
                    ? AppColor.lightgreen
                    : Colors.grey.shade600,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _roleDropdown(BuildContext context, AppLocalizations loc, bool isWin) {
    return Obx(
      () => AppDropdownFormField2<String>(
        value: controller.selectedRole.value,
        decoration: _fieldDecoration(
          context,
          hint: loc.select_user_role,
          isWin: isWin,
        ),
        selectedItemBuilder: (context) => _roleSelectedItems(loc),
        items: AddStaffController.roleOptions
            .map(
              (role) =>
                  DropdownItem(value: role, child: Text(_roleLabel(loc, role))),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            controller.onRoleChanged(value);
          }
        },
      ),
    );
  }

  String _roleLabel(AppLocalizations loc, String role) {
    return role == 'Secondary Admin' ? loc.secondary_admin : loc.biller;
  }

  List<Widget> _roleSelectedItems(AppLocalizations loc) {
    return AddStaffController.roleOptions
        .map(
          (role) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(_roleLabel(loc, role), maxLines: 2, softWrap: true),
          ),
        )
        .toList();
  }

  Widget _buildStaffImageSection(
    BuildContext context,
    AppLocalizations loc,
    bool isWin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.staff_image,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final file = controller.selectedImage.value;
          final url = resolvedMediaUrl(controller.imageUrl.value);
          final uploading = controller.isUploadingImage.value;
          final hasImage = controller.hasStaffImage;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: uploading ? null : controller.pickStaffImage,
                    child: Container(
                      height: isWin ? 180 : 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isWin
                            ? Theme.of(context).colorScheme.surface
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(isWin ? 10 : 8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isWin ? 10 : 8),
                        child: uploading
                            ? const Center(child: CircularProgressIndicator())
                            : file != null
                            ? Image.file(
                                file,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : url.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorWidget: (_, __, ___) =>
                                    _buildImagePlaceholder(loc),
                              )
                            : _buildImagePlaceholder(loc),
                      ),
                    ),
                  ),
                  if (hasImage && !uploading)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: controller.removeStaffImage,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Tooltip(
                              message: loc.remove_image,
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (hasImage && !uploading) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: controller.removeStaffImage,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(loc.remove_image),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _buildImagePlaceholder(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 36,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text(
            loc.tap_to_upload_image,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(
    BuildContext context,
    AppLocalizations loc, {
    required bool isWin,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStaffImageSection(context, loc, isWin),
        SizedBox(height: isWin ? 20 : 24),
        _labelRequired(loc, loc.name_label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.userNameController,
          validator: controller.validateUserName,
          decoration: _fieldDecoration(
            context,
            hint: loc.tap_to_enter,
            isWin: isWin,
          ),
        ),
        SizedBox(height: isWin ? 20 : 24),
        _buildEmailField(context, loc, isWin),
        SizedBox(height: isWin ? 20 : 24),
        _labelRequired(loc, loc.mobile_number),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.phoneNumberController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          validator: controller.validatePhone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration:
              _fieldDecoration(
                context,
                hint: loc.tap_to_enter,
                isWin: isWin,
              ).copyWith(
                counterText: '',
                prefixText: '+91 ',
                prefixStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
        ),
        SizedBox(height: isWin ? 20 : 24),
        _labelRequired(loc, loc.address_label),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: 3,
          controller: controller.addressController,
          validator: controller.validateAddress,
          decoration: _fieldDecoration(
            context,
            hint: loc.tap_to_enter,
            isWin: isWin,
          ),
        ),
        SizedBox(height: isWin ? 20 : 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelRequired(loc, loc.state_label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.stateController,
                    validator: controller.validateState,
                    decoration: _fieldDecoration(
                      context,
                      hint: loc.tap_to_enter,
                      isWin: isWin,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelRequired(loc, loc.district_label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.districtController,
                    validator: controller.validateDistrict,
                    decoration: _fieldDecoration(
                      context,
                      hint: loc.tap_to_enter,
                      isWin: isWin,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isWin ? 20 : 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelRequired(loc, loc.pincode_label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.pincodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: controller.validatePincode,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _fieldDecoration(
                      context,
                      hint: loc.tap_to_enter,
                      isWin: isWin,
                    ).copyWith(counterText: ''),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelRequired(loc, loc.date_of_birth),
                  const SizedBox(height: 8),
                  Obx(() {
                    final showErrors = controller.showValidationErrors.value;
                    final dobError =
                        showErrors ? controller.validateDateOfBirth() : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: controller.pickDateOfBirth,
                            borderRadius: BorderRadius.circular(isWin ? 10 : 8),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isWin ? 14 : 16,
                                vertical: isWin ? 14 : 16,
                              ),
                              decoration: BoxDecoration(
                                color: isWin
                                    ? Theme.of(context).colorScheme.surface
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(
                                  isWin ? 10 : 8,
                                ),
                                border: Border.all(
                                  color: dobError != null
                                      ? Colors.red.shade300
                                      : (isWin
                                            ? Colors.grey[300]!
                                            : Colors.transparent),
                                ),
                              ),
                              child: Text(
                                controller.dateOfBirthLabel.isEmpty
                                    ? loc.dd_mm_yyyy
                                    : controller.dateOfBirthLabel,
                                style: TextStyle(
                                  color: controller.dateOfBirthLabel.isEmpty
                                      ? Colors.grey[400]
                                      : const Color(0xFF374151),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (dobError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            dobError,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isWin ? 20 : 24),
        _labelRequired(loc, loc.gender_label),
        const SizedBox(height: 8),
        Obx(() {
          final showErrors = controller.showValidationErrors.value;
          final genderError = showErrors
              ? controller.validateGender(
                  controller.selectedGender.value.isEmpty
                      ? null
                      : controller.selectedGender.value,
                )
              : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDropdownFormField2<String>(
                value: controller.selectedGender.value.isEmpty
                    ? null
                    : controller.selectedGender.value,
                hint: Text(
                  loc.select_gender,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                decoration: _fieldDecoration(
                  context,
                  hint: loc.select_gender,
                  isWin: isWin,
                ).copyWith(errorText: genderError),
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
              ),
            ],
          );
        }),
      ],
    );
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

  Widget _buildRoleSection(
    BuildContext context,
    AppLocalizations loc,
    bool isWin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelRequired(loc, loc.user_role),
        const SizedBox(height: 8),
        _roleDropdown(context, loc, isWin),
        SizedBox(height: isWin ? 20 : 32),
        StaffPermissionsSection(
          selected: controller.selectedPermissions,
          onToggle: controller.togglePermission,
          onSelectAll: controller.selectAllPermissions,
          onDeselectAll: controller.deselectAllPermissions,
        ),
        SizedBox(height: isWin ? 12 : 16),
        Obx(
          () => controller.selectedRole.value == 'Biller'
              ? billerOverView(context, loc, isWin)
              : secondaryAdminOverView(context, isWin),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isWin = _isWindows(context);

    final isEditMode = controller.isEditMode;

    return Scaffold(
      appBar: AppBar(
        elevation: isWin ? 0 : 0,
        scrolledUnderElevation: isWin ? 0 : null,
        toolbarHeight: isWin ? 48 : kToolbarHeight,
        title: Text(
          isEditMode ? loc.edit_staff : loc.add_staff,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = isWin ? _windowsMaxFormWidth : double.infinity;
                final isWide = isWin && constraints.maxWidth >= 960;

                final formContent = Form(
                  key: controller.formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildFormFields(
                                context,
                                loc,
                                isWin: isWin,
                              ),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              child: _buildRoleSection(context, loc, isWin),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormFields(context, loc, isWin: isWin),
                            SizedBox(height: isWin ? 20 : 24),
                            _buildRoleSection(context, loc, isWin),
                          ],
                        ),
                );

                final cardBody = Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 26 : 22),
                    child: formContent,
                  ),
                );

                final scrollChild = isWin
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isWide) ...[
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColor.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColor.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.group_add_outlined,
                                    color: AppColor.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEditMode
                                            ? loc.edit_staff
                                            : loc.add_staff,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isEditMode
                                            ? loc.update_team_member_subtitle
                                            : loc.invite_team_member_subtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.grey.shade700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(color: Colors.grey.shade200, height: 1),
                            const SizedBox(height: 20),
                          ],
                          cardBody,
                        ],
                      )
                    : formContent;

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: isWin,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: isWin
                        ? const ClampingScrollPhysics()
                        : const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isWin ? 28 : 16,
                      vertical: isWin ? 20 : 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: scrollChild,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWin ? 28 : 16,
              vertical: isWin ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: isWin
                  ? Border(
                      top: BorderSide(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    )
                  : null,
              boxShadow: isWin
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWin ? _windowsMaxFormWidth : double.infinity,
                ),
                child: Align(
                  alignment: isWin ? Alignment.centerRight : Alignment.center,
                  child: SizedBox(
                    width: isWin ? 220 : double.infinity,
                    child: ElevatedButton(
                      onPressed: isEditMode
                          ? () => controller.onUpdateStaff(context)
                          : () => controller.sendInvite(context),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: isWin ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isWin ? 10 : 8),
                        ),
                      ),
                      child: Text(
                        isEditMode ? loc.update_staff : loc.send_invite,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget secondaryAdminOverView(BuildContext context, bool isWin) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(isWin ? 18 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(isWin ? 10 : 8),
        border: isWin ? Border.all(color: Colors.grey.shade200) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.role_overview,
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

  Widget billerOverView(
    BuildContext context,
    AppLocalizations loc,
    bool isWin,
  ) {
    return Container(
      padding: EdgeInsets.all(isWin ? 18 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(isWin ? 10 : 8),
        border: isWin ? Border.all(color: Colors.grey.shade200) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.role_overview,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          Gap(10),
          overView(1, loc.biller_overview_create_orders),
          overView(2, loc.biller_overview_view_items),
          overView(3, loc.biller_overview_cannot_delete),
          overView(4, loc.biller_overview_cannot_access_others),
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
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
      ],
    );
  }
}
