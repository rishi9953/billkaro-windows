import 'package:billkaro/app/modules/BusinessDetails/business_details_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';

class BusinessDetailsScreen extends StatelessWidget {
  BusinessDetailsScreen({super.key});

  final controller = Get.put(BusinessDetailsController());

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        title: Text(
          loc.business_details,
          style: TextStyle(color: AppColor.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(label: loc.business_name, controller: controller.businessNameController, hint: loc.tap_to_enter),
                  const SizedBox(height: 20),
                  _buildTextField(label: 'Phone Number', controller: controller.phoneController, required: true, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  _buildLogoSection(),
                  const SizedBox(height: 20),
                  _buildTextField(label: loc.outlet_address, controller: controller.outletAddressController, hint: loc.tap_to_enter),
                  const SizedBox(height: 20),
                  _buildTextField(label: loc.upi_id, controller: controller.upiIdController, hint: loc.tap_to_enter, helperText: 'This will be used to print QR on bills'),
                  const SizedBox(height: 20),
                  _buildTextField(label: loc.custom_footer_message_on_bills, controller: controller.footerMessageController, maxLines: 3),
                  const SizedBox(height: 20),
                  _buildTextField(label: loc.fssai_number, controller: controller.fssaiController, hint: loc.tap_to_enter),
                  const SizedBox(height: 20),
                  _buildDropdownField(label: loc.tax_slab, value: controller.selectedTaxSlab, items: controller.taxSlabOptions),
                  const SizedBox(height: 20),
                  _buildSeatingCapacityField(label: loc.seating_capacity, value: controller.selectedSeatingCapacity, options: controller.seatingCapacityOptions),
                  const SizedBox(height: 20),
                  _buildDropdownField(label: loc.business_type, value: controller.selectedBusinessType, items: controller.businessTypeOptions),
                  const SizedBox(height: 20),
                  _buildDropdownField(label: loc.business_category_question, value: controller.selectedBusinessCategory, items: controller.businessCategoryOptions),
                  const SizedBox(height: 20),
                  _buildTextField(label: loc.gstin_number, controller: controller.gstinController, hint: loc.tap_to_enter),
                  const SizedBox(height: 20),
                  _buildTextField(label: loc.business_address, controller: controller.businessAddressController, hint: loc.tap_to_enter, maxLines: 3),
                  const SizedBox(height: 20),
                  _buildTextField(label: loc.google_profile_link, controller: controller.googleProfileController, hint: loc.tap_to_enter),
                  const SizedBox(height: 20),
                  _buildTextField(label: loc.swiggy_link, controller: controller.swiggyLinkController, hint: loc.tap_to_enter),
                  const SizedBox(height: 20),
                  _buildTextField(label: loc.zomato_link, controller: controller.zomatoLinkController, hint: loc.tap_to_enter),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.deleteOutlet();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        loc.delete_outlet,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? prefix,
    String? helperText,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            if (required) const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            prefixStyle: const TextStyle(color: Colors.black, fontSize: 16),
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(helperText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField({required String label, required RxString value, required List<String> items}) {
    var loc = AppLocalizations.of(Get.context!)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.value,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item.capitalize!, style: TextStyle(color: item.contains('Tap to') || item == loc.none ? Colors.grey : Colors.black)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    value.value = newValue;
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatingCapacityField({
    required String label,
    required RxString value,
    required List<Map<String, String>> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.value,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: options.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['value'],
                    child: Text(opt['label']!, style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) value.value = newValue;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    var loc = AppLocalizations.of(Get.context!)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.logo, style: TextStyle(fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        Obx(
          () => GestureDetector(
            onTap: controller.pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: controller.businessLogo.value != null
                    ? Image.file(controller.businessLogo.value!, fit: BoxFit.cover)
                    : controller.appPref.selectedOutlet!.logo!.isNotEmpty
                    ? Image.network(controller.appPref.selectedOutlet!.logo!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(loc.upload_business_logo, style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    var loc = AppLocalizations.of(Get.context!)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, -3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  loc.cancel,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: controller.updateBusinessDetails,
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text(
                  loc.update_details,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
