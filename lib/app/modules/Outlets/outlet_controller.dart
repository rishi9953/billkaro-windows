import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/outlets/outlet_request.dart';
import 'package:billkaro/config/config.dart';

// Controller for Create Outlet Screen
class CreateOutletController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final Rx<OutletData?> selectedOutlet = Rx<OutletData?>(null);

  var outletName = ''.obs;
  var selectedType = 'None'.obs;
  var selectedCapacity = '0-10'.obs;
  var selectedAge = 'Less than 6 Months'.obs;
  var outletAddress = ''.obs;

  final typeOptions = ['Retail', 'Service', 'Manufacturing', 'Other', 'None'];

  final capacityOptions = [
    {'label': 'No Seating', 'value': '0'},
    {'label': 'Less than 10', 'value': '0-10'},
    {'label': '10-20', 'value': '10-20'},
    {'label': '20-50', 'value': '20-50'},
    {'label': '50-100', 'value': '50-100'},
    {'label': 'More than 100', 'value': '100+'},
  ];

  final ageOptions = ['Less than 6 Months', '6 Months - 1 Year', '1-2 Years', '2-5 Years', 'More than 5 Years'];

  void createOutlet() async {
    if (formKey.currentState!.validate()) {
      final request = OutletRequest(
        businessName: outletName.value,
        businessType: selectedType.value.toLowerCase(),
        seatingCapacity: selectedCapacity.value,
        outletAge: selectedAge.value,
        outletAddress: outletAddress.value,
      );
      final reponse = await callApi(apiClient.addOutlet(appPref.user!.id!, request));
      if (reponse['status'] == 'success') {
        await getUserDetails();
        Get.offAllNamed(AppRoute.homeMain);
      }
    }
  }

  Future<void> getUserDetails() async {
    final response = await callApi(apiClient.getUserDetails(appPref.user!.id!));
    if (response!.status == 'success') {
      appPref.user = response.data;

      // Select the most recently created outlet (last outlet in the list)
      if (appPref.allOutlets.isNotEmpty) {
        // Assuming the API returns outlets with the newest one last
        final lastOutlet = appPref.allOutlets.last;
        appPref.selectedOutlet = lastOutlet;
        selectedOutlet.value = lastOutlet;
        debugPrint('🏪 Auto-selected recently created outlet: ${lastOutlet.businessName}');
      } else if (!appPref.hasSelectedOutlet && appPref.allOutlets.isNotEmpty) {
        // Fallback: select first outlet if none selected
        appPref.selectFirstOutlet();
        selectedOutlet.value = appPref.selectedOutlet;
      }
    }
  }
}
