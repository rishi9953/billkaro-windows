import 'package:billkaro/app/modules/AddOrder/OrderDetails/order_details_controller.dart';
import 'package:billkaro/app/services/Modals/orders/split_payment.dart';
import 'package:billkaro/config/config.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OrderDetailsController());

    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.order_details)),
      body: Form(
        key: c.formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Bill Number - Prominent Display
                  _buildBillNumberDisplay(c, loc),
                  if (c.isDineIn) _buildTableNumberField(c, loc),
                  _buildField(
                    loc.customer_name,
                    c.customerName,
                    TextInputType.name,
                    cap: TextCapitalization.words,
                    loc: loc,
                  ),
                  _buildField(
                    loc.phone_number_field,
                    c.phoneNumber,
                    TextInputType.phone,
                    max: 10,
                    validator: (v) => _phoneVal(v, loc),
                    loc: loc,
                  ),
                  _buildDiscount(c, loc),
                  _buildField(
                    loc.service_charge,
                    c.serviceCharge,
                    TextInputType.number,
                    loc: loc,
                  ),
                  _buildPayment(c, loc),
                  _buildSplitPayment(c, loc),
                ],
              ),
            ),
            _buildSaveButton(c),
          ],
        ),
      ),
    );
  }

  /// Build prominent bill number display
  Widget _buildBillNumberDisplay(
    OrderDetailsController c,
    AppLocalizations loc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.bill_number),
          const SizedBox(height: 8),
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.primary.withOpacity(0.3),
                  width: 2,
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.table_number),
          const SizedBox(height: 8),
          TextFormField(
            controller: c.tableNumber,
            keyboardType: TextInputType.number,
            validator: (v) => v?.isEmpty ?? true ? loc.required : null,
            decoration: InputDecoration(
              hintText: loc.enter_table_number,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: 24),
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
            decoration: InputDecoration(
              hintText: hintText,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscount(OrderDetailsController c, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.discount),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: c.discount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: loc.enter_discount,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? loc.required : null,
                  ),
                ),
                InkWell(
                  onTap: () => c.discountType.value =
                      c.discountType.value == loc.percentage
                      ? loc.amount
                      : loc.percentage,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Obx(
                      () => Row(
                        children: [
                          Icon(
                            c.discountType.value == loc.percentage
                                ? Icons.percent
                                : Icons.currency_rupee,
                            color: AppColor.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.discountType.value,
                            style: const TextStyle(
                              color: AppColor.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
                  Obx(
                    () => c.remainingAmount != null
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.remainingAmount! < 0
                                  ? Colors.red[50]
                                  : c.remainingAmount! > 0.01
                                  ? Colors.orange[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: c.remainingAmount! < 0
                                    ? Colors.red[300]!
                                    : c.remainingAmount! > 0.01
                                    ? Colors.orange[300]!
                                    : Colors.green[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  c.remainingAmount! < 0
                                      ? 'Excess:'
                                      : c.remainingAmount! > 0.01
                                      ? 'Remaining:'
                                      : 'Complete!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: c.remainingAmount! < 0
                                        ? Colors.red[900]
                                        : c.remainingAmount! > 0.01
                                        ? Colors.orange[900]
                                        : Colors.green[900],
                                  ),
                                ),
                                Text(
                                  '₹${(c.remainingAmount ?? 0).abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: c.remainingAmount! < 0
                                        ? Colors.red[900]
                                        : c.remainingAmount! > 0.01
                                        ? Colors.orange[900]
                                        : Colors.green[900],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox.shrink(),
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
              value: payment.paymentMethod,
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
                    paymentMethod: value,
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

  Widget _buildSaveButton(OrderDetailsController c) {
    final loc = AppLocalizations.of(Get.context!);
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (c.formKey.currentState?.validate() ?? false) {
              c.saveOrderDetails();
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
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontSize: 14, color: Colors.grey));

  String? _phoneVal(String? v, AppLocalizations loc) {
    if (v == null || v.isEmpty) return loc.required;
    if (v.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(v)) {
      return loc.enter_valid_10_digit_number;
    }
    return null;
  }
}
