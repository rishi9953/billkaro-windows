import 'dart:async';

import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/app/services/sync/bill_number_util.dart';
import 'package:billkaro/app/services/sync/order_sync_util.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/offline/offline_table_loader.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter/material.dart';

class OrderDetailsController extends BaseController {
  final formKey = GlobalKey<FormState>();

  final billNumber = TextEditingController();
  final tableNumber = TextEditingController();
  final customerName = TextEditingController();
  final phoneNumber = TextEditingController();
  final discount = TextEditingController();
  final serviceCharge = TextEditingController();

  final orderFrom = ''.obs;
  bool get isDineIn => orderFrom.value.trim().toLowerCase() == 'dine in';

  final discountType = 'percentage'.obs;
  final status = 'pending'.obs;

  final RxBool isLoading = true.obs;
  final RxList<TableModel> availableTables = <TableModel>[].obs;
  final RxBool hasOutletTables = false.obs;
  Timer? _phoneLookupTimer;

  bool get showTableField =>
      isDineIn && HomeMainRoutes.outletShowsTables() && hasOutletTables.value;

  /// All orders from API
  final RxList<OrderModel> allOrders = <OrderModel>[].obs;

  /// Local database instance
  final AppDatabase _db = AppDatabase();

  OrderModel? orderDetails;

  /// Save Order Details (bill number is preview-only; server assigns on create).
  Future<CreateorderRequest?> buildOrderDetails() async {
    return CreateorderRequest(
      billNumber: null,
      tableNumber: showTableField ? tableNumber.text : '',
      customerName: customerName.text,
      phoneNumber: phoneNumber.text,
      discount: double.tryParse(discount.text) ?? 0.0,
      discountType: discountType.value,
      serviceCharge: double.tryParse(serviceCharge.text) ?? 0.0,
      status: 'pending',
    );
  }

  Future<void> saveOrderDetailsAndClose(BuildContext context) async {
    final result = await buildOrderDetails();
    if (result == null) return;

    // Pop using the local Navigator first (most reliable).
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
      return;
    }

    // Fallbacks (in case the screen was opened differently).
    if (Modular.to.canPop()) {
      Modular.to.pop(result);
      return;
    }

    Modular.to.pop(result);
    // Get.back(result: result);
  }

  /// Check if bill number already exists (in both API and local database)
  Future<bool> _checkBillNumberExists(String billNo) async {
    try {
      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) return false;

      // Check in local database
      final localOrders = await _db.getAllOrders(outletId: outletId);
      final existsInLocal = localOrders.any(
        (order) =>
            order.billNumber.trim().toLowerCase() ==
            billNo.trim().toLowerCase(),
      );

      if (existsInLocal) {
        debugPrint('⚠️ Bill number $billNo exists in local database');
        return true;
      }

      // Check in API orders (from allOrders list)
      final existsInApi = allOrders.any(
        (order) =>
            order.billNumber.trim().toLowerCase() ==
            billNo.trim().toLowerCase(),
      );

      if (existsInApi) {
        debugPrint('⚠️ Bill number $billNo exists in API orders');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking bill number: $e');
      // If error occurs, allow the save to proceed (fail-safe)
      return false;
    }
  }

  /// On Screen Load
  @override
  void onInit() {
    // Read route args from Modular first, fallback to Get.arguments.
    final dynamic modularArgs = Modular.args.data;
    final args =
        (modularArgs is Map<String, dynamic>)
        ? modularArgs
        : (Get.arguments as Map<String, dynamic>?);

    if (args != null) {
      orderFrom.value = args['orderFrom'] ?? '';
      tableNumber.text = args['tableNumber'] ?? '';
      customerName.text = args['customerName'] ?? '';
      phoneNumber.text = args['phoneNumber'] ?? '';
      discount.text = '${args['discount'] ?? 0.0}';
      final rawDiscountType = args['discountType']?.toString().trim().toLowerCase();
      discountType.value =
          rawDiscountType == 'amount' ? 'amount' : 'percentage';
      serviceCharge.text = '${args['serviceCharge'] ?? 0.0}';
      status.value = args['status'] ?? '';
      // billNumber.text = args['billNumber'] ?? '';
    }

    // Ensure table number isn't kept when not dine-in or outlet has no seating.
    if (!isDineIn || !HomeMainRoutes.outletShowsTables()) {
      tableNumber.text = '';
      hasOutletTables.value = false;
    }

    phoneNumber.addListener(_onPhoneChanged);
    super.onInit();
  }

  void _onPhoneChanged() {
    _phoneLookupTimer?.cancel();
    _phoneLookupTimer = Timer(const Duration(milliseconds: 500), () {
      lookupRegularCustomer();
    });
  }

  Future<void> lookupRegularCustomer() async {
    final digits = phoneNumber.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return;

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    try {
      final response = await callApi(
        apiClient.lookupRegularCustomerByPhone(outletId, digits),
        showLoader: false,
      );

      if (response?.status == 'success' && response?.data != null) {
        final customer = response!.data!;
        if (customerName.text.trim().isEmpty) {
          customerName.text = customer.customerName;
        }
        final existingDiscount = double.tryParse(discount.text.trim()) ?? 0.0;
        // Don't overwrite a discount already set on this order (e.g. hold reopen).
        if (customer.loyalityDiscount > 0 && existingDiscount <= 0) {
          discountType.value = customer.loyalityDiscountType == 'amount'
              ? 'amount'
              : 'percentage';
          discount.text = customer.loyalityDiscount.toString();
        }
      }
    } catch (e) {
      debugPrint('Regular customer lookup failed: $e');
    }
  }

  String _normalizeTableNumber(String raw) {
    var value = raw.trim().toLowerCase();
    value = value.replaceFirst(RegExp(r'^table\s*'), '');
    value = value.replaceAll(RegExp(r'\s+'), '');
    return value;
  }

  bool _tableMatchesSelection(TableModel table, String selected) {
    if (selected.trim().isEmpty) return false;
    final target = _normalizeTableNumber(selected);
    if (target.isEmpty) return false;
    return _normalizeTableNumber(table.tableNumber) == target ||
        _normalizeTableNumber(table.displayName) == target;
  }

  Future<void> loadAvailableTables() async {
    if (!isDineIn || !HomeMainRoutes.outletShowsTables()) {
      availableTables.clear();
      hasOutletTables.value = false;
      return;
    }

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      availableTables.clear();
      hasOutletTables.value = false;
      return;
    }

    final cached = OfflineTableLoader.loadCached(appPref, outletId);
    if (cached.isNotEmpty) {
      _applyAvailableTables(cached);
    }

    if (!await NetworkUtils.hasInternetConnection()) return;

    try {
      final response = await callApi(
        apiClient.getOutletTables(outletId),
        showLoader: false,
      );

      if (response?.status == 'success') {
        appPref.setCachedOutletTables(outletId, response!.data);
        _applyAvailableTables(
          response.data.map(TableModel.fromTableData).toList(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load available tables: $e');
    }
  }

  void _applyAvailableTables(List<TableModel> allTables) {
    hasOutletTables.value = allTables.isNotEmpty;
    if (!hasOutletTables.value) {
      availableTables.clear();
      return;
    }

    final currentTable = tableNumber.text.trim();
    final tables = allTables.where((t) {
      if (t.isAvailableFromApi) return true;
      return _tableMatchesSelection(t, currentTable);
    }).toList(growable: true);

    if (currentTable.isNotEmpty &&
        !tables.any((t) => _tableMatchesSelection(t, currentTable))) {
      tables.insert(
        0,
        TableModel(
          id: 'current_table',
          tableNumber: currentTable,
          status: 'occupied',
        ),
      );
    }

    availableTables.assignAll(tables);
  }

  /// Fetch orders & set latest bill number
  /// Uses billNumber from outletData as base, then checks orders for higher values
  void getOrderList() async {
    try {
      isLoading.value = true;

      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) {
        debugPrint('⚠️ No outlet selected');
        // Still set default bill number
        if (billNumber.text.isEmpty) {
          billNumber.text = "1";
        }
        isLoading.value = false;
        return;
      }

      // Get outlet's billNumber from profile API (owner) or assigned outlet (staff)
      int outletBillNumber = 0;
      try {
        if (appPref.isStaffSession) {
          outletBillNumber = appPref.selectedOutlet?.billNumber ?? 0;
          debugPrint('📌 Staff outlet billNumber: $outletBillNumber');
        } else {
          final ownerId = appPref.ownerUserId;
          if (ownerId == null || ownerId.isEmpty) {
            outletBillNumber = appPref.selectedOutlet?.billNumber ?? 0;
          } else {
            final userResponse = await callApi(
              apiClient.getUserDetails(ownerId),
              showLoader: false,
            );

            if (userResponse != null && userResponse.status == 'success') {
              appPref.user = userResponse.data;

              final selectedOutlet = userResponse.data.outletData?.firstWhere(
                (outlet) => outlet.id == outletId,
                orElse: () => userResponse.data.outletData?.first ?? OutletData(),
              );

              outletBillNumber = selectedOutlet?.billNumber ?? 0;
              debugPrint('📌 Outlet billNumber from API: $outletBillNumber');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not fetch user details: $e');
        // Fallback to outlet from appPref
        outletBillNumber = appPref.selectedOutlet?.billNumber ?? 0;
        debugPrint(
          '📌 Using outlet billNumber from appPref: $outletBillNumber',
        );
      }

      // Get orders from local database first (always available)
      List<OrderModel> localOrders = [];
      try {
        localOrders = await _db.getAllOrders(outletId: outletId);
        allOrders.assignAll(localOrders);
        allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        debugPrint('✅ Loaded ${localOrders.length} orders from local database');
      } catch (e) {
        debugPrint('⚠️ Error loading local orders: $e');
      }

      // Try to get orders from API (optional, won't fail if offline)
      try {
        final response = await callApi(
          apiClient.getOrders(
            appPref.ordersApiUserId!,
            outletId,
            null,
            null,
            null,
            null,
            null, // startDate
            null, // endDate
          ), // page, limit, category, paymentReceivedIn
          showLoader: false,
        );

        if (response != null && response.status == 'success') {
          await _db.insertOrders(
            response.data,
            outletId,
            isSyncedFromApi: true,
          );
          final merged = <String, OrderModel>{
            for (final order in allOrders) order.id: order,
          };
          final unsyncedIds = await _db.getUnsyncedOrderIds(outletId: outletId);
          mergeRemoteOrders(
            merged,
            response.data,
            unsyncedIds: unsyncedIds,
          );
          allOrders.assignAll(merged.values);
          allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          debugPrint('✅ Loaded ${allOrders.length} orders from API + local');
        }
      } catch (e) {
        debugPrint('⚠️ Could not load orders from API (may be offline): $e');
        // Continue with local database only
      }

      String nextBillNumberStr = '1';
      var resolvedFromApi = false;
      final isOnline = await NetworkUtils.hasInternetConnection();
      if (isOnline) {
        try {
          final nextResponse = await callApi(
            apiClient.getNextBillNumber(outletId),
            showLoader: false,
          );
          final nextBill =
              nextResponse?['data']?['nextBillNumber']?.toString();
          if (nextResponse?['status'] == 'success' &&
              nextBill != null &&
              nextBill.isNotEmpty) {
            nextBillNumberStr = nextBill;
            resolvedFromApi = true;
          }
        } catch (e) {
          debugPrint('⚠️ Could not fetch next bill number from API: $e');
        }
      }

      if (!resolvedFromApi) {
        final billNumbers = <String>[
          ...allOrders.map((order) => order.billNumber),
          ...localOrders.map((order) => order.billNumber),
        ];
        nextBillNumberStr = computeNextBillNumber(
          outletLastBillNumber: outletBillNumber,
          orderBillNumbers: billNumbers,
        ).toString();
      }

      debugPrint('📊 Bill number calculation:');
      debugPrint('   Outlet billNumber: $outletBillNumber');
      debugPrint('   Next billNumber: $nextBillNumberStr');

      // Preview only — shown in UI, not sent to server on create.
      if (billNumber.text.isEmpty) {
        billNumber.text = nextBillNumberStr;
        debugPrint('📌 Bill preview: ${billNumber.text}');
      }

      if (allOrders.isNotEmpty) {
        orderDetails = allOrders.first;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching orders: $e');
      debugPrint('Stack trace: $stackTrace');

      // Fallback: try to get from local database and outlet
      try {
        final outletId = appPref.selectedOutlet?.id;
        if (outletId != null) {
          // Get outlet billNumber from appPref
          final outletBillNumber = appPref.selectedOutlet?.billNumber ?? 0;

          final localOrders = await _db.getAllOrders(outletId: outletId);

          if (billNumber.text.isEmpty) {
            final finalBill = computeNextBillNumber(
              outletLastBillNumber: outletBillNumber,
              orderBillNumbers: localOrders.map((order) => order.billNumber),
            );
            billNumber.text = finalBill.toString();
          }
        } else {
          if (billNumber.text.isEmpty) {
            billNumber.text = "1";
          }
        }
      } catch (e2) {
        debugPrint('❌ Error in fallback: $e2');
        if (billNumber.text.isEmpty) {
          billNumber.text = "1";
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Validate bill number is a valid integer
  bool _isValidIntegerBillNumber(String billNo) {
    return int.tryParse(billNo.trim()) != null;
  }

  /// Get Latest Order
  OrderModel? getLatestOrder() {
    if (allOrders.isEmpty) return null;
    return allOrders.first;
  }

  @override
  void onReady() {
    loadAvailableTables();
    getOrderList();
    super.onReady();
  }

  @override
  void onClose() {
    _phoneLookupTimer?.cancel();
    phoneNumber.removeListener(_onPhoneChanged);
    tableNumber.dispose();
    customerName.dispose();
    phoneNumber.dispose();
    discount.dispose();
    serviceCharge.dispose();
    billNumber.dispose();
    super.onClose();
  }
}
