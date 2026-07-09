import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/config/config.dart';

class MergeTablesDialog extends StatefulWidget {
  final TableController controller;
  final List<TableWithStatus> initialEligible;
  final TableWithStatus? editMergedGroup;

  const MergeTablesDialog({
    super.key,
    required this.controller,
    required this.initialEligible,
    this.editMergedGroup,
  });

  static Future<void> show({
    required TableController controller,
    required List<TableWithStatus> initialEligible,
  }) {
    return Get.dialog<void>(
      MergeTablesDialog(
        controller: controller,
        initialEligible: initialEligible,
      ),
      barrierDismissible: true,
    );
  }

  static Future<void> showEdit({
    required TableController controller,
    required TableWithStatus mergedPrimary,
  }) {
    return Get.dialog<void>(
      MergeTablesDialog(
        controller: controller,
        initialEligible: controller.mergeEditCandidates(mergedPrimary.table),
        editMergedGroup: mergedPrimary,
      ),
      barrierDismissible: true,
    );
  }

  @override
  State<MergeTablesDialog> createState() => _MergeTablesDialogState();
}

class _MergeTablesDialogState extends State<MergeTablesDialog> {
  late List<TableWithStatus> _eligible;
  String? _primaryId;
  final Set<String> _secondaryIds = {};
  var _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _eligible = List<TableWithStatus>.from(widget.initialEligible);
    if (widget.editMergedGroup != null) {
      _primaryId = widget.editMergedGroup!.table.id;
      _secondaryIds.addAll(widget.controller.mergedChildIds(_primaryId!));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleRefresh());
  }

  bool get _isEditMode => widget.editMergedGroup != null;

  void _scheduleRefresh() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    widget.controller.loadTables().then((_) {
      if (!mounted) return;
      if (_isEditMode) {
        final primary = widget.editMergedGroup!.table;
        setState(() {
          _eligible = widget.controller.mergeEditCandidates(primary);
          _secondaryIds
            ..clear()
            ..addAll(widget.controller.mergedChildIds(primary.id));
        });
        return;
      }
      final updated = widget.controller.tables
          .where(widget.controller.isMergeEligible)
          .toList(growable: false);
      if (updated.length >= 2) {
        setState(() => _eligible = updated);
      }
    });
  }

  TableWithStatus? get _primary {
    if (_primaryId == null) return null;
    for (final t in _eligible) {
      if (t.table.id == _primaryId) return t;
    }
    return null;
  }

  List<TableWithStatus> get _secondaries => _eligible
      .where((t) => widget.controller.isSecondaryMergeEligible(t, _primaryId))
      .toList(growable: false);

  List<TableWithStatus> get _joinCandidates {
    if (!_isEditMode) return _secondaries;
    final primaryId = _primaryId;
    if (primaryId == null) return [];
    return _eligible.where((t) => t.table.id != primaryId).toList(growable: false);
  }

  String _previewLabel(AppLocalizations loc) {
    final primary = _isEditMode ? widget.editMergedGroup : _primary;
    if (primary == null) return '';
    if (_secondaryIds.isEmpty) {
      return primary.table.displayName;
    }
    final names = [
      primary.table.displayName,
      ..._secondaryIds.map((id) {
        final tws = _eligible.firstWhereOrNull((e) => e.table.id == id);
        return tws?.table.displayName ??
            widget.controller
                .mergedChildModels(primary.table.id)
                .firstWhereOrNull((m) => m.id == id)
                ?.displayName ??
            '';
      }).where((name) => name.isNotEmpty),
    ];
    return names.join(' + ');
  }

  Future<void> _confirm(AppLocalizations loc) async {
    if (_primaryId == null) return;
    Get.back();
    if (_isEditMode) {
      await widget.controller.updateMergedTables(
        _primaryId!,
        _secondaryIds.toList(growable: false),
      );
      return;
    }
    if (_secondaryIds.isEmpty) return;
    await widget.controller.executeMerge(
      _primaryId!,
      _secondaryIds.toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final preview = _previewLabel(loc);
    final canConfirm = _isEditMode
        ? _primaryId != null
        : _primaryId != null && _secondaryIds.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(loc: loc, isEditMode: _isEditMode),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isEditMode) ...[
                      _SectionTitle(
                        icon: Icons.star_rounded,
                        iconColor: AppColor.primary,
                        title: loc.merge_step_main,
                        subtitle: widget.editMergedGroup!.table.combinedDisplayName,
                      ),
                      const SizedBox(height: 10),
                      _TablePickCard(
                        tws: widget.editMergedGroup!,
                        loc: loc,
                        selected: true,
                        selectionMode: _SelectionMode.primary,
                        onTap: () {},
                        enabled: false,
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        icon: Icons.add_link_rounded,
                        iconColor: AppColor.secondaryPrimary,
                        title: loc.merge_select_other_tables,
                        subtitle: loc.edit_merged_tables_hint,
                      ),
                      const SizedBox(height: 10),
                      if (_joinCandidates.isEmpty)
                        _EmptyHint(text: loc.no_other_tables_to_merge)
                      else
                        ..._joinCandidates.map(
                          (tws) => _TablePickCard(
                            tws: tws,
                            loc: loc,
                            selected: _secondaryIds.contains(tws.table.id),
                            selectionMode: _SelectionMode.secondary,
                            onTap: () {
                              setState(() {
                                if (_secondaryIds.contains(tws.table.id)) {
                                  _secondaryIds.remove(tws.table.id);
                                } else {
                                  _secondaryIds.add(tws.table.id);
                                }
                              });
                            },
                          ),
                        ),
                    ] else ...[
                    _StepIndicator(
                      step1Active: true,
                      step2Active: _primaryId != null,
                      step1Label: loc.merge_step_main,
                      step2Label: loc.merge_step_join,
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(
                      icon: Icons.star_rounded,
                      iconColor: AppColor.primary,
                      title: loc.merge_select_primary_table,
                      subtitle: loc.merge_available_hint,
                    ),
                    const SizedBox(height: 10),
                    ..._eligible.map(
                      (tws) => _TablePickCard(
                        tws: tws,
                        loc: loc,
                        selected: _primaryId == tws.table.id,
                        selectionMode: _SelectionMode.primary,
                        onTap: () {
                          setState(() {
                            _primaryId = tws.table.id;
                            _secondaryIds.remove(tws.table.id);
                          });
                        },
                      ),
                    ),
                    if (_primaryId != null) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(
                        icon: Icons.add_link_rounded,
                        iconColor: AppColor.secondaryPrimary,
                        title: loc.merge_select_other_tables,
                        subtitle: loc.merge_join_hint,
                      ),
                      const SizedBox(height: 10),
                      if (_secondaries.isEmpty)
                        _EmptyHint(text: loc.no_other_tables_to_merge)
                      else
                        ..._secondaries.map(
                          (tws) => _TablePickCard(
                            tws: tws,
                            loc: loc,
                            selected: _secondaryIds.contains(tws.table.id),
                            selectionMode: _SelectionMode.secondary,
                            onTap: () {
                              setState(() {
                                if (_secondaryIds.contains(tws.table.id)) {
                                  _secondaryIds.remove(tws.table.id);
                                } else {
                                  _secondaryIds.add(tws.table.id);
                                }
                              });
                            },
                          ),
                        ),
                    ],
                    ],
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _MergePreview(label: preview),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
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
                      onPressed: () => Get.back(),
                      child: Text(loc.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: canConfirm ? () => _confirm(loc) : null,
                      icon: Icon(
                        _isEditMode ? Icons.save : Icons.merge_type,
                        size: 18,
                      ),
                      label: Text(_isEditMode ? loc.save : loc.merge_tables),
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

enum _SelectionMode { primary, secondary }

class _DialogHeader extends StatelessWidget {
  final AppLocalizations loc;
  final bool isEditMode;

  const _DialogHeader({required this.loc, this.isEditMode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primary.withValues(alpha: 0.12),
            AppColor.secondaryPrimary.withValues(alpha: 0.08),
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
              isEditMode ? Icons.edit_outlined : Icons.merge_type,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditMode ? loc.edit_merged_tables : loc.merge_tables_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEditMode
                      ? loc.edit_merged_tables_subtitle
                      : loc.merge_dialog_subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final bool step1Active;
  final bool step2Active;
  final String step1Label;
  final String step2Label;

  const _StepIndicator({
    required this.step1Active,
    required this.step2Active,
    required this.step1Label,
    required this.step2Label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StepChip(
            number: '1',
            label: step1Label,
            active: step1Active,
            done: step2Active,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
              alpha: step2Active ? 0.8 : 0.35,
            ),
          ),
        ),
        Expanded(
          child: _StepChip(
            number: '2',
            label: step2Label,
            active: step2Active,
            done: false,
          ),
        ),
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  final String number;
  final String label;
  final bool active;
  final bool done;

  const _StepChip({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColor.primary.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? AppColor.primary.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: done
                ? AppColor.lightgreen
                : active
                ? AppColor.primary
                : Colors.grey.shade400,
            child: done
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : Text(
                    number,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? AppColor.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TablePickCard extends StatelessWidget {
  final TableWithStatus tws;
  final AppLocalizations loc;
  final bool selected;
  final _SelectionMode selectionMode;
  final VoidCallback onTap;
  final bool enabled;

  const _TablePickCard({
    required this.tws,
    required this.loc,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusVisual(tws, loc);
    final isMerged = tws.table.hasMergedTables;
    final isBoth = isMerged && tws.status == TableStatus.reserved;
    final title = isMerged
        ? tws.table.combinedDisplayName
        : tws.table.displayName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColor.primary
                    : status.color.withValues(alpha: 0.35),
                width: selected ? 2 : 1,
              ),
              color: selected
                  ? AppColor.primary.withValues(alpha: 0.07)
                  : Theme.of(context).colorScheme.surface,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColor.primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  selectionMode == _SelectionMode.primary
                      ? (selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off)
                      : (selected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank),
                  color: selected ? AppColor.primary : Colors.grey.shade500,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(status.icon, size: 18, color: status.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.85),
                        ),
                      ),
                      if (isMerged) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _MergedChip(
                              label: tws.table.displayName,
                              isPrimary: true,
                            ),
                            ...tws.table.mergedTableNumbers.map(
                              (n) => _MergedChip(
                                label: n.toLowerCase().startsWith('table ')
                                    ? n
                                    : 'Table $n',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(label: status.shortLabel, color: status.color),
                    if (isBoth) ...[
                      const SizedBox(height: 4),
                      _StatusBadge(
                        label: loc.merged_tables_badge(
                          1 + tws.table.mergedTableNumbers.length,
                        ),
                        color: AppColor.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _TableStatusVisual _statusVisual(TableWithStatus tws, AppLocalizations loc) {
    if (tws.currentOrder?.billNumber != null) {
      return _TableStatusVisual(
        color: AppColor.secondaryPrimary,
        icon: Icons.receipt_long,
        label: loc.home_bill_number(tws.currentOrder!.billNumber.toString()),
        shortLabel: loc.home_occupied,
      );
    }
    if (tws.table.hasMergedTables && tws.status == TableStatus.reserved) {
      final reservation = tws.upcomingReservation;
      return _TableStatusVisual(
        color: Colors.blue,
        icon: Icons.event_seat,
        label: reservation != null
            ? loc.reserved_by(
                reservation.customerName,
                reservation.reservationTime,
              )
            : loc.table_status_reserved,
        shortLabel: loc.filter_reserved,
      );
    }
    if (tws.table.hasMergedTables && tws.status != TableStatus.reserved) {
      return _TableStatusVisual(
        color: AppColor.primary,
        icon: Icons.merge_type,
        label: loc.table_merged_with_others,
        shortLabel: loc.merge_tables,
      );
    }
    switch (tws.status) {
      case TableStatus.reserved:
        return _TableStatusVisual(
          color: Colors.blue,
          icon: Icons.event_seat,
          label: loc.table_status_reserved,
          shortLabel: loc.filter_reserved,
        );
      case TableStatus.occupied:
        return _TableStatusVisual(
          color: AppColor.secondaryPrimary,
          icon: Icons.person,
          label: loc.home_occupied,
          shortLabel: loc.home_occupied,
        );
      case TableStatus.billing:
        return _TableStatusVisual(
          color: Colors.orange,
          icon: Icons.receipt_long,
          label: loc.home_billing,
          shortLabel: loc.home_billing,
        );
      default:
        return _TableStatusVisual(
          color: AppColor.lightgreen,
          icon: Icons.table_restaurant,
          label: loc.table_status_available,
          shortLabel: loc.table_status_available,
        );
    }
  }
}

class _TableStatusVisual {
  final Color color;
  final IconData icon;
  final String label;
  final String shortLabel;

  const _TableStatusVisual({
    required this.color,
    required this.icon,
    required this.label,
    required this.shortLabel,
  });
}

class _MergedChip extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _MergedChip({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isPrimary ? AppColor.primary : Colors.grey.shade600)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isPrimary ? AppColor.primary : Colors.grey.shade500)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPrimary ? AppColor.primary : Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MergePreview extends StatelessWidget {
  final String label;

  const _MergePreview({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primary.withValues(alpha: 0.1),
            AppColor.lightgreen.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.preview_rounded, color: AppColor.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.merge_preview_label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColor.primary,
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

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
