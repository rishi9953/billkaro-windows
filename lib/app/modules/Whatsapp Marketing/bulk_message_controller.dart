import 'package:billkaro/app/services/Network/api_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BulkWhatsappController extends GetxController {
  // Observable variables
  final messageController = TextEditingController();
  final numberController = TextEditingController();
  final numbers = <String>[].obs;
  final isLoading = false.obs;

  // Replace with your actual server URL
  static const String baseUrl =
      'https://07258545fd8a.ngrok-free.app'; // For Android emulator
  // For real device use: 'http://YOUR_COMPUTER_IP:3000'

  // Add number to list
  void addNumber() {
    String number = numberController.text.trim();
    if (number.isNotEmpty) {
      numbers.add(number);
      numberController.clear();
    } else {
      showError(description: 'Please enter a phone number');
    }
  }

  // Remove number from list
  void removeNumber(int index) {
    numbers.removeAt(index);
  }

  // Clear all numbers
  void clearAllNumbers() {
    numbers.clear();
  }

  // Send bulk WhatsApp messages
  Future<void> sendMessages() async {
    if (numbers.isEmpty) {
      showError(description: 'Please add at least one phone number');
      return;
    }

    if (messageController.text.trim().isEmpty) {
      showError(description: 'Please enter a message');
      return;
    }

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-bulk-whatsapp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'numbers': numbers.toList(),
          'message': messageController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          showSuccess(
            description:
                'Messages sent successfully to ${numbers.length} numbers!',
          );

          // Clear data after successful send
          numbers.clear();
          messageController.clear();
        }
      } else {
        throw Exception('Failed to send messages: ${response.body}');
      }
    } catch (e) {
      showError(description: 'Failed to send messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    numberController.dispose();
    super.onClose();
  }
}
