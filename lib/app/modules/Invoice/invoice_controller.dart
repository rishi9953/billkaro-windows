import 'dart:io';
import 'dart:ui' as ui;
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/utils/pos_cart_line.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:billkaro/app/services/download/download_notification_service.dart';
import 'package:billkaro/app/services/download/file_download_service.dart';
import 'package:billkaro/utils/extensions.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class InvoicePreviewController extends BaseController {
  final phone = ''.obs;
  final date = formatDate(DateTime.now().toString()).obs;
  final time = formatTime(DateTime.now().toString()).obs;
  final invoiceNo = ''.obs;
  var orderFrom = ''.obs;
  var customerName = ''.obs;
  var customerPhone = ''.obs;
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

  /// Builds the invoice PDF document matching the preview screen layout.
  void _buildPdfDocument() {
    final user = appPref.user!;
    final outlet = appPref.selectedOutlet!;

    pdf = pw.Document();
    // MultiPage auto-creates extra pages when item rows overflow A4 height.
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        build: (pw.Context context) {
          return [
            // --- Business Header ---
            pw.Text(
              '${user.brandName},',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              businessName.value,
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              user.address ?? '',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'GSTIN No: ${outlet.gstinNumber ?? 'N/A'}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'FSSAI No: ${outlet.fssaiNumber ?? 'N/A'}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Phone No: ${outlet.phoneNumber ?? 'N/A'}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 10),
            _buildDottedLine(),
            pw.SizedBox(height: 10),

            // --- Invoice Title ---
            pw.Text(
              'Invoice',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildDottedLine(),
            pw.SizedBox(height: 10),

            // --- Order Source ---
            pw.Text(
              '* ${orderFrom.value} *',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),

            // --- Customer & Date Info ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To : ${customerName.value}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                    ),
                    if (customerPhone.value.isNotEmpty)
                      pw.Text(
                        'Phone : ${customerPhone.value}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                      ),
                    pw.Text(
                      'Payment In : ${paymentMode.value}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date: ${date.value}', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('Time: ${time.value}', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('Invoice no: ${invoiceNo.value}', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            _buildDottedLine(),
            pw.SizedBox(height: 10),

            // --- Table Header ---
            pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
                pw.Expanded(flex: 1, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
                pw.Expanded(flex: 1, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
                pw.Expanded(flex: 1, child: pw.Text('GST', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
                pw.Expanded(flex: 1, child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
              ],
            ),
            pw.SizedBox(height: 10),

            // --- Items (flat list so MultiPage can split across pages) ---
            ...itemList.map((item) {
              final quantity = item.quantity ?? 1;
              final price = (item.salePrice ?? 0).toDouble();
              final amount = price * quantity;
              final gstRate = (item.gst ?? 0).toDouble();
              final gstLabel = gstRate <= 0
                  ? '-'
                  : gstRate == gstRate.roundToDouble()
                      ? '${gstRate.toInt()}%'
                      : '${gstRate.toStringAsFixed(1)}%';
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text(PosCartLine.invoiceLineName(itemName: item.itemName, variantName: item.variantName), style: const pw.TextStyle(fontSize: 12))),
                    pw.Expanded(flex: 1, child: pw.Text('x$quantity', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 12))),
                    pw.Expanded(flex: 1, child: pw.Text('Rs ${price.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12))),
                    pw.Expanded(flex: 1, child: pw.Text(gstLabel, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12))),
                    pw.Expanded(flex: 1, child: pw.Text('Rs ${amount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12))),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 10),
            _buildDottedLine(),
            pw.SizedBox(height: 10),

            // --- Subtotal ---
            _buildSummaryRow('Subtotal', 'Rs ${subtotal.toStringAsFixed(2)}'),

            // --- Tax ---
            if (totalTax > 0) ...[
              pw.SizedBox(height: 5),
              _buildSummaryRow('Tax (GST)', 'Rs ${totalTax.toStringAsFixed(2)}'),
            ],

            // --- Service Charge ---
            if (serviceCharge.value > 0) ...[
              pw.SizedBox(height: 5),
              _buildSummaryRow('Service Charge', 'Rs ${serviceCharge.value.toStringAsFixed(2)}'),
            ],

            // --- Discount ---
            if (discount.value > 0) ...[
              pw.SizedBox(height: 5),
              _buildSummaryRow('Discount', '- Rs ${discount.value.toStringAsFixed(2)}'),
            ],
            pw.SizedBox(height: 10),

            // --- Total ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Rs ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 10),
            _buildDottedLine(),
            pw.SizedBox(height: 10),

            // --- Terms ---
            pw.Center(
              child: pw.Column(children: [
                pw.Text('Terms & Conditions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text('Thank you for doing business with us.', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 11)),
              ]),
            ),

            // --- QR Code ---
            if (appPref.showQrOnBill && upiId.value.isNotEmpty && qrCodeImageProvider != null) ...[
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Column(children: [
                  pw.Text('Scan to Pay', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Image(qrCodeImageProvider!, width: 150, height: 150),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('UPI ID: ${upiId.value}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                  pw.Text('Amount: Rs ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ]),
              ),
              pw.SizedBox(height: 10),
              _buildDottedLine(),
            ],
          ];
        },
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
      ],
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
    const notificationId =
        DownloadNotificationService.invoiceDownloadNotificationId;
    try {
      await DownloadNotificationService.instance.notifyProgress(
        notificationId: notificationId,
        title: 'Invoice downloading',
        body: 'Preparing your invoice PDF…',
      );

      _buildPdfDocument();
      await _savePdf(pdf, notificationId: notificationId);
    } catch (e) {
      await DownloadNotificationService.instance.notifyFailed(
        notificationId: notificationId,
        title: 'Download failed',
        body: 'Failed to download invoice',
      );
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
      customerPhone.value = '';
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
    customerPhone.value = invoice.phoneNumber ?? '';
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
    // Never leave the Windows overlay loader up across Connect Printer —
    // that overlay paints above Get.dialog and looks like an infinite spinner.
    dismissAllAppLoader();

    try {
      _buildPdfDocument();

      // printInvoice may open Connect Printer; loader must stay off until that resolves.
      await ThermalPrinterService.instance.printInvoice(
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

      // Pop only after success. Route was opened with Modular, not Get.back().
      if (Modular.to.canPop()) {
        Modular.to.pop();
      }
    } catch (e) {
      dismissAllAppLoader();
      debugPrint('Failed to print invoice: $e');
      showError(description: 'Failed to print invoice: $e');
    }
  }

  String _sanitizeFileName(String name) {
    if (name.isEmpty) return 'invoice';
    return name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();
  }

  Future<void> printPdf(pw.Document pdf) async {
    try {
      dismissAllAppLoader();
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
      dismissAllAppLoader();
      debugPrint('Failed to print PDF: $e');
      showError(description: 'Failed to print PDF: $e');
    }
  }

  Future<File?> _savePdf(
    pw.Document pdf, {
    bool notify = true,
    int? notificationId,
  }) async {
    try {
      final bytes = await pdf.save();
      if (bytes.isEmpty) {
        showError(description: 'PDF generation failed - empty document');
        return null;
      }

      final name = _sanitizeFileName(invoiceNo.value);
      final fileName = 'invoice-$name.pdf';

      final file = await FileDownloadService.instance.saveBytes(
        bytes: bytes,
        fileName: fileName,
        preferredDirectory: appPref.downloadPath,
        notify: notify,
        notificationId: notificationId,
        notificationTitle: 'Invoice $name downloaded',
        notificationBody: '$fileName saved to Downloads',
      );

      if (file == null) {
        showError(description: 'Failed to save PDF file');
      }
      return file;
    } catch (e) {
      showError(description: 'Failed to save PDF: $e');
      return null;
    }
  }

  Future<void> openWhatsApp(String phoneNumber, {String? message}) async {
    try {
      dismissAllAppLoader();
      final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
      final phone = digits.length >= 10
          ? '91${digits.substring(digits.length - 10)}'
          : '';
      if (phone.isEmpty) {
        showError(description: 'Customer phone number is missing in invoice');
        return;
      }

      final invoiceMessage =
          message ??
          'Invoice ${invoiceNo.value}\n'
              'Customer: ${customerName.value}\n'
              'Phone: $phone\n'
              'Total: Rs ${totalAmount.toStringAsFixed(2)}\n'
              'Date: ${date.value} ${time.value}';

      // Build PDF in temp only — do not save/download to Downloads.
      await _withLoader(() async {
        _buildPdfDocument();
        final bytes = await pdf.save();
        if (bytes.isEmpty) {
          showError(description: 'PDF generation failed - empty document');
          return;
        }

        final name = _sanitizeFileName(invoiceNo.value);
        final fileName = 'invoice-$name.pdf';
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(bytes, flush: true);

        try {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'application/pdf')],
              text: invoiceMessage,
              subject: 'Invoice ${invoiceNo.value}',
              title: 'Invoice ${invoiceNo.value}',
            ),
          );
        } on UnimplementedError {
          await Printing.sharePdf(bytes: bytes, filename: fileName);
        }
      });
    } catch (e) {
      showError(description: 'Failed to share invoice on WhatsApp: $e');
    } finally {
      dismissAllAppLoader();
      if (Get.isDialogOpen == true) Get.back();
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
      final fileName = 'invoice-$name.pdf';

      // `Printing.sharePdf` just opens the PDF in the default viewer on
      // Windows, so use the native Windows share sheet via share_plus instead.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);

      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/pdf')],
            subject: 'Invoice ${invoiceNo.value}',
            title: 'Invoice ${invoiceNo.value}',
          ),
        );
      } on UnimplementedError {
        // Older Windows without the share UI — fall back to opening the file.
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
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
