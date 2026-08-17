import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/Modals/wallet/wallet_transaction.dart';

enum OwnerDashRange { today, week, month }

enum OwnerSortBy { salesHigh, salesLow, nameAz, lowStock, walletLow }

enum OwnerStatusFilter { all, lowStock, lowWallet, expiringSub, inactiveSub }

class OutletWalletInfo {
  const OutletWalletInfo({
    required this.balance,
    required this.lowBalanceThreshold,
    required this.transactions,
  });

  final double balance;
  final double lowBalanceThreshold;
  final List<WalletTransaction> transactions;

  bool get isLow => balance > 0 && balance < lowBalanceThreshold;

  static OutletWalletInfo empty() => const OutletWalletInfo(
        balance: 0,
        lowBalanceThreshold: 50,
        transactions: [],
      );
}

class OutletSubscriptionInfo {
  const OutletSubscriptionInfo({
    required this.status,
    required this.planLabel,
    required this.startDate,
    required this.endDate,
    required this.paymentId,
    required this.daysRemaining,
  });

  final String status; // Active | Expiring | Expired | None
  final String planLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? paymentId;
  final int? daysRemaining;

  bool get isActive => status == 'Active' || status == 'Expiring';
  bool get isExpiring => status == 'Expiring';

  static OutletSubscriptionInfo none() => const OutletSubscriptionInfo(
        status: 'None',
        planLabel: 'No plan',
        startDate: null,
        endDate: null,
        paymentId: null,
        daysRemaining: null,
      );
}

class OutletInventoryInfo {
  const OutletInventoryInfo({
    required this.totalRawMaterials,
    required this.lowStockCount,
    required this.totalStockValue,
    required this.todayConsumption,
    required this.pendingPurchaseOrders,
    required this.trackedMenuItems,
    required this.lowStockMenuItems,
    required this.lowStockMaterials,
  });

  final int totalRawMaterials;
  final int lowStockCount;
  final double totalStockValue;
  final double todayConsumption;
  final int pendingPurchaseOrders;
  final int trackedMenuItems;
  final int lowStockMenuItems;
  final List<LowStockMaterial> lowStockMaterials;

  bool get hasLowStock => lowStockCount > 0 || lowStockMenuItems > 0;

  static OutletInventoryInfo empty() => const OutletInventoryInfo(
        totalRawMaterials: 0,
        lowStockCount: 0,
        totalStockValue: 0,
        todayConsumption: 0,
        pendingPurchaseOrders: 0,
        trackedMenuItems: 0,
        lowStockMenuItems: 0,
        lowStockMaterials: [],
      );

  factory OutletInventoryInfo.fromDashboard(InventoryDashboardData d) {
    return OutletInventoryInfo(
      totalRawMaterials: d.totalRawMaterials,
      lowStockCount: d.lowStockCount,
      totalStockValue: d.totalStockValue,
      todayConsumption: d.todayConsumption,
      pendingPurchaseOrders: d.pendingPurchaseOrders,
      trackedMenuItems: d.trackedMenuItems,
      lowStockMenuItems: d.lowStockMenuItems,
      lowStockMaterials: d.lowStockMaterials,
    );
  }
}

class OutletMetrics {
  const OutletMetrics({
    required this.outlet,
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
    required this.recentOrders,
    required this.wallet,
    required this.inventory,
    required this.subscription,
  });

  final OutletData outlet;
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
  final List<OrderModel> recentOrders;
  final OutletWalletInfo wallet;
  final OutletInventoryInfo inventory;
  final OutletSubscriptionInfo subscription;

  String get id => outlet.id ?? '';

  String get name {
    final n = outlet.businessName?.trim();
    if (n == null || n.isEmpty) return 'Unnamed Outlet';
    return n;
  }

  String get businessType => (outlet.businessType ?? '').trim();

  double get avgOrderValue {
    if (todayOrders <= 0) return 0;
    return todaySales / todayOrders;
  }

  double salesDeltaPct() {
    if (yesterdaySales <= 0) return todaySales > 0 ? 100 : 0;
    return ((todaySales - yesterdaySales) / yesterdaySales) * 100;
  }

  double salesFor(OwnerDashRange range) {
    switch (range) {
      case OwnerDashRange.today:
        return todaySales;
      case OwnerDashRange.week:
        return weekSales;
      case OwnerDashRange.month:
        return monthSales;
    }
  }

  int ordersFor(OwnerDashRange range) {
    switch (range) {
      case OwnerDashRange.today:
        return todayOrders;
      case OwnerDashRange.week:
        return weekOrders;
      case OwnerDashRange.month:
        return monthOrders;
    }
  }
}

class OwnerDashboardSummary {
  const OwnerDashboardSummary({
    required this.todaySales,
    required this.yesterdaySales,
    required this.todayOrders,
    required this.yesterdayOrders,
    required this.weekSales,
    required this.monthSales,
    required this.outletCount,
    required this.weekTrend,
    required this.weekLabels,
    required this.totalWalletBalance,
    required this.lowWalletOutlets,
    required this.lowStockOutlets,
    required this.totalStockValue,
    required this.activeSubscriptions,
    required this.expiringSubscriptions,
  });

  final double todaySales;
  final double yesterdaySales;
  final int todayOrders;
  final int yesterdayOrders;
  final double weekSales;
  final double monthSales;
  final int outletCount;
  final List<double> weekTrend;
  final List<String> weekLabels;
  final double totalWalletBalance;
  final int lowWalletOutlets;
  final int lowStockOutlets;
  final double totalStockValue;
  final int activeSubscriptions;
  final int expiringSubscriptions;

  double get salesDeltaPct {
    if (yesterdaySales <= 0) return todaySales > 0 ? 100 : 0;
    return ((todaySales - yesterdaySales) / yesterdaySales) * 100;
  }

  double get avgOrderValue {
    if (todayOrders <= 0) return 0;
    return todaySales / todayOrders;
  }

  static OwnerDashboardSummary empty() => const OwnerDashboardSummary(
        todaySales: 0,
        yesterdaySales: 0,
        todayOrders: 0,
        yesterdayOrders: 0,
        weekSales: 0,
        monthSales: 0,
        outletCount: 0,
        weekTrend: [0, 0, 0, 0, 0, 0, 0],
        weekLabels: ['', '', '', '', '', '', ''],
        totalWalletBalance: 0,
        lowWalletOutlets: 0,
        lowStockOutlets: 0,
        totalStockValue: 0,
        activeSubscriptions: 0,
        expiringSubscriptions: 0,
      );
}

class OwnerRecentSaleTx {
  const OwnerRecentSaleTx({
    required this.order,
    required this.outletName,
    required this.outletId,
  });

  final OrderModel order;
  final String outletName;
  final String outletId;
}

String formatOwnerMoney(double value) {
  final abs = value.abs();
  if (abs >= 10000000) {
    return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
  }
  if (abs >= 100000) {
    return '₹${(value / 100000).toStringAsFixed(2)}L';
  }
  if (abs >= 1000) {
    return '₹${(value / 1000).toStringAsFixed(1)}K';
  }
  return '₹${value.toStringAsFixed(0)}';
}

String formatOwnerMoneyFull(double value) {
  final raw = value.toStringAsFixed(0);
  final sb = StringBuffer('₹');
  final n = raw.length;
  for (var i = 0; i < n; i++) {
    sb.write(raw[i]);
    final remaining = n - i - 1;
    if (remaining > 0 && remaining % 3 == 0) sb.write(',');
  }
  return sb.toString();
}
