import 'package:billkaro/config/config.dart';
import 'package:billkaro/app/modules/subscription/subscription_controller.dart';

class GoldMembershipSheet extends StatefulWidget {
  const GoldMembershipSheet({super.key});

  @override
  State<GoldMembershipSheet> createState() => _GoldMembershipSheetState();
}

class _GoldMembershipSheetState extends State<GoldMembershipSheet> {
  SubscriptionController? _subscriptionController;
  bool _isInitialized = false;

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

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _subscriptionController == null) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Obx(() {
      final subscriptionController = _subscriptionController!;

      // Check if subscriptions are loaded
      if (subscriptionController.subscriptionPlans.isEmpty) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading subscription plans...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Check if we have at least 1 subscription (need index 0)
      if (subscriptionController.subscriptionPlans.isEmpty) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No subscription plans available',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check back later.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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

      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Trial over!\nKeep billing running!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
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

                  // Price
                  Row(
                    children: [
                      Text(
                        "₹${plan.price.toStringAsFixed(0)}",
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "₹${plan.discountedPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
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
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  if (plan.subtitle.isNotEmpty) ...[
                    Text(
                      plan.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pricePerDay.isNotEmpty) ...[
                          Text(
                            pricePerDay,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Text(' • ', style: TextStyle(fontSize: 12)),
                        ],
                        Text(
                          _formatDuration(plan.duration),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Features from bulletPoints
                  if (plan.bulletPoints.isNotEmpty) ...[
                    ...plan.bulletPoints
                        .take(3)
                        .map(
                          (feature) => _feature(Icons.check_circle, feature),
                        ),
                  ],

                  const SizedBox(height: 20),

                  // Buy Gold Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF7D88C), Color(0xFFB89B5E)],
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(),
                        onPressed: () {
                          Get.back(); // Close the bottom sheet
                          // subscriptionController.buyNow(
                          //   plan.id,
                          //   plan.discountedPrice,
                          // );
                          Get.toNamed(AppRoute.subscriptions);
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

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      );
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
