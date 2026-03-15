import 'package:billkaro/app/modules/Regular%20customer/CustomerDetails/customer_details_controller.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';

class CustomerDetailsScreen extends StatelessWidget {
  CustomerDetailsScreen({super.key});
  final controller = Get.put(CustomerDetailsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        actions: [
          IconButton(
            icon: Assets.svg.whatsapp.svg(width: 24, height: 24),
            onPressed: () {
              openWhatsApp(controller.phoneNumber.value);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.toNamed(
                AppRoute.addRegularCustomer,
                arguments: {
                  'isEdit': true,
                  'customerData': controller.customer,
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Name
              Obx(
                () => Text(
                  controller.customerName.value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Phone and Loyalty
              Row(
                children: [
                  Obx(
                    () => Text(
                      controller.phoneNumber.value,
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                  Spacer(),
                  Obx(
                    () => Text(
                      '${controller.loyaltyDiscount.value}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Loyalty\nDiscount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '₹${controller.avgOrder.value.toInt()} Avg Order',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      '₹${controller.totalDiscount.value.toInt()} Total\nDiscount',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '${controller.totalVisits.value} Total Visits',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      '₹${controller.orderValue.value.toInt()} Order\nValue',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Order Details
              Obx(
                () => Text(
                  controller.orderNumber.value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Text(
                  controller.orderDate.value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 16),

              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Obx(
                              () => Text(
                                '₹${controller.orderTotal.value.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Type',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Obx(
                              () => Text(
                                controller.paymentType.value,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Assets.svg.print.svg(width: 24, height: 24),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Assets.svg.export.svg(
                                width: 24,
                                height: 24,
                              ),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Assets.svg.delete.svg(
                                width: 24,
                                height: 24,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String text) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          height: 1.3,
        ),
      ),
    );
  }
}
