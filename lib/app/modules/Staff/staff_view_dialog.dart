import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_permission_keys.dart';
import 'package:intl/intl.dart';

Future<void> showStaffViewDialog(BuildContext context, StaffMember member) {
  return showDialog<void>(
    context: context,
    builder: (context) => _StaffViewDialog(member: member),
  );
}

class _StaffViewDialog extends StatelessWidget {
  const _StaffViewDialog({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final roleTitle = _localizedRoleTitle(loc, member.role);
    final isSecondaryAdmin = _isSecondaryAdminRole(member.role);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: loc.close,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  children: [
                    _buildProfileAvatar(member),
                    const SizedBox(height: 16),
                    Text(
                      member.name.trim().isEmpty
                          ? '-'
                          : member.name.trim().capitalize!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
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
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    _detailRow(loc.unique_id, member.uniqueId),
                    _detailRow(loc.email, member.email),
                    _detailRow(loc.mobile_number, member.phone),
                    _detailRow(loc.address_label, member.address),
                    _detailRow(loc.state_label, member.state),
                    _detailRow(loc.district_label, member.district),
                    _detailRow(loc.pincode_label, member.pincode),
                    _detailRow(
                      loc.date_of_birth,
                      _formatDateOfBirth(member.dateOfBirth),
                    ),
                    _detailRow(
                      loc.join_date,
                      _formatDateOfBirth(member.joinDate),
                    ),
                    _detailRow(
                      loc.gender_label,
                      _genderLabel(loc, member.gender),
                    ),
                    if (member.permissions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _BillerPermissionsSection(
                        permissions: member.permissions,
                        loc: loc,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(StaffMember member) {
    final url = resolvedMediaUrl(member.profileImage);
    final name = member.name.trim();

    if (url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _initialsAvatar(name),
        ),
      );
    }

    return _initialsAvatar(name);
  }

  Widget _initialsAvatar(String name) {
    return CircleAvatar(
      radius: 60,
      backgroundColor: AppColor.primary.withValues(alpha: 0.12),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColor.primary,
          fontSize: 40,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final display = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
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

String _formatDateOfBirth(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return '-';
  try {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(text));
  } catch (_) {
    return text;
  }
}

String _genderLabel(AppLocalizations loc, String gender) {
  switch (gender.trim().toLowerCase()) {
    case 'male':
      return loc.male;
    case 'female':
      return loc.female;
    default:
      return gender.trim().isEmpty ? '-' : gender.trim();
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.title, required this.isSecondaryAdmin});

  final String title;
  final bool isSecondaryAdmin;

  @override
  Widget build(BuildContext context) {
    final bg = isSecondaryAdmin
        ? const Color(0xFFDBEAFE)
        : const Color(0xFFEDE9FE);
    final fg = isSecondaryAdmin
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF7C3AED);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? loc.status_active_label : loc.status_pending,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
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
    final granted = expandStaffPermissions(permissions);
    final labels = <String>[];
    for (final group in kStaffPermissionGroups) {
      for (final item in group.items) {
        if (granted.contains(item.key)) {
          labels.add(item.label);
        }
      }
    }

    if (labels.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          'No permissions assigned',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in labels) _PermissionChip(label: label),
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: AppColor.primary),
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
    );
  }
}
