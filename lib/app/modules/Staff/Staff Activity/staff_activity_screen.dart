import 'package:billkaro/app/Widgets/app_date_picker.dart';
import 'package:billkaro/app/modules/Staff/Staff%20Activity/staff_activity_controller.dart';
import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/app/services/Modals/activites/activities_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';

String _staffActorName(ActivityModel activity) {
  final direct = activity.createdByName.trim();
  if (direct.isNotEmpty) return direct;

  final desc = activity.description.trim();
  if (desc.isNotEmpty) {
    final match = RegExp(
      r'^(.+?)\s+(added|edited|deleted|enabled|disabled)\s',
      caseSensitive: false,
    ).firstMatch(desc);
    final parsed = match?.group(1)?.trim();
    if (parsed != null && parsed.isNotEmpty) return parsed;
  }

  return '—';
}

String _activitySubtitle(ActivityModel a, AppLocalizations loc) {
  final parts = <String>[];
  if (a.entityName.isNotEmpty) {
    final type = a.type.toLowerCase();
    if (type.contains('item')) {
      parts.add('${loc.item_name}: ${a.entityName}');
    } else if (type.contains('customer')) {
      parts.add('${loc.customer_name}: ${a.entityName}');
    } else if (type.contains('order')) {
      parts.add('${loc.bill_number}: ${a.entityName}');
    } else {
      parts.add(loc.activity_entity_name(a.entityName));
    }
  }
  final category = a.details.category;
  if (category != null && category.isNotEmpty) {
    parts.add(loc.activity_entity_category(category));
  }
  return parts.join(' · ');
}

String _formatActivityTimestamp(String createdAt) {
  final trimmed = createdAt.trim();
  if (trimmed.isEmpty) return '';
  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) {
    return DateFormat('dd MMM yyyy · hh:mm a').format(parsed.toLocal());
  }
  return trimmed;
}

DateTime _todayDateOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _clampDate(DateTime date, DateTime min, DateTime max) {
  if (date.isBefore(min)) return min;
  if (date.isAfter(max)) return max;
  return date;
}

IconData _activityTypeIcon(String type) {
  final t = type.toLowerCase();
  if (t.contains('order')) return Icons.receipt_long_rounded;
  if (t.contains('customer')) return Icons.person_outline_rounded;
  if (t.contains('item')) return Icons.inventory_2_outlined;
  if (t.contains('staff')) return Icons.badge_outlined;
  return Icons.edit_notifications_outlined;
}

IconData _activityFilterSheetIcon(String option) {
  switch (option) {
    case StaffActivityController.activityTypeAll:
      return Icons.layers_outlined;
    case StaffActivityController.activityTypeOrderAdded:
      return Icons.add_shopping_cart_outlined;
    case StaffActivityController.activityTypeOrderDeleted:
      return Icons.remove_shopping_cart_outlined;
    case StaffActivityController.activityTypeCustomerAdded:
      return Icons.person_add_alt_1_outlined;
    case StaffActivityController.activityTypeCustomerDeleted:
      return Icons.person_off_outlined;
    case StaffActivityController.activityTypeCustomerEdited:
      return Icons.manage_accounts_outlined;
    case StaffActivityController.activityTypeItemAdded:
      return Icons.add_box_outlined;
    case StaffActivityController.activityTypeItemDeleted:
      return Icons.delete_outline_rounded;
    case StaffActivityController.activityTypeItemEdited:
      return Icons.edit_note_rounded;
    case StaffActivityController.activityTypeStaffAdded:
      return Icons.person_add_alt_outlined;
    case StaffActivityController.activityTypeStaffDeleted:
      return Icons.person_remove_outlined;
    case StaffActivityController.activityTypeStaffUpdated:
      return Icons.badge_outlined;
    default:
      return Icons.tune_rounded;
  }
}

class StaffActivityScreen extends StatelessWidget {
  const StaffActivityScreen({super.key});

  bool _isWindows(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.windows;

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = Get.put(StaffActivityController());
    final colorScheme = Theme.of(context).colorScheme;
    final isWindows = _isWindows(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          loc.staff_activity_title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: loc.refresh,
            onPressed: controller.refreshStaffActivityData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildWindowsLayout(context, controller),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(
    BuildContext context,
    StaffActivityController controller,
  ) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(
                  () => _FilterButton(
                    label: controller.timePeriodLabel(
                      loc,
                      controller.selectedTimePeriod.value,
                    ),
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: () => _showTimePeriodSheet(context, controller),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Obx(
                  () => _FilterButton(
                    label: controller.selectedDateRangeLabelLocalized(loc),
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _showDateRangeSheet(context, controller),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _FilterButton(
                    label: controller.selectedUserLabelLocalized(loc),
                    icon: Icons.people_outline_rounded,
                    onTap: () => _showUsersSheet(context, controller),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => _FilterButton(
                    label: controller.activityTypeFilterLabelLocalized(loc),
                    icon: Icons.edit_note_rounded,
                    onTap: () => _showActivityTypeSheet(context, controller),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            loc.activity_log,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildActivitiesList(context, controller)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WINDOWS LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildWindowsLayout(
    BuildContext context,
    StaffActivityController controller,
  ) {
    final loc = AppLocalizations.of(context)!;
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification n) {
        if (n.metrics.axis != Axis.vertical) return false;
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 220) {
          controller.loadMoreActivities();
        }
        return false;
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        Text(
                          loc.filters,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Obx(
                          () => controller.hasActiveFilters
                              ? TextButton.icon(
                                  onPressed: controller.resetFilters,
                                  icon: const Icon(
                                    Icons.filter_alt_off_outlined,
                                    size: 18,
                                  ),
                                  label: Text(loc.reset),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey.shade800,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.staff_activity_filters_hint,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 820;
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Obx(
                                  () => _FilterButton(
                                    label: controller.timePeriodLabel(
                                      loc,
                                      controller.selectedTimePeriod.value,
                                    ),
                                    icon: Icons.keyboard_arrow_down_rounded,
                                    onTap: () => _showTimePeriodSheet(
                                      context,
                                      controller,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: Obx(
                                  () => _FilterButton(
                                    label: controller
                                        .selectedDateRangeLabelLocalized(loc),
                                    icon: Icons.calendar_today_outlined,
                                    onTap: () => _showDateRangeSheet(
                                      context,
                                      controller,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Obx(
                                  () => _FilterButton(
                                    label: controller
                                        .selectedUserLabelLocalized(loc),
                                    icon: Icons.people_outline_rounded,
                                    onTap: () =>
                                        _showUsersSheet(context, controller),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Obx(
                                  () => _FilterButton(
                                    label: controller
                                        .activityTypeFilterLabelLocalized(loc),
                                    icon: Icons.edit_note_rounded,
                                    onTap: () => _showActivityTypeSheet(
                                      context,
                                      controller,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Obx(
                                    () => _FilterButton(
                                      label: controller.timePeriodLabel(
                                        loc,
                                        controller.selectedTimePeriod.value,
                                      ),
                                      icon: Icons.keyboard_arrow_down_rounded,
                                      onTap: () => _showTimePeriodSheet(
                                        context,
                                        controller,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Obx(
                                    () => _FilterButton(
                                      label: controller
                                          .selectedDateRangeLabelLocalized(loc),
                                      icon: Icons.calendar_today_outlined,
                                      onTap: () => _showDateRangeSheet(
                                        context,
                                        controller,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Obx(
                                    () => _FilterButton(
                                      label: controller
                                          .selectedUserLabelLocalized(loc),
                                      icon: Icons.people_outline_rounded,
                                      onTap: () =>
                                          _showUsersSheet(context, controller),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Obx(
                                    () => _FilterButton(
                                      label: controller
                                          .activityTypeFilterLabelLocalized(
                                            loc,
                                          ),
                                      icon: Icons.edit_note_rounded,
                                      onTap: () => _showActivityTypeSheet(
                                        context,
                                        controller,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Container(
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
                            Text(
                              loc.activity_log,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Obx(
                              () => Text(
                                controller.selectedDateRangeLabelLocalized(loc),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildActivitiesList(
                          context,
                          controller,
                          isWindows: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitiesList(
    BuildContext context,
    StaffActivityController controller, {
    bool isWindows = false,
  }) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = controller.activities;
      if (items.isEmpty) {
        return Center(
          child: Text(
            loc.no_activities_yet,
            style: TextStyle(
              color: isWindows
                  ? Colors.grey.shade600
                  : colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        );
      }

      final showLoadingFooter = controller.isLoadingMore.value;
      final list = ListView.separated(
        shrinkWrap: isWindows,
        physics: isWindows
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (showLoadingFooter ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _StaffActivityListCard(
            activity: items[index],
            index: index,
            isWindows: isWindows,
          );
        },
      );

      if (isWindows) return list;

      return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification n) {
          if (n.metrics.axis != Axis.vertical) return false;
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 220) {
            controller.loadMoreActivities();
          }
          return false;
        },
        child: list,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // BOTTOM SHEETS / DIALOGS
  // ---------------------------------------------------------------------------

  Future<void> _showTimePeriodSheet(
    BuildContext context,
    StaffActivityController controller,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final isWindows = _isWindows(context);
    String tempSelected = controller.selectedTimePeriod.value;

    final selected = await _presentChooser<String>(
      context: context,
      title: loc.select_time_period,
      builder: (setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: StaffActivityController.timePeriods.map((option) {
            final isSelected = option == tempSelected;
            return InkWell(
              onTap: () => setState(() => tempSelected = option),
              child: Container(
                width: double.infinity,
                color: isSelected ? AppColor.primary : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Text(
                  controller.timePeriodLabel(loc, option),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      resetLabel: loc.reset,
      onReset: () => StaffActivityController.timePeriodAll,
      showReset: () =>
          tempSelected != StaffActivityController.timePeriodAll,
      onApply: () => tempSelected,
      isWindows: isWindows,
    );

    if (selected == null) return;
    await controller.applyTimePeriod(selected);
  }

  Future<void> _showUsersSheet(
    BuildContext context,
    StaffActivityController controller,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final isWindows = _isWindows(context);
    StaffMember? tempSelected;
    for (final member in controller.staffMembers) {
      if (member.id == controller.selectedUserId.value) {
        tempSelected = member;
        break;
      }
    }

    final result = await _presentChooser<Map<String, dynamic>>(
      context: context,
      title: loc.select_user,
      builder: (setState) {
        return Obx(() {
          final members = controller.staffMembers;
          if (controller.isLoading.value && members.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (members.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                loc.no_users_found,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            );
          }
          final tiles = <Widget>[
            InkWell(
              onTap: () => setState(() => tempSelected = null),
              child: Container(
                width: double.infinity,
                color: tempSelected == null
                    ? AppColor.primary
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Text(
                  loc.all_users,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: tempSelected == null ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            ...members.map(
              (member) => InkWell(
                onTap: () => setState(() => tempSelected = member),
                child: Container(
                  width: double.infinity,
                  color: tempSelected?.id == member.id
                      ? AppColor.primary
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Text(
                    member.name.isNotEmpty ? member.name : member.phone,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: tempSelected?.id == member.id
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ];
          return Column(mainAxisSize: MainAxisSize.min, children: tiles);
        });
      },
      resetLabel: loc.reset,
      onReset: () => {'applied': true, 'member': null},
      onApply: () => {'applied': true, 'member': tempSelected},
      isWindows: isWindows,
    );

    if (result == null || result['applied'] != true) return;
    await controller.applyUserSelection(result['member'] as StaffMember?);
  }

  Future<void> _showActivityTypeSheet(
    BuildContext context,
    StaffActivityController controller,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final isWindows = _isWindows(context);
    String tempSelected = controller.selectedActivityType.value;
    final searchController = TextEditingController();
    final listScrollController = ScrollController();
    var searchQuery = '';

    try {
      final String? selected;
      if (isWindows) {
        selected = await Get.dialog<String>(
          Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final filteredTypes = StaffActivityController.activityTypes
                      .where((option) {
                        if (searchQuery.trim().isEmpty) return true;
                        final q = searchQuery.trim().toLowerCase();
                        final label = StaffActivityController.activityTypeLabel(
                          loc,
                          option,
                        ).toLowerCase();
                        return label.contains(q) ||
                            option.toLowerCase().contains(q);
                      })
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 8, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColor.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.category_outlined,
                                color: AppColor.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.select_activity_type,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    loc.activity_type_sheet_hint,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey.shade700,
                              ),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) =>
                              setModalState(() => searchQuery = value),
                          decoration: InputDecoration(
                            hintText: loc.search_default_hint,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).deleteButtonTooltip,
                                    onPressed: () {
                                      searchController.clear();
                                      setModalState(() => searchQuery = '');
                                    },
                                    icon: const Icon(Icons.clear, size: 18),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColor.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filteredTypes.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    loc.no_users_found,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            : RawScrollbar(
                                controller: listScrollController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                thickness: 8,
                                radius: const Radius.circular(8),
                                thumbColor: AppColor.primary.withValues(
                                  alpha: 0.55,
                                ),
                                trackColor: Colors.grey.shade200,
                                trackBorderColor: Colors.grey.shade300,
                                child: ListView.separated(
                                  controller: listScrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    12,
                                    8,
                                  ),
                                  itemCount: filteredTypes.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, index) {
                                    final option = filteredTypes[index];
                                    final isSelected = option == tempSelected;
                                    final isAll =
                                        option ==
                                        StaffActivityController
                                            .activityTypeAll;
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => setModalState(
                                          () => tempSelected = option,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 160,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColor.primary.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColor.primary
                                                  : Colors.grey.shade200,
                                              width: isSelected ? 1.6 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColor.primary
                                                            .withValues(
                                                              alpha: 0.14,
                                                            )
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppColor.primary
                                                              .withValues(
                                                                alpha: 0.25,
                                                              )
                                                        : Colors.grey.shade200,
                                                  ),
                                                ),
                                                child: Icon(
                                                  _activityFilterSheetIcon(
                                                    option,
                                                  ),
                                                  size: 20,
                                                  color: isSelected
                                                      ? AppColor.primary
                                                      : Colors.grey.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      StaffActivityController
                                                          .activityTypeLabel(
                                                            loc,
                                                            option,
                                                          ),
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: isAll
                                                            ? FontWeight.w700
                                                            : FontWeight.w600,
                                                        color: isSelected
                                                            ? AppColor.primary
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                    if (isAll) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        loc
                                                            .show_every_activity_type,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                isSelected
                                                    ? Icons
                                                          .check_circle_rounded
                                                    : Icons.circle_outlined,
                                                size: 22,
                                                color: isSelected
                                                    ? AppColor.primary
                                                    : Colors.grey.shade400,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Get.back(
                                  result:
                                      StaffActivityController.activityTypeAll,
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(loc.reset),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    Get.back(result: tempSelected),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(loc.apply),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          barrierDismissible: true,
        );
      } else {
        selected = await _presentChooser<String>(
          context: context,
          title: loc.select_activity_type,
          builder: (setState) {
            final filteredTypes = StaffActivityController.activityTypes.where((
              option,
            ) {
              if (searchQuery.trim().isEmpty) return true;
              final label = StaffActivityController.activityTypeLabel(
                loc,
                option,
              ).toLowerCase();
              return label.contains(searchQuery.trim().toLowerCase()) ||
                  option.toLowerCase().contains(
                    searchQuery.trim().toLowerCase(),
                  );
            }).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: loc.search_default_hint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                searchController.clear();
                                setState(() => searchQuery = '');
                              },
                              icon: const Icon(Icons.clear, size: 18),
                            ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (filteredTypes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                    child: Text(
                      loc.no_users_found,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  ...filteredTypes.map((option) {
                    final isSelected = option == tempSelected;
                    return InkWell(
                      onTap: () => setState(() => tempSelected = option),
                      child: Container(
                        width: double.infinity,
                        color: isSelected
                            ? AppColor.primary
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Text(
                          StaffActivityController.activityTypeLabel(
                            loc,
                            option,
                          ),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
          resetLabel: loc.reset,
          onReset: () => StaffActivityController.activityTypeAll,
          onApply: () => tempSelected,
          isWindows: false,
        );
      }

      if (selected == null) return;
      await controller.applyActivityType(selected);
    } finally {
      searchController.dispose();
      listScrollController.dispose();
    }
  }

  Future<void> _showDateRangeSheet(
    BuildContext context,
    StaffActivityController controller,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final isWindows = _isWindows(context);
    DateTime? tempFrom = controller.selectedFromDate.value;
    DateTime? tempTo = controller.selectedToDate.value;

    final result = await _presentChooser<Map<String, dynamic>>(
      context: context,
      title: loc.select_date_range,
      builder: (setState) {
        Future<void> pickDate({required bool isFrom}) async {
          final today = _todayDateOnly();
          final earliest = DateTime(2020);
          final minDate = earliest;
          final maxDate = isFrom
              ? (tempTo != null ? _clampDate(tempTo!, earliest, today) : today)
              : today;
          final rawInitial = isFrom
              ? (tempFrom ?? today)
              : (tempTo ?? tempFrom ?? today);
          final initialDate = _clampDate(rawInitial, minDate, maxDate);
          final picked = await showAppDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: minDate,
            lastDate: maxDate,
          );
          if (picked == null) return;
          setState(() {
            if (isFrom) {
              tempFrom = picked;
              if (tempTo != null && tempTo!.isBefore(picked)) {
                tempTo = picked;
              }
            } else {
              tempTo = picked;
              if (tempFrom != null && tempFrom!.isAfter(picked)) {
                tempFrom = picked;
              }
            }
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DatePickerTile(
                label: loc.from_date,
                value: tempFrom == null
                    ? loc.select_date
                    : _formatDate(tempFrom!),
                onTap: () => pickDate(isFrom: true),
              ),
              const SizedBox(height: 10),
              _DatePickerTile(
                label: loc.to_date,
                value: tempTo == null ? loc.select_date : _formatDate(tempTo!),
                onTap: () => pickDate(isFrom: false),
              ),
            ],
          ),
        );
      },
      resetLabel: loc.reset,
      onReset: () => {
        'applied': true,
        'from': DateTime.now(),
        'to': DateTime.now(),
        'reset': true,
      },
      onApply: () {
        if (tempFrom == null || tempTo == null) return null;
        return {'applied': true, 'from': tempFrom, 'to': tempTo};
      },
      isWindows: isWindows,
    );

    if (result == null || result['applied'] != true) return;
    if (result['reset'] == true) {
      await controller.resetDateRange();
      return;
    }
    await controller.applyDateRangeAndRefresh(
      result['from'] as DateTime?,
      result['to'] as DateTime?,
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  // ---------------------------------------------------------------------------
  // Modal presenter: dialog on Windows, bottom-sheet elsewhere.
  // ---------------------------------------------------------------------------

  Future<T?> _presentChooser<T>({
    required BuildContext context,
    required String title,
    required Widget Function(void Function(VoidCallback)) builder,
    required String resetLabel,
    required T? Function() onReset,
    required T? Function() onApply,
    required bool isWindows,
    bool Function()? showReset,
  }) async {
    final loc = AppLocalizations.of(context)!;
    if (isWindows) {
      return Get.dialog<T>(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final resetVisible = showReset?.call() ?? true;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 18, 0, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey.shade700,
                              ),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: SingleChildScrollView(
                          child: builder(setModalState),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            if (resetVisible) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Get.back(result: onReset()),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(resetLabel),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final v = onApply();
                                  if (v == null) return;
                                  Get.back(result: v);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(loc.apply),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final resetVisible = showReset?.call() ?? true;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 34),
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: SingleChildScrollView(
                          child: builder(setModalState),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            if (resetVisible) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(
                                    sheetContext,
                                  ).pop(onReset()),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    resetLabel,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final v = onApply();
                                  if (v == null) return;
                                  Navigator.of(sheetContext).pop(v);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  loc.apply,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: Colors.grey.shade700, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today_outlined, color: Colors.grey.shade700),
          ],
        ),
      ),
    );
  }
}

class _StaffActivityListCard extends StatelessWidget {
  const _StaffActivityListCard({
    required this.activity,
    required this.index,
    this.isWindows = false,
  });

  final ActivityModel activity;
  final int index;
  final bool isWindows;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = _activitySubtitle(activity, loc);
    final when = _formatActivityTimestamp(activity.createdAt);
    final staffName = _staffActorName(activity);
    final activityType = StaffActivityController.displayActivityTypeLabel(
      loc,
      activity.type,
    );
    final desc = activity.description.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: isWindows ? const Color(0xFFFBFCFF) : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWindows
              ? Colors.grey.shade200
              : colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}.'),
          const SizedBox(width: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _activityTypeIcon(activity.type),
                size: 22,
                color: AppColor.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staffName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (when.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    when,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  activityType,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColor.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                ],
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Icon(
          //   Icons.chevron_right_rounded,
          //   color: Colors.grey.shade600,
          //   size: 26,
          // ),
        ],
      ),
    );
  }
}
