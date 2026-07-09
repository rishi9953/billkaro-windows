import 'dart:io';

import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:billkaro/app/modules/Outlets/outlet_controller.dart';
import 'package:billkaro/config/app_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateOutletScreen extends GetView<CreateOutletController> {
  const CreateOutletScreen({super.key});

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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CreateOutletController>()) {
      Get.put(CreateOutletController());
    }

    final showWindowsTitleBar = !kIsWeb && Platform.isWindows;
    final appBar = AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColor.backGroundColor,
      iconTheme: const IconThemeData(color: AppColor.black87),
      title: Text(
        'Create New Outlet',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColor.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final formContent = Center(
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
                              Icons.storefront_rounded,
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
                                  'Create New Outlet',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add another outlet to manage from the same account.',
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
                      _requiredLabel(context, 'Outlet Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: _inputDecoration('Enter the outlet name'),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter outlet name';
                          }
                          return null;
                        },
                        onChanged: (value) =>
                            controller.outletName.value = value,
                      ),
                      const SizedBox(height: 20),
                      _requiredLabel(context, 'Type'),
                      const SizedBox(height: 8),
                      Obx(
                        () => AppDropdownFormField2<String>(
                          value: controller.selectedType.value,
                          decoration: _inputDecoration('Select the type'),
                          items: controller.typeOptions.map((value) {
                            return DropdownItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          validator: controller.validateBusinessType,
                          onChanged: (newValue) {
                            if (newValue == null) return;
                            controller.selectedType.value = newValue;
                          },
                        ),
                      ),
                      Obx(() {
                        if (!controller.showSeatingCapacityField) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'Seating Capacity',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            AppDropdownFormField2<String>(
                              value: controller.selectedCapacity.value,
                              decoration: _inputDecoration(
                                'Select the capacity',
                              ),
                              items: controller.capacityOptions.map((opt) {
                                return DropdownItem<String>(
                                  value: opt['value'],
                                  child: Text(opt['label']!),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue == null) return;
                                controller.selectedCapacity.value = newValue;
                              },
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 20),
                      Text(
                        'How old is the outlet?',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => AppDropdownFormField2<String>(
                          value: controller.selectedAge.value,
                          decoration: _inputDecoration('Select the age'),
                          items: controller.ageOptions.map((value) {
                            return DropdownItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue == null) return;
                            controller.selectedAge.value = newValue;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Outlet Address',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: _inputDecoration(
                          'Enter the outlet address',
                        ),
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        onChanged: (value) =>
                            controller.outletAddress.value = value,
                      ),
                      const SizedBox(height: 28),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.isCreating.value
                                ? null
                                : controller.createOutlet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              disabledBackgroundColor: AppColor.primary
                                  .withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: controller.isCreating.value
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Create Outlet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (showWindowsTitleBar) {
      return Scaffold(
        backgroundColor: AppColor.backGroundColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const WindowsDesktopTitleBar(actions: []),
            appBar,
            Expanded(child: SafeArea(top: false, child: formContent)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: appBar,
      body: formContent,
    );
  }
}
