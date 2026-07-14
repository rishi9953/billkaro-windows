import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/modules/AddOrder/OrderDetails/order_details_controller.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/config/config.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final OrderDetailsController c;

  static const double _desktopBreakpoint = 980;

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
                    c.hasOutletTables.value;
                    if (Get.isRegistered<HomeScreenController>()) {
                      Get.find<HomeScreenController>().selectedOutlet.value;
                    }
                    if (!c.showTableField) {
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
                  // _buildField(
                  //   loc.service_charge,
                  //   c.serviceCharge,
                  //   TextInputType.number,
                  //   loc: loc,
                  //   prefixIcon: Icons.add_circle_outline,
                  //   bottomGap: 0,
                  // ),
                ],
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
                                children: [customerCard],
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
      helperMaxLines: 2,
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
            String? dropdownValue;
            if (selectedTable.isNotEmpty) {
              for (final t in tables) {
                if (t.displayName == selectedTable ||
                    t.tableNumber == selectedTable) {
                  dropdownValue = t.displayName;
                  break;
                }
              }
            }

            return AppDropdownFormField2<String>(
              value: dropdownValue,
              isExpanded: true,
              items: tables
                  .map(
                    (table) => DropdownItem<String>(
                      value: table.displayName,

                      child: Text(
                        table.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
            final isPercent = c.discountType.value == 'percentage';
            return TextFormField(
              controller: c.discount,
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? loc.required : null,
              decoration: _fieldDecoration(
                hintText: loc.enter_discount,
                prefixIcon: isPercent ? Icons.percent : Icons.currency_rupee,
                suffixIcon: TextButton(
                  onPressed: () => c.discountType.value = isPercent
                      ? 'amount'
                      : 'percentage',
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColor.primary,
                  ),
                  child: Text(
                    isPercent ? loc.percentage : loc.amount,
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
