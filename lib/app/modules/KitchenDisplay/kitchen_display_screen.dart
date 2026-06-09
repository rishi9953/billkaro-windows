import 'package:billkaro/app/modules/KitchenDisplay/kitchen_display_controller.dart';
import 'package:billkaro/app/services/kds/kds_realtime_service.dart';
import 'package:billkaro/app/services/Modals/kds/kds_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/kitchen_display_browser.dart';
import 'package:flutter/material.dart';

class KitchenDisplayScreen extends StatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  State<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends State<KitchenDisplayScreen> {
  late final KitchenDisplayController c;

  @override
  void initState() {  
    super.initState();
    c = Get.isRegistered<KitchenDisplayController>()
        ? Get.find<KitchenDisplayController>()
        : Get.put(KitchenDisplayController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<KitchenDisplayController>()) {
      Get.delete<KitchenDisplayController>();
    }
    super.dispose();
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'overdue':
        return const Color(0xFFD32F2F);
      case 'warning':
        return const Color(0xFFF9A825);
      default:
        return AppColor.lightgreen;
    }
  }

  Color _statusAccent(String status) {
    switch (status) {
      case 'preparing':
        return const Color(0xFF1565C0);
      case 'ready':
        return AppColor.lightgreen;
      default:
        return const Color(0xFFE65100);
    }
  }

  Widget _orderSourceChip(String? source) {
    final label = (source ?? 'Order').trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColor.primary,
        ),
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required int count,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? color : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: selected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _ticketTotalItemQty(KdsTicket ticket) {
    return ticket.items.fold<int>(
      0,
      (sum, item) => sum + item.kotSentQuantity,
    );
  }

  static const double _kdsTicketCardHeight = 420;

  Widget _ticketActionBar(KdsTicket ticket) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (ticket.kitchenStatus == 'new')
            Expanded(
              child: FilledButton.icon(
                onPressed: () => c.startPreparing(ticket),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Start Preparing'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (ticket.kitchenStatus == 'preparing')
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => c.markReady(ticket),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Ready'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.lightgreen,
                  side: BorderSide(color: AppColor.lightgreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (ticket.kitchenStatus == 'ready')
            Expanded(
              child: FilledButton.icon(
                onPressed: () => c.bumpTicket(ticket),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Bump'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ticketCard(KdsTicket ticket) {
    final accent = _statusAccent(ticket.kitchenStatus);
    final totalItemQty = _ticketTotalItemQty(ticket);
    final tableLabel = ticket.tableNumber?.trim().isNotEmpty == true
        ? 'Table ${ticket.tableNumber}'
        : (ticket.customerName?.trim().isNotEmpty == true
              ? ticket.customerName!
              : 'Walk-in');

    return SizedBox(
      height: _kdsTicketCardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Bill #${ticket.billNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _orderSourceChip(ticket.orderFrom),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tableLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$totalItemQty items',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (ticket.estimatedPrepMinutes > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Order prep ~${ticket.estimatedPrepMinutes} min',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Obx(() {
                  c.clockTick.value;
                  final timerColor = _urgencyColor(c.urgencyFor(ticket));
                  final estLabel = c.formatOrderEstimate(ticket);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: timerColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: timerColor.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: timerColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              c.formatElapsed(c.elapsedSecondsFor(ticket)),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: timerColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (estLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          estLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: timerColor,
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
          if (ticket.specialInstructions?.trim().isNotEmpty == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFFFF8E1),
              child: Row(
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 16,
                    color: Color(0xFFF57C00),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticket.specialInstructions!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: ticket.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = ticket.items[index];
                return InkWell(
                  onTap: () => c.toggleItemReady(ticket, item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: item.isReady
                          ? AppColor.lightgreen.withOpacity(0.12)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.isReady
                            ? AppColor.lightgreen
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: item.isReady
                                ? AppColor.lightgreen
                                : accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.kotSentQuantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: item.isReady ? Colors.white : accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  decoration: item.isReady
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.isReady
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                ),
                              ),
                              if (!item.isReady &&
                                  item.estimatedMinutes > 0)
                                Text(
                                  c.formatItemEstimate(item),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              if (item.itemRemark?.trim().isNotEmpty == true)
                                Text(
                                  '📝 ${item.itemRemark!.trim()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: item.isReady
                                ? AppColor.lightgreen
                                : item.isPreparing
                                    ? const Color(0xFF1565C0).withOpacity(0.15)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              width: 2,
                              color: item.isReady
                                  ? AppColor.lightgreen
                                  : item.isPreparing
                                      ? const Color(0xFF1565C0)
                                      : Colors.grey.shade300,
                            ),
                          ),
                          child: item.isReady
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : item.isPreparing
                                  ? const Text(
                                      '…',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1565C0),
                                      ),
                                    )
                                  : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _ticketActionBar(ticket),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.colorScheme.surface,
            elevation: 2,
            shadowColor: Colors.black26,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.soup_kitchen_rounded,
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kitchen Display',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Obx(() {
                          final live =
                              KdsRealtimeService.instance.isConnected.value;
                          return Text(
                            live
                                ? 'Live — connected via WebSocket'
                                : 'Polling — WebSocket reconnecting…',
                            style: TextStyle(
                              fontSize: 13,
                              color: live
                                  ? const Color(0xFF2E7D32)
                                  : Colors.orange.shade800,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Obx(() {
                    return Row(
                      children: [
                        IconButton(
                          tooltip: c.alertsEnabled.value
                              ? 'New order alerts on'
                              : 'New order alerts off',
                          onPressed: () => c.alertsEnabled.toggle(),
                          icon: Icon(
                            c.alertsEnabled.value
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_outlined,
                            color: c.alertsEnabled.value
                                ? AppColor.primary
                                : Colors.grey,
                          ),
                        ),
                        IconButton(
                          tooltip: c.soundEnabled.value
                              ? 'Alert sound on'
                              : 'Alert sound off',
                          onPressed: () => c.soundEnabled.toggle(),
                          icon: Icon(
                            c.soundEnabled.value
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: c.soundEnabled.value
                                ? AppColor.primary
                                : Colors.grey,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Auto refresh',
                          onPressed: () => c.autoRefresh.toggle(),
                          icon: Icon(
                            c.autoRefresh.value
                                ? Icons.sync
                                : Icons.sync_disabled,
                            color: c.autoRefresh.value
                                ? AppColor.primary
                                : Colors.grey,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open in browser',
                          onPressed: KitchenDisplayBrowser.open,
                          icon: Icon(
                            Icons.open_in_browser_rounded,
                            color: AppColor.primary,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh now',
                          onPressed: () => c.loadQueue(),
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: AppColor.backGroundColor,
                  elevation: 1,
                  shadowColor: Colors.black12,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                    child: Obx(() {
                      final s = c.summary.value;
                      return Row(
                        children: [
                          _summaryChip(
                            label: 'All',
                            count: s?.total ?? 0,
                            color: AppColor.primary,
                            selected: c.activeFilter.value == KdsFilter.all,
                            onTap: () => c.activeFilter.value = KdsFilter.all,
                          ),
                          const SizedBox(width: 10),
                          _summaryChip(
                            label: 'New',
                            count: s?.newCount ?? 0,
                            color: const Color(0xFFE65100),
                            selected:
                                c.activeFilter.value == KdsFilter.newOrders,
                            onTap: () =>
                                c.activeFilter.value = KdsFilter.newOrders,
                          ),
                          const SizedBox(width: 10),
                          _summaryChip(
                            label: 'Preparing',
                            count: s?.preparing ?? 0,
                            color: const Color(0xFF1565C0),
                            selected:
                                c.activeFilter.value == KdsFilter.preparing,
                            onTap: () =>
                                c.activeFilter.value = KdsFilter.preparing,
                          ),
                          const SizedBox(width: 10),
                          _summaryChip(
                            label: 'Ready',
                            count: s?.ready ?? 0,
                            color: AppColor.lightgreen,
                            selected: c.activeFilter.value == KdsFilter.ready,
                            onTap: () => c.activeFilter.value = KdsFilter.ready,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                Expanded(
            child: Obx(() {
              if (c.isLoading.value && c.tickets.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c.errorMessage.value.isNotEmpty && c.tickets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.errorMessage.value),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => c.loadQueue(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final list = c.filteredTickets;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Kitchen is clear',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'New tickets appear when KOT is sent from POS',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1400
                        ? 4
                        : width >= 1050
                        ? 3
                        : width >= 700
                        ? 2
                        : 1;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: _kdsTicketCardHeight,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, index) => _ticketCard(list[index]),
                    );
                  },
                ),
              );
            }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
