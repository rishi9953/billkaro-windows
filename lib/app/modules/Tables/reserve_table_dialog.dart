import 'package:billkaro/app/Widgets/app_date_picker.dart';
import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/app/services/Modals/tables/table_reservation_model.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/config/config.dart';

class ReserveTableDialog extends StatefulWidget {
  final TableController controller;
  final TableModel table;

  const ReserveTableDialog({
    super.key,
    required this.controller,
    required this.table,
  });

  static Future<void> show({
    required TableController controller,
    required TableModel table,
  }) {
    return Get.dialog<void>(
      ReserveTableDialog(controller: controller, table: table),
      barrierDismissible: true,
    );
  }

  @override
  State<ReserveTableDialog> createState() => _ReserveTableDialogState();
}

class _ReserveTableDialogState extends State<ReserveTableDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _date;
  late TimeOfDay _time;
  late int _partySize;
  late TableModel _reservationTable;
  final Set<String> _extraTableIds = <String>{};
  bool _submitting = false;

  static const _timeOptions = ['12:00', '13:00', '19:00', '20:00', '21:00'];
  static const _partyPresets = [1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20];

  int get _baseCapacity =>
      widget.controller.effectiveSeatingCapacity(_reservationTable);

  int get _extraCapacity {
    var total = 0;
    for (final id in _extraTableIds) {
      final tws = widget.controller.tables.firstWhereOrNull(
        (entry) => entry.table.id == id,
      );
      if (tws != null) total += tws.table.seatingCapacity;
    }
    return total;
  }

  int get _effectiveCapacity => _baseCapacity + _extraCapacity;

  List<int> get _partyOptions {
    final ceiling = widget.controller
        .maxCombinablePartySize(_reservationTable)
        .clamp(1, 30);
    final options = _partyPresets
        .where((size) => size <= ceiling)
        .toList(growable: true);
    if (!options.contains(ceiling) && ceiling <= 30) {
      options.add(ceiling);
      options.sort();
    }
    return options.isEmpty ? [1] : options;
  }

  bool get _needsMoreSeats => _partySize > _effectiveCapacity;

  List<TableWithStatus> get _mergeCandidates =>
      widget.controller.reserveMergeCandidates(_reservationTable);

  List<TableWithStatus> get _alternateTables => widget.controller
      .tablesFittingParty(_partySize, excludeTableId: _reservationTable.id);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _time = const TimeOfDay(hour: 19, minute: 0);
    _reservationTable = widget.table;
    final cap = _baseCapacity;
    _partySize = cap >= 2 ? 2 : 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  String _displayDate(AppLocalizations loc) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tomorrow = todayDate.add(const Duration(days: 1));
    if (_date == todayDate) return loc.reservation_today;
    if (_date == tomorrow) return loc.reservation_tomorrow;
    return _formatDate(_date);
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() => _date = DateTime(now.year, now.month, now.day));
  }

  void _setTomorrow() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    setState(
      () => _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
    );
  }

  void _setTimeFromString(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return;
    setState(() => _time = TimeOfDay(hour: h, minute: m));
  }

  bool get _canSubmit =>
      !_submitting &&
      _nameController.text.trim().length >= 2 &&
      _partySize <= _effectiveCapacity &&
      _slotConflict == null;

  TableReservationModel? get _slotConflict =>
      widget.controller.findReservationConflict(
        table: _reservationTable,
        reservationDate: _formatDate(_date),
        reservationTime: _formatTime(_time),
      );

  List<TableReservationModel> get _existingBookings =>
      widget.controller.reservationsForTable(_reservationTable);

  void _switchReservationTable(TableModel table) {
    setState(() {
      _reservationTable = table;
      _extraTableIds.clear();
      if (_partySize > _effectiveCapacity && _partyOptions.isNotEmpty) {
        _partySize = _partyOptions.last;
      }
    });
  }

  void _toggleExtraTable(String tableId) {
    setState(() {
      if (_extraTableIds.contains(tableId)) {
        _extraTableIds.remove(tableId);
      } else {
        _extraTableIds.add(tableId);
      }
    });
  }

  String _reservationTableLabel() {
    if (_extraTableIds.isEmpty) {
      return _reservationTable.hasMergedTables
          ? _reservationTable.combinedDisplayName
          : _reservationTable.displayName;
    }
    final names = [
      _reservationTable.hasMergedTables
          ? _reservationTable.combinedDisplayName
          : _reservationTable.displayName,
    ];
    for (final id in _extraTableIds) {
      final tws = widget.controller.tables.firstWhereOrNull(
        (entry) => entry.table.id == id,
      );
      if (tws != null) names.add(tws.table.displayName);
    }
    return names.join(' + ');
  }

  InputDecoration _fieldDecoration({
    required ColorScheme colorScheme,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: maxLines > 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Icon(icon, color: AppColor.primary),
            )
          : Icon(icon, color: AppColor.primary),
      alignLabelWithHint: maxLines > 1,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(color: AppColor.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColor.primary, width: 1.5),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
    );
  }

  Future<void> _submit(AppLocalizations loc) async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      showError(description: loc.reservation_name_required);
      return;
    }
    if (_partySize > _effectiveCapacity) {
      showError(
        description: loc.reservation_party_needs_more_tables(
          _partySize,
          _effectiveCapacity,
        ),
      );
      return;
    }

    final conflict = _slotConflict;
    if (conflict != null) {
      showError(
        description:
            'Table ${_reservationTable.displayName} is already reserved at '
            '${conflict.reservationTime} on ${conflict.reservationDate}'
            '${conflict.customerName.isNotEmpty ? ' by ${conflict.customerName}' : ''}. '
            'Choose another time or cancel the existing reservation.',
      );
      return;
    }

    setState(() => _submitting = true);

    if (_extraTableIds.isNotEmpty) {
      final merged = await widget.controller.executeMerge(
        _reservationTable.id,
        _extraTableIds.toList(growable: false),
      );
      if (!merged) {
        if (mounted) setState(() => _submitting = false);
        return;
      }
    }

    final created = await widget.controller.createReservation(
      table: _reservationTable,
      customerName: name,
      customerPhone: _phoneController.text.trim(),
      partySize: _partySize,
      reservationDate: _formatDate(_date),
      reservationTime: _formatTime(_time),
      notes: _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (created && Get.isDialogOpen == true) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;
    final name = _nameController.text.trim();
    final showPreview = name.length >= 2;
    final fieldStyle = TextStyle(color: textColor, fontSize: 14);

    return Dialog(
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              table: _reservationTable,
              effectiveCapacity: _effectiveCapacity,
              loc: loc,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FormSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(
                            icon: Icons.person_outline_rounded,
                            iconColor: AppColor.primary,
                            title: loc.reservation_guest_section,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            style: fieldStyle,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            decoration: _fieldDecoration(
                              colorScheme: colorScheme,
                              label: loc.reservation_customer_name,
                              icon: Icons.badge_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            style: fieldStyle,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(
                              colorScheme: colorScheme,
                              label: loc.reservation_phone,
                              icon: Icons.phone_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(
                            icon: Icons.groups_outlined,
                            iconColor: AppColor.secondaryPrimary,
                            title: loc.reservation_party_size,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc.reservation_combined_seating(
                              _effectiveCapacity,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _partyOptions.map((size) {
                              final selected = _partySize == size;
                              return ChoiceChip(
                                label: Text('$size'),
                                selected: selected,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _partySize = size),
                                selectedColor: AppColor.secondaryPrimary
                                    .withValues(alpha: 0.18),
                                backgroundColor: colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? AppColor.secondaryPrimary
                                      : textColor,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? AppColor.secondaryPrimary
                                      : colorScheme.outlineVariant,
                                ),
                              );
                            }).toList(),
                          ),
                          if (_needsMoreSeats) ...[
                            const SizedBox(height: 14),
                            _LargePartyHelper(
                              loc: loc,
                              controller: widget.controller,
                              partySize: _partySize,
                              effectiveCapacity: _effectiveCapacity,
                              mergeCandidates: _mergeCandidates,
                              alternateTables: _alternateTables,
                              selectedExtraIds: _extraTableIds,
                              onToggleExtra: _toggleExtraTable,
                              onSwitchTable: _switchReservationTable,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(
                            icon: Icons.schedule_rounded,
                            iconColor: AppColor.primary,
                            title: loc.reservation_when_section,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DateTimeTile(
                                  icon: Icons.calendar_today_rounded,
                                  label: loc.reservation_date,
                                  value: _displayDate(loc),
                                  onTap: _pickDate,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DateTimeTile(
                                  icon: Icons.access_time_rounded,
                                  label: loc.reservation_time,
                                  value: _formatTime(_time),
                                  onTap: _pickTime,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ShortcutChip(
                                icon: Icons.today_rounded,
                                label: loc.reservation_today,
                                onTap: _setToday,
                              ),
                              _ShortcutChip(
                                icon: Icons.wb_sunny_outlined,
                                label: loc.reservation_tomorrow,
                                onTap: _setTomorrow,
                              ),
                              ..._timeOptions.map(
                                (t) => _ShortcutChip(
                                  icon: Icons.schedule_rounded,
                                  label: t,
                                  onTap: () => _setTimeFromString(t),
                                ),
                              ),
                            ],
                          ),
                          if (_existingBookings.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _ExistingBookingsBanner(
                              bookings: _existingBookings,
                              conflict: _slotConflict,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _notesController,
                      style: fieldStyle,
                      maxLines: 2,
                      decoration: _fieldDecoration(
                        colorScheme: colorScheme,
                        label: loc.reservation_notes,
                        icon: Icons.notes_outlined,
                        maxLines: 2,
                      ),
                    ),
                    if (showPreview) ...[
                      const SizedBox(height: 14),
                      _PreviewCard(
                        tableName: _reservationTableLabel(),
                        guestName: name,
                        partySize: _partySize,
                        dateLabel: _displayDate(loc),
                        timeLabel: _formatTime(_time),
                        loc: loc,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: colorScheme.outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(loc.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _canSubmit ? () => _submit(loc) : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: AppColor.white,
                        disabledBackgroundColor: AppColor.primary.withValues(
                          alpha: 0.35,
                        ),
                        disabledForegroundColor: AppColor.white.withValues(
                          alpha: 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColor.white,
                              ),
                            )
                          : const Icon(Icons.event_seat, size: 18),
                      label: Text(loc.reserve_table),
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

class _Header extends StatelessWidget {
  final TableModel table;
  final int effectiveCapacity;
  final AppLocalizations loc;

  const _Header({
    required this.table,
    required this.effectiveCapacity,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final tableLabel = table.hasMergedTables
        ? table.combinedDisplayName
        : table.displayName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.primary, AppColor.primary.withValues(alpha: 0.88)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColor.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_seat_rounded,
              color: AppColor.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.reserve_table,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColor.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.reservation_dialog_subtitle(tableLabel),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColor.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.reservation_combined_seating(effectiveCapacity),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColor.white.withValues(alpha: 0.75),
                  ),
                ),
                if (table.hasMergedTables) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _MergedChip(
                        label: table.displayName,
                        isPrimary: true,
                        onDark: true,
                      ),
                      ...table.mergedTableNumbers.map(
                        (n) => _MergedChip(
                          label: n.toLowerCase().startsWith('table ')
                              ? n
                              : 'Table $n',
                          onDark: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close_rounded, color: AppColor.white),
            tooltip: loc.cancel,
          ),
        ],
      ),
    );
  }
}

class _MergedChip extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool onDark;

  const _MergedChip({
    required this.label,
    this.isPrimary = false,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (onDark) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColor.white.withValues(alpha: isPrimary ? 0.22 : 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColor.white.withValues(alpha: isPrimary ? 0.5 : 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColor.white.withValues(alpha: isPrimary ? 1 : 0.9),
          ),
        ),
      );
    }

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

class _FormSection extends StatelessWidget {
  final Widget child;

  const _FormSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color textColor;

  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColor.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColor.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: AppColor.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColor.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargePartyHelper extends StatelessWidget {
  final AppLocalizations loc;
  final TableController controller;
  final int partySize;
  final int effectiveCapacity;
  final List<TableWithStatus> mergeCandidates;
  final List<TableWithStatus> alternateTables;
  final Set<String> selectedExtraIds;
  final ValueChanged<String> onToggleExtra;
  final ValueChanged<TableModel> onSwitchTable;

  const _LargePartyHelper({
    required this.loc,
    required this.controller,
    required this.partySize,
    required this.effectiveCapacity,
    required this.mergeCandidates,
    required this.alternateTables,
    required this.selectedExtraIds,
    required this.onToggleExtra,
    required this.onSwitchTable,
  });

  String _tableChipLabel(TableWithStatus tws) {
    final name = tws.table.hasMergedTables
        ? tws.table.combinedDisplayName
        : tws.table.displayName;
    final seats = controller.effectiveSeatingCapacity(tws.table);
    return '$name · ${loc.table_seats_count(seats)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.reservation_party_needs_more_tables(
                    partySize,
                    effectiveCapacity,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (mergeCandidates.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              loc.reservation_add_tables_to_combine,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mergeCandidates.map((tws) {
                final selected = selectedExtraIds.contains(tws.table.id);
                return FilterChip(
                  label: Text(_tableChipLabel(tws)),
                  selected: selected,
                  showCheckmark: true,
                  onSelected: (_) => onToggleExtra(tws.table.id),
                  selectedColor: AppColor.primary.withValues(alpha: 0.16),
                  checkmarkColor: AppColor.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColor.primary : textColor,
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppColor.primary
                        : colorScheme.outlineVariant,
                  ),
                );
              }).toList(),
            ),
          ],
          if (alternateTables.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              loc.reservation_or_switch_table,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: alternateTables.map((tws) {
                return ActionChip(
                  avatar: Icon(
                    Icons.table_restaurant_outlined,
                    size: 16,
                    color: AppColor.primary,
                  ),
                  label: Text(_tableChipLabel(tws)),
                  onPressed: () => onSwitchTable(tws.table),
                  backgroundColor: colorScheme.surface,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  side: BorderSide(
                    color: AppColor.primary.withValues(alpha: 0.35),
                  ),
                );
              }).toList(),
            ),
          ],
          if (mergeCandidates.isEmpty && alternateTables.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              loc.reservation_no_tables_for_party,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String tableName;
  final String guestName;
  final int partySize;
  final String dateLabel;
  final String timeLabel;
  final AppLocalizations loc;

  const _PreviewCard({
    required this.tableName,
    required this.guestName,
    required this.partySize,
    required this.dateLabel,
    required this.timeLabel,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(
          alpha: colorScheme.brightness == Brightness.dark ? 0.12 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_outlined,
                size: 16,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                loc.reservation_preview_label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            guestName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _PreviewChip(icon: Icons.table_restaurant, label: tableName),
              _PreviewChip(icon: Icons.groups_outlined, label: '$partySize'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$dateLabel · $timeLabel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PreviewChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.blue.shade700),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingBookingsBanner extends StatelessWidget {
  final List<TableReservationModel> bookings;
  final TableReservationModel? conflict;

  const _ExistingBookingsBanner({
    required this.bookings,
    required this.conflict,
  });

  @override
  Widget build(BuildContext context) {
    final hasConflict = conflict != null;
    final accent = hasConflict ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasConflict ? Icons.error_outline : Icons.info_outline,
                size: 16,
                color: accent.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasConflict
                      ? 'Selected slot is already booked. Pick another time.'
                      : 'Existing bookings for this table',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...bookings.take(4).map((booking) {
            final isConflict = conflict?.id == booking.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${booking.reservationDate} · ${booking.reservationTime}'
                '${booking.customerName.isNotEmpty ? ' · ${booking.customerName}' : ''}'
                '${isConflict ? ' (selected)' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isConflict ? FontWeight.w700 : FontWeight.w500,
                  color: isConflict ? accent.shade900 : accent.shade800,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
