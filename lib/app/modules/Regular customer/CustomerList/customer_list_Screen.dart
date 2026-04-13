import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerList/cutomer_list_controller.dart';
import 'package:billkaro/app/modules/Regular%20customer/customer_tracking_screen.dart';
import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CustomerListScreen extends StatelessWidget {
  CustomerListScreen({super.key});
  final controller = Get.put(CutomerListController());
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.customerList.isEmpty) {
        return CustomerTrackingScreen();
      }

      final filteredCustomers = controller.customerList
          .where(
            (customer) =>
                customer.customerName.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                customer.phoneNumber.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
          )
          .toList();

      final isWideScreen = MediaQuery.of(context).size.width > 900;

      return Scaffold(
        appBar: AppBar(
          title: AppText.regular('Customers'),
          centerTitle: false,
          elevation: 0.3,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 24 : 12,
                vertical: 16,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColor.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: searchController,
                            onChanged: (value) => searchQuery.value = value,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search by customer name or phone',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: searchQuery.value.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        searchController.clear();
                                        searchQuery.value = '';
                                      },
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AppText.regular(
                            '${filteredCustomers.length} Customers',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColor.grey.shade200),
                      ),
                      child: filteredCustomers.isEmpty
                          ? Center(
                              child: AppText.regular('No matching customers'),
                            )
                          : ListView.separated(
                              itemCount: filteredCustomers.length,
                              itemBuilder: (context, index) {
                                return customerData(
                                  filteredCustomers[index],
                                  index,
                                );
                              },
                              separatorBuilder: (BuildContext context, int i) =>
                                  Divider(
                                    height: 1,
                                    color: AppColor.grey.shade200,
                                  ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: isWideScreen
            ? FloatingActionButton.extended(
                onPressed: () {
                  Modular.to.pushNamed(HomeMainRoutes.addRegularCustomer);
                },
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(
                  AppLocalizations.of(Get.context!)!.add_regular_customer,
                ),
              )
            : null,
        bottomNavigationBar: isWideScreen ? null : _buildBottomButton(context),
      );
    });
  }

  Widget customerData(CustomerData customerData, int index) {
    return InkWell(
      onTap: () {
        Modular.to.pushNamed(
          HomeMainRoutes.customersDetails,
          arguments: customerData,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppText.medium('${index + 1}'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.medium(customerData.customerName),
                  const SizedBox(height: 2),
                  AppText.regular(
                    customerData.phoneNumber,
                    color: AppColor.grey.shade700,
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Assets.svg.whatsapp.svg(width: 20, height: 20),
              ),
              onTap: () => openWhatsApp(customerData.phoneNumber),
            ),
          ],
        ),
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
            // Get.toNamed(AppRoute.addRegularCustomer);
            Modular.to.pushNamed(HomeMainRoutes.addRegularCustomer);
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
