import 'package:billkaro/app/modules/Staff/widgets/staff_permissions_section.dart';
import 'package:billkaro/app/modules/StaffProfile/staff_profile_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_permission_keys.dart';
import 'package:flutter/material.dart' show Image;

class StaffProfileScreen extends StatelessWidget {
  StaffProfileScreen({super.key});

  // late final StaffProfileController controller = _createController();
  final StaffProfileController controller = Get.put(StaffProfileController());
  // static StaffProfileController _createController() {
  //   if (Get.isRegistered<StaffProfileController>()) {
  //     Get.delete<StaffProfileController>(force: true);
  //   }
  //   return Get.put(StaffProfileController());
  // }

  static const _bg = Color(0xFFF4F7FC);
  static const _cardBorder = Color(0xFFE8EEF5);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Obx(() {
            if (controller.isLoadingProfile.value) {
              return const SizedBox.shrink();
            }
            if (controller.isEditMode.value) {
              return TextButton(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.cancelEdit,
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return IconButton(
              tooltip: 'Edit',
              onPressed: controller.enterEditMode,
              icon: const Icon(Icons.edit_outlined),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingProfile.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.loadProfile,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _PhotoCard(controller: controller),
                        const SizedBox(height: 14),
                        _SummaryCard(controller: controller),
                        const SizedBox(height: 14),
                        if (controller.isEditMode.value)
                          _EditForm(controller: controller)
                        else
                          _ViewDetails(controller: controller),
                        const SizedBox(height: 14),
                        _PermissionsCard(controller: controller),
                      ],
                    ),
                  ),
                ),
                if (controller.isEditMode.value)
                  _SaveBar(controller: controller),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.controller});

  final StaffProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StaffProfileScreen._cardBorder),
      ),
      child: Obx(() {
        final file = controller.selectedImage.value;
        final url = resolvedMediaUrl(controller.imageUrl.value);
        final uploading = controller.isUploadingImage.value;
        final canEdit = controller.isEditMode.value;

        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: canEdit && !uploading
                      ? controller.pickProfileImage
                      : null,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF1F5F9),
                      border: Border.all(
                        color: AppColor.primary.withOpacity(0.2),
                        width: 3,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: file != null
                        ? Image.file(file, fit: BoxFit.cover)
                        : url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.person, size: 48),
                          )
                        : Icon(
                            Icons.person,
                            size: 48,
                            color: AppColor.primary.withOpacity(0.45),
                          ),
                  ),
                ),
                if (canEdit)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: AppColor.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: uploading ? null : controller.pickProfileImage,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              controller.displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: StaffProfileScreen._textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.roleLabel,
              style: const TextStyle(
                fontSize: 14,
                color: StaffProfileScreen._textSecondary,
              ),
            ),
            if (canEdit &&
                (file != null || controller.imageUrl.value.isNotEmpty)) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: uploading ? null : controller.removeProfileImage,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove photo'),
              ),
            ],
            if (uploading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
          ],
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final StaffProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: StaffProfileScreen._cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: 'Outlet',
                value: controller.outletName.value.isEmpty
                    ? '—'
                    : controller.outletName.value,
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: StaffProfileScreen._cardBorder,
            ),
            Expanded(
              child: _SummaryItem(
                label: 'Status',
                value: controller.isActivated.value ? 'Active' : 'Inactive',
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: StaffProfileScreen._cardBorder,
            ),
            Expanded(
              child: _SummaryItem(
                label: 'Permissions',
                value: '${controller.permissions.length}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: StaffProfileScreen._textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: StaffProfileScreen._textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ViewDetails extends StatelessWidget {
  const _ViewDetails({required this.controller});

  final StaffProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          _Section(
            title: 'Contact',
            icon: Icons.contact_mail_outlined,
            children: [
              _InfoTile(
                icon: Icons.badge_outlined,
                label: 'Unique ID',
                value: controller.uniqueIdController.text,
              ),
              _InfoTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: controller.emailController.text,
              ),
              _InfoTile(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: controller.phoneNumberController.text.isEmpty
                    ? ''
                    : '+91 ${controller.phoneNumberController.text}',
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Address',
            icon: Icons.location_on_outlined,
            children: [
              _InfoTile(
                icon: Icons.home_outlined,
                label: 'Address',
                value: controller.addressController.text,
              ),
              _InfoTile(
                icon: Icons.map_outlined,
                label: 'State',
                value: controller.locationPicker.selectedStateName.value ?? '',
              ),
              _InfoTile(
                icon: Icons.place_outlined,
                label: 'District',
                value: controller.locationPicker.selectedCityName.value ?? '',
              ),
              _InfoTile(
                icon: Icons.pin_drop_outlined,
                label: 'Pincode',
                value: controller.pincodeController.text,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Personal',
            icon: Icons.person_outline,
            children: [
              _InfoTile(
                icon: Icons.cake_outlined,
                label: 'Date of birth',
                value: controller.dateOfBirthLabel,
              ),
              _InfoTile(
                icon: Icons.wc_outlined,
                label: 'Gender',
                value: controller.selectedGender.value,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({required this.controller});

  final StaffProfileController controller;

  @override
  Widget build(BuildContext context) {
    final location = controller.locationPicker;

    return Column(
      children: [
        _Section(
          title: 'Contact',
          icon: Icons.contact_mail_outlined,
          children: [
            _LabeledField(
              label: 'Full name',
              child: TextField(
                controller: controller.userNameController,
                decoration: _decoration('Enter your name'),
              ),
            ),
            _LabeledField(
              label: 'Unique ID',
              child: TextField(
                controller: controller.uniqueIdController,
                decoration: _decoration('Unique ID'),
              ),
            ),
            _LabeledField(
              label: 'Email',
              child: TextField(
                controller: controller.emailController,
                enabled: false,
                decoration: _decoration(
                  'Email',
                ).copyWith(fillColor: const Color(0xFFF8FAFC), filled: true),
              ),
            ),
            _LabeledField(
              label: 'Phone',
              isLast: true,
              child: TextField(
                controller: controller.phoneNumberController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _decoration(
                  '10-digit mobile',
                ).copyWith(counterText: '', prefixText: '+91 '),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Address',
          icon: Icons.location_on_outlined,
          children: [
            _LabeledField(
              label: 'Address',
              child: TextField(
                controller: controller.addressController,
                maxLines: 2,
                decoration: _decoration('Address'),
              ),
            ),
            Obx(() {
              final stateValue = location.selectedStateName.value;
              return _LabeledField(
                label: 'State',
                child: DropdownButtonFormField<String>(
                  value:
                      stateValue != null &&
                          location.stateNames.contains(stateValue)
                      ? stateValue
                      : null,
                  items: location.stateNames
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: location.onStateNameChanged,
                  decoration: _decoration('Select state'),
                  isExpanded: true,
                ),
              );
            }),
            Obx(() {
              final cityValue = location.selectedCityName.value;
              return _LabeledField(
                label: 'District',
                child: DropdownButtonFormField<String>(
                  value:
                      cityValue != null &&
                          location.cityNames.contains(cityValue)
                      ? cityValue
                      : null,
                  items: location.cityNames
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: location.hasStateSelected
                      ? location.selectCity
                      : null,
                  decoration: _decoration('Select district'),
                  isExpanded: true,
                ),
              );
            }),
            _LabeledField(
              label: 'Pincode',
              isLast: true,
              child: TextField(
                controller: controller.pincodeController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Pincode'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Personal',
          icon: Icons.person_outline,
          children: [
            _LabeledField(
              label: 'Date of birth',
              child: Obx(
                () => InkWell(
                  onTap: controller.pickDateOfBirth,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _decoration('Select date'),
                    child: Text(
                      controller.dateOfBirthLabel.isEmpty
                          ? 'Select date'
                          : controller.dateOfBirthLabel,
                      style: TextStyle(
                        color: controller.dateOfBirthLabel.isEmpty
                            ? StaffProfileScreen._textSecondary
                            : StaffProfileScreen._textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _LabeledField(
              label: 'Gender',
              isLast: true,
              child: Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedGender.value.isEmpty
                      ? null
                      : controller.selectedGender.value,
                  items: StaffProfileController.genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) {
                    controller.selectedGender.value = value ?? '';
                  },
                  decoration: _decoration('Select gender'),
                  isExpanded: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: StaffProfileScreen._textSecondary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: StaffProfileScreen._cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: StaffProfileScreen._cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColor.primary),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.controller});

  final StaffProfileController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Obx(
          () => SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed:
                  controller.isSaving.value || controller.isUploadingImage.value
                  ? null
                  : controller.saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save changes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StaffProfileScreen._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColor.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: StaffProfileScreen._textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 6 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: StaffProfileScreen._textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: StaffProfileScreen._textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  display,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: StaffProfileScreen._textPrimary,
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.isLast = false,
  });

  final String label;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: StaffProfileScreen._textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// Read-only permissions for the logged-in staff member.
class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({required this.controller});

  final StaffProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isSecondaryAdmin) {
        return const StaffFullAccessPermissionsCard();
      }

      final granted = expandStaffPermissions(controller.permissions);
      final groups = <({String title, List<String> labels})>[];
      var grantedCount = 0;

      for (final group in kStaffPermissionGroups) {
        final labels = <String>[];
        for (final item in group.items) {
          if (item.isGranted(granted)) {
            labels.add(item.label);
            grantedCount++;
          }
        }
        if (labels.isNotEmpty) {
          groups.add((title: group.title, labels: labels));
        }
      }

      final total = kStaffPermissionCatalogSize;
      final progress = total == 0
          ? 0.0
          : (grantedCount / total).clamp(0.0, 1.0);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: StaffProfileScreen._cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security_outlined,
                  size: 18,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Permissions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: StaffProfileScreen._textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$grantedCount / $total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppColor.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
              ),
            ),
            const SizedBox(height: 14),
            if (groups.isEmpty)
              Text(
                'No permissions assigned',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              )
            else
              ...groups.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: StaffProfileScreen._textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final label in group.labels)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColor.primary.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: AppColor.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
