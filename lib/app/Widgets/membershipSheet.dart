import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/app/modules/subscription/subscription_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';

class GoldMembershipSheet extends StatefulWidget {
  const GoldMembershipSheet({super.key});

  @override
  State<GoldMembershipSheet> createState() => _GoldMembershipSheetState();
}

class _GoldMembershipSheetState extends State<GoldMembershipSheet> {
  SubscriptionController? _subscriptionController;
  bool _isInitialized = false;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    // Defer API call until after first frame so Get.dialog (loader) can run safely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController();
    });
  }

  Future<void> _initializeController() async {
    try {
      // Ensure SubscriptionController is initialized
      if (!Get.isRegistered<SubscriptionController>()) {
        Get.put(SubscriptionController());
      }
      _subscriptionController = Get.find<SubscriptionController>();

      // Always fetch subscriptions to ensure fresh data
      await _subscriptionController!.getSubscriptions();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing subscription controller: $e');
      if (mounted) {
        setState(() {
          _isInitialized =
              true; // Set to true even on error to show error state
        });
      }
    }
  }

  /// Format duration in months to readable format
  String _formatDuration(int months) {
    if (months <= 0) {
      return 'Invalid duration';
    }

    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (years == 0) {
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else if (remainingMonths == 0) {
      return '$years ${years == 1 ? 'year' : 'years'}';
    } else {
      final yearText = years == 1 ? 'year' : 'years';
      final monthText = remainingMonths == 1 ? 'month' : 'months';
      return '$years $yearText $remainingMonths $monthText';
    }
  }

  /// Calculate price per day
  String _calculatePricePerDay(double price, int durationMonths) {
    if (durationMonths <= 0) return '';
    final days = durationMonths * 30; // Approximate
    final pricePerDay = price / days;
    return 'Only ₹${pricePerDay.toStringAsFixed(0)} per day';
  }

  Widget _buildStateShell({
    required BuildContext context,
    required Widget child,
  }) {
    final borderRadius = BorderRadius.circular(_isWindows ? 14 : 24);
    final horizontalPadding = _isWindows ? 24.0 : 16.0;
    final verticalPadding = _isWindows ? 22.0 : 16.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _isWindows
            ? borderRadius
            : const BorderRadius.vertical(top: Radius.circular(24)),
        border: _isWindows ? Border.all(color: Colors.grey.shade300) : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _subscriptionController == null) {
      return _buildStateShell(
        context: context,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Obx(() {
      final subscriptionController = _subscriptionController!;

      // Check if we have at least 1 subscription (need index 0)
      if (subscriptionController.subscriptionPlans.isEmpty) {
        return _buildStateShell(
          context: context,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No subscription plans available',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please check back later.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      // Get the first subscription (index 0)
      final plan = subscriptionController.subscriptionPlans[0];
      final discount = ((plan.price - plan.discountedPrice) / plan.price * 100)
          .round();
      final pricePerDay = _calculatePricePerDay(
        plan.discountedPrice,
        plan.duration,
      );

      final content = SingleChildScrollView(
        physics: _isWindows
            ? const ClampingScrollPhysics()
            : const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isWindows) ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Upgrade your plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_isWindows ? 18 : 16),
              decoration: BoxDecoration(
                color: AppColor.primary,
                borderRadius: BorderRadius.circular(_isWindows ? 12 : 16),
              ),
              child: const Text(
                "Trial over!\nKeep billing running!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_isWindows ? 18 : 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plan.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        "₹${plan.price.toStringAsFixed(0)}",
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "₹${plan.discountedPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (discount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '$discount% OFF',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (plan.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      plan.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (pricePerDay.isNotEmpty)
                          Text(
                            pricePerDay,
                            style: const TextStyle(fontSize: 12),
                          ),
                        Text(
                          _formatDuration(plan.duration),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (plan.bulletPoints.isNotEmpty) ...[
              ...plan.bulletPoints
                  .take(4)
                  .map((feature) => _feature(Icons.check_circle, feature)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (_isWindows) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Maybe later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: _isWindows ? 2 : 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF7D88C), Color(0xFFB89B5E)],
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        // Get.toNamed(AppRoute.subscriptions);
                        Modular.to.pushNamed(HomeMainRoutes.subscriptions);
                      },
                      child: Text(
                        "Buy ${plan.title}",
                        style: const TextStyle(
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      );

      if (_isWindows) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _buildStateShell(context: context, child: content),
          ),
        );
      }

      return _buildStateShell(context: context, child: content);
    });
  }

  static Widget _feature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
