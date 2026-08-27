import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/modules/StoreSession/store_session_history_controller.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:billkaro/app/services/Modals/store_session/store_session_model.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';

class StoreSessionHistoryScreen extends StatefulWidget {
  const StoreSessionHistoryScreen({super.key});

  @override
  State<StoreSessionHistoryScreen> createState() =>
      _StoreSessionHistoryScreenState();
}

class _StoreSessionHistoryScreenState extends State<StoreSessionHistoryScreen> {
  late final StoreSessionHistoryController controller;
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _timeFmt = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<StoreSessionHistoryController>()
        ? Get.find<StoreSessionHistoryController>()
        : Get.put(StoreSessionHistoryController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<StoreSessionHistoryController>()) {
      Get.delete<StoreSessionHistoryController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.store_history_title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: loc.refresh,
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.loadHistory(),
            ),
          ),
        ],
      ),
      body: Obx(() {
        return Column(
          children: [
            _buildFiltersSection(loc, isDesktop),
            Expanded(
              child: controller.isLoading.value && controller.sessions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : controller.sessions.isEmpty
                  ? _emptyState(loc)
                  : RefreshIndicator(
                      onRefresh: () => controller.loadHistory(),
                      child: Scrollbar(
                        thumbVisibility: isDesktop,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: EdgeInsets.all(isDesktop ? 24 : 16),
                          itemCount: controller.sessions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _sessionCard(
                              controller.sessions[index],
                              loc,
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFiltersSection(AppLocalizations loc, bool isDesktop) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 16,
        12,
        isDesktop ? 24 : 16,
        8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildPeriodSelector(loc)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateRangeSelector(loc)),
            ],
          ),
          const SizedBox(height: 12),
          _buildStaffSelector(loc),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations loc) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterLabel(loc.period),
          const SizedBox(height: 6),
          AppFilterDropdown2<String>(
            value: controller.selectedTimePeriod.value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            items: controller.getLocalizedTimePeriods().map((value) {
              return DropdownItem<String>(
                value: value,
                child: Text(
                  controller.getLocalizedTimePeriodLabel(value, loc),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                controller.selectedTimePeriod.value = newValue;
                controller.filterByTimePeriod();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterLabel(loc.date_range),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: controller.selectCustomDateRange,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.formattedDateRange,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Assets.svg.calendar.svg(
                    color: AppColor.grey,
                    height: 18,
                    width: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffSelector(AppLocalizations loc) {
    return Obx(() {
      final options = controller.staffFilterOptions;
      final selected = controller.selectedStaffFilterId.value;
      final validSelected =
          selected == 'all' || options.any((o) => o.id == selected)
          ? selected
          : 'all';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterLabel(loc.staff_filter),
          const SizedBox(height: 6),
          controller.isLoadingStaff.value && options.isEmpty
              ? Container(
                  height: 48,
                  decoration: appFilterDropdownDecoration(),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        loc.all_users,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                )
              : AppFilterDropdown2<String>(
                  value: validSelected,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  items: [
                    DropdownItem<String>(
                      value: 'all',
                      child: Text(loc.all_users),
                    ),
                    ...options.map(
                      (staff) => DropdownItem<String>(
                        value: staff.id,
                        child: Text(staff.name),
                      ),
                    ),
                  ],
                  onChanged: controller.onStaffFilterChanged,
                ),
        ],
      );
    });
  }

  Widget _buildFilterLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[700],
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _emptyState(AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              loc.store_history_empty,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionCard(OutletDaySession session, AppLocalizations loc) {
    final isOpen = session.isOpen;
    final summary = session.summary;
    final sales = summary?.totalSales ?? 0;
    final orders = summary?.totalOrders ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? const Color(0xFF1B7F4B).withOpacity(0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOpen
                          ? const Color(0xFF2E9E62)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    isOpen ? loc.store_open : loc.store_closed,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isOpen
                          ? const Color(0xFF1B7F4B)
                          : Colors.grey[700],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _dateFmt.format(DateTime.parse(session.businessDate)),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow(
              Icons.schedule_rounded,
              loc.opened_at,
              session.openedAt != null
                  ? _timeFmt.format(session.openedAt!.toLocal())
                  : '—',
            ),
            const SizedBox(height: 8),
            _staffRow(loc.opened_by, session.openedByName),
            if (session.closedAt != null) ...[
              const SizedBox(height: 8),
              _infoRow(
                Icons.schedule_rounded,
                loc.closed_at,
                _timeFmt.format(session.closedAt!.toLocal()),
              ),
            ],
            if (!isOpen) ...[
              const SizedBox(height: 8),
              _staffRow(loc.closed_by, session.closedByName),
            ],
            const Divider(height: 24),
            Row(
              children: [
                _metric(loc.total_orders, '$orders'),
                _metric(loc.total_sales, _currency.format(sales)),
                _metric(
                  loc.opening_cash,
                  _currency.format(session.openingCash),
                ),
              ],
            ),
            if (!isOpen && session.closingCash != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _metric(
                    loc.closing_cash,
                    _currency.format(session.closingCash!),
                  ),
                  session.cashVariance != null
                      ? _metric(
                          loc.cash_variance,
                          _currency.format(session.cashVariance!),
                          valueColor: session.cashVariance! >= 0
                              ? const Color(0xFF1B7F4B)
                              : const Color(0xFFC62828),
                        )
                      : const Expanded(child: SizedBox.shrink()),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
            if (summary != null && summary.paymentBreakdown.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.paymentBreakdown.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_capitalize(e.key)}: ${_currency.format(e.value)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _staffRow(String label, String? staffName) {
    final name = staffName?.trim();
    final display = (name != null && name.isNotEmpty) ? name : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColor.primary.withOpacity(0.12),
            child: Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  display,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
