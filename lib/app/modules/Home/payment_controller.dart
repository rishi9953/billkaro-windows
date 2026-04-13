import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:get/get.dart';

class PaymentController extends BaseController {
  // Payment statistics
  final RxDouble todayTotalPayments = 0.0.obs;
  final RxDouble yesterdayTotalPayments = 0.0.obs;
  final RxDouble thisWeekTotalPayments = 0.0.obs;
  final RxDouble thisMonthTotalPayments = 0.0.obs;

  // Payment breakdown by method
  final RxMap<String, double> paymentMethodBreakdown = <String, double>{}.obs;
  final RxMap<String, double> todayPaymentBreakdown = <String, double>{}.obs;

  // Loading state
  final RxBool isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    loadPaymentStatistics();
  }

  /// Load payment statistics from orders
  Future<void> loadPaymentStatistics() async {
    try {
      isLoading.value = true;
      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) {
        isLoading.value = false;
        return;
      }

      final db = AppDatabase();
      final allOrders = await db.getAllOrders(outletId: outletId);

      // Filter only closed orders (paid orders)
      final paidOrders = allOrders.where((order) => 
        order.status.toLowerCase() == 'closed'
      ).toList();

      // IST calendar boundaries as UTC instants for order comparison
      final todayIst = todayIstDateOnly();
      final todayStartUtc = startOfIstDayAsUtcInstant(todayIst);
      final todayEndUtc = endOfIstDayExclusiveUtc(todayIst);
      final yesterdayStartUtc =
          startOfIstDayAsUtcInstant(todayIst.subtract(const Duration(days: 1)));
      final weekStartUtc =
          startOfIstDayAsUtcInstant(istMondayOfWeek(todayIst));
      final monthStartUtc = startOfIstDayAsUtcInstant(
        DateTime(todayIst.year, todayIst.month, 1),
      );

      // Initialize breakdown maps
      final breakdown = <String, double>{};
      final todayBreakdown = <String, double>{};

      // Calculate totals and breakdowns
      double todayTotal = 0.0;
      double yesterdayTotal = 0.0;
      double weekTotal = 0.0;
      double monthTotal = 0.0;

      for (final order in paidOrders) {
        try {
          final orderUtc = DateTime.parse(order.createdAt).toUtc();
          final orderAmount = order.totalAmount;

          // Check if order has split payments
          if (order.splitPayments != null && order.splitPayments!.isNotEmpty) {
            // Handle split payments
            for (final splitPayment in order.splitPayments!) {
              final method = splitPayment.paymentMethod.toLowerCase();
              final amount = splitPayment.amount;

              // Add to overall breakdown
              breakdown[method] = (breakdown[method] ?? 0.0) + amount;

              // Add to today's breakdown if applicable
              if (!orderUtc.isBefore(todayStartUtc) &&
                  orderUtc.isBefore(todayEndUtc)) {
                todayBreakdown[method] = (todayBreakdown[method] ?? 0.0) + amount;
                todayTotal += amount;
              }

              // Add to period totals
              if (!orderUtc.isBefore(todayStartUtc) &&
                  orderUtc.isBefore(todayEndUtc)) {
                todayTotal += amount;
              } else if (!orderUtc.isBefore(yesterdayStartUtc) &&
                  orderUtc.isBefore(todayStartUtc)) {
                yesterdayTotal += amount;
              }
              if (!orderUtc.isBefore(weekStartUtc)) {
                weekTotal += amount;
              }
              if (!orderUtc.isBefore(monthStartUtc)) {
                monthTotal += amount;
              }
            }
          } else if (order.paymentReceivedIn != null && order.paymentReceivedIn!.isNotEmpty) {
            // Handle single payment method
            final method = order.paymentReceivedIn!.toLowerCase();
            
            // Add to overall breakdown
            breakdown[method] = (breakdown[method] ?? 0.0) + orderAmount;

            // Add to today's breakdown if applicable
            if (!orderUtc.isBefore(todayStartUtc) &&
                orderUtc.isBefore(todayEndUtc)) {
              todayBreakdown[method] = (todayBreakdown[method] ?? 0.0) + orderAmount;
            }

            // Add to period totals
            if (!orderUtc.isBefore(todayStartUtc) &&
                orderUtc.isBefore(todayEndUtc)) {
              todayTotal += orderAmount;
            } else if (!orderUtc.isBefore(yesterdayStartUtc) &&
                orderUtc.isBefore(todayStartUtc)) {
              yesterdayTotal += orderAmount;
            }
            if (!orderUtc.isBefore(weekStartUtc)) {
              weekTotal += orderAmount;
            }
            if (!orderUtc.isBefore(monthStartUtc)) {
              monthTotal += orderAmount;
            }
          } else {
            // No payment method specified, treat as cash
            breakdown['cash'] = (breakdown['cash'] ?? 0.0) + orderAmount;

            if (!orderUtc.isBefore(todayStartUtc) &&
                orderUtc.isBefore(todayEndUtc)) {
              todayBreakdown['cash'] = (todayBreakdown['cash'] ?? 0.0) + orderAmount;
              todayTotal += orderAmount;
            } else if (!orderUtc.isBefore(yesterdayStartUtc) &&
                orderUtc.isBefore(todayStartUtc)) {
              yesterdayTotal += orderAmount;
            }
            if (!orderUtc.isBefore(weekStartUtc)) {
              weekTotal += orderAmount;
            }
            if (!orderUtc.isBefore(monthStartUtc)) {
              monthTotal += orderAmount;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing order ${order.id}: $e');
        }
      }

      // Update observables
      todayTotalPayments.value = todayTotal;
      yesterdayTotalPayments.value = yesterdayTotal;
      thisWeekTotalPayments.value = weekTotal;
      thisMonthTotalPayments.value = monthTotal;
      paymentMethodBreakdown.value = breakdown;
      todayPaymentBreakdown.value = todayBreakdown;

      debugPrint('✅ Payment statistics loaded:');
      debugPrint('   Today: ₹${todayTotal.toStringAsFixed(2)}');
      debugPrint('   Yesterday: ₹${yesterdayTotal.toStringAsFixed(2)}');
      debugPrint('   This Week: ₹${weekTotal.toStringAsFixed(2)}');
      debugPrint('   This Month: ₹${monthTotal.toStringAsFixed(2)}');
    } catch (e) {
      debugPrint('❌ Error loading payment statistics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get formatted payment method name
  String getPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'online':
        return 'Online';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card';
      case 'credit':
        return 'Credit';
      case 'debit':
        return 'Debit Card';
      default:
        return method.toUpperCase();
    }
  }

  /// Get payment method icon
  IconData getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'online':
      case 'upi':
        return Icons.account_balance_wallet;
      case 'card':
      case 'credit':
      case 'debit':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  /// Get payment method color
  Color getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return const Color(0xFF10B981); // Green
      case 'online':
      case 'upi':
        return const Color(0xFF3B82F6); // Blue
      case 'card':
      case 'credit':
      case 'debit':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return Colors.grey;
    }
  }

  /// Refresh payment statistics
  Future<void> refresh() async {
    await loadPaymentStatistics();
  }
}

