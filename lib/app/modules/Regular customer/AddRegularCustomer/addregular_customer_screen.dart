import 'package:billkaro/app/modules/Regular%20customer/AddRegularCustomer/addregular_customer_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';

class AddRegularCustomerScreen extends StatelessWidget {
  final controller = Get.put(AddCustomerController());

  AddRegularCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: !isDesktop,
        title: Obx(
          () => Text(
            controller.isEdit.isTrue
                ? loc.edit_regular_customer
                : loc.add_regular_customer,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 700;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 24,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(compact ? 16 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(
                                context,
                                label: loc.phone_number_field,
                                isRequired: true,
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller.phoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                decoration: _inputDecoration(
                                  context,
                                  prefixText: '+91 ',
                                  prefixStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildLabel(context, label: loc.name_label),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller.nameController,
                                decoration: _inputDecoration(
                                  context,
                                  hintText: loc.enter_customer_name,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildLabel(
                                context,
                                label: loc.loyalty_discount_label,
                              ),
                              const SizedBox(height: 8),
                              Obx(() {
                                final isPercent =
                                    controller.discountType.value ==
                                    'percentage';
                                return TextField(
                                  controller: controller.discountController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    context,
                                    hintText: loc.enter_discount,
                                    prefixIcon: Icon(
                                      isPercent
                                          ? Icons.percent
                                          : Icons.currency_rupee,
                                      size: 20,
                                    ),
                                    suffixIcon: TextButton(
                                      onPressed: () =>
                                          controller.discountType.value =
                                              isPercent
                                              ? 'amount'
                                              : 'percentage',
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor:
                                            theme.colorScheme.primary,
                                      ),
                                      child: Text(
                                        isPercent ? loc.percentage : loc.amount,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      loc.discount_applied_on_orders,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Obx(
                () => Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 10,
                        children: controller.isEdit.isTrue
                            ? [
                                if (StaffAccess.canDeleteCustomers)
                                  SizedBox(
                                  width: compact ? double.infinity : 180,
                                  child: OutlinedButton(
                                    onPressed: controller.deleteRegularCustomer,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 46),
                                      side: BorderSide(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ),
                                if (StaffAccess.canUpdateCustomers)
                                  SizedBox(
                                  width: compact ? double.infinity : 220,
                                  child: ElevatedButton(
                                    onPressed: controller.updateRegularCustomer,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 46),
                                      elevation: 0,
                                    ),
                                    child: Text(loc.update_details),
                                  ),
                                ),
                              ]
                            : [
                                if (StaffAccess.canCreateCustomers)
                                  SizedBox(
                                  width: compact ? double.infinity : 180,
                                  child: OutlinedButton(
                                    onPressed: controller.saveAndNew,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 46),
                                      side: BorderSide(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    child: Text(loc.save_and_new),
                                  ),
                                ),
                                if (StaffAccess.canCreateCustomers)
                                  SizedBox(
                                  width: compact ? double.infinity : 220,
                                  child: ElevatedButton(
                                    onPressed: controller.addRegularCustomer,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 46),
                                      elevation: 0,
                                    ),
                                    child: Text(loc.save_customer),
                                  ),
                                ),
                              ],
                      ),
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

  Widget _buildLabel(
    BuildContext context, {
    required String label,
    bool isRequired = false,
  }) {
    final color = Theme.of(context).textTheme.bodyMedium?.color;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color?.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: Colors.red, fontSize: 14)),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    String? hintText,
    String? suffixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? prefixText,
    TextStyle? prefixStyle,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixText: suffixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefixText: prefixText,
      prefixStyle: prefixStyle,
      counterText: '',
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF5B8DEE), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
