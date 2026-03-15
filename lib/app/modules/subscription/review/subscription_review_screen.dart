import 'package:billkaro/app/modules/subscription/review/subscription_review_controller.dart';
import 'package:billkaro/config/config.dart';

class SubscriptionReviewScreen extends StatelessWidget {
  const SubscriptionReviewScreen({super.key});

  SubscriptionReviewController get controller =>
      Get.put(SubscriptionReviewController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,

      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Subscription ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
            ),
            Text(
              'Review',
              style: TextStyle(
                color: AppColor.secondaryPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)], // Balance the leading
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  // Product Card
                  _buildProductCard(),
                  const SizedBox(height: 24),
                  // Price Details
                  _buildPriceDetails(),
                  const SizedBox(height: 24),
                  // GSTIN Input
                  _buildGstinSection(),
                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),

          // Pay Button
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.productName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${controller.originalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    '₹${controller.offerPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Valid Till ${controller.validTill} (Software)',
            style: const TextStyle(color: AppColor.white, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.deliveryInfo}\n${controller.printerWarranty}',
            style: const TextStyle(color: AppColor.white, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${controller.discountPercentage.toInt()}% OFF',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coupon',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: controller.updateCoupon,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: controller.applyCoupon,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  'APPLY',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow(
            'Offer Price',
            '₹${controller.offerPrice.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildPriceRow(
            'Taxes & Charges',
            '₹${controller.taxes.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white),
          const SizedBox(height: 16),
          _buildPriceRow(
            'Total Amount',
            '₹${controller.totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.grey[400],
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildGstinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'USE GSTIN FOR PURCHASE',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: controller.updateGstin,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tap to Enter GSTIN',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: _SlideToPayButton(
          amount: controller.totalAmount,
          onPay: () => controller.processPayment(),
        ),
      ),
    );
  }
}

class _SlideToPayButton extends StatefulWidget {
  const _SlideToPayButton({required this.amount, required this.onPay});

  final double amount;
  /// Called when user slides past threshold. Should create order and open Razorpay.
  final Future<void> Function() onPay;

  @override
  State<_SlideToPayButton> createState() => _SlideToPayButtonState();
}

class _SlideToPayButtonState extends State<_SlideToPayButton> {
  double _dragPosition = 0;
  bool _completed = false;

  static const double _thumbSize = 56;
  static const double _height = 56;
  static const double _threshold = 0.85;

  Future<void> _triggerPayment() async {
    if (!mounted || _completed) return;
    setState(() => _completed = true);
    await widget.onPay();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 40;
    final maxDrag = width - _thumbSize - 8;
    final isTriggered = _completed || (_dragPosition / maxDrag >= _threshold);

    if (isTriggered && !_completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerPayment();
      });
    }

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Track
          Container(
            width: double.infinity,
            height: _height,
            decoration: BoxDecoration(
              color: AppColor.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(_height / 2),
            ),
            alignment: Alignment.center,
            child: Text(
              _completed
                  ? 'Processing...'
                  : 'Slide to Pay ₹${widget.amount.toStringAsFixed(2)}/-',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.white,
              ),
            ),
          ),
          // Thumb
          Positioned(
            left: _completed ? maxDrag : _dragPosition.clamp(0.0, maxDrag),
            child: GestureDetector(
              onHorizontalDragUpdate: _completed
                  ? null
                  : (details) {
                      setState(() {
                        _dragPosition += details.delta.dx;
                        _dragPosition = _dragPosition.clamp(0.0, maxDrag);
                      });
                    },
              onHorizontalDragEnd: _completed
                  ? null
                  : (details) {
                      if (_dragPosition / maxDrag < _threshold) {
                        setState(() => _dragPosition = 0);
                      }
                    },
              child: Container(
                width: _thumbSize,
                height: _thumbSize,
                decoration: BoxDecoration(
                  color: AppColor.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  _completed ? Icons.check : Icons.arrow_forward_ios,
                  size: 22,
                  color: AppColor.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
