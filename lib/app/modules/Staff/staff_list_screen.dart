import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/app/modules/Staff/staff_view_dialog.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class StaffListScreen extends StatelessWidget {
  const StaffListScreen({super.key});

  bool _isWindows(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StaffDetailsController>();
    final isWindows = _isWindows(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          loc.manage_staff,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          // Refresh button for Windows platform
          IconButton(
            onPressed: controller.loadStaffList,
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
          ),
        ],
      ),
      body: _buildWindowsLayout(context, controller, loc),
    );
  }

  // ---------------------------------------------------------------------------
  // WINDOWS LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildWindowsLayout(
    BuildContext context,
    StaffDetailsController controller,
    AppLocalizations loc,
  ) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.loadStaffList,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WindowsHeaderCard(
                          onActivityTap: () => Modular.to.pushNamed(
                            HomeMainRoutes.staffActivityScreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      loc.staff_list_title,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 360,
                                    child: _SearchField(
                                      controller: controller,
                                      isWindows: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.manage_outlet_staff_access,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Obx(() {
                                if (controller.isLoading.value &&
                                    controller.staffList.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 50),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final members = controller.filteredStaff;
                                final isSearching = controller.searchQuery.value
                                    .trim()
                                    .isNotEmpty;
                                if (members.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                    ),
                                    child: _EmptyStaffState(
                                      isSearching: isSearching,
                                      onInviteTap: isSearching
                                          ? null
                                          : controller.onAddStaff,
                                    ),
                                  );
                                }
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _windowsHeaderRow(loc),
                                    const SizedBox(height: 8),
                                    ...members.map(
                                      (member) => _WindowsStaffRow(
                                        member: member,
                                        controller: controller,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomButton(context, controller, loc),
      ],
    );
  }

  Widget _windowsHeaderRow(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              loc.name_label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              loc.role_label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              loc.phone_label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              loc.email,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              loc.status,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              loc.actions,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildBottomButton(
    BuildContext context,
    StaffDetailsController controller,
    AppLocalizations loc,
  ) {
    final isWindows = _isWindows(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWindows ? 28 : 16,
        vertical: isWindows ? 16 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Align(
        alignment: isWindows ? Alignment.centerRight : Alignment.center,
        child: SizedBox(
          width: isWindows ? 320 : double.infinity,
          height: isWindows ? 48 : 56,
          child: ElevatedButton.icon(
            onPressed: controller.onAddStaff,
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(
              loc.invite_staff,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.isWindows});

  final StaffDetailsController controller;
  final bool isWindows;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: isWindows
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          isDense: isWindows,
          hintText: loc.search_staff_hint,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: isWindows ? Colors.white : const Color(0xFFF9FAFB),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isWindows ? 12 : 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: isWindows
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: isWindows
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColor.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _StaffActivityEntry extends StatelessWidget {
  const _StaffActivityEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(Icons.people_alt_outlined, color: Colors.blueGrey.shade700),
              const SizedBox(width: 10),
              Text(
                loc.check_staff_activity,
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.blueGrey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowsHeaderCard extends StatelessWidget {
  const _WindowsHeaderCard({required this.onActivityTap});
  final VoidCallback onActivityTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onActivityTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people_alt_outlined, color: AppColor.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.check_staff_activity,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.staff_activity_filter_hint,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.blueGrey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.member, required this.controller});
  final StaffMember member;
  final StaffDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final roleTitle = _localizedRoleTitle(loc, member.role);
    final isSecondaryAdmin = _isSecondaryAdminRole(member.role);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColor.primary.withValues(alpha: 0.12),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColor.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name.isEmpty ? '-' : member.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RoleChip(
                      title: roleTitle,
                      isSecondaryAdmin: isSecondaryAdmin,
                    ),
                    _StatusChip(isActive: member.isActive),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  member.phone.isEmpty ? '-' : member.phone,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email.isEmpty ? '-' : member.email,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                if (_isBillerRole(member.role)) ...[
                  const SizedBox(height: 10),
                  _BillerPermissionsSection(
                    permissions: member.permissions,
                    loc: loc,
                  ),
                ],
              ],
            ),
          ),
          _StaffActionMenu(member: member, controller: controller),
        ],
      ),
    );
  }
}

class _WindowsStaffRow extends StatelessWidget {
  const _WindowsStaffRow({required this.member, required this.controller});
  final StaffMember member;
  final StaffDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final roleTitle = _localizedRoleTitle(loc, member.role);
    final isSecondaryAdmin = _isSecondaryAdminRole(member.role);
    final isBiller = _isBillerRole(member.role);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColor.primary.withValues(alpha: 0.12),
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        member.name.isEmpty ? '-' : member.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: _RoleChip(
                  title: roleTitle,
                  isSecondaryAdmin: isSecondaryAdmin,
                  compact: true,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  member.phone.isEmpty ? '-' : member.phone,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  member.email.isEmpty ? '-' : member.email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
              Expanded(
                child: Center(child: _StatusChip(isActive: member.isActive)),
              ),
              SizedBox(
                width: 56,
                child: Center(
                  child: _StaffActionMenu(
                    member: member,
                    controller: controller,
                    isWindows: true,
                  ),
                ),
              ),
            ],
          ),
          if (isBiller) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 10),
            _BillerPermissionsSection(permissions: member.permissions, loc: loc),
          ],
        ],
      ),
    );
  }
}

class _StaffActionMenu extends StatelessWidget {
  const _StaffActionMenu({
    required this.member,
    required this.controller,
    this.isWindows = false,
  });
  final StaffMember member;
  final StaffDetailsController controller;
  final bool isWindows;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Obx(() {
      final staffId = member.id.trim();
      final deleting =
          staffId.isNotEmpty && controller.deletingStaffIds.contains(staffId);
      final reinviting =
          staffId.isNotEmpty && controller.reinvitingStaffIds.contains(staffId);
      if (deleting || reinviting) {
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      return AppActionDropdown2<String>(
        width: isWindows ? 180 : 160,
        customButton: Icon(
          Icons.more_vert,
          size: isWindows ? 20 : 22,
          color: isWindows ? Colors.grey.shade700 : null,
        ),
        items: [
          DropdownItem(
            value: 'view',
            height: 44,
            child: _staffActionMenuItem(
              icon: Icons.visibility_outlined,
              label: loc.view,
              iconColor: Colors.blueGrey.shade700,
            ),
          ),
          if (!member.isActive)
            DropdownItem(
              value: 'reinvite',
              height: 44,
              child: _staffActionMenuItem(
                icon: Icons.mail_outline,
                label: loc.reinvite,
                iconColor: Colors.orange.shade800,
              ),
            ),
          DropdownItem(
            value: 'edit',
            height: 44,
            child: _staffActionMenuItem(
              icon: Icons.edit_outlined,
              label: loc.edit,
              iconColor: AppColor.primary,
            ),
          ),
          DropdownItem(
            value: 'remove',
            height: 44,
            child: _staffActionMenuItem(
              icon: Icons.delete_outline,
              label: loc.remove,
              iconColor: Colors.red,
            ),
          ),
        ],
        onChanged: (value) async {
          if (value == 'view') {
            await showStaffViewDialog(context, member);
            return;
          }
          if (value == 'reinvite') {
            await controller.reinviteStaff(member);
            return;
          }
          if (value == 'edit') {
            await controller.onEditStaff(member);
            return;
          }
          if (value == 'remove') {
            await _confirmDelete(context, member, loc);
          }
        },
      );
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StaffMember member,
    AppLocalizations loc,
  ) async {
    final staffId = member.id.trim();
    if (staffId.isEmpty) {
      showError(description: loc.unable_to_delete_staff_entry);
      return;
    }

    final shouldDelete =
        await Get.dialog<bool>(
          AlertDialog(
            title: Text(loc.remove_staff),
            content: Text(
              loc.remove_staff_confirm(
                member.name.isEmpty ? loc.this_staff : member.name,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(loc.remove),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) return;
    await controller.deleteStaffById(staffId);
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.title,
    required this.isSecondaryAdmin,
    this.compact = false,
  });
  final String title;
  final bool isSecondaryAdmin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bg = isSecondaryAdmin
        ? const Color(0xFFDBEAFE)
        : const Color(0xFFEDE9FE);
    final fg = isSecondaryAdmin
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF7C3AED);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        softWrap: true,
        maxLines: 2,
        style: TextStyle(
          color: fg,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bg = isActive
        ? Colors.green.withValues(alpha: 0.12)
        : Colors.orange.withValues(alpha: 0.12);
    final fg = isActive ? Colors.green.shade700 : Colors.orange.shade800;
    return Container(
      height: 24,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? loc.status_active_label : loc.status_pending,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyStaffState extends StatelessWidget {
  const _EmptyStaffState({required this.isSearching, this.onInviteTap});

  final bool isSearching;
  final VoidCallback? onInviteTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching ? loc.no_matching_staff_found : loc.no_staff_found,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? loc.try_different_staff_search
                  : loc.invite_staff_empty_hint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (onInviteTap != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onInviteTap,
                child: Text(loc.invite_staff),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _isSecondaryAdminRole(String role) {
  final normalized = role.trim().toLowerCase().replaceAll('_', ' ');
  return normalized == 'secondary admin';
}

bool _isBillerRole(String role) => !_isSecondaryAdminRole(role);

String _localizedRoleTitle(AppLocalizations loc, String role) {
  return _isSecondaryAdminRole(role) ? loc.secondary_admin : loc.biller;
}

class _BillerPermissionsSection extends StatelessWidget {
  const _BillerPermissionsSection({
    required this.permissions,
    required this.loc,
  });

  final List<String> permissions;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final granted = permissions.map((item) => item.trim()).toSet();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PermissionReadOnlyRow(
            label: loc.allow_biller_create_menu_items,
            enabled: granted.contains('create_bill'),
          ),
          const SizedBox(height: 6),
          _PermissionReadOnlyRow(
            label: loc.allow_biller_edit_menu_items,
            enabled: granted.contains('edit_menu'),
          ),
        ],
      ),
    );
  }
}

class _PermissionReadOnlyRow extends StatelessWidget {
  const _PermissionReadOnlyRow({
    required this.label,
    required this.enabled,
  });

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          enabled ? Icons.check_circle : Icons.cancel_outlined,
          size: 16,
          color: enabled ? Colors.green.shade600 : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: enabled ? const Color(0xFF374151) : Colors.grey.shade500,
              fontWeight: enabled ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _staffActionMenuItem({
  required IconData icon,
  required String label,
  Color? iconColor,
}) {
  return Row(
    children: [
      Icon(icon, size: 18, color: iconColor),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}
