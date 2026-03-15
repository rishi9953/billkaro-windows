import 'package:billkaro/app/modules/Regular%20customer/AddRegularCustomer/Widget/contact_sheet.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerList/cutomer_list_controller.dart';
import 'package:billkaro/app/services/Modals/customer/customerRequest.dart';
import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

// Controller
class AddCustomerController extends BaseController {
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final discountController = TextEditingController();

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
      showError(description: 'Failed to fetch contacts: $e');
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
        showError(
          description: 'Contact permission is needed to fetch contacts',
        );
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
    Get.dialog(
      AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          'Contact permission is permanently denied. Please enable it from settings.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: Text('Open Settings'),
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

  void addRegularCustomer() async {
    // Add regular customer logic
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: 'Please select an outlet first');
      return;
    }

    final phone = fullPhoneNumber;
    if (phone.length < 13) {
      showError(description: 'Please enter a valid 10 digit phone number');
      return;
    }
    final customerRequest = CustomerRequest(
      userId: appPref.user!.id!,
      outletId: outletId,
      phoneNumber: phone,
      customerName: nameController.text.trim(),
      loyalityDiscount: int.parse(discountController.text.trim()),
    );
    final response = await callApi(
      apiClient.addRegularCustomer(outletId, customerRequest),
    );
    if (response['status'] == 'success') {
      cutomerListController.getCustomerList();
      dismissAllAppLoader();
      Get.back();
      showSuccess(description: response['message']);

      clearAllFields();
    }
  }

  void updateRegularCustomer() async {
    // Update regular customer logic
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: 'Please select an outlet first');
      return;
    }

    final phone = fullPhoneNumber;
    if (phone.length < 13) {
      showError(description: 'Please enter a valid 10 digit phone number');
      return;
    }
    final customerRequest = CustomerRequest(
      userId: appPref.user!.id!,
      outletId: outletId,
      phoneNumber: phone,
      customerName: nameController.text.trim(),
      loyalityDiscount: int.parse(discountController.text.trim()),
    );
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
    // Delete regular customer logic
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: 'Please select an outlet first');
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
  }

  void toggleEdit() {
    final args = Get.arguments;
    if (args != null && args['isEdit'] == true) {
      isEdit.value = true;
      var customer = args['customerData'] as CustomerData;
      // Store only 10 digits (strip +91 if present)
      final digits = customer.phoneNumber.replaceAll(RegExp(r'\D'), '');
      phoneController.text = digits.length >= 10
          ? digits.substring(digits.length - 10)
          : digits;
      nameController.text = customer.customerName;
      discountController.text = customer.loyalityDiscount.toString();
      customerId.value = customer.id;
    } else {
      phoneController.text = '';
      isEdit.value = false;
    }
  }

  void saveCustomer() {
    if (phoneController.text.trim().length != 10) {
      showError(description: 'Please enter a valid 10 digit phone number');
      return;
    }

    // Save customer logic
    showSuccess(description: 'Customer saved successfully');
  }

  void saveAndNew() {
    if (phoneController.text.trim().length != 10) {
      showError(description: 'Please enter a valid 10 digit phone number');
      return;
    }

    // Save and create new customer logic
    showSuccess(description: 'Customer saved successfully');
    phoneController.text = '';
    nameController.clear();
    discountController.clear();
  }

  @override
  void onClose() {
    phoneController.dispose();
    nameController.dispose();
    discountController.dispose();
    super.onClose();
  }
}
