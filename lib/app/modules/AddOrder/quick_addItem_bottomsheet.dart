import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/config/config.dart';

class QuickAddItemBottomSheet extends StatelessWidget {
  QuickAddItemBottomSheet({super.key});

  final AddOrderController controller = Get.find<AddOrderController>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                /// Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const Text(
                  'Quick Add Item',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),

                /// ITEM NAME
                _label("Item Name", required: true),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.itemNameController,
                  decoration: _inputDecoration("Tea"),
                ),
                const SizedBox(height: 20),

                /// SALE PRICE
                _label("Sale Price"),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.salePriceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("15").copyWith(prefixText: "₹ "),
                ),
                const SizedBox(height: 20),

                /// TAX OPTIONS
                Obx(
                  () => Row(
                    children: [
                      _buildTaxButton(
                        'Without Tax',
                        controller.selectedTaxOption.value == 'Without Tax',
                      ),
                      const SizedBox(width: 12),
                      _buildTaxButton(
                        'With Tax',
                        controller.selectedTaxOption.value == 'With Tax',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                /// GST OPTIONS
                Obx(
                  () => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildGSTButton('None', 0.0),
                      _buildGSTButton('GST @ 5%', 5.0),
                      _buildGSTButton('GST @ 12%', 12.0),
                      _buildGSTButton('GST @ 18%', 18.0),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
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
        borderSide: const BorderSide(color: AppColor.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColor.primary, width: 2),
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
