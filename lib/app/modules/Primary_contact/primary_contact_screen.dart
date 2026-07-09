import 'dart:io';

import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/modules/Primary_contact/primary_contact_controller.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PrimaryContactScreen extends GetView<PrimaryContactController> {
  const PrimaryContactScreen({super.key});

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
    // Initialize controller
    if (!Get.isRegistered<PrimaryContactController>()) {
      Get.put(PrimaryContactController(), permanent: true);
    }

    final showWindowsTitleBar = !kIsWeb && Platform.isWindows;
    final appBar = AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColor.backGroundColor,
      iconTheme: const IconThemeData(color: AppColor.black87),
      title: Text(
        'Primary Contact',
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
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
                              Icons.person_rounded,
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
                                  'Primary Contact',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add key contact information for your business.',
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

                      // Name Fields
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context: context,
                              label: 'First Name',
                              hint: 'Enter first name',
                              controller: controller.firstNameController,
                              validator: (value) =>
                                  controller.validateName(value, 'First name'),
                              textCapitalization: TextCapitalization.words,
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              context: context,
                              label: 'Last Name',
                              hint: 'Enter last name',
                              controller: controller.lastNameController,
                              validator: (value) =>
                                  controller.validateName(value, 'Last name'),
                              textCapitalization: TextCapitalization.words,
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title Dropdown
                      _buildDropdownField(
                        context: context,
                        label: 'Title',
                        hint: 'Select title',
                        prefixIcon: Icons.work_outline_rounded,
                      ),
                      const SizedBox(height: 16),

                      _buildMobileField(context),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: controller.submitContact,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColor.primary,
                            foregroundColor: AppColor.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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

  Widget _buildMobileField(BuildContext context) {
    return Obx(() {
      final Widget? suffixIcon;
      final String? helperText;

      if (controller.isMobileChecking.value) {
        suffixIcon = Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColor.primary,
            ),
          ),
        );
        helperText = 'Checking mobile number availability...';
      } else if (controller.isMobileAvailable.value == true) {
        suffixIcon = const Icon(
          Icons.check_circle_rounded,
          color: AppColor.lightgreen,
        );
        helperText = 'Mobile number is available';
      } else if (controller.mobileVerificationError.value != null) {
        suffixIcon = Icon(
          Icons.info_outline_rounded,
          color: Colors.orange.shade700,
        );
        helperText = controller.mobileVerificationError.value;
      } else if (controller.isMobileAvailable.value == false) {
        suffixIcon = Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.error,
        );
        helperText =
            'This mobile number is already registered. Please use a different number.';
      } else {
        suffixIcon = null;
        helperText = null;
      }

      return TextFormField(
        controller: controller.mobileController,
        validator: controller.validateMobile,
        keyboardType: TextInputType.phone,
        onChanged: controller.onMobileChanged,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          hintText: 'Enter mobile number',
          label: _requiredLabel(context, 'Mobile Number'),
          suffixIcon: suffixIcon,
          helperText: helperText,
          helperMaxLines: 2,
          filled: true,
          prefixIcon: Icon(
            Icons.phone_outlined,
            color: Colors.grey.shade600,
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      );
    });
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    IconData? prefixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        label: _requiredLabel(context, label),
        filled: true,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey.shade600, size: 20)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _requiredLabel(context, label),
        const SizedBox(height: 8),
        Obx(
          () => AppDropdownFormField2<String>(
            value: controller.selectedTitle.value.isEmpty
                ? null
                : controller.selectedTitle.value,
            hint: Text(
              hint,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            decoration: InputDecoration(
              filled: true,
              prefixIcon: Icon(
                prefixIcon,
                color: Colors.grey.shade600,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            iconStyleData: appDropdownIconStyle(color: Colors.grey.shade600),
            dropdownStyleData: appDropdownMenuStyle(context: context),
            menuItemStyleData: const MenuItemStyleData(
              padding: EdgeInsets.symmetric(horizontal: 14),
            ),
            items: controller.titleList.map((String title) {
              return DropdownItem<String>(
                value: title,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.selectedTitle.value = newValue;
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Title is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
