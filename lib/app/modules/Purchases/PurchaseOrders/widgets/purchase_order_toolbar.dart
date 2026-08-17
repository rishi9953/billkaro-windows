import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_controller.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_status_filter.dart';
import 'package:billkaro/config/config.dart';

class PurchaseOrderToolbar extends StatelessWidget {
  const PurchaseOrderToolbar({
    super.key,
    required this.controller,
    required this.loc,
    this.searchController,
  });

  final PurchaseOrderController controller;
  final AppLocalizations loc;
  final TextEditingController? searchController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: searchController,
              onChanged: controller.setSearchQuery,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: loc.search_default_hint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    tooltip: loc.clear_search,
                    onPressed: () {
                      searchController?.clear();
                      controller.setSearchQuery('');
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  );
                }),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: _border(Colors.grey.shade300),
                enabledBorder: _border(Colors.grey.shade300),
                focusedBorder: _border(PurchaseOrderController.accent),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Obx(() {
          final active = controller.statusFilter.value !=
              PurchaseOrderStatusFilter.all;
          return _FilterIconButton(
            active: active,
            accent: PurchaseOrderController.accent,
            tooltip: loc.filters,
            onTap: () => showPurchaseOrderFilterSheet(
              context: context,
              loc: loc,
              selectedStatus: controller.statusFilter.value,
              onSelected: controller.setStatusFilter,
              onClear: () => controller.setStatusFilter(
                PurchaseOrderStatusFilter.all,
              ),
            ),
          );
        }),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({
    required this.active,
    required this.accent,
    required this.tooltip,
    required this.onTap,
  });

  final bool active;
  final Color accent;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? accent.withOpacity(0.12) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: active ? accent : Colors.grey.shade300,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: active ? accent : Colors.grey.shade700,
                ),
                if (active)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showPurchaseOrderFilterSheet({
  required BuildContext context,
  required AppLocalizations loc,
  required String selectedStatus,
  required ValueChanged<String> onSelected,
  required VoidCallback onClear,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var current = selectedStatus;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    loc.filters,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: loc.clear,
                  onPressed: () {
                    setState(() => current = PurchaseOrderStatusFilter.all);
                    onClear();
                  },
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in PurchaseOrderStatusFilter.values)
                        _StatusFilterChip(
                          label: status == PurchaseOrderStatusFilter.all
                              ? loc.filter_all
                              : PurchaseOrderStatusFilter.labelOf(status),
                          selected: current == status,
                          color: status == PurchaseOrderStatusFilter.all
                              ? PurchaseOrderController.accent
                              : PurchaseOrderStatusFilter.colorOf(status),
                          onTap: () => setState(() => current = status),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(loc.cancel),
              ),
              FilledButton(
                onPressed: () {
                  onSelected(current);
                  Navigator.of(dialogContext).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: PurchaseOrderController.accent,
                  foregroundColor: Colors.white,
                ),
                child: Text(loc.apply),
              ),
            ],
          );
        },
      );
    },
  );
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.18),
      checkmarkColor: color,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
        color: selected ? color : Colors.grey.shade800,
      ),
      side: BorderSide(
        color: selected ? color : Colors.grey.shade300,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
