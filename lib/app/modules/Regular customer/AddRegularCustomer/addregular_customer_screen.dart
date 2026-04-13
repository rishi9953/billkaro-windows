import 'package:billkaro/app/modules/Regular%20customer/AddRegularCustomer/addregular_customer_controller.dart';
import 'package:billkaro/config/config.dart';

class AddRegularCustomerScreen extends StatelessWidget {
  final controller = Get.put(AddCustomerController());

  AddRegularCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: !isDesktop,
        title: const Text(
          'Add Regular Customer',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                              Obx(() {
                                if (!controller.showBanner.value) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        controller.showContactPicker();
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColor.primary,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.contact_phone,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 10),
                                            const Expanded(
                                              child: Text(
                                                'Fetch customer details directly from your contacts.',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: controller.closeBanner,
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                );
                              }),
                              _buildLabel(
                                context,
                                label: 'Phone Number',
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
                              _buildLabel(context, label: 'Name'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller.nameController,
                                decoration: _inputDecoration(
                                  context,
                                  hintText: 'Enter customer name',
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildLabel(context, label: 'Loyalty Discount'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller.discountController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  context,
                                  hintText: 'Enter discount',
                                  suffixText: '%',
                                ),
                              ),
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
                                      'Discount will be applied on orders of this customer.',
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
                                SizedBox(
                                  width: compact ? double.infinity : 220,
                                  child: ElevatedButton(
                                    onPressed: controller.updateRegularCustomer,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 46),
                                      elevation: 0,
                                    ),
                                    child: const Text('Update Details'),
                                  ),
                                ),
                              ]
                            : [
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
                                    child: const Text('Save & New'),
                                  ),
                                ),
                                SizedBox(
                                  width: compact ? double.infinity : 220,
                                  child: ElevatedButton(
                                    onPressed: controller.addRegularCustomer,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 46),
                                      elevation: 0,
                                    ),
                                    child: const Text('Save Customer'),
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
    String? prefixText,
    TextStyle? prefixStyle,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixText: suffixText,
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
