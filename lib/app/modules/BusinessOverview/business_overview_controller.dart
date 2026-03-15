import 'dart:async';
import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/config/config.dart';

class BusinessOverviewController extends BaseController {
  var todayTotalSales = 0.0.obs;
  var yesterdaySales = 0.0.obs;
  var todayTotalOrders = 0.obs;
  var yesterdayOrders = 0.obs;

  var lastMonthAvgDailyOrder = 0.0.obs;
  var lastMonthAvgDailySale = 0.0.obs;
  var thisMonthAvgDailyOrder = 0.0.obs;
  var thisMonthAvgDailySale = 0.0.obs;

  var selectedTab = 0.obs; // 0 = 7 days, 1 = 30 days

  RxList<OrderModel> allOrders = <OrderModel>[].obs;
  RxList<Map<String, dynamic>> mostSellingItems = <Map<String, dynamic>>[].obs;

  // Loading state
  final RxBool isLoadingOrders = false.obs;

  // Connectivity listener
  StreamSubscription<bool>? _connectivitySubscription;
  bool _lastConnectivityState = false;
  bool _hasLoadedFromApi = false;

  @override
  void onReady() {
    getOrderList();

    // Listen to connectivity changes
    _connectivitySubscription = ConnectivityHelper.instance.onConnectivityChange
        .listen((isConnected) {
          if (isConnected && !_lastConnectivityState && !_hasLoadedFromApi) {
            debugPrint(
              '🌐 Internet came back - refreshing business overview from API',
            );
            getOrderList(forceApiRefresh: true);
          }
          _lastConnectivityState = isConnected;
        });

    _lastConnectivityState = ConnectivityHelper.instance.isConnected;
    super.onReady();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  void selectTab(int index) {
    selectedTab.value = index;

    // Recalculate based on new tab
    calculateMostSelling();
  }

  // ---------------------------------------------------------------------------
  // API CALL WITH OFFLINE SUPPORT
  // ---------------------------------------------------------------------------

  Future<void> getOrderList({bool forceApiRefresh = false}) async {
    try {
      isLoadingOrders.value = true;

      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) return;

      final isOnline = await NetworkUtils.hasInternetConnection();
      final db = AppDatabase();
      debugPrint('🔄 BusinessOverview isOnline: $isOnline');

      /// ===============================
      /// 🔌 ONLINE → API + SAVE SQLITE (only if not already loaded or forced)
      /// ===============================
      if (isOnline && (!_hasLoadedFromApi || forceApiRefresh)) {
        debugPrint('🌐 Internet available → fetching from API');

        final res = await callApi(
          apiClient.getOrders(appPref.user!.id!, outletId, null, null, null, null, null, null), // page, limit, category, paymentReceivedIn
          showLoader: false,
        );

        if (res?.status == "success") {
          allOrders.value = res!.data
              .where((e) => e.status == 'closed')
              .toList();

          /// Save to SQLite
          await db.insertOrders(
            allOrders,
            appPref.selectedOutlet!.id!,
            isSyncedFromApi: true,
          );

          _hasLoadedFromApi = true;
          debugPrint('✅ Orders synced to SQLite (${allOrders.length})');

          calculateTodayYesterday();
          calculateMonthlyAverages();
          calculateMostSelling();
        }
      } else if (!isOnline) {
        _hasLoadedFromApi = false;
      }
      /// ===============================
      /// 📦 OFFLINE → LOAD FROM SQLITE
      /// ===============================
      else {
        debugPrint('📴 No internet → loading from SQLite');

        final localOrders = await db.getAllOrders(
          outletId: appPref.selectedOutlet!.id!,
        );

        allOrders.value = localOrders
            .where((e) => e.status == 'closed')
            .toList();

        debugPrint('✅ Loaded ${allOrders.length} orders from SQLite');

        calculateTodayYesterday();
        calculateMonthlyAverages();
        calculateMostSelling();
      }
    } catch (e) {
      debugPrint('❌ Order load error on business: $e');
      showError(description: "Error fetching orders");
    } finally {
      isLoadingOrders.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // TODAY & YESTERDAY
  // ---------------------------------------------------------------------------

  void calculateTodayYesterday() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));

    double todaySales = 0;
    int todayOrders = 0;

    double ySales = 0;
    int yOrders = 0;

    for (var order in allOrders) {
      DateTime date = DateTime.parse(order.createdAt);

      DateTime orderDay = DateTime(date.year, date.month, date.day);

      if (orderDay == today) {
        todaySales += (order.totalAmount ?? 0);
        todayOrders++;
      } else if (orderDay == yesterday) {
        ySales += (order.totalAmount ?? 0);
        yOrders++;
      }
    }

    todayTotalSales.value = todaySales;
    todayTotalOrders.value = todayOrders;

    yesterdaySales.value = ySales;
    yesterdayOrders.value = yOrders;
  }

  // ---------------------------------------------------------------------------
  // MONTHLY AVERAGES
  // ---------------------------------------------------------------------------

  void calculateMonthlyAverages() {
    DateTime now = DateTime.now();

    DateTime startThisMonth = DateTime(now.year, now.month, 1);
    DateTime startLastMonth = DateTime(now.year, now.month - 1, 1);
    DateTime endLastMonth = DateTime(now.year, now.month, 0);

    double thisMonthSale = 0;
    int thisMonthCount = 0;

    double lastMonthSale = 0;
    int lastMonthCount = 0;

    for (var order in allOrders) {
      DateTime date = DateTime.parse(order.createdAt);

      if (date.isAfter(startThisMonth)) {
        thisMonthSale += (order.totalAmount ?? 0);
        thisMonthCount++;
      }

      if (date.isAfter(startLastMonth) && date.isBefore(endLastMonth)) {
        lastMonthSale += (order.totalAmount ?? 0);
        lastMonthCount++;
      }
    }

    int daysThisMonth = now.day;
    int daysLastMonth = endLastMonth.day;

    thisMonthAvgDailySale.value = thisMonthSale / daysThisMonth;
    thisMonthAvgDailyOrder.value = thisMonthCount / daysThisMonth;

    lastMonthAvgDailySale.value = lastMonthSale / daysLastMonth;
    lastMonthAvgDailyOrder.value = lastMonthCount / daysLastMonth;
  }

  // ---------------------------------------------------------------------------
  // MOST SELLING ITEMS (7 OR 30 DAYS)
  // ---------------------------------------------------------------------------

  void calculateMostSelling() {
    int days = selectedTab.value == 0 ? 7 : 30;

    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: days));

    // name → qty + price
    Map<String, Map<String, dynamic>> itemMap = {};

    for (var order in allOrders) {
      DateTime date = DateTime.parse(order.createdAt);

      if (date.isAfter(startDate)) {
        for (var item in order.items ?? []) {
          String name = item.itemName ?? "Unknown";
          int qty = item.quantity ?? 0;
          double price = (item.salePrice ?? 0).toDouble(); // ✔ FIXED salePrice

          if (!itemMap.containsKey(name)) {
            itemMap[name] = {"qty": 0, "price": 0.0};
          }

          itemMap[name]!["qty"] += qty;
          itemMap[name]!["price"] += (price * qty); // total revenue
        }
      }
    }

    // Convert to list + sort
    final sorted =
        itemMap.entries
            .map(
              (e) => {
                "name": e.key,
                "qty": e.value["qty"],
                "price": e.value["price"], // total revenue
              },
            )
            .toList()
          ..sort(
            (a, b) =>
                ((b["qty"] ?? 0) as num).compareTo((a["qty"] ?? 0) as num),
          );

    mostSellingItems.value = sorted;

    print("mostSellingItems: $sorted");
  }
}
