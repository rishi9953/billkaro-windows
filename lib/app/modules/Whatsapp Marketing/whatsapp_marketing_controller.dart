import 'package:billkaro/app/services/Modals/whatsapp/whatsapp_marketing_request.dart';
import 'package:billkaro/app/services/Modals/whatsapp/whatsapp_marketing_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:dio/dio.dart';

class WhatsappMarketingController extends BaseController
    with WidgetsBindingObserver {
  final restaurantNameController = TextEditingController(text: '');
  final discountValueController = TextEditingController(text: '10');
  final festivalNameController = TextEditingController(text: '');

  final isSending = false.obs;
  final sendingProgress = 0.obs;
  final totalMessages = 0.obs;
  final recipientCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    final outletName = Get.find<AppPref>().selectedOutlet?.businessName;
    if (outletName != null && outletName.trim().isNotEmpty) {
      restaurantNameController.text = outletName.trim();
    }
    _loadRecipientCount();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    restaurantNameController.dispose();
    discountValueController.dispose();
    festivalNameController.dispose();
    super.onClose();
  }

  @override
  void didChangeMetrics() {}

  Future<void> _loadRecipientCount() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    try {
      final response = await callApi(
        apiClient.getRegularCustomer(outletId),
        showLoader: false,
      );

      if (response?.status == 'success') {
        recipientCount.value = response!.data
            .map((c) => c.phoneNumber.trim())
            .where((phone) => phone.isNotEmpty)
            .toSet()
            .length;
      }
    } catch (_) {}
  }

  Future<void> sendBulkWhatsAppMessages(String templateType) async {
    if (restaurantNameController.text.trim().isEmpty) {
      showError(description: 'Please enter restaurant name');
      return;
    }

    if (templateType == 'discount' &&
        discountValueController.text.trim().isEmpty) {
      showError(description: 'Please enter discount value');
      return;
    }

    if (templateType == 'festival' &&
        festivalNameController.text.trim().isEmpty) {
      showError(description: 'Please enter festival name');
      return;
    }

    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.user?.id;
    if (outletId == null || userId == null) {
      showError(description: 'Outlet or user information is missing');
      return;
    }

    final count = recipientCount.value;
    if (count == 0) {
      showError(
        description:
            'No customers with phone numbers found. Add regular customers first.',
      );
      return;
    }

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Bulk Message'),
        content: Text(
          'Send WhatsApp messages to $count customers via the server?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    isSending.value = true;
    sendingProgress.value = 0;
    totalMessages.value = count;

    try {
      final message = generateMessage(templateType);

      Get.dialog(
        PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Sending Messages'),
            content: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Sending to ${totalMessages.value} customers...'),
                  const SizedBox(height: 8),
                  const Text('Please wait, this may take a minute.'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final dio = Get.find<Dio>();
      final previousReceiveTimeout = dio.options.receiveTimeout;
      final previousSendTimeout = dio.options.sendTimeout;
      final bulkTimeout = Duration(seconds: (count * 3).clamp(60, 600));

      dio.options.receiveTimeout = bulkTimeout;
      dio.options.sendTimeout = bulkTimeout;

      WhatsappMarketingResponse? response;
      try {
        response = await callApi(
          apiClient.sendBulkWhatsappMarketing(
            outletId,
            WhatsappMarketingRequest(
              userId: userId,
              templateType: templateType,
              message: message,
              restaurantName: restaurantNameController.text.trim(),
              discountValue: templateType == 'discount'
                  ? discountValueController.text.trim()
                  : null,
              festivalName: templateType == 'festival'
                  ? festivalNameController.text.trim()
                  : null,
            ),
          ),
          showLoader: false,
        );
      } finally {
        dio.options.receiveTimeout = previousReceiveTimeout;
        dio.options.sendTimeout = previousSendTimeout;
      }

      if (Get.isDialogOpen == true) Get.back();

      final result = response?.data;
      if (result == null) {
        showError(
          description:
              'Request timed out or failed. If you have many customers, wait and check campaign history in the database before resending.',
        );
        return;
      }

      if (result.success) {
        showSuccess(
          description: 'Successfully sent ${result.successCount} messages',
        );
      } else {
        showError(
          description:
              'Sent: ${result.successCount}, Failed: ${result.failureCount}',
        );
      }

      showResultsDialog({
        'success': result.success,
        'total': result.total,
        'successCount': result.successCount,
        'failureCount': result.failureCount,
        'results': result.results
            .map(
              (item) => {
                'success': item.success,
                'to': item.to,
                'error': item.error,
              },
            )
            .toList(),
      });
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      showError(description: 'Failed to send messages: $e');
    } finally {
      isSending.value = false;
    }
  }

  /// Backward-compatible entry used by existing UI hooks.
  Future<void> sendNgrokBulkMessage({
    required String title,
    required String description,
  }) async {
    await sendBulkWhatsAppMessages('custom');
  }

  String generateMessage(String templateType) {
    final restaurantName = restaurantNameController.text.trim();

    if (templateType == 'discount') {
      final discount = discountValueController.text.trim();
      return '''Hello! 🎉

Get $discount% OFF on your next order at $restaurantName!

This is a limited time offer. Use code: SAVE$discount

Order now and enjoy delicious food with amazing savings!

Thank you for being a valued customer! ❤️''';
    }

    if (templateType == 'menu') {
      return '''Hello! 🍽️

Exciting news from $restaurantName!

We've just launched our new menu with amazing dishes. Come try our latest specialties!

Visit us today and enjoy great food! 😊

Best regards,
$restaurantName Team''';
    }

    if (templateType == 'festival') {
      final festival = festivalNameController.text.trim();
      return '''Hello! 🎊

$restaurantName wishes you a very Happy $festival!

Visit us for our special festival menu and exclusive discounts.

Celebrate with great food! 🍽️

Warm wishes,
$restaurantName Team''';
    }

    return '''Hello from $restaurantName! 👋

We have an important update for you. Thank you for being a loyal customer!

Visit us soon! ❤️''';
  }

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
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No results available'),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index] as Map<String, dynamic>;
                      final isSuccess = item['success'] == true;
                      return ListTile(
                        leading: Icon(
                          isSuccess ? Icons.check_circle : Icons.error,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                        title: Text(item['to']?.toString() ?? 'Unknown'),
                        subtitle: Text(
                          isSuccess
                              ? 'Sent successfully'
                              : 'Failed: ${item['error'] ?? 'Unknown error'}',
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  void showCustomFieldsDialog(
    String templateType,
    String title,
    String description,
  ) {
    final theme = Get.theme;
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    Get.dialog(
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Custom Fields',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recipientCount.value > 0)
                    Text(
                      '${recipientCount.value} customers will receive this message',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: restaurantNameController,
                    decoration: const InputDecoration(
                      labelText: 'Restaurant Name',
                    ),
                  ),
                  if (templateType == 'discount') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: discountValueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discount value (%)',
                      ),
                    ),
                  ],
                  if (templateType == 'festival') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: festivalNameController,
                      decoration: const InputDecoration(
                        labelText: 'Festival Name',
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
                                sendBulkWhatsAppMessages(templateType);
                              },
                        child: isSending.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send Bulk Message'),
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
