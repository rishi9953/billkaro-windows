import 'package:billkaro/app/modules/Invoice/invoice_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final controller = Get.put(InvoicePreviewController());

  InvoicePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Preview'),
        centerTitle: false,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: () => controller.downloadPdf(),
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => controller.sharePdfFromAppBar(),
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Obx(
            () => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                    'GSTIN No: ${controller.appPref.selectedOutlet!.gstinNumber! ?? 'N/A'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'FSSAI No: ${controller.appPref.selectedOutlet!.fssaiNumber! ?? 'N/A'}',
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          Text(
                            'Sale In : ${controller.paymentMode} ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Date: ${controller.date.value}'),
                          Text('Time: ${controller.time.value}'),
                          Text('Invoice no: ${controller.invoiceNo.value}'),
                        ],
                      ),
                    ],
                  ),
                  const Gap(10),
                  const DottedLine(),
                  const Gap(10),

                  // Table Header
                  Row(
                    children: const [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Item Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Qty',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Price',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Amount',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),

                  // Items List
                  ...controller.itemList.map((item) {
                    final quantity = item.quantity ?? 1;
                    final price = (item.salePrice is num)
                        ? (item.salePrice as num).toDouble()
                        : double.tryParse(item.salePrice.toString()) ?? 0.0;
                    final amount = price * quantity;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(item.itemName.toString() ?? ''),
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
                      Text('₹${controller.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),

                  // Tax (if applicable)
                  if (controller.totalTax > 0) ...[
                    const Gap(5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax (GST)'),
                        Text('₹${controller.totalTax.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],

                  // Service Charge (if applicable)
                  if (controller.serviceCharge.value > 0) ...[
                    const Gap(5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        border: Border.all(color: Colors.grey.shade300),
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
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back(result: true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await controller.generateAndPrintInvoice();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Generate Bill'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
