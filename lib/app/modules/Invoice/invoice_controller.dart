import 'dart:io';
import 'dart:ui' as ui;
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:billkaro/utils/download_path_util.dart';
import 'package:billkaro/utils/extensions.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InvoicePreviewController extends BaseController {
  final phone = ''.obs;
  final date = formatDate(DateTime.now().toString()).obs;
  final time = formatTime(DateTime.now().toString()).obs;
  final invoiceNo = ''.obs;
  var orderFrom = ''.obs;
  var customerName = ''.obs;
  var paymentMode = ''.obs;
  pw.Document pdf = pw.Document();

  RxList<OrderItem> itemList = <OrderItem>[].obs;

  final discount = 0.0.obs;
  final serviceCharge = 0.0.obs;

  final upiId = ''.obs;
  final businessName = ''.obs;
  pw.ImageProvider? qrCodeImageProvider;

  double get subtotal => itemList.fold(0.0, (sum, item) {
    final price = (item.salePrice ?? 0).toDouble();
    final quantity = item.quantity ?? 1;
    return sum + (price * quantity);
  });

  double get totalTax => itemList.fold(0.0, (sum, item) {
    final price = (item.salePrice ?? 0).toDouble();
    final quantity = item.quantity ?? 1;
    final gstRate = (item.gst ?? 0).toDouble();
    final lineTotal = price * quantity;
    return sum + (lineTotal * gstRate / 100.0);
  });

  double get totalAmount =>
      subtotal + totalTax + serviceCharge.value - discount.value;

  /// Builds the invoice PDF document (used by Generate Bill, Download, Share).
  void _buildPdfDocument() {
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
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Phone: ${phone.value}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      _buildDottedLine(),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Tax Invoice',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Cash Sale',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date: ${date.value}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Time: ${time.value}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Invoice no: ${invoiceNo.value}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                _buildDottedLine(),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Item Name',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Qty',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Price',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Amount',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                ...itemList.map((item) {
                  final quantity = item.quantity ?? 1;
                  final price = (item.salePrice ?? 0).toDouble();
                  final amount = price * quantity;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            item.itemName ?? '',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'x$quantity',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Rs${price.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Rs${amount.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                pw.SizedBox(height: 10),
                _buildDottedLine(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Subtotal',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'Rs${subtotal.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                if (totalTax > 0) ...[
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Tax (GST)',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Rs${totalTax.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
                if (serviceCharge.value > 0) ...[
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Service Charge',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Rs${serviceCharge.value.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
                if (discount.value > 0) ...[
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Discount',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        '- Rs${discount.value.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Rs${totalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 20),
                if (appPref.showQrOnBill &&
                    upiId.value.isNotEmpty &&
                    qrCodeImageProvider != null) ...[
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Scan to Pay',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Image(
                            qrCodeImageProvider!,
                            width: 150,
                            height: 150,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'UPI ID: ${upiId.value}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Amount: Rs${totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 20),
                ],
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Terms & Conditions',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Thank you for doing business with us.',
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center,
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
  }

  Future<void> _withLoader(Future<void> Function() fn) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      await fn();
    } finally {
      if (Get.isDialogOpen == true) Get.back();
    }
  }

  Future<void> downloadPdf() async {
    try {
      await _withLoader(() async {
        _buildPdfDocument();
        await _savePdf(pdf);
      });
    } catch (e) {
      showError(description: 'Failed to download PDF: $e');
    }
  }

  Future<void> sharePdfFromAppBar() async {
    try {
      await _withLoader(() async {
        _buildPdfDocument();
        await sharePdf(pdf);
      });
    } catch (e) {
      showError(description: 'Failed to share PDF: $e');
    }
  }

  void getUserDetails() {
    phone.value = appPref.selectedOutlet!.phoneNumber ?? '';
    upiId.value = appPref.selectedOutlet?.upiId ?? '';
    businessName.value = appPref.selectedOutlet?.businessName ?? '';
  }

  void getItemList() {
    final rawArgs = Get.arguments ?? Modular.args.data;
    final map = rawArgs is Map ? rawArgs : null;

    final invoice = map?['invoice'] as CreateorderRequest?;
    if (invoice == null) {
      // Screen opened without required arguments; keep UI alive instead of crashing.
      itemList.clear();
      invoiceNo.value = '';
      discount.value = 0.0;
      serviceCharge.value = 0.0;
      orderFrom.value = '';
      customerName.value = '';
      paymentMode.value = '';
      _generateQRCode();
      return;
    }

    itemList.value = invoice.items ?? [];
    invoiceNo.value = invoice.billNumber ?? '';
    discount.value = invoice.discount ?? 0.0;
    serviceCharge.value = invoice.serviceCharge ?? 0.0;
    orderFrom.value = (map?['orderFrom'] ?? '').toString();
    customerName.value = invoice.customerName ?? '';
    paymentMode.value = invoice.paymentReceivedIn ?? '';
    _generateQRCode();
  }

  Future<void> _generateQRCode() async {
    if (upiId.value.isEmpty) {
      qrCodeImageProvider = null;
      return;
    }
    try {
      final upiUrl = generateUpiUrl();
      if (upiUrl.isEmpty) {
        qrCodeImageProvider = null;
        return;
      }
      final result = QrValidator.validate(
        data: upiUrl,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      if (result.status != QrValidationStatus.valid) {
        qrCodeImageProvider = null;
        return;
      }
      final painter = QrPainter.withQr(
        qr: result.qrCode!,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );
      final picData = await painter.toImageData(
        300,
        format: ui.ImageByteFormat.png,
      );
      if (picData == null) {
        qrCodeImageProvider = null;
        return;
      }
      qrCodeImageProvider = pw.MemoryImage(picData.buffer.asUint8List());
    } catch (_) {
      qrCodeImageProvider = null;
    }
  }

  String generateUpiUrl() {
    if (upiId.value.isEmpty) return '';
    final amount = totalAmount.toStringAsFixed(2);
    final merchantName = Uri.encodeComponent(
      businessName.value.isNotEmpty ? businessName.value : 'Payment',
    );
    final transactionNote = Uri.encodeComponent('Invoice ${invoiceNo.value}');
    return 'upi://pay?pa=${upiId.value}&pn=$merchantName&am=$amount&cu=INR&tn=$transactionNote';
  }

  Future<void> generateAndPrintInvoice() async {
    showAppLoader();

    try {
      _buildPdfDocument();
      Get.back(); // Close the invoice preview after printing
      await printPdf(pdf);
    } catch (e) {
      showError(description: 'Failed to print invoice: $e');
    } finally {
      dismissAllAppLoader();
      if (Get.isDialogOpen == true) Get.back();
    }
  }

  String _sanitizeFileName(String name) {
    if (name.isEmpty) return 'invoice';
    return name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();
  }

  Future<void> printPdf(pw.Document pdf) async {
    try {
      await Get.context!.printer.printInvoice(
        brandName: appPref.user!.brandName ?? '',
        businessName: appPref.selectedOutlet!.businessName ?? '',
        address: appPref.user!.address ?? '',
        city: appPref.user!.city ?? '',
        zipcode: appPref.user!.zipcode ?? '',
        state: appPref.user!.state ?? '',
        orderFrom: orderFrom.value,
        customerName: customerName.value,
        paymentMode: paymentMode.value,
        date: date.value,
        time: time.value,
        fssaiNumber: appPref.selectedOutlet!.fssaiNumber ?? '',
        gstinNumber: appPref.selectedOutlet!.gstinNumber ?? '',
        invoiceNo: invoiceNo.value,
        items: itemList,
        subtotal: subtotal,
        totalTax: totalTax,
        serviceCharge: serviceCharge.value,
        discount: discount.value,
        totalAmount: totalAmount,
        upiId: appPref.selectedOutlet!.upiId ?? '',
      );
      showSuccess(description: 'Invoice printed successfully');
    } catch (e) {
      debugPrint('Failed to print PDF: $e');
      showError(description: 'Failed to print PDF: $e');
    }
  }

  Future<void> _savePdf(pw.Document pdf) async {
    try {
      final bytes = await pdf.save();
      if (bytes.isEmpty) {
        showError(description: 'PDF generation failed - empty document');
        return;
      }
      final dir = await DownloadPathUtil.resolveSaveDirectory(
        preferredPath: appPref.downloadPath,
      );
      await Directory(dir).create(recursive: true);
      final name = _sanitizeFileName(invoiceNo.value);
      final filePath =
          '$dir/invoice_${name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      if (await file.exists()) {
        showSuccess(description: 'Invoice saved to Downloads folder');
      } else {
        showError(description: 'Failed to save PDF file');
      }
    } catch (e) {
      showError(description: 'Failed to save PDF: $e');
    }
  }

  Future<void> sharePdf(pw.Document pdf) async {
    try {
      final bytes = await pdf.save();
      if (bytes.isEmpty) {
        showError(description: 'PDF generation failed - empty document');
        return;
      }
      final name = _sanitizeFileName(invoiceNo.value);
      await Printing.sharePdf(bytes: bytes, filename: 'invoice_$name.pdf');
    } catch (e) {
      showError(description: 'Failed to share PDF: $e');
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
    getUserDetails();
    getItemList();
  }
}
