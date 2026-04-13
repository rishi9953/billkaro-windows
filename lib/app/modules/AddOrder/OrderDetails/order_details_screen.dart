import 'package:billkaro/app/modules/AddOrder/OrderDetails/order_details_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/Modals/orders/split_payment.dart';
import 'package:billkaro/config/config.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final OrderDetailsController c;

  static const double _desktopBreakpoint = 980;
  static const Set<String> _allowedPaymentMethods = {'cash', 'card', 'upi'};

  String _normalizePaymentMethod(String value) {
    final v = value.trim().toLowerCase();
    return _allowedPaymentMethods.contains(v) ? v : 'cash';
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<OrderDetailsController>()) {
      Get.delete<OrderDetailsController>(force: true);
    }
    c = Get.put(OrderDetailsController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<OrderDetailsController>()) {
      Get.delete<OrderDetailsController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.order_details), centerTitle: false),
      body: Form(
        key: c.formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
            final pagePadding = EdgeInsets.symmetric(
              horizontal: isDesktop ? 28 : 16,
              vertical: isDesktop ? 24 : 16,
            );

            final orderCard = _sectionCard(
              title: 'Order',
              icon: Icons.receipt_long,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBillNumberDisplay(c, loc),
                  Obx(() {
                    c.orderFrom.value;
                    if (Get.isRegistered<HomeScreenController>()) {
                      Get.find<HomeScreenController>().selectedOutlet.value;
                    }
                    if (!c.isDineIn || !HomeMainRoutes.outletShowsTables()) {
                      return const SizedBox.shrink();
                    }
                    return _buildTableNumberField(c, loc);
                  }),
                ],
              ),
            );

            final customerCard = _sectionCard(
              title: 'Customer',
              icon: Icons.person_outline,
              child: isDesktop
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            loc.customer_name,
                            c.customerName,
                            TextInputType.name,
                            cap: TextCapitalization.words,
                            loc: loc,
                            prefixIcon: Icons.person_outline,
                            bottomGap: 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            loc.phone_number_field,
                            c.phoneNumber,
                            TextInputType.phone,
                            max: 10,
                            validator: (v) => _phoneVal(v, loc),
                            loc: loc,
                            prefixIcon: Icons.phone_outlined,
                            bottomGap: 0,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          loc.customer_name,
                          c.customerName,
                          TextInputType.name,
                          cap: TextCapitalization.words,
                          loc: loc,
                          prefixIcon: Icons.person_outline,
                          bottomGap: 16,
                        ),
                        _buildField(
                          loc.phone_number_field,
                          c.phoneNumber,
                          TextInputType.phone,
                          max: 10,
                          validator: (v) => _phoneVal(v, loc),
                          loc: loc,
                          prefixIcon: Icons.phone_outlined,
                          bottomGap: 0,
                        ),
                      ],
                    ),
            );

            final chargesCard = _sectionCard(
              title: 'Charges',
              icon: Icons.percent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDiscount(c, loc, bottomGap: 16),
                  _buildField(
                    loc.service_charge,
                    c.serviceCharge,
                    TextInputType.number,
                    loc: loc,
                    prefixIcon: Icons.add_circle_outline,
                    bottomGap: 0,
                  ),
                ],
              ),
            );

            final paymentCard = _sectionCard(
              title: 'Payment',
              icon: Icons.payments_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildPayment(c, loc), _buildSplitPayment(c, loc)],
              ),
            );

            final content = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: pagePadding,
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  orderCard,
                                  const SizedBox(height: 16),
                                  chargesCard,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  customerCard,
                                  const SizedBox(height: 16),
                                  paymentCard,
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            orderCard,
                            const SizedBox(height: 16),
                            customerCard,
                            const SizedBox(height: 16),
                            chargesCard,
                            const SizedBox(height: 16),
                            paymentCard,
                          ],
                        ),
                ),
              ),
            );

            return Column(
              children: [
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: isDesktop,
                    child: SingleChildScrollView(child: content),
                  ),
                ),
                _buildSaveButton(context, c, isWide: isDesktop),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: AppColor.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.withOpacity(0.06),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 18, color: Colors.grey[700]),
      suffixIcon: suffixIcon,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColor.primary.withOpacity(0.65)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  /// Build prominent bill number display
  Widget _buildBillNumberDisplay(
    OrderDetailsController c,
    AppLocalizations loc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.bill_number),
          const SizedBox(height: 8),
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: AppColor.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.billNumber.text.isEmpty
                          ? loc.loading
                          : (c.billNumber.text == '0'
                                ? '1'
                                : c.billNumber.text),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (c.isLoading.value)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableNumberField(
    OrderDetailsController c,
    AppLocalizations loc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.table_number),
          const SizedBox(height: 8),
          Obx(() {
            final tables = c.availableTables;
            final selectedTable = c.tableNumber.text.trim();
            final dropdownValue = selectedTable.isEmpty
                ? null
                : tables.any((t) => t.displayName == selectedTable)
                ? selectedTable
                : null;

            return DropdownButtonFormField<String>(
              value: dropdownValue,
              items: tables
                  .map(
                    (table) => DropdownMenuItem<String>(
                      value: table.displayName,
                      child: Text(table.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) => c.tableNumber.text = value ?? '',
              validator: (v) => v?.isEmpty ?? true ? loc.required : null,
              decoration: _fieldDecoration(
                hintText: tables.isEmpty
                    ? 'No available tables'
                    : loc.enter_table_number,
                prefixIcon: Icons.table_restaurant_outlined,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    TextInputType type, {
    TextCapitalization cap = TextCapitalization.none,
    int? max,
    bool enabled = true,
    String? Function(String?)? validator,
    required AppLocalizations loc,
    double bottomGap = 24,
    IconData? prefixIcon,
  }) {
    String hintText = '';
    if (label == loc.table_number) {
      hintText = loc.enter_table_number;
    } else if (label == loc.customer_name) {
      hintText = loc.enter_customer_name;
    } else if (label == loc.phone_number_field) {
      hintText = loc.enter_phone_number;
    } else if (label == loc.service_charge) {
      hintText = loc.enter_service_charge;
    } else if (label == loc.bill_number) {
      hintText = loc.enter_bill_number;
    } else {
      hintText = 'Enter $label';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 8),
          TextFormField(
            enabled: enabled,
            controller: ctrl,
            keyboardType: type,
            textCapitalization: cap,
            maxLength: max,
            validator:
                validator ?? (v) => v?.isEmpty ?? true ? loc.required : null,
            decoration: _fieldDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscount(
    OrderDetailsController c,
    AppLocalizations loc, {
    double bottomGap = 24,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.discount),
          const SizedBox(height: 8),
          Obx(() {
            final isPercent = c.discountType.value == loc.percentage;
            return TextFormField(
              controller: c.discount,
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? loc.required : null,
              decoration: _fieldDecoration(
                hintText: loc.enter_discount,
                prefixIcon: isPercent ? Icons.percent : Icons.currency_rupee,
                suffixIcon: TextButton(
                  onPressed: () => c.discountType.value = isPercent
                      ? loc.amount
                      : loc.percentage,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColor.primary,
                  ),
                  child: Text(
                    c.discountType.value,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPayment(OrderDetailsController c, AppLocalizations loc) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(loc.payment_received_in)),
              Switch(
                value: c.useSplitPayment.value,
                onChanged: (value) {
                  c.useSplitPayment.value = value;
                  if (!value) {
                    c.splitPayments.clear();
                  }
                },
              ),
              Text(
                'Split Payment',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!c.useSplitPayment.value)
            DropdownButtonFormField<String>(
              value: c.paymentRecieved.value,
              items: [
                DropdownMenuItem(value: 'cash', child: Text(loc.cash)),
                DropdownMenuItem(value: 'card', child: Text(loc.card)),
                DropdownMenuItem(value: 'upi', child: Text(loc.upi)),
              ],
              onChanged: (v) => c.paymentRecieved.value = v!,
              decoration: _fieldDecoration(
                hintText: '',
                prefixIcon: Icons.payments_outlined,
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSplitPayment(OrderDetailsController c, AppLocalizations loc) {
    return Obx(
      () => c.useSplitPayment.value
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Split Payment'),
                  const SizedBox(height: 8),
                  if (c.totalAmount != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                          Text(
                            '₹${(c.totalAmount ?? 0).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  ...c.splitPayments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final payment = entry.value;
                    return _buildSplitPaymentItem(c, loc, index, payment);
                  }),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final remaining = c.remainingAmount;
                      if (remaining == null) return const SizedBox.shrink();

                      final bg = remaining < 0
                          ? Colors.red[50]
                          : remaining > 0.01
                          ? Colors.orange[50]
                          : Colors.green[50];
                      final border = remaining < 0
                          ? Colors.red[300]!
                          : remaining > 0.01
                          ? Colors.orange[300]!
                          : Colors.green[300]!;
                      final fg = remaining < 0
                          ? Colors.red[900]
                          : remaining > 0.01
                          ? Colors.orange[900]
                          : Colors.green[900];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              remaining < 0
                                  ? 'Excess:'
                                  : remaining > 0.01
                                  ? 'Remaining:'
                                  : 'Complete!',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: fg,
                              ),
                            ),
                            Text(
                              '₹${remaining.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: fg,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSplitPaymentDialog(c, loc),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment Method'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSplitPaymentItem(
    OrderDetailsController c,
    AppLocalizations loc,
    int index,
    dynamic payment,
  ) {
    final safeMethod = _normalizePaymentMethod(payment.paymentMethod);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: safeMethod,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                DropdownMenuItem(value: 'cash', child: Text(loc.cash)),
                DropdownMenuItem(value: 'card', child: Text(loc.card)),
                DropdownMenuItem(value: 'upi', child: Text(loc.upi)),
              ],
              onChanged: (value) {
                if (value != null) {
                  c.splitPayments[index] = SplitPayment(
                    paymentMethod: _normalizePaymentMethod(value),
                    amount: payment.amount,
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: payment.amount.toStringAsFixed(2),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                c.splitPayments[index] = SplitPayment(
                  paymentMethod: payment.paymentMethod,
                  amount: amount,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => c.removeSplitPayment(index),
          ),
        ],
      ),
    );
  }

  void _showAddSplitPaymentDialog(
    OrderDetailsController c,
    AppLocalizations loc,
  ) {
    final amountController = TextEditingController();
    String selectedMethod = 'cash';

    Get.dialog(
      AlertDialog(
        title: const Text('Add Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedMethod,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'cash', child: Text(loc.cash)),
                DropdownMenuItem(value: 'card', child: Text(loc.card)),
                DropdownMenuItem(value: 'upi', child: Text(loc.upi)),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedMethod = value;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0) {
                c.addSplitPayment(selectedMethod, amount);
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    OrderDetailsController c, {
    required bool isWide,
  }) {
    final loc = AppLocalizations.of(Get.context!);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Align(
        alignment: isWide ? Alignment.centerRight : Alignment.center,
        child: SizedBox(
          width: isWide ? 260 : double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (c.formKey.currentState?.validate() ?? false) {
                c.saveOrderDetailsAndClose(context);
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              loc?.save_order_details ?? 'Save order details',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12.5,
      color: Colors.grey[700],
      fontWeight: FontWeight.w700,
    ),
  );

  String? _phoneVal(String? v, AppLocalizations loc) {
    if (v == null || v.isEmpty) return loc.required;
    if (v.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(v)) {
      return loc.enter_valid_10_digit_number;
    }
    return null;
  }
}
