import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/OwnerPanel/models/outlet_metrics.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/Modals/wallet/wallet_transaction.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';

class OwnerPanelController extends BaseController {
  final searchQuery = ''.obs;
  final expandedOutletIds = <String>{}.obs;
  final activeOutletId = RxnString();
  final outlets = <OutletData>[].obs;
  final metrics = <OutletMetrics>[].obs;
  final summary = OwnerDashboardSummary.empty().obs;
  final selectedRange = OwnerDashRange.today.obs;
  final selectedOutletFilterId = RxnString(); // null = all
  final selectedBusinessType = ''.obs; // empty = all
  final statusFilter = OwnerStatusFilter.all.obs;
  final sortBy = OwnerSortBy.salesHigh.obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final loadError = RxnString();

  static const _weekDayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void onInit() {
    super.onInit();
    activeOutletId.value = appPref.selectedOutlet?.id;
    refreshOutlets();
    loadDashboard();
  }

  void refreshOutlets() {
    outlets.assignAll(appPref.allOutlets);
  }

  List<String> get businessTypeOptions {
    final types = outlets
        .map((o) => (o.businessType ?? '').trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return types;
  }

  List<OutletMetrics> get filteredMetrics {
    var list = metrics.toList();

    final outletId = selectedOutletFilterId.value;
    if (outletId != null && outletId.isNotEmpty) {
      list = list.where((m) => m.id == outletId).toList();
    }

    final type = selectedBusinessType.value.trim().toLowerCase();
    if (type.isNotEmpty) {
      list = list.where((m) => m.businessType.toLowerCase() == type).toList();
    }

    switch (statusFilter.value) {
      case OwnerStatusFilter.all:
        break;
      case OwnerStatusFilter.lowStock:
        list = list.where((m) => m.inventory.hasLowStock).toList();
      case OwnerStatusFilter.lowWallet:
        list = list.where((m) => m.wallet.isLow || m.wallet.balance <= 0).toList();
      case OwnerStatusFilter.expiringSub:
        list = list.where((m) => m.subscription.isExpiring).toList();
      case OwnerStatusFilter.inactiveSub:
        list = list
            .where(
              (m) =>
                  m.subscription.status == 'Expired' ||
                  m.subscription.status == 'None',
            )
            .toList();
    }

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((m) {
        final o = m.outlet;
        final haystack = [
          o.businessName,
          o.businessType,
          o.businessCategory,
          o.outletAddress,
          o.phoneNumber,
          o.gstinNumber,
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    switch (sortBy.value) {
      case OwnerSortBy.salesHigh:
        list.sort(
          (a, b) => b
              .salesFor(selectedRange.value)
              .compareTo(a.salesFor(selectedRange.value)),
        );
      case OwnerSortBy.salesLow:
        list.sort(
          (a, b) => a
              .salesFor(selectedRange.value)
              .compareTo(b.salesFor(selectedRange.value)),
        );
      case OwnerSortBy.nameAz:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case OwnerSortBy.lowStock:
        list.sort(
          (a, b) => b.inventory.lowStockCount.compareTo(a.inventory.lowStockCount),
        );
      case OwnerSortBy.walletLow:
        list.sort((a, b) => a.wallet.balance.compareTo(b.wallet.balance));
    }

    return list;
  }

  List<OutletMetrics> get rankedBySelectedRange => filteredMetrics;

  List<OwnerRecentSaleTx> get recentSalesTransactions {
    final txs = <OwnerRecentSaleTx>[];
    for (final m in filteredMetrics) {
      for (final o in m.recentOrders) {
        txs.add(
          OwnerRecentSaleTx(
            order: o,
            outletName: m.name,
            outletId: m.id,
          ),
        );
      }
    }
    txs.sort((a, b) {
      final da = DateTime.tryParse(a.order.createdAt) ?? DateTime(1970);
      final db = DateTime.tryParse(b.order.createdAt) ?? DateTime(1970);
      return db.compareTo(da);
    });
    return txs.take(25).toList();
  }

  List<MapEntry<OutletMetrics, WalletTransaction>> get recentWalletTransactions {
    final rows = <MapEntry<OutletMetrics, WalletTransaction>>[];
    for (final m in filteredMetrics) {
      for (final tx in m.wallet.transactions.take(8)) {
        rows.add(MapEntry(m, tx));
      }
    }
    rows.sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt));
    return rows.take(20).toList();
  }

  List<LowStockMaterial> get aggregatedLowStock {
    final items = <LowStockMaterial>[];
    for (final m in filteredMetrics) {
      items.addAll(m.inventory.lowStockMaterials.take(5));
    }
    return items.take(15).toList();
  }

  bool get hasActiveFilters =>
      selectedOutletFilterId.value != null ||
      selectedBusinessType.value.isNotEmpty ||
      statusFilter.value != OwnerStatusFilter.all ||
      sortBy.value != OwnerSortBy.salesHigh ||
      searchQuery.value.trim().isNotEmpty;

  void setRange(OwnerDashRange range) => selectedRange.value = range;

  void setOutletFilter(String? outletId) =>
      selectedOutletFilterId.value = outletId;

  void setBusinessType(String type) => selectedBusinessType.value = type;

  void setStatusFilter(OwnerStatusFilter filter) => statusFilter.value = filter;

  void setSortBy(OwnerSortBy sort) => sortBy.value = sort;

  void onSearchChanged(String value) => searchQuery.value = value;

  void clearSearch() => searchQuery.value = '';

  void clearFilters() {
    selectedOutletFilterId.value = null;
    selectedBusinessType.value = '';
    statusFilter.value = OwnerStatusFilter.all;
    sortBy.value = OwnerSortBy.salesHigh;
    searchQuery.value = '';
  }

  void toggleExpanded(String? outletId) {
    if (outletId == null || outletId.isEmpty) return;
    if (expandedOutletIds.contains(outletId)) {
      expandedOutletIds.remove(outletId);
    } else {
      expandedOutletIds.add(outletId);
    }
  }

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    if (isLoading.value) return;
    refreshOutlets();

    if (outlets.isEmpty) {
      metrics.clear();
      summary.value = OwnerDashboardSummary.empty();
      return;
    }

    isLoading.value = !forceRefresh || metrics.isEmpty;
    isRefreshing.value = forceRefresh;
    loadError.value = null;

    try {
      final results = await Future.wait(
        outlets
            .where((o) => (o.id ?? '').isNotEmpty)
            .map((o) => _loadOutletMetrics(o, forceRefresh: forceRefresh)),
      );

      final valid = results.whereType<OutletMetrics>().toList()
        ..sort((a, b) => b.todaySales.compareTo(a.todaySales));

      metrics.assignAll(valid);
      summary.value = _buildSummary(valid);
    } catch (e, st) {
      debugPrint('OwnerPanel load error: $e\n$st');
      loadError.value = 'Could not load outlet analytics';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshDashboard() => loadDashboard(forceRefresh: true);

  Future<OutletMetrics?> _loadOutletMetrics(
    OutletData outlet, {
    required bool forceRefresh,
  }) async {
    final outletId = outlet.id;
    if (outletId == null || outletId.isEmpty) return null;

    final db = AppDatabase();
    List<OrderModel> closed = [];

    try {
      final local = await db.getAllOrders(outletId: outletId);
      closed = local.where((e) => e.status == 'closed').toList();
    } catch (_) {}

    final walletFuture = _loadWallet(outletId);
    final inventoryFuture = _loadInventory(outletId);

    if (isConnectedToNetwork && (forceRefresh || closed.isEmpty)) {
      try {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 31));
        final startStr = DateFormat('yyyy-MM-dd').format(start);
        final endStr = DateFormat('yyyy-MM-dd').format(now);

        final response = await callApi(
          apiClient.getOrders(
            appPref.ordersApiUserId ?? '',
            outletId,
            null,
            null,
            null,
            null,
            startStr,
            endStr,
          ),
          showLoader: false,
        );

        if (response?.status == 'success') {
          await db.insertOrders(
            response!.data,
            outletId,
            isSyncedFromApi: true,
          );
          final updated = await db.getAllOrders(outletId: outletId);
          closed = updated.where((e) => e.status == 'closed').toList();
        }
      } catch (e) {
        debugPrint('OwnerPanel API sync failed for $outletId: $e');
      }
    }

    final wallet = await walletFuture;
    final inventory = await inventoryFuture;
    final sales = _computeSales(closed);
    final recent = [...closed]
      ..sort((a, b) {
        final da = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
        final db = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
        return db.compareTo(da);
      });

    return OutletMetrics(
      outlet: outlet,
      todaySales: sales.todaySales,
      yesterdaySales: sales.yesterdaySales,
      todayOrders: sales.todayOrders,
      yesterdayOrders: sales.yesterdayOrders,
      weekSales: sales.weekSales,
      monthSales: sales.monthSales,
      weekOrders: sales.weekOrders,
      monthOrders: sales.monthOrders,
      weekSeries: sales.weekSeries,
      paymentBreakdown: sales.paymentBreakdown,
      recentOrders: recent.take(8).toList(),
      wallet: wallet,
      inventory: inventory,
      subscription: _computeSubscription(outlet),
    );
  }

  Future<OutletWalletInfo> _loadWallet(String outletId) async {
    final userId = appPref.ownerUserId;
    if (userId == null || userId.isEmpty || !isConnectedToNetwork) {
      return OutletWalletInfo.empty();
    }
    try {
      final res = await callApi(
        apiClient.getOutletWallet(outletId, userId),
        showLoader: false,
      );
      if (res is Map && res['data'] is Map) {
        final json = Map<String, dynamic>.from(res['data'] as Map);
        final txs = <WalletTransaction>[];
        final txRaw = json['transactions'];
        if (txRaw is List) {
          txs.addAll(
            txRaw
                .whereType<Map>()
                .map(
                  (e) => WalletTransaction.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                ),
          );
          txs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        return OutletWalletInfo(
          balance: (json['balance'] as num?)?.toDouble() ?? 0,
          lowBalanceThreshold:
              (json['lowBalanceThreshold'] as num?)?.toDouble() ?? 50,
          transactions: txs,
        );
      }
    } catch (e) {
      debugPrint('OwnerPanel wallet failed for $outletId: $e');
    }
    return OutletWalletInfo.empty();
  }

  Future<OutletInventoryInfo> _loadInventory(String outletId) async {
    if (!isConnectedToNetwork) return OutletInventoryInfo.empty();
    try {
      final res = await callApi(
        apiClient.getInventoryDashboard(outletId),
        showLoader: false,
      );
      if (res is Map && res['data'] != null) {
        final data = InventoryDashboardData.fromJson(
          Map<String, dynamic>.from(res['data'] as Map),
        );
        return OutletInventoryInfo.fromDashboard(data);
      }
    } catch (e) {
      debugPrint('OwnerPanel inventory failed for $outletId: $e');
    }
    return OutletInventoryInfo.empty();
  }

  OutletSubscriptionInfo _computeSubscription(OutletData outlet) {
    final subs = outlet.subscriptions;
    if (subs == null || subs.isEmpty) return OutletSubscriptionInfo.none();

    OutletSubscription? best;
    DateTime? bestEnd;
    for (final sub in subs) {
      final end = DateTime.tryParse(sub.endDate ?? '');
      if (end == null) continue;
      if (bestEnd == null || end.isAfter(bestEnd)) {
        best = sub;
        bestEnd = end;
      }
    }
    best ??= subs.first;
    bestEnd ??= DateTime.tryParse(best.endDate ?? '');
    final start = DateTime.tryParse(best.startDate ?? '');

    final now = DateTime.now();
    String status = 'None';
    int? daysRemaining;
    if (bestEnd != null) {
      daysRemaining = bestEnd.difference(now).inDays;
      if (bestEnd.isAfter(now)) {
        status = daysRemaining <= 7 ? 'Expiring' : 'Active';
      } else {
        status = 'Expired';
      }
    }

    final days = best.subscription?.duration;
    final price = best.subscription?.price;
    final planLabel = (days != null && price != null)
        ? '$days days · ₹${price.toStringAsFixed(0)}'
        : (status == 'None' ? 'No plan' : status);

    return OutletSubscriptionInfo(
      status: status,
      planLabel: planLabel,
      startDate: start,
      endDate: bestEnd,
      paymentId: best.paymentId,
      daysRemaining: daysRemaining,
    );
  }

  _SalesBucket _computeSales(List<OrderModel> closed) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(const Duration(days: 6));
    final monthStart = today.subtract(const Duration(days: 29));

    double todaySales = 0;
    double yesterdaySales = 0;
    int todayOrders = 0;
    int yesterdayOrders = 0;
    double weekSales = 0;
    double monthSales = 0;
    int weekOrders = 0;
    int monthOrders = 0;
    final weekSeries = List<double>.filled(7, 0);
    final payments = <String, double>{};

    for (final order in closed) {
      final parsed = DateTime.tryParse(order.createdAt);
      if (parsed == null) continue;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      final amount = order.totalAmount;

      if (!day.isBefore(monthStart)) {
        monthSales += amount;
        monthOrders++;
      }
      if (!day.isBefore(weekStart)) {
        weekSales += amount;
        weekOrders++;
        final idx = day.difference(weekStart).inDays;
        if (idx >= 0 && idx < 7) weekSeries[idx] += amount;
      }
      if (day == today) {
        todaySales += amount;
        todayOrders++;
        _accumulatePayment(payments, order, amount);
      } else if (day == yesterday) {
        yesterdaySales += amount;
        yesterdayOrders++;
      }
    }

    return _SalesBucket(
      todaySales: todaySales,
      yesterdaySales: yesterdaySales,
      todayOrders: todayOrders,
      yesterdayOrders: yesterdayOrders,
      weekSales: weekSales,
      monthSales: monthSales,
      weekOrders: weekOrders,
      monthOrders: monthOrders,
      weekSeries: weekSeries,
      paymentBreakdown: payments,
    );
  }

  void _accumulatePayment(
    Map<String, double> map,
    OrderModel order,
    double fallbackAmount,
  ) {
    final splits = order.splitPayments;
    if (splits != null && splits.isNotEmpty) {
      for (final s in splits) {
        final key = s.paymentMethod.trim();
        final label = key.isEmpty ? 'Other' : key;
        map[label] = (map[label] ?? 0) + s.amount;
      }
      return;
    }
    final method = (order.paymentReceivedIn ?? 'Other').trim();
    final label = method.isEmpty ? 'Other' : method;
    map[label] = (map[label] ?? 0) + fallbackAmount;
  }

  OwnerDashboardSummary _buildSummary(List<OutletMetrics> list) {
    final weekTrend = List<double>.filled(7, 0);
    double todaySales = 0;
    double yesterdaySales = 0;
    int todayOrders = 0;
    int yesterdayOrders = 0;
    double weekSales = 0;
    double monthSales = 0;
    double totalWallet = 0;
    double totalStock = 0;
    var lowWallet = 0;
    var lowStock = 0;
    var activeSubs = 0;
    var expiringSubs = 0;

    for (final m in list) {
      todaySales += m.todaySales;
      yesterdaySales += m.yesterdaySales;
      todayOrders += m.todayOrders;
      yesterdayOrders += m.yesterdayOrders;
      weekSales += m.weekSales;
      monthSales += m.monthSales;
      totalWallet += m.wallet.balance;
      totalStock += m.inventory.totalStockValue;
      if (m.wallet.isLow || m.wallet.balance <= 0) lowWallet++;
      if (m.inventory.hasLowStock) lowStock++;
      if (m.subscription.isActive) activeSubs++;
      if (m.subscription.isExpiring) expiringSubs++;
      for (var i = 0; i < 7; i++) {
        weekTrend[i] += m.weekSeries[i];
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final labels = List<String>.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      return _weekDayLabels[d.weekday - 1];
    });

    return OwnerDashboardSummary(
      todaySales: todaySales,
      yesterdaySales: yesterdaySales,
      todayOrders: todayOrders,
      yesterdayOrders: yesterdayOrders,
      weekSales: weekSales,
      monthSales: monthSales,
      outletCount: list.length,
      weekTrend: weekTrend,
      weekLabels: labels,
      totalWalletBalance: totalWallet,
      lowWalletOutlets: lowWallet,
      lowStockOutlets: lowStock,
      totalStockValue: totalStock,
      activeSubscriptions: activeSubs,
      expiringSubscriptions: expiringSubs,
    );
  }

  void switchToOutlet(OutletData outlet) {
    if (outlet.id == null || outlet.id!.isEmpty) return;
    if (outlet.id == activeOutletId.value) return;

    if (Get.isRegistered<HomeScreenController>()) {
      Get.find<HomeScreenController>().selectOutlet(outlet, closeSheet: false);
    } else {
      appPref.selectedOutlet = outlet;
    }
    activeOutletId.value = outlet.id;
  }

  String valueOrDash(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '—';
    return trimmed;
  }

  String activePlanLabel(OutletData outlet) =>
      _computeSubscription(outlet).planLabel;
}

class _SalesBucket {
  const _SalesBucket({
    required this.todaySales,
    required this.yesterdaySales,
    required this.todayOrders,
    required this.yesterdayOrders,
    required this.weekSales,
    required this.monthSales,
    required this.weekOrders,
    required this.monthOrders,
    required this.weekSeries,
    required this.paymentBreakdown,
  });

  final double todaySales;
  final double yesterdaySales;
  final int todayOrders;
  final int yesterdayOrders;
  final double weekSales;
  final double monthSales;
  final int weekOrders;
  final int monthOrders;
  final List<double> weekSeries;
  final Map<String, double> paymentBreakdown;
}
