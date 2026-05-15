import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
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
      ),
      body: isWindows
          ? _buildWindowsLayout(context, controller, loc)
          : _buildMobileLayout(context, controller, loc),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(
    BuildContext context,
    StaffDetailsController controller,
    AppLocalizations loc,
  ) {
    return Column(
      children: [
        _StaffActivityEntry(
          onTap: () => Modular.to.pushNamed(HomeMainRoutes.staffActivityScreen),
        ),
        _SearchField(controller: controller, isWindows: false),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.loadStaffList,
            child: Obx(() {
              if (controller.isLoading.value && controller.staffList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = controller.filteredStaff;
              final isSearching = controller.searchQuery.value
                  .trim()
                  .isNotEmpty;
              if (list.isEmpty) {
                return _EmptyStaffState(
                  isSearching: isSearching,
                  onInviteTap: isSearching ? null : controller.onAddStaff,
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _StaffCard(
                    member: list[index],
                    controller: controller,
                  );
                },
              );
            }),
          ),
        ),
        _buildBottomButton(context, controller, loc),
      ],
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
                                  const Expanded(
                                    child: Text(
                                      'Staff List',
                                      style: TextStyle(
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
                                'Manage your outlet staff access',
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
                                    _windowsHeaderRow(),
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

  Widget _windowsHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Name',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Role',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Phone',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 96),
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
    return Padding(
      padding: isWindows
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          isDense: isWindows,
          hintText: 'Search by name, role, phone or email',
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
              const Text(
                'Check Staff Activity',
                style: TextStyle(fontSize: 16),
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
                    const Text(
                      'Check Staff Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Filter activity by date range and user',
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
    final roleTitle = _normalizedRoleTitle(member.role);
    final isSecondaryAdmin = roleTitle == 'Secondary Admin';
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
    final roleTitle = _normalizedRoleTitle(member.role);
    final isSecondaryAdmin = roleTitle == 'Secondary Admin';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
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
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
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
            flex: 2,
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
            width: 96,
            child: Align(
              alignment: Alignment.centerRight,
              child: _StaffActionMenu(
                member: member,
                controller: controller,
                isWindows: true,
              ),
            ),
          ),
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
    return Obx(() {
      final staffId = member.id.trim();
      final deleting =
          staffId.isNotEmpty && controller.deletingStaffIds.contains(staffId);
      if (deleting) {
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      if (isWindows) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit',
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColor.primary,
              ),
              onPressed: () => controller.onEditStaff(member),
              style: IconButton.styleFrom(
                backgroundColor: AppColor.primary.withValues(alpha: 0.08),
                minimumSize: const Size(36, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () => _confirmDelete(context, member),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.08),
                minimumSize: const Size(36, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        );
      }

      return PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'edit') {
            await controller.onEditStaff(member);
            return;
          }
          await _confirmDelete(context, member);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'remove', child: Text('Remove')),
        ],
      );
    });
  }

  Future<void> _confirmDelete(BuildContext context, StaffMember member) async {
    final staffId = member.id.trim();
    if (staffId.isEmpty) {
      showError(description: 'Unable to delete this staff entry');
      return;
    }

    final shouldDelete =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Remove Staff'),
            content: Text(
              'Do you want to remove ${member.name.isEmpty ? "this staff" : member.name}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remove'),
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
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Pending',
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
              isSearching ? 'No matching staff found' : 'No staff found',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different name, role, phone, or email.'
                  : 'Invite your first team member to start managing staff permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (onInviteTap != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onInviteTap,
                child: const Text('Invite Staff'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _normalizedRoleTitle(String role) {
  final normalized = role.trim().toLowerCase().replaceAll('_', ' ');
  if (normalized == 'secondary admin') return 'Secondary Admin';
  return 'Biller';
}
