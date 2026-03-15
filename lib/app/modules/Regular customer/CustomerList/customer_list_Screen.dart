import 'package:billkaro/app/modules/Regular%20customer/CustomerList/cutomer_list_controller.dart';
import 'package:billkaro/app/modules/Regular%20customer/customer_tracking_screen.dart';
import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';

class CustomerListScreen extends StatelessWidget {
  CustomerListScreen({super.key});
  final controller = Get.put(CutomerListController());
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.customerList.isEmpty) {
        return CustomerTrackingScreen();
      }
      return Scaffold(
        appBar: AppBar(title: AppText.regular('Customers')),
        body: Column(
          children: [
            // Search TextField
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search',
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: controller.customerList.length,
                itemBuilder: (context, index) {
                  return customerData(controller.customerList[index], index);
                },
                separatorBuilder: (BuildContext context, int index) =>
                    Divider(color: AppColor.grey.shade300),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomButton(context),
      );
    });
  }

  Widget customerData(CustomerData customerData, int index) {
    return ListTile(
      onTap: () {
        Get.toNamed(AppRoute.regularCustomerDetails, arguments: customerData);
      },
      leading: AppText.regular('${index + 1}'),
      title: AppText.regular(customerData.customerName),
      trailing: InkWell(
        child: Assets.svg.whatsapp.svg(width: 24, height: 24),
        onTap: () {
          openWhatsApp(customerData.phoneNumber);
        },
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            // Handle button press
            Get.toNamed(AppRoute.addRegularCustomer);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            loc.add_regular_customer,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
