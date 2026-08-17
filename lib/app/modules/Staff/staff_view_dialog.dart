import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/app/modules/Staff/widgets/staff_permissions_section.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:billkaro/utils/staff_permission_keys.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final granted = expandStaffPermissions(member.permissions);
    final permissionCount = _countGrantedLabels(granted);
    final displayName =
        member.name.trim().isEmpty ? loc.manage_staff : member.name.trim();

    return Dialog(
      backgroundColor: const Color(0xFFF4F7FC),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              color: AppColor.primary,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (StaffAccess.canUpdateStaff)
                    IconButton(
                      tooltip: loc.edit,
                      onPressed: () => _openEdit(context, member),
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    ),
                  IconButton(
                    tooltip: loc.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _HeroHeader(
                      member: member,
                      roleTitle: roleTitle,
                      isSecondaryAdmin: isSecondaryAdmin,
                      loc: loc,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      child: Column(
                        children: [
                          _SummaryStrip(
                            roleTitle: roleTitle,
                            isActive: member.isActive,
                            permissionCount: permissionCount,
                            loc: loc,
                          ),
                          _QuickActions(member: member, loc: loc),
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: 'Contact',
                            icon: Icons.contact_mail_outlined,
                            children: [
                              _InfoTile(
                                icon: Icons.badge_outlined,
                                label: loc.unique_id,
                                value: member.uniqueId,
                              ),
                              _InfoTile(
                                icon: Icons.email_outlined,
                                label: loc.email,
                                value: member.email,
                              ),
                              _InfoTile(
                                icon: Icons.phone_outlined,
                                label: loc.mobile_number,
                                value: member.phone,
                                isLast: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: loc.address_label,
                            icon: Icons.location_on_outlined,
                            children: [
                              _InfoTile(
                                icon: Icons.home_outlined,
                                label: loc.address_label,
                                value: member.address,
                              ),
                              _InfoTile(
                                icon: Icons.map_outlined,
                                label: loc.state_label,
                                value: member.state,
                              ),
                              _InfoTile(
                                icon: Icons.place_outlined,
                                label: loc.district_label,
                                value: member.district,
                              ),
                              _InfoTile(
                                icon: Icons.pin_drop_outlined,
                                label: loc.pincode_label,
                                value: member.pincode,
                                isLast: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: 'Personal',
                            icon: Icons.person_outline,
                            children: [
                              _InfoTile(
                                icon: Icons.cake_outlined,
                                label: loc.date_of_birth,
                                value: _formatDate(member.dateOfBirth),
                              ),
                              _InfoTile(
                                icon: Icons.event_available_outlined,
                                label: loc.join_date,
                                value: _formatDate(member.joinDate),
                              ),
                              _InfoTile(
                                icon: Icons.wc_outlined,
                                label: loc.gender_label,
                                value: _genderLabel(loc, member.gender),
                                isLast: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (isSecondaryAdmin)
                            const StaffFullAccessPermissionsCard()
                          else
                            _PermissionsSection(
                              granted: granted,
                              totalCatalog: kStaffPermissionCatalogSize,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.primary,
                        side: BorderSide(
                          color: AppColor.primary.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(loc.close),
                    ),
                  ),
                  if (StaffAccess.canUpdateStaff) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openEdit(context, member),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(loc.edit),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, StaffMember member) async {
    if (!StaffAccess.ensure(StaffAccess.canUpdateStaff)) return;
    Navigator.of(context).pop();
    if (Get.isRegistered<StaffDetailsController>()) {
      await Get.find<StaffDetailsController>().onEditStaff(member);
    }
  }
}

int _countGrantedLabels(Set<String> granted) =>
    countGrantedStaffPermissionItems(granted);

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.member,
    required this.roleTitle,
    required this.isSecondaryAdmin,
    required this.loc,
  });

  final StaffMember member;
  final String roleTitle;
  final bool isSecondaryAdmin;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final name = member.name.trim().isEmpty ? '-' : member.name.trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColor.primary,
            AppColor.primary.withValues(alpha: 0.92),
            const Color(0xFFF4F7FC),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColor.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _Avatar(member: member, size: 88),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (member.uniqueId.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                member.uniqueId.trim(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  icon: Icons.workspace_premium_outlined,
                  label: roleTitle,
                  background: isSecondaryAdmin
                      ? const Color(0xFFDBEAFE)
                      : const Color(0xFFEDE9FE),
                  foreground: isSecondaryAdmin
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF7C3AED),
                ),
                _StatusPill(
                  icon: member.isActive
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                  label: member.isActive
                      ? loc.status_active_label
                      : loc.status_inactive_label,
                  background: member.isActive
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEF3C7),
                  foreground: member.isActive
                      ? const Color(0xFF047857)
                      : const Color(0xFFB45309),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member, this.size = 88});

  final StaffMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = resolvedMediaUrl(member.profileImage);
    final name = member.name.trim();
    final radius = size / 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? AppCachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initials(name, radius),
              )
            : _initials(name, radius),
      ),
    );
  }

  Widget _initials(String name, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColor.primary.withValues(alpha: 0.12),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColor.primary,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.roleTitle,
    required this.isActive,
    required this.permissionCount,
    required this.loc,
  });

  final String roleTitle;
  final bool isActive;
  final int permissionCount;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: roleTitle,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: isActive
                ? Icons.verified_outlined
                : Icons.hourglass_empty_outlined,
            label: 'Status',
            value: isActive
                ? loc.status_active_label
                : loc.status_inactive_label,
            color: isActive ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.security_outlined,
            label: 'Access',
            value: '$permissionCount',
            color: const Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.member, required this.loc});

  final StaffMember member;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final phone = member.phone.trim();
    final email = member.email.trim();
    final hasPhone = phone.isNotEmpty && phone != '-';
    final hasEmail = email.isNotEmpty && email.contains('@');

    if (!hasPhone && !hasEmail) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColor.grey.shade200),
        ),
        child: Row(
          children: [
            if (hasPhone)
              Expanded(
                child: _ActionButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  color: const Color(0xFF059669),
                  onTap: () => _launchUri(Uri(scheme: 'tel', path: phone)),
                ),
              ),
            if (hasPhone)
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  color: const Color(0xFF128C7E),
                  onTap: () => openWhatsApp(phone),
                ),
              ),
            if (hasEmail)
              Expanded(
                child: _ActionButton(
                  icon: Icons.mail_outline,
                  label: loc.email,
                  color: const Color(0xFF2563EB),
                  onTap: () =>
                      _launchUri(Uri(scheme: 'mailto', path: email)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUri(Uri uri) async {
    try {
      await launchUrl(uri);
    } catch (_) {}
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.grey.shade200),
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
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
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(children: children),
          ),
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
    final display = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 10, 8, isLast ? 10 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  display,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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

class _PermissionsSection extends StatelessWidget {
  const _PermissionsSection({
    required this.granted,
    required this.totalCatalog,
  });

  final Set<String> granted;
  final int totalCatalog;

  @override
  Widget build(BuildContext context) {
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

    final progress =
        totalCatalog == 0 ? 0.0 : (grantedCount / totalCatalog).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.grey.shade200),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.security_outlined,
                  size: 18,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Permissions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$grantedCount / $totalCatalog',
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
              backgroundColor: AppColor.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
            ),
          ),
          const SizedBox(height: 16),
          if (groups.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No permissions assigned',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            )
          else
            ...groups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
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
                              color: AppColor.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    AppColor.primary.withValues(alpha: 0.18),
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
                                    color: AppColor.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
  }
}

bool _isSecondaryAdminRole(String role) {
  final normalized = role.trim().toLowerCase().replaceAll('_', ' ');
  return normalized == 'secondary admin';
}

String _localizedRoleTitle(AppLocalizations loc, String role) {
  return _isSecondaryAdminRole(role) ? loc.secondary_admin : loc.biller;
}

String _formatDate(String raw) {
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
