import 'dart:io';

import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:billkaro/app/modules/Address/address_controller.dart';
import 'package:billkaro/config/app_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class AddAddressScreen extends GetView<AddAddressController> {
  const AddAddressScreen({super.key});

  Widget _requiredLabel(BuildContext context, String label) {
    final errorColor = Theme.of(context).colorScheme.error;
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.labelLarge,
        children: [
          TextSpan(text: label),
          const TextSpan(text: ' '),
          TextSpan(
            text: '*',
            style: TextStyle(color: errorColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize controller if not already done
    if (!Get.isRegistered<AddAddressController>()) {
      Get.put(AddAddressController(), permanent: true);
    }

    final showWindowsTitleBar = !kIsWeb && Platform.isWindows;
    final appBar = AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColor.backGroundColor,
      iconTheme: const IconThemeData(color: AppColor.black87),
      title: Text(
        'Add Address',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColor.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final scrollContent = Center(
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColor.primary.withOpacity(0.15),
                              ),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: AppColor.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Address',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enter your address details and save.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Divider(color: Colors.grey.shade200, height: 1),
                      const SizedBox(height: 18),

                      // Locate on Map Button
                      InkWell(
                        onTap: controller.openMap,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/lottie/LocationPin.json',
                                width: 26,
                                height: 26,
                                fit: BoxFit.cover,
                                repeat: false,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Locate on Map',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AppColor.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Form Fields
                      _buildTextField(
                        context: context,
                        label: 'Address Line',
                        hint: 'House/Flat No., Street Name',
                        controller: controller.addressController,
                        maxLines: 3,
                        validator: (value) =>
                            controller.validateRequired(value, 'Address'),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context: context,
                              label: 'City',
                              hint: 'Enter city',
                              controller: controller.cityController,
                              validator: (value) =>
                                  controller.validateRequired(value, 'City'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              context: context,
                              label: 'State',
                              hint: 'Enter state',
                              controller: controller.stateController,
                              validator: (value) =>
                                  controller.validateRequired(value, 'State'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context: context,
                              label: 'Zipcode',
                              hint: 'Enter zipcode',
                              controller: controller.zipcodeController,
                              keyboardType: TextInputType.number,
                              validator: controller.validateZipcode,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              context: context,
                              label: 'Country',
                              hint: 'Enter country',
                              controller: controller.countryController,
                              validator: (value) =>
                                  controller.validateRequired(value, 'Country'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: controller.saveAddress,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColor.primary,
                            foregroundColor: AppColor.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            // Keep existing UX wording for this screen.
                            'Save Address',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!showWindowsTitleBar) {
      return Scaffold(
        backgroundColor: AppColor.backGroundColor,
        appBar: appBar,
        body: SafeArea(child: scrollContent),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WindowsDesktopTitleBar(actions: []),
          appBar,
          Expanded(child: SafeArea(top: false, child: scrollContent)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            label: _requiredLabel(context, label),
            counterText: '',
          ),
        ),
      ],
    );
  }
}
