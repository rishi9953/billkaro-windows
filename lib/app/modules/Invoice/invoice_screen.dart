import 'package:billkaro/app/modules/Invoice/invoice_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final controller = Get.put(InvoicePreviewController());

  InvoicePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        title: const Text('Preview'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColor.white),
            onPressed: () => controller.downloadPdf(),
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColor.white),
            onPressed: () => controller.sharePdfFromAppBar(),
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 1100
                ? 1100.0
                : (constraints.maxWidth > 720 ? 900.0 : constraints.maxWidth);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Obx(
                  () => Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${controller.appPref.user!.brandName},'),
                            Text(controller.businessName.value),
                            Text(
                              '${controller.appPref.user!.address!} ${controller.appPref.user!.city!} ${controller.appPref.user!.zipcode!}\n${controller.appPref.user!.state!}',
                              textAlign: TextAlign.center,
                            ),

                            Text(
                              'GSTIN No: ${controller.appPref.selectedOutlet!.gstinNumber ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'FSSAI No: ${controller.appPref.selectedOutlet!.fssaiNumber ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Phone No: ${controller.appPref.selectedOutlet!.phoneNumber ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Gap(10),
                            const DottedLine(),
                            const Gap(10),

                            const Text(
                              'Invoice',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Gap(10),
                            const DottedLine(),
                            const Gap(10),
                            Obx(() {
                              return Text(
                                '★ ${controller.orderFrom.value} ★',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              );
                            }),
                            const Gap(10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bill To : ${controller.customerName} ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      'Sale In : ${controller.paymentMode} ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Date: ${controller.date.value}'),
                                    Text('Time: ${controller.time.value}'),
                                    Text(
                                      'Invoice no: ${controller.invoiceNo.value}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Gap(10),
                            const DottedLine(),
                            const Gap(10),

                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Item Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Price',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Amount',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(10),

                            // Items List
                            ...controller.itemList.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final quantity = item.quantity;
                              final price = item.salePrice;
                              final amount = price * quantity;
                              final isZebra = index.isOdd;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isZebra
                                      ? Colors.grey.shade50
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        item.itemName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'x$quantity',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '₹${price.toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '₹${amount.toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const Gap(10),
                            const DottedLine(),
                            const Gap(10),

                            // Subtotal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal'),
                                Text(
                                  '₹${controller.subtotal.toStringAsFixed(2)}',
                                ),
                              ],
                            ),

                            // Tax (if applicable)
                            if (controller.totalTax > 0) ...[
                              const Gap(5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tax (GST)'),
                                  Text(
                                    '₹${controller.totalTax.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ],

                            // Service Charge (if applicable)
                            if (controller.serviceCharge.value > 0) ...[
                              const Gap(5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Service Charge'),
                                  Text(
                                    '₹${controller.serviceCharge.value.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ],

                            // Discount (if applicable)
                            if (controller.discount.value > 0) ...[
                              const Gap(5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount'),
                                  Text(
                                    '- ₹${controller.discount.value.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ],

                            const Gap(10),

                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '₹${controller.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),

                            const Gap(10),
                            const DottedLine(),
                            const Gap(10),
                            const Text(
                              'Terms & Conditions',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Thank you for doing business with us.',
                              textAlign: TextAlign.center,
                            ),

                            // ✅ QR Code for Payment
                            if (controller.appPref.showQrOnBill &&
                                controller.upiId.value.isNotEmpty) ...[
                              const Text(
                                'Scan to Pay',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Gap(10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: QrImageView(
                                  data: controller.generateUpiUrl(),
                                  version: QrVersions.auto,
                                  size: 180,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const Gap(10),
                              Text(
                                'UPI ID: ${controller.upiId.value}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Amount: ₹${controller.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Gap(10),
                              const DottedLine(),
                              const Gap(10),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Material(
            color: Colors.white,
            elevation: 1,
            borderRadius: const BorderRadius.all(Radius.circular(0)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await controller.generateAndPrintInvoice();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Generate Bill'),
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
