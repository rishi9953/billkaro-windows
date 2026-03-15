import 'package:billkaro/app/modules/Signup/singup_controller.dart';
import 'package:billkaro/config/app_colors.dart';
import 'package:billkaro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(SignupController());
    var loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        automaticallyImplyLeading: true,
        foregroundColor: AppColor.white,
        title: Text(
          loc.business_registration,
          style: TextStyle(color: AppColor.white),
        ),
        elevation: 0,
      ),
      body: Form(
        key: controller.formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: loc.business_name,
                      controller: controller.businessNameController,
                      validator: controller.validateBusinessName,
                      hint: loc.enter_business_name,
                      maxLength: 100,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      label: loc.brand_name,
                      controller: controller.brandNameController,
                      validator: controller.validateBrandName,
                      hint: loc.enter_brand_name,
                      maxLength: 100,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      label: loc.email,
                      controller: controller.emailController,
                      validator: controller.validateEmail,
                      hint: loc.enter_email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        // color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColor.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColor.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.activation_details_sent,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColor.primary.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Obx(
                      () => _buildTextField(
                        label: loc.password,
                        hint: loc.enter_password,
                        controller: controller.passwordController,
                        validator: controller.validatePassword,
                        obscureText: !controller.isPasswordVisible.value,
                        maxLength: 50,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(
                            RegExp(r'\s'),
                          ), // No spaces
                        ],
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColor.primary,
                          ),
                          onPressed: () {
                            controller.isPasswordVisible.value =
                                !controller.isPasswordVisible.value;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Obx(
                      () => _buildListTile(
                        label: loc.business_type,
                        subtitle:
                            controller.selectedBusinessType.value.capitalize!,
                        onTap: controller.showBusinessTypeDialog,
                        icon: Icons.business,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Obx(
                      () => _buildListTile(
                        label: loc.business_address,
                        subtitle: controller.businessAddress.value != null
                            ? _formatAddress(controller.businessAddress.value!)
                            : loc.enter_business_address,
                        onTap: controller.selectAddress,
                        icon: Icons.location_on,
                        isCompleted: controller.businessAddress.value != null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Obx(
                      () => _buildListTile(
                        label: loc.primary_contact,
                        subtitle: controller.primaryContact.value != null
                            ? _formatContact(controller.primaryContact.value!)
                            : loc.specify_primary_contact,
                        onTap: controller.selectPrimaryContact,
                        icon: Icons.phone,
                        isCompleted: controller.primaryContact.value != null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: controller.submitRegistration,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColor.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 0,
                  ),
                  child: Text(
                    loc.submit,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: obscureText,
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
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
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            counterText: '', // Hide character counter
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required IconData icon,
    bool isCompleted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isCompleted ? Colors.green : AppColor.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
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
