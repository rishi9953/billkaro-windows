import 'dart:async';



import 'package:billkaro/app/services/Modals/kds/kds_response.dart';

import 'package:billkaro/app/services/kds/kds_realtime_service.dart';

import 'package:billkaro/config/config.dart';

import 'package:flutter/services.dart';



enum KdsFilter { all, newOrders, preparing, ready }



class KitchenDisplayController extends BaseController {

  final RxList<KdsTicket> tickets = <KdsTicket>[].obs;

  final Rx<KdsQueueSummary?> summary = Rx<KdsQueueSummary?>(null);

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  final Rx<KdsFilter> activeFilter = KdsFilter.all.obs;

  final RxBool soundEnabled = true.obs;

  final RxBool alertsEnabled = true.obs;

  final RxBool autoRefresh = true.obs;



  StreamSubscription<KdsQueueData>? _queueSub;

  Timer? _fallbackPollTimer;

  Timer? _clockTimer;

  bool _queueBaselineReady = false;

  bool _alertDialogOpen = false;

  final Map<String, String> _knownFiredAtByOrder = {};



  /// Bumps every second so elapsed timers re-render without re-fetching the queue.

  final RxInt clockTick = 0.obs;



  @override

  void onInit() {

    super.onInit();

    loadQueue();

    _bindRealtime();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {

      clockTick.value++;

    });

  }



  @override

  void onClose() {

    _queueSub?.cancel();

    _fallbackPollTimer?.cancel();

    _clockTimer?.cancel();

    super.onClose();

  }



  void _bindRealtime() {

    _queueSub?.cancel();

    _queueSub = KdsRealtimeService.instance.queueStream.listen(

      _applyQueueData,

      onError: (e) => debugPrint('KDS WS stream error: $e'),

    );



    final outletId = appPref.selectedOutlet?.id;

    if (outletId != null && autoRefresh.value) {

      KdsRealtimeService.instance.connect(outletId);

    }



    ever(autoRefresh, (enabled) {

      final id = appPref.selectedOutlet?.id;

      if (enabled && id != null) {

        KdsRealtimeService.instance.connect(id);

        _startFallbackPoll();

      } else {

        _fallbackPollTimer?.cancel();

        KdsRealtimeService.instance.disconnect();

      }

    });

    _startFallbackPoll();

  }



  void _startFallbackPoll() {

    _fallbackPollTimer?.cancel();

    _fallbackPollTimer = Timer.periodic(const Duration(seconds: 12), (_) {

      if (!autoRefresh.value) return;

      if (KdsRealtimeService.instance.isConnected.value) return;

      loadQueue(showLoader: false);

    });

  }



  List<KdsTicket> get filteredTickets {

    return tickets.where((ticket) {

      switch (activeFilter.value) {

        case KdsFilter.all:

          return true;

        case KdsFilter.newOrders:

          return ticket.kitchenStatus == 'new';

        case KdsFilter.preparing:

          return ticket.kitchenStatus == 'preparing';

        case KdsFilter.ready:

          return ticket.kitchenStatus == 'ready';

      }

    }).toList();

  }



  Future<void> loadQueue({bool showLoader = true}) async {

    final outletId = appPref.selectedOutlet?.id;

    if (outletId == null) {

      errorMessage.value = 'Please select an outlet';

      tickets.clear();

      return;

    }



    isLoading.value = showLoader;

    errorMessage.value = '';



    try {

      final response = await callApi(

        apiClient.getKdsQueue(outletId),

        showLoader: showLoader,

      );

      if (response != null) {

        _applyQueueData(response.data);

      } else {

        errorMessage.value = 'Unable to load kitchen queue';

      }

    } catch (e) {

      errorMessage.value = 'Unable to load kitchen queue';

      debugPrint('KDS load error: $e');

    } finally {

      isLoading.value = false;

    }

  }



  void _applyQueueData(KdsQueueData data) {

    summary.value = data.summary;

    final incoming = data.tickets;

    final alerts = _detectNewKitchenOrders(incoming);

    tickets.assignAll(incoming);

    if (alerts.isNotEmpty) {

      unawaited(_showNewOrderAlerts(alerts));

    }

    isLoading.value = false;

    errorMessage.value = '';

  }



  Future<void> startPreparing(KdsTicket ticket) async {

    await _updateStatus(ticket.orderId, 'preparing');

  }



  Future<void> markReady(KdsTicket ticket) async {

    await _updateStatus(ticket.orderId, 'ready');

  }



  Future<void> bumpTicket(KdsTicket ticket) async {

    try {

      await callApi(apiClient.bumpKdsTicket(ticket.orderId));

      // Remove immediately so the elapsed timer stops even before WS refresh.

      tickets.removeWhere((t) => t.orderId == ticket.orderId);

      _knownFiredAtByOrder.remove(ticket.orderId);

      _recomputeSummaryFromTickets();

    } catch (e) {

      showError(description: 'Failed to bump ticket');

    }

  }

  void _recomputeSummaryFromTickets() {
    final list = tickets;
    summary.value = KdsQueueSummary(
      newCount: list.where((t) => t.kitchenStatus == 'new').length,
      preparing: list.where((t) => t.kitchenStatus == 'preparing').length,
      ready: list.where((t) => t.kitchenStatus == 'ready').length,
      total: list.length,
    );
  }



  Future<void> toggleItemReady(KdsTicket ticket, KdsTicketItem item) async {

    final next = item.isReady ? 'pending' : 'ready';

    try {

      await callApi(

        apiClient.updateKdsItemStatus(ticket.orderId, item.itemId, {

          'status': next,

        }),

        showLoader: false,

      );

    } catch (e) {

      showError(description: 'Failed to update item');

    }

  }



  Future<void> _updateStatus(String orderId, String status) async {

    try {

      await callApi(

        apiClient.updateKdsOrderStatus(orderId, {'status': status}),

        showLoader: false,

      );

    } catch (e) {

      showError(description: 'Failed to update kitchen status');

    }

  }



  String formatElapsed(int seconds) {

    final m = seconds ~/ 60;

    final s = seconds % 60;

    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

  }



  String formatOrderEstimate(KdsTicket ticket) {

    if (ticket.estimatedPrepMinutes <= 0) return '';

    if (ticket.overEstimate) {

      final overMin =

          ((elapsedSecondsFor(ticket) - ticket.estimatedPrepMinutes * 60) / 60)

              .ceil();

      return 'Over ~${overMin > 0 ? overMin : 1} min';

    }

    final left = (ticket.remainingPrepSeconds / 60).ceil();

    return left > 0 ? 'Est. $left min left' : 'Est. ready';

  }



  String formatItemEstimate(KdsTicketItem item) {

    if (item.estimatedMinutes <= 0) return '';

    return 'Est. ${item.estimatedMinutes} min';

  }



  int elapsedSecondsFor(KdsTicket ticket) {

    final fired = DateTime.tryParse(ticket.firedAt);

    if (fired == null) return ticket.elapsedSeconds;

    return DateTime.now().difference(fired.toLocal()).inSeconds.clamp(0, 86400);

  }



  String urgencyFor(KdsTicket ticket) {

    if (ticket.overEstimate) return 'overdue';

    final seconds = elapsedSecondsFor(ticket);

    if (ticket.estimatedPrepMinutes > 0 &&

        ticket.remainingPrepSeconds <= 120) {

      return 'warning';

    }

    if (seconds >= 900) return 'overdue';

    if (seconds >= 600) return 'warning';

    return 'normal';

  }



  List<KdsTicket> _detectNewKitchenOrders(List<KdsTicket> incoming) {

    if (!_queueBaselineReady) {

      for (final ticket in incoming) {

        _knownFiredAtByOrder[ticket.orderId] = ticket.firedAt;

      }

      _queueBaselineReady = true;

      return const [];

    }



    final alerts = <KdsTicket>[];

    for (final ticket in incoming) {

      if (ticket.kitchenStatus != 'new') {

        _knownFiredAtByOrder[ticket.orderId] = ticket.firedAt;

        continue;

      }

      final previousFiredAt = _knownFiredAtByOrder[ticket.orderId];

      if (previousFiredAt == null || previousFiredAt != ticket.firedAt) {

        alerts.add(ticket);

      }

      _knownFiredAtByOrder[ticket.orderId] = ticket.firedAt;

    }



    final activeIds = incoming.map((t) => t.orderId).toSet();

    _knownFiredAtByOrder.removeWhere((id, _) => !activeIds.contains(id));

    return alerts;

  }



  Future<void> _showNewOrderAlerts(List<KdsTicket> newTickets) async {

    if (!alertsEnabled.value || newTickets.isEmpty || _alertDialogOpen) return;



    if (soundEnabled.value) {

      try {

        await SystemSound.play(SystemSoundType.alert);

      } catch (e) {

        debugPrint('KDS alert sound failed: $e');

      }

    }



    final context = Get.context;

    if (context == null || !context.mounted) return;



    _alertDialogOpen = true;

    try {

      await showDialog<void>(

      context: context,

      barrierDismissible: true,

      builder: (dialogContext) {

        final isSingle = newTickets.length == 1;

        final ticket = isSingle ? newTickets.first : null;



        return AlertDialog(

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

          icon: Icon(Icons.soup_kitchen_rounded, color: AppColor.primary, size: 36),

          title: Text(

            isSingle ? 'New Kitchen Order' : '${newTickets.length} New Orders',

            style: const TextStyle(fontWeight: FontWeight.w800),

          ),

          content: SingleChildScrollView(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                if (isSingle && ticket != null) ...[

                  Text(

                    'Bill #${ticket.billNumber}',

                    style: const TextStyle(

                      fontSize: 18,

                      fontWeight: FontWeight.w800,

                    ),

                  ),

                  const SizedBox(height: 6),

                  Text(

                    _ticketSubtitle(ticket),

                    style: TextStyle(color: Colors.grey.shade700),

                  ),

                  if (ticket.items.isNotEmpty) ...[

                    const SizedBox(height: 12),

                    ...ticket.items.take(5).map(

                      (item) => Padding(

                        padding: const EdgeInsets.only(bottom: 4),

                        child: Text(

                          '• ${item.kotSentQuantity}x ${item.itemName}',

                          style: const TextStyle(fontWeight: FontWeight.w600),

                        ),

                      ),

                    ),

                    if (ticket.items.length > 5)

                      Text(

                        '+ ${ticket.items.length - 5} more items',

                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),

                      ),

                  ],

                ] else

                  ...newTickets.map(

                    (t) => Padding(

                      padding: const EdgeInsets.only(bottom: 8),

                      child: Text(

                        'Bill #${t.billNumber} — ${_ticketSubtitle(t)}',

                        style: const TextStyle(fontWeight: FontWeight.w600),

                      ),

                    ),

                  ),

              ],

            ),

          ),

          actions: [

            TextButton(

              onPressed: () => Navigator.of(dialogContext).pop(),

              child: const Text('Dismiss'),

            ),

            FilledButton(

              onPressed: () {

                activeFilter.value = KdsFilter.newOrders;

                Navigator.of(dialogContext).pop();

              },

              child: const Text('View Queue'),

            ),

          ],

        );

      },

    );

    } finally {

      _alertDialogOpen = false;

    }

  }



  String _ticketSubtitle(KdsTicket ticket) {

    if (ticket.tableNumber?.trim().isNotEmpty == true) {

      return 'Table ${ticket.tableNumber}';

    }

    if (ticket.customerName?.trim().isNotEmpty == true) {

      return ticket.customerName!;

    }

    return ticket.orderFrom?.trim().isNotEmpty == true

        ? ticket.orderFrom!

        : 'Walk-in';

  }

}


