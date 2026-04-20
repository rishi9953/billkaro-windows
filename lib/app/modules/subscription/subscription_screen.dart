// Main Screen
import 'dart:math' as math;
import 'dart:ui' show PaintingStyle;
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/subscription/review/subscription_review_screen.dart';
import 'package:billkaro/app/modules/subscription/subscription_controller.dart';
import 'package:billkaro/app/services/Modals/Subscriptions/subscription_response.dart';
import 'package:billkaro/app/services/Modals/login_response.dart'
    hide SubscriptionPlan;
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const double _windowsMaxContentWidth = 1120;

  bool _isWindowsDesktop(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());
    final isWindowsDesktop = _isWindowsDesktop(context);

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        elevation: isWindowsDesktop ? 0 : null,
        scrolledUnderElevation: isWindowsDesktop ? 0 : null,
        surfaceTintColor: isWindowsDesktop ? Colors.transparent : null,
        toolbarHeight: isWindowsDesktop ? 48 : kToolbarHeight,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: () => controller.showSupportBottomSheet(),
            tooltip: 'Support',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = isWindowsDesktop
              ? _windowsMaxContentWidth
              : double.infinity;

          return Stack(
            children: [
              if (!isWindowsDesktop)
                Positioned.fill(
                  child: CustomPaint(painter: BackgroundDecorationPainter()),
                )
              else
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColor.backGroundColor,
                      border: Border(
                        top: BorderSide(color: Colors.black.withOpacity(0.06)),
                      ),
                    ),
                  ),
                ),
              SingleChildScrollView(
                physics: isWindowsDesktop
                    ? const ClampingScrollPhysics()
                    : const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWindowsDesktop ? 28 : 16,
                  vertical: isWindowsDesktop ? 20 : 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: LayoutBuilder(
                      builder: (context, inner) {
                        final contentWidth = inner.maxWidth;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderSection(
                              isWindowsStyle: isWindowsDesktop,
                            ),
                            SizedBox(height: isWindowsDesktop ? 20 : 24),
                            Obx(
                              () => _buildPlansSection(
                                controller: controller,
                                isWindowsStyle: isWindowsDesktop,
                                isWide: isWindowsDesktop && contentWidth >= 960,
                                columnWidth: contentWidth,
                              ),
                            ),
                            SizedBox(height: isWindowsDesktop ? 24 : 16),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlansSection({
    required SubscriptionController controller,
    required bool isWindowsStyle,
    required bool isWide,
    required double columnWidth,
  }) {
    final plans = controller.subscriptionPlans;
    if (plans.isEmpty) return _buildEmptyState(isWindowsStyle: isWindowsStyle);

    final outlet = controller.appPref.selectedOutlet;
    final activePlanIds = _activeSubscriptionPlanIds(outlet);
    final visible = plans;

    final gap = isWindowsStyle ? 20.0 : 16.0;
    final useTwoColumns = isWide && visible.length > 1;
    final cardWidth = useTwoColumns ? (columnWidth - gap) / 2 : columnWidth;

    Widget cardFor(SubscriptionPlan plan) => _buildPlanCard(
      title: plan.title,
      badge: null,
      originalPrice: plan.price,
      price: plan.discountedPrice,
      subtitle: plan.subtitle,
      duration: plan.duration,
      features: plan.bulletPoints,
      printerFeatures: plan.withPrinter
          ? ['Free Home Delivery', 'Bluetooth + USB Support', '1 Year Warranty']
          : null,
      showPrinterImage: plan.withPrinter,
      printerNote: plan.withPrinter
          ? null
          : 'Printer not included in this plan.',
      onBuyNow: () => controller.buyNow(plan.id, plan.discountedPrice),
      isPopular: false,
      plan: plan,
      isWindowsStyle: isWindowsStyle,
      isCurrentPlan: activePlanIds.contains(plan.id),
    );

    if (isWide) {
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: visible
            .map((plan) => SizedBox(width: cardWidth, child: cardFor(plan)))
            .toList(),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          cardFor(visible[i]),
        ],
      ],
    );
  }

  /// Plan IDs for subscriptions that are still active (endDate in the future).
  /// Empty set when outlet has no subscription or only expired ones.
  Set<String> _activeSubscriptionPlanIds(OutletData? outlet) {
    return activeSubscriptionPlanIdsFromOutlet(outlet);
  }

  Widget _buildHeaderSection({required bool isWindowsStyle}) {
    final radius = isWindowsStyle ? 8.0 : 16.0;
    return Container(
      padding: EdgeInsets.all(isWindowsStyle ? 18 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.primary, AppColor.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: isWindowsStyle
            ? Border.all(color: Colors.black.withOpacity(0.12))
            : null,
        boxShadow: [
          BoxShadow(
            color: isWindowsStyle
                ? Colors.black.withOpacity(0.08)
                : AppColor.primary.withOpacity(0.3),
            blurRadius: isWindowsStyle ? 8 : 12,
            offset: Offset(0, isWindowsStyle ? 2 : 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (!isWindowsStyle)
            Positioned.fill(
              child: CustomPaint(painter: HeaderDecorationPainter()),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isWindowsStyle ? 10 : 12),
                    decoration: BoxDecoration(
                      color: AppColor.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        isWindowsStyle ? 8 : 12,
                      ),
                    ),
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColor.white,
                      size: isWindowsStyle ? 26 : 28,
                    ),
                  ),
                  SizedBox(width: isWindowsStyle ? 14 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BillKaro Premium',
                          style: TextStyle(
                            color: AppColor.white,
                            fontSize: isWindowsStyle ? 22 : 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: isWindowsStyle ? 0.2 : 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unlock all features and boost your business',
                          style: TextStyle(
                            color: AppColor.white.withOpacity(0.9),
                            fontSize: isWindowsStyle ? 13 : 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool isWindowsStyle}) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isWindowsStyle ? 32 : 40,
          vertical: isWindowsStyle ? 48 : 40,
        ),
        decoration: isWindowsStyle
            ? BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: isWindowsStyle ? 56 : 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No plans available',
              style: TextStyle(
                fontSize: isWindowsStyle ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later',
              style: TextStyle(
                fontSize: isWindowsStyle ? 13 : 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    String? badge,
    required double originalPrice,
    required double price,
    required String subtitle,
    required int duration,
    required List<String> features,
    List<String>? printerFeatures,
    bool showPrinterImage = false,
    String? printerNote,
    required VoidCallback onBuyNow,
    bool isPopular = false,
    required SubscriptionPlan plan,
    bool isWindowsStyle = false,
    bool isCurrentPlan = false,
  }) {
    final discount = ((originalPrice - price) / originalPrice * 100).round();
    final cardRadius = isWindowsStyle ? 8.0 : 16.0;
    final innerPadding = isWindowsStyle ? 18.0 : 20.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: isPopular
              ? AppColor.secondaryPrimary
              : (isWindowsStyle
                    ? Colors.black.withOpacity(0.10)
                    : Colors.grey.shade200),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? AppColor.secondaryPrimary.withOpacity(0.15)
                : Colors.black.withOpacity(isWindowsStyle ? 0.06 : 0.05),
            blurRadius: isPopular ? 12 : (isWindowsStyle ? 6 : 8),
            offset: Offset(0, isWindowsStyle ? 2 : 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (!isWindowsStyle)
            Positioned.fill(
              child: CustomPaint(
                painter: CardDecorationPainter(isPopular: isPopular),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              if (badge != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColor.secondaryPrimary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(cardRadius),
                      topRight: Radius.circular(cardRadius),
                    ),
                  ),
                  child: Text(
                    badge,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColor.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

              Padding(
                padding: EdgeInsets.all(innerPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isWindowsStyle ? 7 : 8),
                          decoration: BoxDecoration(
                            color: AppColor.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              isWindowsStyle ? 6 : 8,
                            ),
                          ),
                          child: Icon(
                            Icons.workspace_premium_outlined,
                            color: AppColor.primary,
                            size: isWindowsStyle ? 18 : 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: AppColor.black87,
                              fontSize: isWindowsStyle ? 18 : 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: isWindowsStyle ? 0.15 : 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isWindowsStyle ? 14 : 16),

                    // Pricing
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹$originalPrice',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹$price',
                          style: TextStyle(
                            color: AppColor.primary,
                            fontSize: isWindowsStyle ? 28 : 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
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
                              color: AppColor.lightgreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$discount% OFF',
                              style: TextStyle(
                                color: AppColor.lightgreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Duration Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWindowsStyle ? 10 : 12,
                        vertical: isWindowsStyle ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          isWindowsStyle ? 6 : 8,
                        ),
                        border: Border.all(
                          color: AppColor.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColor.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              color: AppColor.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isWindowsStyle ? 16 : 20),
                    Divider(
                      height: 1,
                      thickness: isWindowsStyle ? 1 : null,
                      color: isWindowsStyle
                          ? Colors.black.withOpacity(0.08)
                          : null,
                    ),

                    SizedBox(height: isWindowsStyle ? 14 : 16),

                    // Features Section
                    Text(
                      'What\'s Included',
                      style: TextStyle(
                        color: AppColor.black87,
                        fontSize: isWindowsStyle ? 15 : 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: isWindowsStyle ? 0.1 : 0.2,
                      ),
                    ),

                    SizedBox(height: isWindowsStyle ? 10 : 12),

                    // Features List
                    ...features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColor.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: AppColor.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  color: AppColor.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Printer Features
                    if (printerFeatures != null) ...[
                      SizedBox(height: isWindowsStyle ? 14 : 16),
                      Container(
                        padding: EdgeInsets.all(isWindowsStyle ? 14 : 16),
                        decoration: BoxDecoration(
                          color: AppColor.backGroundColor,
                          borderRadius: BorderRadius.circular(
                            isWindowsStyle ? 8 : 12,
                          ),
                          border: Border.all(
                            color: isWindowsStyle
                                ? Colors.black.withOpacity(0.08)
                                : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.print,
                                  size: 18,
                                  color: AppColor.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Printer Features',
                                  style: TextStyle(
                                    color: AppColor.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: printerFeatures
                                        .map(
                                          (feature) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 4,
                                                  ),
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: AppColor
                                                        .secondaryPrimary
                                                        .withOpacity(0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.check,
                                                    size: 12,
                                                    color: AppColor
                                                        .secondaryPrimary,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    feature,
                                                    style: TextStyle(
                                                      color: AppColor.black87,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                if (showPrinterImage)
                                  Assets.printer.image(
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Printer Note
                    if (printerNote != null) ...[
                      SizedBox(height: isWindowsStyle ? 10 : 12),
                      Container(
                        padding: EdgeInsets.all(isWindowsStyle ? 10 : 12),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(
                            isWindowsStyle ? 6 : 8,
                          ),
                          border: Border.all(color: AppColor.primary, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColor.primary.withOpacity(0.8),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                printerNote,
                                style: TextStyle(
                                  color: AppColor.primary.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: isWindowsStyle ? 16 : 20),

                    SizedBox(
                      width: double.infinity,
                      child: isCurrentPlan
                          ? OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColor.primary,
                                disabledForegroundColor: AppColor.primary
                                    .withOpacity(0.75),
                                side: BorderSide(
                                  color: AppColor.primary.withOpacity(0.35),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isWindowsStyle ? 14 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isWindowsStyle ? 6 : 12,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Current plan',
                                style: TextStyle(
                                  fontSize: isWindowsStyle ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                if (plan.withPrinter) {
                                  Modular.to.pushNamed(
                                    HomeMainRoutes.subscriptionForm,
                                    arguments: {'subscription': plan},
                                  );
                                  // Get.toNamed(
                                  //   AppRoute.subscriptionForm,
                                  //   arguments: {'subscription': plan},
                                  // );
                                } else {
                                  if (isWindowsStyle) {
                                    Get.dialog(
                                      Dialog(
                                        insetPadding: const EdgeInsets.symmetric(
                                          horizontal: 64,
                                          vertical: 36,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 980,
                                            maxHeight: 760,
                                          ),
                                          child: SubscriptionReviewScreen(
                                            subscription: plan,
                                          ),
                                        ),
                                      ),
                                      barrierDismissible: false,
                                    );
                                  } else {
                                    Modular.to.pushNamed(
                                      HomeMainRoutes.subscriptionReview,
                                      arguments: {'subscription': plan},
                                    );
                                  }
                                  // Get.toNamed(
                                  //   AppRoute.subscriptionReview,
                                  //   arguments: {'subscription': plan},
                                  // );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPopular
                                    ? AppColor.secondaryPrimary
                                    : AppColor.primary,
                                foregroundColor: AppColor.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isWindowsStyle ? 14 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isWindowsStyle ? 6 : 12,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Buy Now',
                                style: TextStyle(
                                  color: AppColor.white,
                                  fontSize: isWindowsStyle ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: isWindowsStyle ? 0.25 : 0.5,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format duration in months to readable format (e.g., "1 year", "6 months", "1 year 6 months")
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
}

// Background Decoration Painter
class BackgroundDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColor.primary.withOpacity(0.03);

    final paint2 = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColor.secondaryPrimary.withOpacity(0.02);

    // Draw circles in background
    final center1 = Offset(size.width * 0.1, size.height * 0.15);
    final radius1 = size.width * 0.3;
    canvas.drawCircle(center1, radius1, paint);

    final center2 = Offset(size.width * 0.9, size.height * 0.3);
    final radius2 = size.width * 0.25;
    canvas.drawCircle(center2, radius2, paint2);

    final center3 = Offset(size.width * 0.5, size.height * 0.7);
    final radius3 = size.width * 0.2;
    canvas.drawCircle(center3, radius3, paint);

    // Draw some decorative lines
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColor.primary.withOpacity(0.05)
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.15,
      size.width * 0.6,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.25,
      size.width,
      size.height * 0.2,
    );
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Header Decoration Painter
class HeaderDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColor.white.withOpacity(0.1);

    final paint2 = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColor.secondaryPrimary.withOpacity(0.15);

    // Draw decorative circles
    final center1 = Offset(size.width * 0.85, size.height * 0.2);
    final radius1 = size.width * 0.15;
    canvas.drawCircle(center1, radius1, paint);

    final center2 = Offset(size.width * 0.9, size.height * 0.6);
    final radius2 = size.width * 0.1;
    canvas.drawCircle(center2, radius2, paint2);

    // Draw decorative arcs
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColor.white.withOpacity(0.2)
      ..strokeWidth = 2;

    final rect1 = Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.3),
      radius: 30,
    );
    canvas.drawArc(rect1, 0, math.pi * 1.5, false, arcPaint);

    final rect2 = Rect.fromCircle(
      center: Offset(size.width * 0.7, size.height * 0.7),
      radius: 25,
    );
    canvas.drawArc(rect2, math.pi * 0.5, math.pi, false, arcPaint);

    // Draw some sparkle effects
    final sparklePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColor.white.withOpacity(0.3);

    final sparkles = [
      Offset(size.width * 0.15, size.height * 0.3),
      Offset(size.width * 0.25, size.height * 0.7),
      Offset(size.width * 0.7, size.height * 0.2),
    ];

    for (final sparkle in sparkles) {
      canvas.drawCircle(sparkle, 3, sparklePaint);
      canvas.drawCircle(sparkle, 1, Paint()..color = AppColor.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Card Decoration Painter
class CardDecorationPainter extends CustomPainter {
  final bool isPopular;

  CardDecorationPainter({this.isPopular = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (isPopular) {
      // Draw special decoration for popular cards
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColor.secondaryPrimary.withOpacity(0.05);

      // Draw corner accent
      final path = Path();
      path.moveTo(size.width - 40, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, 40);
      path.close();
      canvas.drawPath(path, paint);

      // Draw decorative circle in corner
      final circlePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColor.secondaryPrimary.withOpacity(0.1)
        ..strokeWidth = 2;

      final center = Offset(size.width - 20, 20);
      canvas.drawCircle(center, 15, circlePaint);
      canvas.drawCircle(
        center,
        8,
        Paint()..color = AppColor.secondaryPrimary.withOpacity(0.15),
      );
    }

    // Draw subtle pattern for all cards
    final patternPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColor.primary.withOpacity(0.03)
      ..strokeWidth = 1;

    // Draw diagonal lines pattern
    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.2 + i * 0.15);
      final path = Path();
      path.moveTo(0, y);
      path.lineTo(size.width * 0.3, y);
      canvas.drawPath(path, patternPaint);
    }

    // Draw decorative dots
    // Use explicit assignments (not cascades ending in `.fill`) so the Dart
    // compiler does not treat `.fill` / loop vars as enum dot-shorthands (GD798B012).
    final dotPaint = Paint();
    dotPaint.style = PaintingStyle.fill;
    dotPaint.color = AppColor.primary.withOpacity(0.05);

    final List<Offset> dots = [
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.2, size.height * 0.85),
      Offset(size.width * 0.9, size.height * 0.25),
    ];

    for (final Offset dotCenter in dots) {
      canvas.drawCircle(dotCenter, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is CardDecorationPainter) {
      return oldDelegate.isPopular != isPopular;
    }
    return false;
  }
}
