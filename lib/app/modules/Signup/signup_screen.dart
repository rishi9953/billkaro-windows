import 'dart:io';

import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:billkaro/app/modules/Signup/singup_controller.dart';
import 'package:billkaro/config/app_colors.dart';
import 'package:billkaro/l10n/app_localizations.dart';
import 'package:billkaro/app/routes/app_routes.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  void _goToLogin() {
    Get.toNamed(AppRoute.login);
  }

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
    var loc = AppLocalizations.of(context)!;
    if (!Get.isRegistered<SignupController>()) {
      Get.put(SignupController(), permanent: true);
    }

    final showWindowsTitleBar = !kIsWeb && Platform.isWindows;
    final appBar = AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColor.backGroundColor,
      iconTheme: const IconThemeData(color: AppColor.black87),
      title: Text(
        loc.business_registration,
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
            constraints: const BoxConstraints(maxWidth: 520),
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
                                  loc.register_new_business,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loc.business_registration,
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

                      _buildTextField(
                        context: context,
                        label: loc.business_name,
                        controller: controller.businessNameController,
                        validator: controller.validateBusinessName,
                        hint: loc.enter_business_name,
                        maxLength: 100,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        context: context,
                        label: loc.brand_name,
                        controller: controller.brandNameController,
                        validator: controller.validateBrandName,
                        hint: loc.enter_brand_name,
                        maxLength: 100,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        context: context,
                        label: loc.email,
                        controller: controller.emailController,
                        validator: controller.validateEmail,
                        hint: loc.enter_email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColor.primary.withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: AppColor.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                loc.activation_details_sent,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColor.primary.withOpacity(0.95),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Obx(
                        () => _buildTextField(
                          context: context,
                          label: loc.password,
                          hint: loc.enter_password,
                          controller: controller.passwordController,
                          validator: controller.validatePassword,
                          obscureText: !controller.isPasswordVisible.value,
                          maxLength: 50,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          ],
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: AppColor.primary,
                            ),
                            tooltip: controller.isPasswordVisible.value
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: () {
                              controller.isPasswordVisible.value =
                                  !controller.isPasswordVisible.value;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Obx(
                        () => _buildListTile(
                          context: context,
                          label: loc.business_type,
                          subtitle:
                              controller.selectedBusinessType.value.capitalize!,
                          onTap: controller.showBusinessTypeDialog,
                          icon: Icons.business_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Obx(
                        () => _buildListTile(
                          context: context,
                          label: loc.business_address,
                          subtitle: controller.businessAddress.value != null
                              ? _formatAddress(
                                  controller.businessAddress.value!,
                                )
                              : loc.enter_business_address,
                          onTap: controller.selectAddress,
                          icon: Icons.location_on_rounded,
                          isCompleted: controller.businessAddress.value != null,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Obx(
                        () => _buildListTile(
                          context: context,
                          label: loc.primary_contact,
                          subtitle: controller.primaryContact.value != null
                              ? _formatContact(controller.primaryContact.value!)
                              : loc.specify_primary_contact,
                          onTap: controller.selectPrimaryContact,
                          icon: Icons.phone_rounded,
                          isCompleted: controller.primaryContact.value != null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: controller.submitRegistration,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColor.primary,
                            foregroundColor: AppColor.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            loc.submit,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: _goToLogin,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColor.primary,
                          ),
                          child: Text(
                            loc.already_registered,
                            style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    String? hint,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      obscureText: obscureText,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
        label: _requiredLabel(context, label),
        counterText: '', // Hide character counter
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required IconData icon,
    bool isCompleted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColor.lightgreen.withOpacity(0.12)
                    : AppColor.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isCompleted ? AppColor.lightgreen : AppColor.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: isCompleted ? AppColor.lightgreen : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    return '${address['address']}, ${address['city']}, ${address['state']}';
  }

  String _formatContact(Map<String, dynamic> contact) {
    final name =
        contact['name'] ?? '${contact['firstName']} ${contact['lastName']}';
    final mobile = contact['mobile'] ?? contact['phone'];
    return '$name - $mobile';
  }
}
