import 'package:billkaro/app/modules/subscription/review/subscription_review_controller.dart';
import 'package:billkaro/app/services/Modals/Subscriptions/subscription_response.dart';
import 'package:billkaro/config/config.dart';

class SubscriptionReviewScreen extends StatelessWidget {
  const SubscriptionReviewScreen({super.key, this.subscription, this.formData});

  static const double _windowsMaxContentWidth = 480;

  final SubscriptionPlan? subscription;
  final Map<String, String>? formData;

  bool _isWindowsDesktop(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.windows;

  SubscriptionReviewController get controller => Get.put(
    SubscriptionReviewController(
      initialPlan: subscription,
      initialFormData: formData,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isWindowsDesktop = _isWindowsDesktop(context);

    if (isWindowsDesktop) {
      return _buildWindowsLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildWindowsLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => Get.back(),
          tooltip: 'Close',
        ),
        title: const Text(
          'Review & Pay',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.black.withOpacity(0.08)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _windowsMaxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWindowsProductCard(),
                      if (controller.formData != null) ...[
                        const SizedBox(height: 14),
                        _buildDeliveryDetailsCard(),
                      ],
                      const SizedBox(height: 14),
                      _buildWindowsPriceCard(),
                      const SizedBox(height: 14),
                      _buildWindowsGstinSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildWindowsPayFooter(context),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
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
        actions: const [SizedBox(width: 48)],
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
                  _buildProductCard(),
                  if (controller.formData != null) ...[
                    const SizedBox(height: 24),
                    _buildDeliveryDetailsCard(windowsStyle: false),
                  ],
                  const SizedBox(height: 24),
                  _buildPriceDetails(),
                  const SizedBox(height: 24),
                  _buildGstinSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _windowsCard({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildWindowsProductCard() {
    final hasPrinter = controller.plan?.withPrinter == true;
    return _windowsCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasPrinter
                        ? Icons.print_outlined
                        : Icons.workspace_premium_outlined,
                    color: AppColor.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valid for ${controller.validTill}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.discountPercentage > 0)
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
                      '${controller.discountPercentage.toInt()}% OFF',
                      style: TextStyle(
                        color: AppColor.lightgreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasPrinter) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColor.secondaryPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColor.secondaryPrimary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 16,
                      color: AppColor.secondaryPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Includes thermal printer with free home delivery',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.secondaryPrimary.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '₹${controller.originalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${controller.offerPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColor.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsCard({bool windowsStyle = true}) {
    final data = controller.formData!;
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: AppColor.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Printer Delivery',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _deliveryRow('Outlet', data['outletName'] ?? '—'),
          _deliveryRow('Phone', data['phone'] ?? '—'),
          _deliveryRow('Address', data['deliveryAddress'] ?? '—'),
          _deliveryRow('Pincode', data['pincode'] ?? '—'),
        ],
      ),
    );
    if (windowsStyle) return _windowsCard(child: content);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.backGroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: content,
    );
  }

  Widget _deliveryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsPriceCard() {
    return _windowsCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Breakdown',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildWindowsPriceRow(
              'Offer price',
              '₹${controller.offerPrice.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildWindowsPriceRow(
              'Taxes & charges',
              '₹${controller.taxes.toStringAsFixed(2)}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.black.withOpacity(0.08)),
            ),
            _buildWindowsPriceRow(
              'Total',
              '₹${controller.totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowsPriceRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal ? AppColor.black87 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? AppColor.primary : AppColor.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildWindowsGstinSection() {
    return _windowsCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final value = controller.gstin.value;
          final isValid = controller.isGstinFilledAndValid;
          final message = controller.gstinVerificationMessage.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'GSTIN (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (isValid) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.verified_outlined,
                      size: 16,
                      color: AppColor.lightgreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.lightgreen,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: controller.updateGstin,
                style: const TextStyle(fontSize: 13, letterSpacing: 0.5),
                textCapitalization: TextCapitalization.characters,
                maxLength: 15,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  _GstinUpperCaseFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: 'e.g. 22AAAAA0000A1Z5',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColor.backGroundColor,
                  isDense: true,
                  counterText: value.isNotEmpty ? '${value.length}/15' : '',
                  suffixIcon: isValid
                      ? Icon(Icons.check_circle, color: AppColor.lightgreen)
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isValid
                          ? AppColor.lightgreen.withOpacity(0.6)
                          : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppColor.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: controller.isVerifyingGstin.value
                          ? null
                          : controller.verifyGstin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isVerifyingGstin.value
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  if (message.isNotEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          message,
                          style: TextStyle(
                            color: isValid ? AppColor.lightgreen : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
              if (value.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Leave blank if you do not need a GST invoice.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWindowsPayFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _windowsMaxContentWidth,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total payable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '₹${controller.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => controller.processPayment(),
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: Text(
                    'Pay ₹${controller.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    try {
      await widget.onPay();
    } finally {
      if (mounted) {
        setState(() {
          _completed = false;
          _dragPosition = 0;
        });
      }
    }
  }

  Future<void> _onDragEnd(double maxDrag) async {
    if (maxDrag <= 0 || _completed) return;
    final progress = _dragPosition / maxDrag;
    if (progress >= _threshold) {
      setState(() => _dragPosition = maxDrag);
      await _triggerPayment();
      return;
    }
    setState(() => _dragPosition = 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = (constraints.maxWidth - _thumbSize).clamp(
          0.0,
          double.infinity,
        );
        final thumbLeft = _completed
            ? maxDrag
            : _dragPosition.clamp(0.0, maxDrag);

        return SizedBox(
          height: _height,
          width: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: _completed
                ? null
                : (details) {
                    if (maxDrag <= 0) return;
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx).clamp(
                        0.0,
                        maxDrag,
                      );
                    });
                  },
            onHorizontalDragEnd: _completed ? null : (_) => _onDragEnd(maxDrag),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
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
                Positioned(
                  left: thumbLeft,
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GstinUpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
