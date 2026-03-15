import 'package:billkaro/config/config.dart';

class AddAddressController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipcodeController = TextEditingController();
  final countryController = TextEditingController();

  @override
  void onClose() {
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipcodeController.dispose();
    countryController.dispose();
    super.onClose();
  }

  void saveAddress() {
    if (formKey.currentState!.validate()) {
      final addressData = {
        'address': addressController.text,
        'city': cityController.text,
        'state': stateController.text,
        'zipcode': zipcodeController.text,
        'country': countryController.text,
      };

      // TODO: Save address logic (e.g., API call)
      print(addressData);

      Get.back(result: addressData);
      showSuccess(description: 'Address saved successfully');
    }
  }

  Future<void> openMap() async {
    final result = await Get.toNamed(AppRoute.map);
    if (result != null && result is Map) {
      // Populate fields from map result
      addressController.text = result['address'] ?? '';
      cityController.text = result['city'] ?? '';
      stateController.text = result['state'] ?? '';
      zipcodeController.text = result['zipcode'] ?? '';
      countryController.text = result['country'] ?? '';
    }
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateZipcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Zipcode is required';
    }
    if (value.length < 5) {
      return 'Invalid zipcode';
    }
    return null;
  }
}
