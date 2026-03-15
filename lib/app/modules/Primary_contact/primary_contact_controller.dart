import 'package:billkaro/app/services/Network/api_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrimaryContactController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();

  // Observable for dropdown selection
  final selectedTitle = 'CEO'.obs;

  // Title list for dropdown
  final List<String> titleList = ['CEO', 'Manager', 'Other'];

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    super.onClose();
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    // Check if name contains only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName should contain only letters';
    }
    return null;
  }

  String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    // Remove spaces and special characters for validation
    String cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanedValue.length < 10) {
      return 'Please enter a valid mobile number';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    // Email regex pattern
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  void submitContact() {
    if (formKey.currentState!.validate()) {
      final contactData = {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'name':
            '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
        'title': selectedTitle.value,
        'mobile': mobileController.text.trim(),
        'email': emailController.text.trim().toLowerCase(),
      };
      print(contactData);

      Get.back(result: contactData);
      showSuccess(description: 'Primary contact saved successfully');
    }
  }
}
