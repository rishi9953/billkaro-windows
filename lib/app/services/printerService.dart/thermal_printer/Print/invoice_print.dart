import 'dart:typed_data';

import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/Print/jobs.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/builders/print_builder.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/text_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePrintJob extends PrintJob {
  // Business Information
  final String brandName;
  final String businessName;
  final String address;
  final String city;
  final String zipcode;
  final String state;
  final String? gstinNumber;
  final String? fssaiNumber;
  final String? phoneNumber;

  // Order Information
  final String orderFrom;
  final String customerName;
  final String paymentMode;
  final String date;
  final String time;
  final String invoiceNo;

  // Items and Pricing
  final List<InvoiceItem> items;
  final double subtotal;
  final double totalTax;
  final double serviceCharge;
  final double discount;
  final double totalAmount;

  // Payment Information
  final String? upiId;
  final Uint8List? qrCodeBytes;

  InvoicePrintJob({
    required this.brandName,
    required this.businessName,
    required this.address,
    required this.city,
    required this.zipcode,
    required this.state,
    this.gstinNumber,
    this.fssaiNumber,
    this.phoneNumber,
    required this.orderFrom,
    required this.customerName,
    required this.paymentMode,
    required this.date,
    required this.time,
    required this.invoiceNo,
    required this.items,
    required this.subtotal,
    required this.totalTax,
    required this.serviceCharge,
    required this.discount,
    required this.totalAmount,
    this.upiId,
    this.qrCodeBytes,
  }) : super(type: PrintJobType.invoice);

  @override
  bool validate() {
    if (brandName.isEmpty || businessName.isEmpty) return false;
    if (invoiceNo.isEmpty || customerName.isEmpty) return false;
    if (items.isEmpty) return false;
    if (totalAmount < 0) return false;
    return true;
  }

  // =========================
  // 🔥 THERMAL PRINT
  // =========================
  @override
  List<int> buildThermal(PrintBuilder builder) {
    builder
      ..center()
      ..boldDoubleHeight('$brandName\n')
      ..boldNormal('')
      ..text('$businessName\n')
      ..text('$address\n')
      ..text('$city, $zipcode\n')
      ..text('$state\n');

    if (gstinNumber != null) builder.text('GSTIN: $gstinNumber\n');
    if (fssaiNumber != null) builder.text('FSSAI: $fssaiNumber\n');
    if (phoneNumber != null) builder.text('Ph: $phoneNumber\n');

    builder
      ..line()
      ..bold('INVOICE\n')
      ..line()
      ..bold('*** $orderFrom ***\n')
      ..left();

    builder
      ..bold(
        TextHelper.formatRow('Bill To: $customerName', 'Date: $date', 48) +
            '\n',
      )
      ..bold(
        TextHelper.formatRow('Sale In: $paymentMode', 'Time: $time', 48) + '\n',
      )
      ..text(TextHelper.formatRow('', 'Invoice No: $invoiceNo', 48) + '\n')
      ..line();

    builder.bold(
      '${TextHelper.padRight('Item', 12)}'
      '${TextHelper.padRight('Qty', 12)}'
      '${TextHelper.padRight('Price', 12)}'
      '${TextHelper.padLeft('Amount', 12)}\n',
    );

    for (final item in items) {
      final name = item.name.length > 14
          ? item.name.substring(0, 14)
          : item.name;
      final row =
          '${TextHelper.padRight(name, 12)}'
          '${TextHelper.padRight('x${item.quantity}', 12)}'
          '${TextHelper.padRight(item.price.toStringAsFixed(0), 12)}'
          '${TextHelper.padLeft((item.total).toStringAsFixed(2), 12)}';
      builder.text('$row\n');
    }

    builder
      ..line()
      ..text(
        TextHelper.formatRow(
          'Subtotal',
          'Rs ${subtotal.toStringAsFixed(2)}',
          48,
        ),
      )
      ..text('\n');

    if (totalTax > 0) {
      builder.text(
        TextHelper.formatRow(
          'Tax (GST)',
          'Rs ${totalTax.toStringAsFixed(2)}',
          48,
        ),
      );
      builder.text('\n');
    }

    if (serviceCharge > 0) {
      builder.text(
        TextHelper.formatRow(
          'Service Charge',
          'Rs ${serviceCharge.toStringAsFixed(2)}',
          48,
        ),
      );
      builder.text('\n');
    }

    if (discount > 0) {
      builder.text(
        TextHelper.formatRow(
          'Discount',
          '-Rs ${discount.toStringAsFixed(2)}',
          48,
        ),
      );
      builder.text('\n');
    }

    builder
      ..line()
      ..boldDoubleHeight(
        TextHelper.formatRow(
          'TOTAL',
          'Rs ${totalAmount.toStringAsFixed(2)}',
          48,
        ),
      )
      ..line()
      ..center()
      ..text('\nThank you for your business\n');

    if (qrCodeBytes != null) {
      builder
        ..text('\nScan to Pay\n\n')
        ..bytes.addAll(qrCodeBytes!)
        ..text('\nUPI ID: $upiId\n')
        ..text('Amount: ₹${totalAmount.toStringAsFixed(2)}\n');
    }

    builder.feed(3).cut();
    return builder.bytes;
  }

  // =========================
  // 📄 PDF PRINT
  // =========================
  @override
  pw.Document buildPdf() {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                brandName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(child: pw.Text(businessName)),
            pw.Center(child: pw.Text(address)),
            pw.Center(child: pw.Text('$city, $zipcode')),
            pw.Center(child: pw.Text(state)),
            pw.Divider(),

            pw.Center(
              child: pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            pw.Text('Bill To: $customerName'),
            pw.Text('Invoice No: $invoiceNo'),
            pw.Text('Date: $date   Time: $time'),
            pw.Divider(),

            ...items.map(
              (e) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e.name),
                  pw.Text('x${e.quantity}'),
                  pw.Text('Rs ${e.total.toStringAsFixed(2)}'),
                ],
              ),
            ),

            pw.Divider(),
            pw.Text(
              'TOTAL: Rs ${totalAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),

            if (qrCodeBytes != null) ...[
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Scan to Pay')),
              pw.Center(
                child: pw.Image(pw.MemoryImage(qrCodeBytes!), width: 120),
              ),
            ],
          ],
        ),
      ),
    );

    return doc;
  }
}

// =========================
// 📦 INVOICE ITEM
// =========================
class InvoiceItem {
  final String name;
  final int quantity;
  final double price;
  final double taxAmount;
  final String? category;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.taxAmount = 0,
    this.category,
  });

  double get total => quantity * price;

  factory InvoiceItem.fromOrderItem(OrderItem item) {
    return InvoiceItem(
      name: item.itemName,
      quantity: item.quantity ?? 1,
      price: item.salePrice,
      category: item.category,
    );
  }
}
