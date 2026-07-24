import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_permission_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Collapsible checkbox grid for staff permissions (Add / Edit Staff).
class StaffPermissionsSection extends StatelessWidget {
  const StaffPermissionsSection({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onSelectAll,
    required this.onDeselectAll,
    this.initiallyExpanded = true,
  });

  final dynamic selected;
  final void Function(String key, bool enabled) onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = selected.length;
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Text(
            'Permissions ($count)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.primary,
            ),
          ),
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: onSelectAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Select All',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: onDeselectAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Deselect All',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final group in kStaffPermissionGroups) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  group.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCol = constraints.maxWidth >= 420;
                  if (!twoCol) {
                    return Column(
                      children: [
                        for (final item in group.items)
                          _PermissionTile(
                            label: item.label,
                            value: selected.contains(item.key),
                            onChanged: (v) => onToggle(item.key, v ?? false),
                          ),
                      ],
                    );
                  }
                  final rows = <Widget>[];
                  for (var i = 0; i < group.items.length; i += 2) {
                    final left = group.items[i];
                    final right = i + 1 < group.items.length
                        ? group.items[i + 1]
                        : null;
                    rows.add(
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PermissionTile(
                              label: left.label,
                              value: selected.contains(left.key),
                              onChanged: (v) =>
                                  onToggle(left.key, v ?? false),
                            ),
                          ),
                          Expanded(
                            child: right == null
                                ? const SizedBox.shrink()
                                : _PermissionTile(
                                    label: right.label,
                                    value: selected.contains(right.key),
                                    onChanged: (v) =>
                                        onToggle(right.key, v ?? false),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(children: rows);
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      );
    });
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
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColor.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
