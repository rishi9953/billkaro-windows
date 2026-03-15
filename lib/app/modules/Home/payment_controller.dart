import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/config/config.dart';
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

      // Calculate today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

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
          final orderDate = DateTime.parse(order.createdAt);
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
              if (orderDate.isAfter(todayStart) && orderDate.isBefore(todayEnd)) {
                todayBreakdown[method] = (todayBreakdown[method] ?? 0.0) + amount;
                todayTotal += amount;
              }

              // Add to period totals
              if (orderDate.isAfter(todayStart) && orderDate.isBefore(todayEnd)) {
                todayTotal += amount;
              } else if (orderDate.isAfter(yesterdayStart) && orderDate.isBefore(todayStart)) {
                yesterdayTotal += amount;
              }
              if (orderDate.isAfter(weekStart)) {
                weekTotal += amount;
              }
              if (orderDate.isAfter(monthStart)) {
                monthTotal += amount;
              }
            }
          } else if (order.paymentReceivedIn != null && order.paymentReceivedIn!.isNotEmpty) {
            // Handle single payment method
            final method = order.paymentReceivedIn!.toLowerCase();
            
            // Add to overall breakdown
            breakdown[method] = (breakdown[method] ?? 0.0) + orderAmount;

            // Add to today's breakdown if applicable
            if (orderDate.isAfter(todayStart) && orderDate.isBefore(todayEnd)) {
              todayBreakdown[method] = (todayBreakdown[method] ?? 0.0) + orderAmount;
            }

            // Add to period totals
            if (orderDate.isAfter(todayStart) && orderDate.isBefore(todayEnd)) {
              todayTotal += orderAmount;
            } else if (orderDate.isAfter(yesterdayStart) && orderDate.isBefore(todayStart)) {
              yesterdayTotal += orderAmount;
            }
            if (orderDate.isAfter(weekStart)) {
              weekTotal += orderAmount;
            }
            if (orderDate.isAfter(monthStart)) {
              monthTotal += orderAmount;
            }
          } else {
            // No payment method specified, treat as cash
            breakdown['cash'] = (breakdown['cash'] ?? 0.0) + orderAmount;

            if (orderDate.isAfter(todayStart) && orderDate.isBefore(todayEnd)) {
              todayBreakdown['cash'] = (todayBreakdown['cash'] ?? 0.0) + orderAmount;
              todayTotal += orderAmount;
            } else if (orderDate.isAfter(yesterdayStart) && orderDate.isBefore(todayStart)) {
              yesterdayTotal += orderAmount;
            }
            if (orderDate.isAfter(weekStart)) {
              weekTotal += orderAmount;
            }
            if (orderDate.isAfter(monthStart)) {
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

