import 'package:billkaro/app/Widgets/payment_success_dialog.dart';
import 'package:billkaro/app/services/Modals/wallet/wallet_api_models.dart';
import 'package:billkaro/app/services/Modals/wallet/wallet_transaction.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/app_shell_sidebar_controller.dart';
import 'package:billkaro/app/services/razorpay/razorpay_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class WalletController extends BaseController {
  final RazorpayService razorpayService = RazorpayService();

  final balance = 0.0.obs;
  final transactions = <WalletTransaction>[].obs;
  final walletCards = <WalletCardModel>[].obs;
  final isProcessingPayment = false.obs;
  final isLoadingWallet = false.obs;
  final searchQuery = ''.obs;

  double _pendingRechargeAmount = 0;
  String? _pendingWalletCardId;
  String _orderId = '';
  bool _paymentInFlight = false;
  bool _checkoutSettled = false;
  double _lowBalanceThreshold = 50;

  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  String formatAmount(double amount) => _currency.format(amount);

  void _applyWalletPayload(Map<String, dynamic> json) {
    final nextBalance = (json['balance'] as num?)?.toDouble();
    if (nextBalance != null) {
      balance.value = nextBalance;
      appPref.setWalletBalanceForOutlet(appPref.selectedOutlet?.id, nextBalance);
    }
    _lowBalanceThreshold =
        (json['lowBalanceThreshold'] as num?)?.toDouble() ?? _lowBalanceThreshold;

    final txRaw = json['transactions'];
    if (txRaw is List) {
      transactions.assignAll(
        txRaw
            .whereType<Map>()
            .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
  }

  /// Applied from wallet WebSocket (`walletUpdated`) — no REST poll.
  void applyRealtimeBalance(
    double nextBalance, {
    double? lowBalanceThreshold,
  }) {
    balance.value = nextBalance;
    appPref.setWalletBalanceForOutlet(appPref.selectedOutlet?.id, nextBalance);
    if (lowBalanceThreshold != null) {
      _lowBalanceThreshold = lowBalanceThreshold;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeRazorpay();
  }

  @override
  void onReady() {
    super.onReady();
    loadWalletData();
  }

  @override
  void onClose() {
    razorpayService.dispose();
    super.onClose();
  }

  Future<void> loadWalletData() async {
    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.user?.id;
    if (outletId == null || userId == null) return;

    isLoadingWallet.value = true;
    try {
      await Future.wait([
        _fetchWalletCards(),
        _fetchWallet(outletId, userId),
      ]);
      if (Get.isRegistered<AppShellSidebarController>()) {
        final shell = Get.find<AppShellSidebarController>();
        shell.walletBalance = balance.value;
        shell.walletLowBalanceThreshold = _lowBalanceThreshold;
        shell.update(['subscription']);
      }
    } finally {
      isLoadingWallet.value = false;
    }
  }

  Future<void> _fetchWalletCards() async {
    try {
      final res = await callApi(
        apiClient.getWalletCards(true),
        showLoader: false,
      );
      if (res is Map && res['data'] is List) {
        walletCards.assignAll(
          (res['data'] as List)
              .map((e) => WalletCardModel.fromJson(e as Map<String, dynamic>))
              .where((c) => c.active && c.amount > 0)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        );
      }
    } catch (e) {
      debugPrint('Failed to load wallet cards: $e');
    }
  }

  Future<void> _fetchWallet(String outletId, String userId) async {
    try {
      final res = await callApi(
        apiClient.getOutletWallet(outletId, userId),
        showLoader: false,
      );
      if (res is Map && res['data'] is Map) {
        _applyWalletPayload(Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      debugPrint('Failed to load wallet: $e');
    }
  }

  bool get isLowBalance =>
      balance.value > 0 && balance.value < _lowBalanceThreshold;

  String get holderName {
    final u = appPref.user;
    final brand = u?.brandName?.trim();
    if (brand != null && brand.isNotEmpty) return brand;
    final name = '${u?.firstName ?? ''} ${u?.lastName ?? ''}'.trim();
    return name.isEmpty ? 'BillKaro User' : name;
  }

  String get outletLabel =>
      appPref.selectedOutlet?.businessName?.trim() ?? 'Outlet wallet';

  double get totalToppedUp => transactions
      .where((t) => t.isCredit)
      .fold<double>(0, (sum, t) => sum + t.amount);

  List<WalletTransaction> get filteredTransactions {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return transactions;
    return transactions
        .where(
          (t) =>
              t.description.toLowerCase().contains(q) ||
              (t.paymentId?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  List<double> get weeklyCreditBars {
    final now = DateTime.now();
    final bars = List<double>.filled(7, 0);
    for (final tx in transactions.where((t) => t.isCredit)) {
      final diff = now.difference(tx.createdAt).inDays;
      if (diff >= 0 && diff < 7) {
        bars[6 - diff] += tx.amount;
      }
    }
    final max = bars.fold<double>(0, (a, b) => a > b ? a : b);
    if (max <= 0) return List<double>.filled(7, 0.15);
    return bars.map((v) => (v / max).clamp(0.12, 1.0)).toList();
  }

  String aiInsightMessage(AppLocalizations loc) {
    if (isLowBalance) return loc.wallet_low_balance_warning;
    final credits = transactions.where((t) => t.isCredit).length;
    if (credits == 0) return loc.wallet_menu_subtitle;
    if (totalToppedUp > 0) {
      return 'You have topped up ${formatAmount(totalToppedUp)} across $credits recharge${credits == 1 ? '' : 's'}. Wallet is ready for platform fees.';
    }
    return loc.wallet_menu_subtitle;
  }

  void setSearchQuery(String value) => searchQuery.value = value;

  void _initializeRazorpay() {
    razorpayService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  Future<void> rechargeFromCard(WalletCardModel card) async {
    await recharge(card.amount, walletCardId: card.id);
  }

  Future<void> recharge(double amount, {String? walletCardId}) async {
    final loc = AppLocalizations.of(Get.context!)!;
    if (amount <= 0) {
      showError(
        title: loc.wallet_recharge,
        description: loc.wallet_enter_valid_amount,
      );
      return;
    }
    if (_paymentInFlight) return;

    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.user?.id;
    if (outletId == null || userId == null) {
      showError(
        title: loc.wallet_recharge,
        description: loc.no_outlet_selected_retry,
      );
      return;
    }

    _pendingRechargeAmount = amount;
    _pendingWalletCardId = walletCardId;
    _orderId = '';
    _checkoutSettled = false;

    try {
      isProcessingPayment.value = true;
      final request = {
        'userId': userId,
        'amount': amount,
        if (walletCardId != null) 'walletCardId': walletCardId,
      };

      final orderResponse = await callApi(
        apiClient.createWalletRechargeOrder(outletId, request),
        showLoader: false,
      );

      if (orderResponse is! Map || orderResponse['status'] != 'success') {
        showError(
          title: loc.payment_failed,
          description:
              orderResponse?['message']?.toString() ?? loc.failed_create_payment_order,
        );
        return;
      }

      _orderId = orderResponse['data']?['id']?.toString() ?? '';
      final payableAmount =
          (orderResponse['data']?['payableAmount'] as num?)?.toDouble() ?? amount;
      _pendingRechargeAmount = payableAmount;
      final amountInPaise = (payableAmount * 100).round();
      final user = appPref.user;

      if (_orderId.isEmpty) {
        showError(
          title: loc.payment_failed,
          description: loc.invalid_order_response,
        );
        return;
      }

      // Re-bind callbacks so subscription/other screens don't steal success events.
      _initializeRazorpay();

      razorpayService.openWalletCheckout(
        orderId: _orderId,
        amountInPaise: amountInPaise,
        name: user?.brandName ?? user?.firstName ?? 'BillKaro User',
        email: user?.email ?? '',
        contact: user?.mobile ?? '',
        description: loc.wallet_recharge,
        notes: {
          'type': 'wallet_recharge',
          'outletId': outletId,
          if (walletCardId != null) 'walletCardId': walletCardId,
        },
        prefill: {'name': user?.firstName ?? 'Customer'},
      );
    } catch (e) {
      debugPrint('Wallet recharge order error: $e');
      showError(
        title: loc.payment_failed,
        description: loc.failed_create_payment_order,
      );
      isProcessingPayment.value = false;
    }
  }

  Future<void> showCustomAmountDialog() async {
    final loc = AppLocalizations.of(Get.context!)!;
    final controller = TextEditingController();
    final amount = await Get.dialog<double>(
      AlertDialog(
        title: Text(loc.wallet_custom_amount),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '₹ ',
            hintText: loc.wallet_enter_amount_hint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value <= 0) {
                showError(
                  title: loc.wallet_recharge,
                  description: loc.wallet_enter_valid_amount,
                );
                return;
              }
              Get.back(result: value);
            },
            child: Text(loc.wallet_recharge),
          ),
        ],
      ),
    );
    if (amount != null) {
      await recharge(amount);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_checkoutSettled || _paymentInFlight) return;
    _paymentInFlight = true;
    _checkoutSettled = true;
    isProcessingPayment.value = true;

    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.user?.id;
    final rechargeAmount = _pendingRechargeAmount;
    final walletCardId = _pendingWalletCardId;
    final fallbackOrderId = _orderId;

    debugPrint(
      'Wallet payment success: paymentId=${response.paymentId}, '
      'orderId=${response.orderId}, signature=${response.signature?.isNotEmpty}, '
      'rechargeAmount=$rechargeAmount',
    );

    try {
      if (outletId == null || userId == null) {
        throw Exception('Missing outlet or user');
      }

      final orderId = (response.orderId?.isNotEmpty ?? false)
          ? response.orderId!
          : fallbackOrderId;
      final paymentId = response.paymentId ?? '';
      final signature = response.signature ?? '';

      if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
        throw Exception('Incomplete payment details from Razorpay');
      }
      if (rechargeAmount <= 0) {
        throw Exception('Recharge amount is missing. Please contact support.');
      }

      final confirmRequest = {
        'userId': userId,
        'amount': rechargeAmount,
        'orderId': orderId,
        'transactionId': paymentId,
        'signature': signature,
        if (walletCardId != null) 'walletCardId': walletCardId,
      };

      debugPrint('Wallet confirm request: $confirmRequest');

      final confirmResponse = await _confirmWalletRechargeWithRetry(
        outletId,
        confirmRequest,
      );

      if (confirmResponse is Map && confirmResponse['status'] == 'success') {
        final data = confirmResponse['data'];
        if (data is Map) {
          final wallet = data['wallet'];
          if (wallet is Map) {
            _applyWalletPayload({
              ...Map<String, dynamic>.from(wallet),
              if (data['transactions'] is List)
                'transactions': data['transactions'],
            });
          }
        }

        await loadWalletData();

        final credited =
            (data is Map ? data['creditedAmount'] as num? : null)?.toDouble() ??
                rechargeAmount;
        await _showPaymentSuccessDialog(
          title: loc.payment_successful,
          description: loc.wallet_recharge_success(formatAmount(credited)),
        );
      } else {
        final message = confirmResponse is Map
            ? confirmResponse['message']?.toString()
            : null;
        throw Exception(message ?? 'Wallet recharge confirmation failed');
      }
    } catch (e) {
      debugPrint('Wallet recharge error: $e');
      showError(
        title: loc.payment_failed,
        description: e.toString().contains('Exception:')
            ? e.toString().replaceFirst('Exception: ', '')
            : loc.payment_failed_description,
      );
    } finally {
      _paymentInFlight = false;
      isProcessingPayment.value = false;
      _pendingRechargeAmount = 0;
      _pendingWalletCardId = null;
      _orderId = '';
    }
  }

  Future<dynamic> _confirmWalletRechargeWithRetry(
    String outletId,
    Map<String, dynamic> confirmRequest,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        return await _confirmWalletRecharge(outletId, confirmRequest);
      } catch (e) {
        lastError = e;
        final message = e.toString().toLowerCase();
        final retryable = message.contains('not captured') ||
            message.contains('network') ||
            message.contains('timeout');
        if (!retryable || attempt == 3) rethrow;
        await Future.delayed(Duration(milliseconds: 1500 * (attempt + 1)));
      }
    }
    throw lastError ?? Exception('Wallet recharge confirmation failed');
  }

  Future<dynamic> _confirmWalletRecharge(
    String outletId,
    Map<String, dynamic> confirmRequest,
  ) async {
    try {
      final response = await apiClient.confirmWalletRecharge(
        outletId,
        confirmRequest,
      );
      return response;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      if (data is String && data.isNotEmpty) {
        throw Exception(data);
      }
      throw Exception(
        e.response?.statusMessage ?? 'Wallet recharge confirmation failed',
      );
    }
  }

  Future<void> _handlePaymentFailure(PaymentFailureResponse response) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_checkoutSettled || _paymentInFlight) {
      debugPrint(
        'Wallet payment failure ignored (checkout already settled): '
        'code=${response.code}, message=${response.message}',
      );
      return;
    }

    _checkoutSettled = true;
    _paymentInFlight = false;
    isProcessingPayment.value = false;
    _pendingRechargeAmount = 0;
    _pendingWalletCardId = null;
    _orderId = '';

    final loc = AppLocalizations.of(Get.context!)!;
    final message = response.message?.trim();
    showError(
      title: loc.payment_failed,
      description: (message != null && message.isNotEmpty)
          ? message
          : loc.payment_failed_description,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final loc = AppLocalizations.of(Get.context!)!;
    showSuccess(
      title: loc.wallet_selected(response.walletName ?? ''),
      description: '',
    );
  }

  Future<void> _showPaymentSuccessDialog({
    required String title,
    required String description,
  }) async {
    final context = Get.context;
    if (context == null) return;

    await PaymentSuccessDialog.show(
      context: context,
      title: title,
      description: description,
      okLabel: AppLocalizations.of(context)!.ok,
    );
  }
}
