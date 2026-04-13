import 'dart:convert';
import 'package:billkaro/app/services/Network/api_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class WhatsappMarketingController extends GetxController
    with WidgetsBindingObserver {
  final restaurantNameController = TextEditingController(text: '');
  final discountValueController = TextEditingController(text: '10');

  // Observable variables for UI state
  final isSending = false.obs;
  final sendingProgress = 0.obs;
  final totalMessages = 0.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    restaurantNameController.dispose();
    discountValueController.dispose();
    super.onClose();
  }

  @override
  void didChangeMetrics() {
    // Handle metrics changes if needed
  }

  // List of phone numbers to send messages to
  List<String> getCustomerPhoneNumbers() {
    // Replace this with your actual customer list from database
    return [
      '+919350413656',
      '+919582222724',
      '+918587911863',
      "+919643166233",
      // Add more numbers
    ];
  }

  /// NEW FUNCTION: Send message via your ngrok API
  Future<void> sendNgrokBulkMessage({
    required String title,
    required String description,
  }) async {
    final url = Uri.parse(
      'https://294f69e62943.ngrok-free.app/send-bulk-whatsapp',
    );

    final body = {
      "numbers": [
        "+919350413656",
        "+919643166233",
        "+919582222724",
        "+918587911863",
      ],
      "message": "$title\n\n$description",
    };

    try {
      isSending.value = true;

      // Optional progress dialog
      Get.dialog(
        PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Sending WhatsApp Message'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Please wait...'),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // Close loader
      if (Get.isDialogOpen == true) Get.back();

      if (response.statusCode == 200) {
        showSuccess(description: 'Messages sent successfully via Ngrok API!');
      } else {
        debugPrint(response.body);
        showError(description: 'API Error: ${response.body}');
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      showError(description: 'Something went wrong: $e');
    } finally {
      isSending.value = false;
    }
  }

  // Generate message based on template type
  String generateMessage(String templateType) {
    final restaurantName = restaurantNameController.text.trim();

    if (templateType == 'discount') {
      final discount = discountValueController.text.trim();
      return '''Hello! 🎉

Get $discount% OFF on your next order at $restaurantName!

This is a limited time offer. Use code: SAVE$discount

Order now and enjoy delicious food with amazing savings!

Thank you for being a valued customer! ❤️''';
    } else if (templateType == 'new_menu') {
      return '''Hello! 🍽️

Exciting news from $restaurantName!

We've just launched our new menu with amazing dishes. Come try our latest specialties!

Visit us today and enjoy great food! 😊

Best regards,
$restaurantName Team''';
    } else {
      // General announcement
      return '''Hello from $restaurantName! 👋

We have an important update for you. Thank you for being a loyal customer!

Visit us soon! ❤️''';
    }
  }

  // Send bulk WhatsApp messages
  // Future<void> sendBulkWhatsAppMessages(String templateType) async {
  //   // Validation
  //   if (restaurantNameController.text.trim().isEmpty) {
  //     showError(description: 'Please enter restaurant name');
  //     return;
  //   }

  //   if (templateType == 'discount' &&
  //       discountValueController.text.trim().isEmpty) {
  //     showError(description: 'Please enter discount value');
  //     return;
  //   }

  //   // Get customer phone numbers
  //   final phoneNumbers = getCustomerPhoneNumbers();

  //   if (phoneNumbers.isEmpty) {
  //     showError(description: 'No customers found to send messages');
  //     return;
  //   }

  //   // Show confirmation dialog
  //   final confirm = await Get.dialog<bool>(
  //     AlertDialog(
  //       title: const Text('Confirm Bulk Message'),
  //       content: Text(
  //         'Do you want to send WhatsApp messages to ${phoneNumbers.length} customers?',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(result: false),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Get.back(result: true),
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
  //           child: const Text('Send'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirm != true) return;

  //   // Start sending
  //   isSending.value = true;
  //   sendingProgress.value = 0;
  //   totalMessages.value = phoneNumbers.length;

  //   try {
  //     // Generate message
  //     final message = generateMessage(templateType);

  //     // Format phone numbers
  //     final formattedNumbers = phoneNumbers
  //         .map((num) => TwilioWhatsAppService.formatPhoneNumber(num))
  //         .toList();

  //     // Show progress dialog
  //     Get.dialog(
  //       PopScope(
  //         canPop: false,
  //         child: AlertDialog(
  //           title: const Text('Sending Messages'),
  //           content: Obx(
  //             () => Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 CircularProgressIndicator(
  //                   value: totalMessages.value > 0
  //                       ? sendingProgress.value / totalMessages.value
  //                       : 0,
  //                 ),
  //                 const SizedBox(height: 16),
  //                 Text(
  //                   '${sendingProgress.value} / ${totalMessages.value}',
  //                   style: const TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 const Text('Please wait...'),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //       barrierDismissible: false,
  //     );

  //     // Send bulk messages
  //     final result = await TwilioWhatsAppService.sendBulkMessages(
  //       phoneNumbers: formattedNumbers,
  //       message: message,
  //       delayBetweenMessages: const Duration(seconds: 2),
  //       onProgress: (current, total) {
  //         sendingProgress.value = current;
  //       },
  //     );

  //     // Close progress dialog
  //     Get.back();

  //     // Show result
  //     if (result['success'] == true) {
  //       showSuccess(
  //         description: 'Successfully sent ${result['successCount']} messages',
  //       );
  //     } else {
  //       showError(
  //         description:
  //             'Sent: ${result['successCount']}, Failed: ${result['failureCount']}',
  //       );
  //     }

  //     // Show detailed results dialog
  //     showResultsDialog(result);
  //   } catch (e) {
  //     // Close progress dialog if it's still open
  //     if (Get.isDialogOpen == true) {
  //       Get.back();
  //     }
  //     showError(description: 'Failed to send messages: $e');
  //     debugPrint("Error sending messages: $e");
  //   } finally {
  //     isSending.value = false;
  //   }
  // }

  // Show results dialog
  void showResultsDialog(Map<String, dynamic> result) {
    final results = result['results'] as List<dynamic>? ?? [];
    final total = result['total'] ?? 0;
    final successCount = result['successCount'] ?? 0;
    final failureCount = result['failureCount'] ?? 0;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sending Results',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Total', total.toString(), Colors.blue),
                  _buildStatCard(
                    'Success',
                    successCount.toString(),
                    Colors.green,
                  ),
                  _buildStatCard('Failed', failureCount.toString(), Colors.red),
                ],
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Details:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No results available'),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),

                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index] as Map<String, dynamic>;
                      final isSuccess = item['success'] == true;
                      final phoneNumber = item['to']?.toString() ?? 'Unknown';
                      final errorMessage =
                          item['error']?.toString() ?? 'Unknown error';

                      return ListTile(
                        leading: Icon(
                          isSuccess ? Icons.check_circle : Icons.error,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                        title: Text(phoneNumber),
                        subtitle: Text(
                          isSuccess
                              ? 'Sent successfully'
                              : 'Failed: $errorMessage',
                          style: TextStyle(
                            color: isSuccess
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  void showCustomFieldsDialog(String templateType, String title, description) {
    final theme = Get.theme;
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    Get.dialog(
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            color: cs.surface,
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Enter Custom Fields',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                        tooltip: 'Close',
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Restaurant Name',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: restaurantNameController,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: cs.surfaceVariant.withOpacity(0.10),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: cs.outline.withOpacity(0.8),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: cs.outline.withOpacity(0.8),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.primary, width: 2),
                      ),
                    ),
                  ),

                  if (templateType == 'discount') ...[
                    const SizedBox(height: 14),
                    Text(
                      'Discount value',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: discountValueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: cs.surfaceVariant.withOpacity(0.10),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        suffixText: '%',
                        suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: cs.outline.withOpacity(0.8),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: cs.outline.withOpacity(0.8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSending.value
                            ? null
                            : () {
                                Get.back();
                                sendNgrokBulkMessage(
                                  title: title,
                                  description: description,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: isSending.value
                              ? cs.onSurfaceVariant.withOpacity(0.18)
                              : cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSending.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Send Bulk Message',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
    );
  }
}
