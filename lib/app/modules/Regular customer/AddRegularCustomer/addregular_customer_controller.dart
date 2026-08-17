import 'package:billkaro/app/modules/Regular%20customer/AddRegularCustomer/Widget/contact_sheet.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerList/cutomer_list_controller.dart';
import 'package:billkaro/app/services/Modals/customer/customerRequest.dart';
import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

// Controller
class AddCustomerController extends BaseController {
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final discountController = TextEditingController();
  final discountType = 'percentage'.obs;

  final showBanner = true.obs;
  final contacts = <Contact>[].obs;
  final filteredContacts = <Contact>[].obs;
  final isLoadingContacts = false.obs;
  final searchQuery = ''.obs;
  var customerId = ''.obs;
  final isEdit = false.obs;
  final cutomerListController = Get.find<CutomerListController>();

  @override
  void onInit() {
    super.onInit();
    toggleEdit();
  }

  void closeBanner() {
    showBanner.value = false;
  }

  void searchContacts(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      filteredContacts.clear();
      return;
    }

    final lowerQuery = query.toLowerCase();
    filteredContacts.value = contacts.where((contact) {
      final nameLower = contact.displayName.toLowerCase();
      final phoneMatch = contact.phones.any(
        (phone) => phone.number.contains(query),
      );

      return nameLower.contains(lowerQuery) || phoneMatch;
    }).toList();
  }

  Future<void> fetchContacts() async {
    try {
      isLoadingContacts.value = true;

      // Fetch contacts with phone numbers
      final fetchedContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Filter contacts that have at least one phone number
      contacts.value = fetchedContacts
          .where((contact) => contact.phones.isNotEmpty)
          .toList();

      // Reset search
      searchQuery.value = '';
      filteredContacts.clear();
    } catch (e) {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.failed_to_fetch_contacts(e.toString()));
    } finally {
      isLoadingContacts.value = false;
    }
  }

  Future<void> checkContactPermissions() async {
    final status = await Permission.contacts.status;

    if (status.isDenied) {
      final newStatus = await Permission.contacts.request();
      if (newStatus.isGranted) {
        await fetchContacts();
      } else if (newStatus.isPermanentlyDenied) {
        _showPermissionDialog();
      } else {
        final loc = AppLocalizations.of(Get.context!)!;
        showError(description: loc.contact_permission_needed);
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    } else if (status.isGranted) {
      if (contacts.isEmpty) {
        await fetchContacts();
      }
    }
  }

  void _showPermissionDialog() {
    final loc = AppLocalizations.of(Get.context!)!;
    Get.dialog(
      AlertDialog(
        title: Text(loc.permission_required),
        content: Text(loc.contact_permission_permanently_denied),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: Text(loc.open_settings),
          ),
        ],
      ),
    );
  }

  Future<void> showContactPicker() async {
    // Reset search when opening
    searchQuery.value = '';
    filteredContacts.clear();

    // Check permissions and fetch contacts if needed
    await checkContactPermissions();

    // Show bottom sheet only if permission is granted
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      Get.bottomSheet(
        ContactPickerSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      );
    }
  }

  /// Returns the full phone number with +91 prefix (10 digits only in controller).
  String get fullPhoneNumber =>
      '+91${phoneController.text.trim().replaceAll(RegExp(r'\D'), '')}';

  void selectContact(Contact? contact) {
    if (contact == null) {
      phoneController.text = '';
      nameController.clear();
    } else {
      // Set phone number (prefer the first phone number, store only 10 digits)
      if (contact.phones.isNotEmpty) {
        final digits = contact.phones.first.number.replaceAll(
          RegExp(r'\D'),
          '',
        );
        phoneController.text = digits.length >= 10
            ? digits.substring(digits.length - 10)
            : digits;
      }

      // Set name
      nameController.text = contact.displayName;
    }

    // Reset search
    searchQuery.value = '';
    filteredContacts.clear();

    Get.back();
  }

  CustomerRequest? _buildCustomerRequest(String outletId) {
    final loc = AppLocalizations.of(Get.context!)!;
    if (nameController.text.trim().isEmpty) {
      showError(description: loc.please_enter_customer_name);
      return null;
    }

    final phone = fullPhoneNumber;
    if (phone.length < 13) {
      showError(description: loc.please_enter_valid_10_digit_phone_alt);
      return null;
    }

    return CustomerRequest(
      userId: appPref.user!.id!,
      outletId: outletId,
      phoneNumber: phone,
      customerName: nameController.text.trim(),
      loyalityDiscount: double.tryParse(discountController.text.trim()) ?? 0,
      loyalityDiscountType: discountType.value,
    );
  }

  void addRegularCustomer() async {
    if (!StaffAccess.ensure(StaffAccess.canCreateCustomers)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return;
    }

    final customerRequest = _buildCustomerRequest(outletId);
    if (customerRequest == null) return;

    final response = await callApi(
      apiClient.addRegularCustomer(outletId, customerRequest),
    );
    if (response['status'] == 'success') {
      await _handleAddSuccess(response, customerRequest, shouldGoBack: true);
    }
  }

  Future<void> _handleAddSuccess(
    Map<String, dynamic> response,
    CustomerRequest customerRequest, {
    required bool shouldGoBack,
  }) async {
    cutomerListController.getCustomerList();
    dismissAllAppLoader();

    final serverSent = response['whatsappSent'] == true;
    await sendRegularCustomerWelcomeWhatsApp(
      phoneNumber: customerRequest.phoneNumber,
      customerName: customerRequest.customerName,
      loyaltyDiscount: customerRequest.loyalityDiscount,
      loyaltyDiscountType: customerRequest.loyalityDiscountType,
      outletName: appPref.selectedOutlet?.businessName ?? 'Our Restaurant',
      serverSent: serverSent,
    );

    if (shouldGoBack) {
      Get.back();
    }
    final loc = AppLocalizations.of(Get.context!)!;
    showSuccess(
      description: response['message']?.toString() ?? loc.customer_added,
    );
    clearAllFields();
  }

  void updateRegularCustomer() async {
    if (!StaffAccess.ensure(StaffAccess.canUpdateCustomers)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return;
    }

    final phone = fullPhoneNumber;
    if (phone.length < 13) {
      showError(description: loc.please_enter_valid_10_digit_phone_alt);
      return;
    }
    final customerRequest = _buildCustomerRequest(outletId);
    if (customerRequest == null) return;
    final response = await callApi(
      apiClient.updateRegularCustomer(
        outletId,
        customerId.value,
        customerRequest,
      ),
    );
    if (response['status'] == 'success') {
      cutomerListController.getCustomerList();
      dismissAllAppLoader();
      Get.back();
      Get.back();
      showSuccess(description: response['message']);
    }
  }

  void deleteRegularCustomer() async {
    if (!StaffAccess.ensure(StaffAccess.canDeleteCustomers)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return;
    }

    final response = await callApi(
      apiClient.deleteRegularCustomer(outletId, customerId.value),
    );
    if (response['status'] == 'success') {
      cutomerListController.getCustomerList();
      dismissAllAppLoader();
      Get.back();
      Get.back();
      showSuccess(description: response['message']);
    }
  }

  void clearAllFields() {
    phoneController.clear();
    nameController.clear();
    discountController.clear();
    discountType.value = 'percentage';
  }

  void toggleEdit() {
    final dynamic rawArgs = Get.arguments ?? Modular.args.data;
    final args = rawArgs is Map ? rawArgs : null;
    if (args != null && args['isEdit'] == true) {
      isEdit.value = true;
      final customer = args['customerData'] as CustomerData;
      // Store only 10 digits (strip +91 if present)
      final digits = customer.phoneNumber.replaceAll(RegExp(r'\D'), '');
      phoneController.text = digits.length >= 10
          ? digits.substring(digits.length - 10)
          : digits;
      nameController.text = customer.customerName;
      discountController.text = customer.loyalityDiscount.toString();
      discountType.value = customer.loyalityDiscountType;
      customerId.value = customer.id;
    } else {
      phoneController.text = '';
      isEdit.value = false;
    }
  }

  void saveCustomer() {
    addRegularCustomer();
  }

  Future<void> saveAndNew() async {
    if (!StaffAccess.ensure(StaffAccess.canCreateCustomers)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return;
    }

    final customerRequest = _buildCustomerRequest(outletId);
    if (customerRequest == null) return;

    final response = await callApi(
      apiClient.addRegularCustomer(outletId, customerRequest),
    );
    if (response['status'] == 'success') {
      await _handleAddSuccess(response, customerRequest, shouldGoBack: false);
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    nameController.dispose();
    discountController.dispose();
    super.onClose();
  }
}
