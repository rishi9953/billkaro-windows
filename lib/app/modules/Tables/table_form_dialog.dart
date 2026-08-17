import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/services.dart';

class TableFormDialog extends StatefulWidget {
  final TableController controller;
  final TableModel? editTable;

  const TableFormDialog({super.key, required this.controller, this.editTable});

  static Future<void> show({
    required TableController controller,
    TableModel? editTable,
  }) {
    return Get.dialog<void>(
      TableFormDialog(controller: controller, editTable: editTable),
      barrierDismissible: true,
    );
  }

  bool get isEdit => editTable != null;

  @override
  State<TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<TableFormDialog> {
  late final TextEditingController _numberController;
  late final TextEditingController _seatsController;
  late final TextEditingController _sectionController;
  bool _submitting = false;

  static String _digitsOnly(String? value) {
    if (value == null || value.isEmpty) return '';
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  @override
  void initState() {
    super.initState();
    final existingNumber = _digitsOnly(widget.editTable?.tableNumber);
    _numberController = TextEditingController(
      text: existingNumber.isNotEmpty
          ? existingNumber
          : '${widget.controller.nextSuggestedTableNumber}',
    );
    _seatsController = TextEditingController(
      text:
          '${widget.editTable?.seatingCapacity ?? widget.controller.defaultSeatsForNewTable}',
    );
    _sectionController = TextEditingController(
      text: widget.editTable?.section.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _seatsController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations loc) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final seats = int.tryParse(_seatsController.text.trim()) ?? 0;
    final section = _sectionController.text.trim();
    final ok = widget.isEdit
        ? await widget.controller.updateTable(
            table: widget.editTable!,
            tableNumber: _numberController.text,
            seatingCapacity: seats,
            section: section,
          )
        : await widget.controller.addTable(
            tableNumber: _numberController.text,
            seatingCapacity: seats,
            section: section,
          );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok && Get.isDialogOpen == true) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final limit = widget.controller.seatingCapacityLimit;
    final usedSeats = widget.controller.totalUsedSeats;
    final remaining = widget.controller.remainingSeats;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColor.primary.withValues(alpha: 0.12),
                    AppColor.lightgreen.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isEdit
                          ? Icons.edit_outlined
                          : Icons.table_restaurant,
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEdit ? loc.edit_table : loc.add_table,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.isEdit
                              ? loc.edit_table_subtitle
                              : (limit > 0
                                    ? loc.tables_count_limit(usedSeats, limit)
                                    : loc.seating_capacity_not_set),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    tooltip: loc.cancel,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: loc.table_number,
                        hintText: loc.table_number_hint,
                        prefixIcon: const Icon(Icons.numbers),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _seatsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: loc.seats_label,
                        hintText: limit > 0 && !widget.isEdit
                            ? loc.table_seats_exceed_remaining(remaining, limit)
                            : loc.seats_hint,
                        prefixIcon: const Icon(Icons.chair_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [2, 4, 6, 8].map((n) {
                        final selected = _seatsController.text.trim() == '$n';
                        return ChoiceChip(
                          label: Text('$n ${loc.seats_label}'),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() => _seatsController.text = '$n');
                          },
                          selectedColor: AppColor.primary.withValues(
                            alpha: 0.2,
                          ),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColor.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          side: BorderSide(
                            color: selected
                                ? AppColor.primary
                                : colorScheme.outlineVariant,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loc.table_section,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            widget.controller.promptAddSection();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(loc.add_section),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final managed = widget.controller.sectionSuggestions;
                      final current = _sectionController.text.trim();
                      final suggestions = <String>[
                        ...managed,
                        if (current.isNotEmpty &&
                            !managed.any(
                              (s) => s.toLowerCase() == current.toLowerCase(),
                            ))
                          current,
                      ];
                      if (suggestions.isEmpty) {
                        return Text(
                          loc.no_sections_yet,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(loc.table_section_general),
                            selected: current.isEmpty,
                            showCheckmark: false,
                            onSelected: (_) {
                              setState(() => _sectionController.text = '');
                            },
                            selectedColor: AppColor.primary.withValues(
                              alpha: 0.2,
                            ),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: current.isEmpty
                                  ? AppColor.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            side: BorderSide(
                              color: current.isEmpty
                                  ? AppColor.primary
                                  : colorScheme.outlineVariant,
                            ),
                          ),
                          ...suggestions.map((name) {
                            final selected =
                                current.toLowerCase() == name.toLowerCase();
                            final canDelete =
                                managed.any(
                                  (s) =>
                                      s.toLowerCase() == name.toLowerCase(),
                                ) &&
                                widget.controller.canDeleteManagedSection(
                                  name,
                                );
                            return InputChip(
                              label: Text(name),
                              selected: selected,
                              showCheckmark: false,
                              onSelected: (_) {
                                setState(() => _sectionController.text = name);
                              },
                              onDeleted: canDelete
                                  ? () async {
                                      final wasSelected = selected;
                                      await widget.controller
                                          .promptDeleteSection(name);
                                      if (!wasSelected || !mounted) return;
                                      if (widget.controller
                                              .managedSectionFor(name) ==
                                          null) {
                                        setState(
                                          () => _sectionController.text = '',
                                        );
                                      }
                                    }
                                  : null,
                              deleteIconColor: colorScheme.error,
                              selectedColor: AppColor.primary.withValues(
                                alpha: 0.2,
                              ),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColor.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppColor.primary
                                    : colorScheme.outlineVariant,
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Get.back(),
                      child: Text(loc.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.disabled)) {
                            return colorScheme.primary.withValues(alpha: 0.5);
                          }
                          return colorScheme.primary;
                        }),
                      ),
                      onPressed: _submitting ? null : () => _submit(loc),
                      icon: _submitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Icon(
                              widget.isEdit ? Icons.save : Icons.add,
                              size: 18,
                            ),
                      label: Text(widget.isEdit ? loc.save : loc.add),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
