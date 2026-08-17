import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_permission_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Permissions UI for Add / Edit Staff (Windows).
///
/// Secondary Admin sees a full-access message; Biller sees the picker.
class StaffPermissionsSection extends StatelessWidget {
  const StaffPermissionsSection({
    super.key,
    required this.hasFullAccess,
    this.selected,
    this.onToggle,
    this.onSelectAll,
    this.onDeselectAll,
    this.initiallyExpanded = true,
  }) : assert(
          hasFullAccess ||
              (selected != null &&
                  onToggle != null &&
                  onSelectAll != null &&
                  onDeselectAll != null),
        );

  /// When true, shows an all-permissions notice instead of the picker.
  final bool hasFullAccess;
  final dynamic selected;
  final void Function(List<String> keys, bool enabled)? onToggle;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (hasFullAccess) {
      return const StaffFullAccessPermissionsCard();
    }
    return _PermissionsPicker(
      selected: selected,
      onToggle: onToggle!,
      onSelectAll: onSelectAll!,
      onDeselectAll: onDeselectAll!,
      initiallyExpanded: initiallyExpanded,
    );
  }
}

/// Compact notice used when a role grants every permission.
class StaffFullAccessPermissionsCard extends StatelessWidget {
  const StaffFullAccessPermissionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: AppColor.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permissions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loc.staff_access_info,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
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

class _PermissionsPicker extends StatelessWidget {
  const _PermissionsPicker({
    required this.selected,
    required this.onToggle,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.initiallyExpanded,
  });

  final dynamic selected;
  final void Function(List<String> keys, bool enabled) onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = countGrantedStaffPermissionItems(selected);
      final total = kStaffPermissionCatalogSize;
      final progress = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.security_outlined,
                color: AppColor.primary,
                size: 20,
              ),
            ),
            title: Text(
              'Permissions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.primary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count of $total selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColor.primary.withValues(alpha: 0.1),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColor.primary),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              Row(
                children: [
                  _LinkAction(label: 'Select all', onTap: onSelectAll),
                  const SizedBox(width: 16),
                  _LinkAction(label: 'Clear all', onTap: onDeselectAll),
                ],
              ),
              const SizedBox(height: 12),
              for (final group in kStaffPermissionGroups) ...[
                _PermissionGroupCard(
                  group: group,
                  selected: selected,
                  onToggle: onToggle,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _LinkAction extends StatelessWidget {
  const _LinkAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColor.primary,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _PermissionGroupCard extends StatelessWidget {
  const _PermissionGroupCard({
    required this.group,
    required this.selected,
    required this.onToggle,
  });

  final StaffPermissionGroup group;
  final dynamic selected;
  final void Function(List<String> keys, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    final granted =
        group.items.where((item) => item.isGranted(selected)).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$granted/${group.items.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth >= 420;
              if (!twoCol) {
                return Column(
                  children: [
                    for (final item in group.items)
                      _PermissionTile(
                        label: item.label,
                        value: item.isGranted(selected),
                        onChanged: (v) => onToggle(item.keys, v),
                      ),
                  ],
                );
              }

              final rows = <Widget>[];
              for (var i = 0; i < group.items.length; i += 2) {
                final left = group.items[i];
                final right =
                    i + 1 < group.items.length ? group.items[i + 1] : null;
                rows.add(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _PermissionTile(
                          label: left.label,
                          value: left.isGranted(selected),
                          onChanged: (v) => onToggle(left.keys, v),
                        ),
                      ),
                      Expanded(
                        child: right == null
                            ? const SizedBox.shrink()
                            : _PermissionTile(
                                label: right.label,
                                value: right.isGranted(selected),
                                onChanged: (v) => onToggle(right.keys, v),
                              ),
                      ),
                    ],
                  ),
                );
              }
              return Column(children: rows);
            },
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: AppColor.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    color: value
                        ? const Color(0xFF111827)
                        : const Color(0xFF4B5563),
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
