import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class QuickAddItemBottomSheet extends StatelessWidget {
  QuickAddItemBottomSheet({super.key});

  final AddOrderController controller = Get.find<AddOrderController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Add Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a new item to your menu',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: Get.back,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Form(
              key: controller.quickAddFormKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ITEM NAME
                  _label('Item Name', required: true),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.itemNameController,
                    validator: controller.validateQuickAddItemName,
                    decoration: _inputDecoration('Tea'),
                  ),
                  const SizedBox(height: 20),

                  /// SALE PRICE
                  _label('Sale Price', required: true),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.salePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: controller.validateQuickAddSalePrice,
                    decoration: _inputDecoration(
                      '15',
                    ).copyWith(prefixText: '₹ '),
                  ),
                  const SizedBox(height: 20),

                  /// TAX OPTIONS
                  // Obx(
                  //   () => Row(
                  //     children: [
                  //       _buildTaxButton(
                  //         'Without Tax',
                  //         controller.selectedTaxOption.value == 'Without Tax',
                  //       ),
                  //       const SizedBox(width: 12),
                  //       _buildTaxButton(
                  //         'With Tax',
                  //         controller.selectedTaxOption.value == 'With Tax',
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 16),

                  /// GST OPTIONS
                  // Obx(
                  //   () => Wrap(
                  //     spacing: 12,
                  //     runSpacing: 12,
                  //     children: [
                  //       _buildGSTButton('None', 0.0),
                  //       _buildGSTButton('GST @ 5%', 5.0),
                  //       _buildGSTButton('GST @ 12%', 12.0),
                  //       _buildGSTButton('GST @ 18%', 18.0),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 24),

                  /// CATEGORY
                  _label('Category'),
                  const SizedBox(height: 8),
                  Obx(() {
                    final categoryItems = <DropdownItem<String>>[
                      const DropdownItem<String>(
                        value: 'none',
                        child: Text('None'),
                      ),
                      ...controller.categories.map(
                        (category) => DropdownItem<String>(
                          value: category.categoryName.toLowerCase(),
                          child: Text(
                            category.categoryName.capitalize ??
                                category.categoryName,
                          ),
                        ),
                      ),
                    ];

                    final selectedValue = controller.quickAddCategory.value
                        .toLowerCase();
                    final validValue =
                        categoryItems.any((item) => item.value == selectedValue)
                        ? selectedValue
                        : 'none';

                    return AppDropdownFormField2<String>(
                      isExpanded: true,
                      decoration: _inputDecoration('Select category'),
                      value: validValue,
                      items: categoryItems,
                      onChanged: (value) {
                        if (value != null) {
                          controller.quickAddCategory.value = value;
                        }
                      },
                      iconStyleData: IconStyleData(
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColor.primary,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  /// ADD ITEM BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.submitItem,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// LABEL
  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  /// INPUT DECORATION
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColor.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColor.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  /// TAX BUTTON
  Widget _buildTaxButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.selectTaxOption(label),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColor.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColor.primary : Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// GST BUTTON
  Widget _buildGSTButton(String label, double value) {
    final isSelected = controller.selectedGSTRate.value == label;
    return GestureDetector(
      onTap: () => controller.selectGSTRate(label, value),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColor.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColor.primary : Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
