import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/Print/jobs.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/builders/print_builder.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/text_helper.dart';
import 'package:pdf/widgets.dart' as pw;

class KotPrintJob extends PrintJob {
  final String kotNumber;
  final String brandName;
  final String businessName;
  final String address;
  final String city;
  final String zipcode;
  final String state;
  final String orderFrom;
  final String tableNumber;
  final String customerName;
  final String waiterName;
  final String date;
  final String time;
  final List<KotItem> items;
  final String specialInstructions;
  final int totalQuantity;

  KotPrintJob({
    required this.kotNumber,
    required this.brandName,
    required this.businessName,
    required this.address,
    required this.city,
    required this.zipcode,
    required this.state,
    required this.orderFrom,
    required this.tableNumber,
    required this.customerName,
    required this.waiterName,
    required this.date,
    required this.time,
    required this.items,
    required this.specialInstructions,
    required this.totalQuantity,
  }) : super(type: PrintJobType.kot);

  @override
  bool validate() {
    if (kotNumber.isEmpty) return false;
    if (items.isEmpty) return false;
    return true;
  }

  @override
  List<int> buildThermal(PrintBuilder builder) {
    builder
      ..center()
      ..text('(This is an internal document\n')
      ..text('and not a BILL)\n\n');

    if (businessName.isNotEmpty) {
      builder.bold(businessName + '\n');
    }

    builder
      ..boldDoubleHeight('KOT\n')
      ..boldNormal('Kitchen Order Ticket\n')
      ..line()
      ..left();

    builder
      ..text('KOT No: $kotNumber\n')
      ..text('Date: $date\n')
      ..text('Time: $time\n');

    if (tableNumber.isNotEmpty) {
      builder.text('Table: $tableNumber\n');
    }

    builder
      ..text('Staff: $waiterName\n')
      ..line();

    if (orderFrom.isNotEmpty) {
      builder.center().bold('*** ${orderFrom.toUpperCase()} ***\n').left();
    }

    if (customerName.isNotEmpty) {
      builder.text('Customer: $customerName\n');
    }

    builder.line();

    final w = builder.receiptWidth;
    builder.bold('${TextHelper.formatRow('Description', 'Qty.', w)}\n');
    builder.line();

    for (var item in items) {
      for (final line in TextHelper.kotNameQtyLines(
        item.name,
        item.quantity,
        w,
      )) {
        builder.text('$line\n');
      }
      for (final line in TextHelper.kotSublineLines(
        category: item.category,
        remark: item.notes,
        receiptWidth: w,
      )) {
        builder.text('$line\n');
      }
    }

    builder
      ..line()
      ..bold(
        TextHelper.formatRow(
              'Total Items',
              '$totalQuantity',
              builder.receiptWidth,
            ) +
            '\n',
      );

    if (specialInstructions.isNotEmpty) {
      builder
        ..line()
        ..bold('SPECIAL INSTRUCTIONS:\n')
        ..text('$specialInstructions\n');
    }

    builder
      ..center()
      ..line()
      ..text('--- End of KOT ---\n')
      ..text('Prepared by: $waiterName\n')
      ..feed(3)
      ..cut();

    return builder.bytes;
  }

  @override
  pw.Document buildPdf() {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('KOT #$kotNumber', style: pw.TextStyle(fontSize: 18)),
            pw.Text('$date $time'),
            if (businessName.isNotEmpty) pw.Text(businessName),
            if (tableNumber.isNotEmpty) pw.Text('Table: $tableNumber'),
            if (customerName.isNotEmpty) pw.Text('Customer: $customerName'),
            pw.SizedBox(height: 8),
            ...items.map(
              (item) => pw.Text('${item.quantity}x ${item.name}'),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Prepared by: ${waiterName.isEmpty ? 'Staff' : waiterName}'),
          ],
        ),
      ),
    );
    return doc;
  }
}

class KotItem {
  final String name;
  final int quantity;
  final String? category;
  final String? notes;

  KotItem({
    required this.name,
    required this.quantity,
    this.category,
    this.notes,
  });

  factory KotItem.fromOrderItem(OrderItem orderItem) {
    return KotItem(
      name: orderItem.itemName,
      quantity: orderItem.quantity ?? 1,
      category: orderItem.category,
      notes: orderItem.itemRemark,
    );
  }
}
