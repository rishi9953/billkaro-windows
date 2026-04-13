import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/Modals/orders/split_payment.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/config/config.dart';
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

  final discountType = 'Percentage'.obs;
  final paymentRecieved = 'cash'.obs;
  final status = 'pending'.obs;

  // Split payment support
  final RxList<SplitPayment> splitPayments = <SplitPayment>[].obs;
  final RxBool useSplitPayment = false.obs;
  double? totalAmount; // Will be set from order details

  final RxBool isLoading = true.obs;
  final RxList<TableModel> availableTables = <TableModel>[].obs;

  String _normalizePaymentMethod(dynamic value) {
    final method = (value ?? '').toString().trim().toLowerCase();
    return (method == 'cash' || method == 'card' || method == 'upi')
        ? method
        : 'cash';
  }

  /// All orders from API
  final RxList<OrderModel> allOrders = <OrderModel>[].obs;

  /// Local database instance
  final AppDatabase _db = AppDatabase();

  OrderModel? orderDetails;

  /// Save Order Details
  Future<CreateorderRequest?> buildOrderDetails() async {
    final loc = AppLocalizations.of(Get.context!)!;

    // Validate bill number is not empty
    if (billNumber.text.trim().isEmpty) {
      showError(description: loc.bill_number_required);
      return null;
    }

    // Validate bill number is an integer
    if (!_isValidIntegerBillNumber(billNumber.text.trim())) {
      showError(description: loc.bill_number_invalid);
      return null;
    }

    // Check if bill number already exists
    final isDuplicate = await _checkBillNumberExists(billNumber.text.trim());
    if (isDuplicate) {
      showError(description: loc.bill_number_duplicate(billNumber.text.trim()));
      return null;
    }

    // Validate split payments if enabled
    if (useSplitPayment.value) {
      final splitTotal = splitPayments.fold<double>(
        0.0,
        (sum, payment) => sum + payment.amount,
      );

      if (splitPayments.isEmpty) {
        showError(description: 'Please add at least one payment method');
        return null;
      }

      if (totalAmount != null && (splitTotal - totalAmount!).abs() > 0.01) {
        showError(
          description:
              'Split payment total (₹${splitTotal.toStringAsFixed(2)}) does not match order total (₹${totalAmount!.toStringAsFixed(2)})',
        );
        return null;
      }
    }

    return CreateorderRequest(
      billNumber: billNumber.text.trim(),
      tableNumber:
          (isDineIn && HomeMainRoutes.outletShowsTables())
              ? tableNumber.text
              : '',
      customerName: customerName.text,
      phoneNumber: phoneNumber.text,
      discount: double.tryParse(discount.text) ?? 0.0,
      serviceCharge: double.tryParse(serviceCharge.text) ?? 0.0,
      paymentReceivedIn: useSplitPayment.value ? null : paymentRecieved.value,
      splitPayments: useSplitPayment.value && splitPayments.isNotEmpty
          ? splitPayments.toList()
          : null,
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
      serviceCharge.text = '${args['serviceCharge'] ?? 0.0}';
      status.value = args['status'] ?? '';
      paymentRecieved.value = _normalizePaymentMethod(args['paymentReceivedIn']);
      totalAmount = args['totalAmount']?.toDouble();

      // Load split payments if available
      if (args['splitPayments'] != null && args['splitPayments'] is List) {
        final List<dynamic> splitList = args['splitPayments'];
        splitPayments.value = splitList.map((json) {
          final p = SplitPayment.fromJson(json as Map<String, dynamic>);
          final method = p.paymentMethod.trim().toLowerCase();
          // Normalize legacy / API values like "Cash" / "UPI" to expected keys.
          final normalized =
              (method == 'cash' || method == 'card' || method == 'upi')
              ? method
              : 'cash';
          return SplitPayment(paymentMethod: normalized, amount: p.amount);
        }).toList();
        useSplitPayment.value = splitPayments.isNotEmpty;
      }
      // billNumber.text = args['billNumber'] ?? '';
    }

    // Ensure table number isn't kept when not dine-in or outlet has no seating.
    if (!isDineIn || !HomeMainRoutes.outletShowsTables()) {
      tableNumber.text = '';
    }

    super.onInit();
  }

  Future<void> loadAvailableTables() async {
    if (!isDineIn || !HomeMainRoutes.outletShowsTables()) {
      availableTables.clear();
      return;
    }

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      availableTables.clear();
      return;
    }

    try {
      final response = await callApi(
        apiClient.getOutletTables(outletId),
        showLoader: false,
      );

      if (response?.status == 'success') {
        final tables = response!.data
            .map((e) => TableModel.fromTableData(e))
            .where((t) => t.isAvailableFromApi)
            .toList();

        availableTables.assignAll(tables);
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load available tables: $e');
    }

    availableTables.clear();
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

      // Get outlet's billNumber from getUserDetails API
      int outletBillNumber = 0;
      try {
        final userResponse = await callApi(
          apiClient.getUserDetails(appPref.user!.id!),
          showLoader: false,
        );

        if (userResponse != null && userResponse.status == 'success') {
          // Update user data
          appPref.user = userResponse.data;

          // Find the selected outlet and get its billNumber
          final selectedOutlet = userResponse.data.outletData?.firstWhere(
            (outlet) => outlet.id == outletId,
            orElse: () => userResponse.data.outletData?.first ?? OutletData(),
          );

          outletBillNumber = selectedOutlet?.billNumber ?? 0;
          debugPrint('📌 Outlet billNumber from API: $outletBillNumber');
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
        debugPrint('✅ Loaded ${localOrders.length} orders from local database');
      } catch (e) {
        debugPrint('⚠️ Error loading local orders: $e');
      }

      // Try to get orders from API (optional, won't fail if offline)
      try {
        final response = await callApi(
          apiClient.getOrders(
            appPref.user!.id!,
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
          allOrders.value = response.data;
          // Sort latest first
          allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          debugPrint('✅ Loaded ${allOrders.length} orders from API');
        }
      } catch (e) {
        debugPrint('⚠️ Could not load orders from API (may be offline): $e');
        // Continue with local database only
      }

      // Find the highest bill number from orders
      int maxOrderBillNumber = 0;

      // Check bill numbers from API orders
      for (final order in allOrders) {
        if (order.billNumber.isNotEmpty) {
          final billNum = int.tryParse(order.billNumber);
          if (billNum != null && billNum > maxOrderBillNumber) {
            maxOrderBillNumber = billNum;
          }
        }
      }

      // Check bill numbers from local orders
      for (final order in localOrders) {
        if (order.billNumber.isNotEmpty) {
          final billNum = int.tryParse(order.billNumber);
          if (billNum != null && billNum > maxOrderBillNumber) {
            maxOrderBillNumber = billNum;
          }
        }
      }

      final nextFromOrders = maxOrderBillNumber > 0
          ? maxOrderBillNumber + 1
          : 1;
      final nextBillNumber = outletBillNumber > nextFromOrders
          ? outletBillNumber
          : nextFromOrders;
      final nextBillNumberStr = nextBillNumber.toString();

      debugPrint('📊 Bill number calculation:');
      debugPrint('   Outlet billNumber: $outletBillNumber');
      debugPrint('   Max order billNumber: $maxOrderBillNumber');
      debugPrint('   Next-from-orders: $nextFromOrders');
      debugPrint('   Next billNumber: $nextBillNumberStr');

      // Generate next unique integer bill number
      if (billNumber.text.isEmpty) {
        billNumber.text = nextBillNumberStr;
        debugPrint('📌 Generated next integer bill number: ${billNumber.text}');
      } else {
        // Validate existing bill number is integer and unique
        final currentBillNum = int.tryParse(billNumber.text.trim());
        if (currentBillNum == null) {
          // Not an integer, generate new one
          billNumber.text = nextBillNumberStr;
          debugPrint(
            '⚠️ Bill number was not integer, generated new: ${billNumber.text}',
          );
        } else {
          // Check if duplicate or lower than the next suggested number
          final isDuplicate = await _checkBillNumberExists(
            billNumber.text.trim(),
          );
          if (isDuplicate || currentBillNum < nextBillNumber) {
            // If duplicate or less than base, generate next one
            billNumber.text = nextBillNumberStr;
            debugPrint(
              '⚠️ Bill number was duplicate or invalid, generated new: ${billNumber.text}',
            );
          }
        }
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
          int maxBill = outletBillNumber;

          if (localOrders.isNotEmpty) {
            // Find max integer bill number from local orders
            for (final order in localOrders) {
              final billNum = int.tryParse(order.billNumber);
              if (billNum != null && billNum > maxBill) {
                maxBill = billNum;
              }
            }
          }

          if (billNumber.text.isEmpty) {
            // Next bill should be one greater than current max
            final finalBill = maxBill == 0 ? 1 : maxBill + 1;
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

  /// Add a split payment
  void addSplitPayment(String paymentMethod, double amount) {
    splitPayments.add(
      SplitPayment(paymentMethod: paymentMethod, amount: amount),
    );
  }

  /// Remove a split payment
  void removeSplitPayment(int index) {
    if (index >= 0 && index < splitPayments.length) {
      splitPayments.removeAt(index);
    }
  }

  /// Get total of split payments
  double get splitPaymentTotal {
    return splitPayments.fold<double>(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
  }

  /// Get remaining amount for split payment
  double? get remainingAmount {
    if (totalAmount == null) return null;
    return totalAmount! - splitPaymentTotal;
  }

  @override
  void onReady() {
    loadAvailableTables();
    getOrderList();
    super.onReady();
  }

  @override
  void onClose() {
    tableNumber.dispose();
    customerName.dispose();
    phoneNumber.dispose();
    discount.dispose();
    serviceCharge.dispose();
    billNumber.dispose();
    super.onClose();
  }
}
