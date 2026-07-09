import 'package:billkaro/app/modules/Whatsapp%20Marketing/twilioapi_service.dart';
import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/config/config.dart';

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

  Future<List<String>> _loadRecipientPhones() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return [];

    try {
      final response = await callApi<CustomerResponse>(
        apiClient.getRegularCustomer(outletId),
        showLoader: false,
      );

      if (response?.status != 'success') return [];

      return response!.data
          .map((c) => c.phoneNumber.trim())
          .where((phone) => phone.isNotEmpty)
          .map(TwilioWhatsAppService.formatPhoneNumber)
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadRecipientCount() async {
    final phones = await _loadRecipientPhones();
    recipientCount.value = phones.length;
  }

  Future<void> sendBulkWhatsAppMessages(String templateType) async {
    final loc = AppLocalizations.of(Get.context!)!;

    if (restaurantNameController.text.trim().isEmpty) {
      showError(description: loc.please_enter_restaurant_name);
      return;
    }

    if (templateType == 'discount' &&
        discountValueController.text.trim().isEmpty) {
      showError(description: loc.please_enter_discount_value);
      return;
    }

    if (templateType == 'festival' &&
        festivalNameController.text.trim().isEmpty) {
      showError(description: loc.please_enter_festival_name);
      return;
    }

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.outlet_or_user_info_missing);
      return;
    }

    if (TwilioWhatsAppService.accountSid.isEmpty ||
        TwilioWhatsAppService.authToken.isEmpty ||
        TwilioWhatsAppService.fromWhatsAppNumber.isEmpty) {
      showError(
        description:
            'Twilio WhatsApp is not configured. Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_WHATSAPP_NUMBER to your production sender in .env',
      );
      return;
    }

    final phones = await _loadRecipientPhones();
    final count = phones.length;
    if (count == 0) {
      showError(description: loc.no_customers_with_phone);
      return;
    }

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text(loc.confirm_bulk_message),
        content: Text(loc.send_whatsapp_confirm(count)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text(loc.send),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    isSending.value = true;
    sendingProgress.value = 0;
    totalMessages.value = count;
    recipientCount.value = count;

    try {
      final message = generateMessage(templateType);

      Get.dialog(
        PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(loc.sending_messages),
            content: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    loc.sending_to_customers(sendingProgress.value.toString()),
                  ),
                  const SizedBox(height: 8),
                  Text(loc.please_wait_sending),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final result = await TwilioWhatsAppService.sendBulkMessages(
        phoneNumbers: phones,
        message: message,
        onProgress: (current, total) {
          sendingProgress.value = current;
          totalMessages.value = total;
        },
      );

      if (Get.isDialogOpen == true) Get.back();

      final successCount = result['successCount'] as int? ?? 0;
      final failureCount = result['failureCount'] as int? ?? 0;
      final total = result['total'] as int? ?? count;

      if (result['success'] == true) {
        showSuccess(
          description: loc.successfully_sent_messages(successCount),
        );
      } else if (successCount > 0) {
        showError(
          description: loc.sent_failed_summary(successCount, failureCount),
        );
      } else {
        showError(description: loc.failed_to_send_messages(
          result['errors']?.toString() ?? loc.unknown_error,
        ));
      }

      showResultsDialog({
        'success': result['success'] == true,
        'total': total,
        'successCount': successCount,
        'failureCount': failureCount,
        'results': result['results'] ?? [],
      });
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      showError(description: loc.failed_to_send_messages(e.toString()));
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
    final loc = AppLocalizations.of(Get.context!)!;
    final restaurantName = restaurantNameController.text.trim();

    if (templateType == 'discount') {
      final discount = discountValueController.text.trim();
      return loc.whatsapp_msg_discount(discount, restaurantName);
    }

    if (templateType == 'menu') {
      return loc.whatsapp_msg_menu(restaurantName);
    }

    if (templateType == 'festival') {
      final festival = festivalNameController.text.trim();
      return loc.whatsapp_msg_festival(restaurantName, festival);
    }

    return loc.whatsapp_msg_default(restaurantName);
  }

  void showResultsDialog(Map<String, dynamic> result) {
    final loc = AppLocalizations.of(Get.context!)!;
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
              Text(
                loc.sending_results,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(loc.total, total.toString(), Colors.blue),
                  _buildStatCard(
                    loc.success_label,
                    successCount.toString(),
                    Colors.green,
                  ),
                  _buildStatCard(
                    loc.failed_label,
                    failureCount.toString(),
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(loc.no_results_available),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index] as Map<String, dynamic>;
                      final isSuccess = item['success'] == true;
                      final errorText =
                          item['error']?.toString() ?? loc.unknown_error;
                      return ListTile(
                        leading: Icon(
                          isSuccess ? Icons.check_circle : Icons.error,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                        title: Text(item['to']?.toString() ?? loc.unknown),
                        subtitle: Text(
                          isSuccess
                              ? loc.sent_successfully
                              : loc.message_failed_error(errorText),
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
                  child: Text(loc.close),
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
    final loc = AppLocalizations.of(Get.context!)!;
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
                    loc.enter_custom_fields,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recipientCount.value > 0)
                    Text(
                      loc.customers_will_receive(recipientCount.value),
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: restaurantNameController,
                    decoration: InputDecoration(
                      labelText: loc.restaurant_name_label,
                    ),
                  ),
                  if (templateType == 'discount') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: discountValueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: loc.discount_value_percent_label,
                      ),
                    ),
                  ],
                  if (templateType == 'festival') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: festivalNameController,
                      decoration: InputDecoration(
                        labelText: loc.festival_name_label,
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
                            : Text(loc.send_bulk_message),
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
