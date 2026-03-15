import 'package:billkaro/app/modules/Invoice/KOT/kot_preview_controller.dart';
import 'package:billkaro/config/config.dart';

class ThermalKOTReceipt extends StatelessWidget {
  const ThermalKOTReceipt({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(KOTPreviewController());

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('KOT Receipt'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => controller.onPrintKOT(),
            tooltip: 'Generate PDF',
          ),
        ],
      ),
      body: Center(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Obx(
            () => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dotted Line
                    _buildDottedLine(),
                    const SizedBox(height: 8),

                    // Header - Internal Document Note
                    const Text(
                      '(This is an internal document and not a BILL)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Business Name
                    if (controller.businessName.value.isNotEmpty) ...[
                      Text(
                        controller.businessName.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // KOT Title
                    const Text(
                      'KOT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'Kitchen Order Ticket',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDottedLine(),
                    const SizedBox(height: 12),

                    // Order Details - Two Columns
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'KOT No',
                                controller.kotNumber.value,
                              ),
                              const SizedBox(height: 4),
                              _buildDetailRow(
                                'Order\nSource',
                                controller.orderFrom.value,
                              ),
                              const SizedBox(height: 4),
                              _buildDetailRow('Date', controller.date.value),
                              const SizedBox(height: 4),
                              if (controller.isDineIn &&
                                  controller.tableNumber.value.isNotEmpty)
                                _buildDetailRow(
                                  'Table',
                                  controller.tableNumber.value,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Time', controller.time.value),
                              const SizedBox(height: 4),
                              _buildDetailRow(
                                'Staff',
                                controller.waiterName.value,
                              ),
                              const SizedBox(height: 4),
                              if (controller.phone.value.isNotEmpty)
                                _buildDetailRow(
                                  'Phone',
                                  controller.phone.value,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Order Source Badge
                    if (controller.orderFrom.value.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('★ ', style: TextStyle(fontSize: 10)),
                            Text(
                              controller.orderFrom.value.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const Text(' ★', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Customer Name
                    if (controller.customerName.value.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Customer: ${controller.customerName.value}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildDottedLine(),
                    const SizedBox(height: 12),

                    // Items Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[400]!),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              'Qty.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Items List
                    if (controller.itemList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No items in this order',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      ...controller.itemList.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (item.category.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '(${item.category})',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 50,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'x${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 12),
                    _buildDottedLine(),
                    const SizedBox(height: 12),

                    // Total Items
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Items',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${controller.totalQuantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Special Instructions
                    if (controller.specialInstructions.value.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDottedLine(),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow[50],
                          border: Border.all(color: Colors.orange[300]!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️ Special Instructions',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              controller.specialInstructions.value,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    _buildDottedLine(),
                    const SizedBox(height: 12),

                    // Footer
                    Column(
                      children: [
                        const Text(
                          '--- End of KOT ---',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prepared by: ${controller.waiterName.value}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
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
                onPressed: () async {
                  await controller.onGenerateKOTPdf();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Print KOT'),
              ),
            ),
            const SizedBox(width: 12),
            if (controller.addOrderController != null)
              Expanded(
                child: ElevatedButton(
                  onPressed: () async => await controller.addOrderController!
                      .saveAndBill('billing'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Generate Order'),
                ),
              ),
          ],
        ),
      ), // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => controller.onGenerateKOTPdf(),
      //   icon: const Icon(Icons.picture_as_pdf),
      //   label: const Text('Generate PDF'),
      // ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text('$label:', style: const TextStyle(fontSize: 9)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDottedLine() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: 1,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
