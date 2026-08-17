import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/app/services/download/file_download_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class KOTPreviewController extends BaseController {
  final phone = ''.obs;
  final date = formatDate(DateTime.now().toString()).obs;
  final time = formatTime(DateTime.now().toString()).obs;
  AddOrderController? get addOrderController =>
      Get.isRegistered<AddOrderController>()
      ? Get.find<AddOrderController>()
      : null;
  final kotNumber = ''.obs;
  var orderFrom = ''.obs;
  var customerName = ''.obs;
  var tableNumber = ''.obs;
  var waiterName = ''.obs;
  var specialInstructions = ''.obs;
  pw.Document pdf = pw.Document();

  RxList<OrderItem> itemList = <OrderItem>[].obs;

  final businessName = ''.obs;

  bool get isDineIn => orderFrom.value.trim().toLowerCase() == 'dine in';

  // Thermal printer service
  late ThermalPrinterService printerService;

  // Get total quantity of all items
  int get totalQuantity => itemList.fold(0, (sum, item) => sum + item.quantity);

  void onExport() {
    _shareKOT(pdf);
  }

  void getUserDetails() {
    final user = appPref.user;
    final outlet = appPref.selectedOutlet ?? user?.outletData?.firstOrNull;
    phone.value = user?.mobile ?? '';
    businessName.value = outlet?.businessName ?? user?.brandName ?? '';
    waiterName.value = user?.brandName ?? 'Staff';
  }

  void getKOTDetails() {
    final args = (Get.arguments ?? Modular.args.data);

    if (args != null) {
      // Get order data
      final map = args is Map ? args : null;
      final orderData = map?['invoice'] as CreateorderRequest?;

      if (orderData != null) {
        itemList.value = _enrichKotItems(orderData.items ?? []);
        kotNumber.value = orderData.billNumber ?? _generateKOTNumber();
        customerName.value = orderData.customerName ?? '';
      }

      // Get additional KOT specific details
      orderFrom.value = (map?['orderFrom'] ?? '').toString();
      tableNumber.value = (map?['tableNumber'] ?? '').toString();
      specialInstructions.value = (map?['specialInstructions'] ?? '')
          .toString();
    }

    debugPrint('KOT Items: ${itemList.length}');
    debugPrint('Total Quantity: $totalQuantity');
  }

  List<OrderItem> _enrichKotItems(List<OrderItem> items) {
    final cartRemarks = addOrderController?.itemRemarks;
    return items
        .map((item) {
          final cartRemark = cartRemarks?[item.itemId]?.trim();
          final existing = item.itemRemark?.trim();
          final remark = (cartRemark != null && cartRemark.isNotEmpty)
              ? cartRemark
              : (existing != null && existing.isNotEmpty ? existing : null);
          if (remark == null || remark == item.itemRemark) return item;
          return OrderItem(
            itemId: item.itemId,
            itemName: item.itemName,
            category: item.category,
            quantity: item.quantity,
            salePrice: item.salePrice,
            gst: item.gst,
            kotSentQuantity: item.kotSentQuantity,
            itemRemark: remark,
            variantId: item.variantId,
            variantName: item.variantName,
            variantSku: item.variantSku,
          );
        })
        .toList(growable: false);
  }

  // Generate KOT number if not provided
  String _generateKOTNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'KOT${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }

  // NEW: Print KOT using thermal printer
  Future<void> onPrintKOT() async {
    try {
      showAppLoader();

      // Drop loader before connect UI / print so it cannot sit over the dialog.
      dismissAllAppLoader();

      await printerService.printKOT(
        kotNumber: kotNumber.value,
        brandName: appPref.user!.brandName ?? '',
        businessName: businessName.value,
        address: appPref.user!.address ?? '',
        city: appPref.user!.city ?? '',
        zipcode: appPref.user!.zipcode ?? '',
        state: appPref.user!.state ?? '',
        orderFrom: orderFrom.value,
        tableNumber: tableNumber.value,
        customerName: customerName.value,
        waiterName: waiterName.value,
        date: date.value,
        time: time.value,
        items: itemList,
        specialInstructions: specialInstructions.value,
        totalQuantity: totalQuantity,
      );

      await addOrderController?.commitKitchenSentQuantities(
        orderId: (Get.arguments ?? Modular.args.data)?['orderId']?.toString(),
      );

      showSuccess(description: 'KOT printed successfully');
    } catch (e) {
      dismissAllAppLoader();
      showError(description: 'Failed to print KOT: $e');
      debugPrint('Print KOT Error: $e');
    }
  }

  // Show printer connection dialog
  Future<void> _showPrinterConnection() async {
    showAppLoader();

    await printerService.requestPermissions();

    // Try auto-connect first
    final autoConnected = await printerService.tryAutoConnect();

    dismissAppLoader();

    if (!autoConnected) {
      // Show scan dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Connect Printer'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                Obx(
                  () => printerService.isScanning.value
                      ? const LinearProgressIndicator()
                      : ElevatedButton(
                          onPressed: () => printerService.startScan(),
                          child: const Text('Scan for Printers'),
                        ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(
                    () => ListView.builder(
                      physics: BouncingScrollPhysics(),
                      itemCount: printerService.scanResults.length,
                      itemBuilder: (context, index) {
                        final device = printerService.scanResults[index].device;
                        return ListTile(
                          title: Text(
                            device.platformName.isEmpty
                                ? 'Unknown Device'
                                : device.platformName,
                          ),
                          subtitle: Text(device.remoteId.toString()),
                          onTap: () async {
                            final connected = await printerService
                                .connectToDevice(device);
                            if (connected) {
                              Get.back();
                              showSuccess(
                                description: 'Printer connected successfully',
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> onGenerateKOTPdf() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          appPref.user!.brandName ?? '',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          businessName.value,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          '${appPref.user!.address ?? ''} ${appPref.user!.city ?? ''} ${appPref.user!.zipcode ?? ''}\n${appPref.user!.state ?? ''}',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 10),
                        _buildDottedLine(),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'KITCHEN ORDER TICKET',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Order Source Box
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 2),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        '★ ${orderFrom.value.toUpperCase()} ★',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // KOT Details
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'KOT No: ${kotNumber.value}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (isDineIn && tableNumber.value.isNotEmpty) ...[
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'Table: ${tableNumber.value}',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                          if (customerName.value.isNotEmpty) ...[
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'Customer: ${customerName.value}',
                              style: const pw.TextStyle(fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Date: ${date.value}',
                            style: const pw.TextStyle(fontSize: 13),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Time: ${time.value}',
                            style: const pw.TextStyle(fontSize: 13),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Waiter: ${waiterName.value}',
                            style: const pw.TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  _buildDottedLine(),
                  pw.SizedBox(height: 10),

                  // Items Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Item Name',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Text(
                          'Qty',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // Items List
                  ...itemList.map((item) {
                    final category = item.category.trim();
                    final remark = item.itemRemark?.trim() ?? '';
                    final sublineStyle = pw.TextStyle(
                      fontSize: 11,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    );
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  item.displayName,
                                  style: const pw.TextStyle(fontSize: 14),
                                ),
                              ),
                              pw.Text(
                                'x${item.quantity}',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (category.isNotEmpty) ...[
                            pw.SizedBox(height: 3),
                            pw.Text('($category)', style: sublineStyle),
                          ],
                          if (remark.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Remark: $remark', style: sublineStyle),
                          ],
                        ],
                      ),
                    );
                  }),

                  pw.SizedBox(height: 10),
                  _buildDottedLine(),
                  pw.SizedBox(height: 10),

                  // Total Items
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Items',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '$totalQuantity',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Special Instructions
                  if (specialInstructions.value.isNotEmpty) ...[
                    pw.SizedBox(height: 20),
                    _buildDottedLine(),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 2),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Special Instructions',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            specialInstructions.value,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],

                  pw.SizedBox(height: 20),
                  _buildDottedLine(),
                  pw.SizedBox(height: 10),

                  // Footer
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          '--- End of KOT ---',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Prepared by: ${appPref.user?.brandName ?? ""}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      Get.back(); // Close loading dialog
      await _showKOTOptionsDialog(pdf);
    } catch (e) {
      Get.back();
      showError(description: 'Failed to generate KOT: $e');
      debugPrint('KOT Generation Error: $e');
    }
  }

  Future<void> _showKOTOptionsDialog(pw.Document pdf) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('KOT Options'),
        content: const Text('Choose an action:'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              onPrintKOT(); // Use thermal printer
            },
            child: const Text('Print (Thermal)'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _saveKOT(pdf);
            },
            child: const Text('Save PDF'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _shareKOT(pdf);
            },
            child: const Text('Share PDF'),
          ),
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _saveKOT(pw.Document pdf) async {
    try {
      final bytes = await pdf.save();
      final fileName =
          'KOT_${kotNumber.value}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = await FileDownloadService.instance.saveBytes(
        bytes: bytes,
        fileName: fileName,
        preferredDirectory: appPref.downloadPath,
        notificationTitle: 'KOT downloaded',
        notificationBody: 'KOT PDF saved to Downloads folder',
      );

      if (file == null) {
        showError(description: 'Failed to save KOT');
      }
    } catch (e) {
      showError(description: 'Failed to save KOT: $e');
    }
  }

  Future<void> _shareKOT(pw.Document pdf) async {
    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'KOT_${kotNumber.value}.pdf',
      );
    } catch (e) {
      showError(description: 'Failed to share KOT: $e');
    }
  }

  pw.Widget _buildDottedLine() {
    return pw.Container(
      height: 1,
      child: pw.LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 4.0;
          final dashSpace = 3.0;
          final dashCount = (constraints!.maxWidth / (dashWidth + dashSpace))
              .floor();

          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return pw.Container(
                width: dashWidth,
                height: 1,
                color: PdfColors.grey400,
              );
            }),
          );
        },
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    printerService = ThermalPrinterService.instance;
    getUserDetails();
    getKOTDetails();
  }
}
