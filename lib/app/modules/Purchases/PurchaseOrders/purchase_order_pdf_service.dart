import 'dart:async';
import 'dart:io';

import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_display.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_terms.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/download_path_util.dart';
import 'package:billkaro/utils/po_print_orientation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PurchaseOrderPdfService {
  static Future<void> _waitNextFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    return completer.future;
  }

  static Future<void> printOrPreview(
    PurchaseOrderData po, {
    OutletData? outlet,
    SupplierData? supplierFallback,
    PurchaseOrderDisplay? display,
  }) async {
    final loc = AppLocalizations.of(Get.context!)!;
    try {
      showAppLoader();
      final resolvedOutlet = outlet ?? Get.find<AppPref>().selectedOutlet;
      final resolvedDisplay = display ??
          PurchaseOrderDisplay.resolve(
            po,
            outlet: resolvedOutlet,
            supplierFallback: supplierFallback,
            termsFallback: Get.find<AppPref>().poDefaultTermsForOutlet(
              resolvedOutlet?.id ?? '',
            ),
          );
      final orientation = Get.find<AppPref>().poPrintOrientation;
      final doc = await buildDocument(
        resolvedDisplay,
        orientation: orientation,
        logoUrl: resolvedOutlet?.logo ?? display?.logoUrl,
        notesLabel: loc.notes_label,
        termsHeading: loc.po_terms_heading,
        termsIntro: loc.po_terms_intro,
      );
      final bytes = await doc.save();
      dismissAllAppLoader();

      if (bytes.isEmpty) {
        showError(description: loc.failed_to_print_pdf);
        return;
      }

      await _waitNextFrame();
      await _showPrintOptions(
        bytes,
        po.orderNumber,
        loc,
        resolvedDisplay,
        orientation,
        resolvedOutlet?.logo ?? display?.logoUrl,
        loc.notes_label,
        loc.po_terms_heading,
        loc.po_terms_intro,
      );
    } catch (e, st) {
      dismissAllAppLoader();
      debugPrint('PO PDF error: $e\n$st');
      showError(description: '${loc.failed_to_print_pdf}: $e');
    }
  }

  static Future<void> _showPrintOptions(
    Uint8List bytes,
    String orderNumber,
    AppLocalizations loc,
    PurchaseOrderDisplay display,
    PoPrintOrientation orientation,
    String? logoUrl,
    String notesLabel,
    String termsHeading,
    String termsIntro,
  ) async {
    await Get.dialog(
      AlertDialog(
        title: Text(loc.print_po),
        content: Text(loc.choose_an_option),
        actions: [
          TextButton(
            onPressed: () async {
              Get.back();
              await _printToSystemPrinter(
                display,
                orientation,
                logoUrl: logoUrl,
                notesLabel: notesLabel,
                termsHeading: termsHeading,
                termsIntro: termsIntro,
                loc: loc,
              );
            },
            child: Text(loc.print),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _savePdf(bytes, orderNumber, loc);
            },
            child: Text(loc.save_pdf),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _sharePdf(bytes, orderNumber, loc);
            },
            child: Text(loc.share),
          ),
          TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
        ],
      ),
      barrierDismissible: true,
    );
  }

  static Future<void> _printToSystemPrinter(
    PurchaseOrderDisplay display,
    PoPrintOrientation orientation, {
    String? logoUrl,
    required String notesLabel,
    required String termsHeading,
    required String termsIntro,
    required AppLocalizations loc,
  }) async {
    try {
      final pageFormat = orientation.pageFormat;
      await Printing.layoutPdf(
        format: pageFormat,
        name: 'Purchase_Order',
        onLayout: (_) async {
          final doc = await buildDocument(
            display,
            orientation: orientation,
            logoUrl: logoUrl,
            notesLabel: notesLabel,
            termsHeading: termsHeading,
            termsIntro: termsIntro,
          );
          return doc.save();
        },
      );
    } catch (e) {
      debugPrint('PO print error: $e');
      showError(description: '${loc.failed_to_print_pdf}: $e');
    }
  }

  static Future<void> _savePdf(
    Uint8List bytes,
    String orderNumber,
    AppLocalizations loc,
  ) async {
    try {
      final savePath = await DownloadPathUtil.resolveSaveDirectory(
        preferredPath: Get.find<AppPref>().downloadPath,
      );
      await Directory(savePath).create(recursive: true);
      final safeName = orderNumber.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
      final filePath =
          '$savePath/PO_${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      showSuccess(description: loc.pdf_saved_to_downloads);
    } catch (e) {
      showError(description: '${loc.failed_to_save_pdf}: $e');
    }
  }

  static Future<void> _sharePdf(
    Uint8List bytes,
    String orderNumber,
    AppLocalizations loc,
  ) async {
    try {
      final safeName = orderNumber.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
      await Printing.sharePdf(bytes: bytes, filename: 'PO_$safeName.pdf');
    } catch (e) {
      showError(description: '${loc.failed_to_share_pdf}: $e');
    }
  }

  static Future<pw.Document> buildDocument(
    PurchaseOrderDisplay display, {
    PoPrintOrientation orientation = PoPrintOrientation.landscape,
    String? logoUrl,
    String notesLabel = 'Notes',
    String termsHeading = 'Terms & Conditions :',
    String termsIntro =
        'These terms and conditions shall form an integral part of the Purchase Order (PO)',
  }) async {
    final doc = pw.Document();
    final po = display.po;
    final isDraft = po.status == 'PENDING' || po.status == 'DRAFT';
    final isLandscape = orientation == PoPrintOrientation.landscape;
    final pageFormat = orientation.pageFormat;
    final pageMargin = isLandscape
        ? const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 20)
        : const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 20);
    final contentWidth =
        pageFormat.width - pageMargin.left - pageMargin.right;
    final infoLabelWidth = isLandscape ? 118.0 : 96.0;
    final logoWidth = isLandscape ? 140.0 : 120.0;
    final logoHeight = isLandscape ? 44.0 : 38.0;
    final titleFontSize = isLandscape ? 15.0 : 13.0;
    final logoTextSize = isLandscape ? 12.0 : 11.0;
    final bodyLabelSize = isLandscape ? 9.0 : 8.5;
    final bodyValueSize = isLandscape ? 9.0 : 8.0;
    final sectionTitleSize = isLandscape ? 11.0 : 10.0;
    final tableHeaderSize = isLandscape ? 8.5 : 7.5;
    final tableCellSize = isLandscape ? 8.0 : 7.0;
    final statusFontSize = 9.0;
    final footerFontSize = 9.0;
    final pageNumFontSize = 7.0;
    final notesFontSize = 10.0;
    final totalFontSize = isLandscape ? 11.0 : 10.0;
    final grandTotalFontSize = isLandscape ? 13.0 : 12.0;
    final tableCellPadding = isLandscape
        ? const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6)
        : const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5);
    final tableColumnWidths = _tableColumnWidths(contentWidth, isLandscape);
    final logoBytes = await _loadLogoBytes(logoUrl ?? display.logoUrl);

    pw.TextStyle label() =>
        pw.TextStyle(fontSize: bodyLabelSize, fontWeight: pw.FontWeight.bold);
    pw.TextStyle value({bool bold = false, double? size}) => pw.TextStyle(
          fontSize: size ?? bodyValueSize,
          fontWeight: bold ? pw.FontWeight.bold : null,
        );

    pw.Widget infoBox(String title, List<List<String>> rows, {int minRows = 0}) {
      final padded = List<List<String>>.from(rows);
      while (padded.length < minRows) {
        padded.add(['', '']);
      }
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(title, style: value(bold: true, size: sectionTitleSize)),
            pw.SizedBox(height: 6),
            ...padded.map(
              (r) {
                if (r[0].isEmpty && r[1].isEmpty) {
                  return pw.SizedBox(height: 17);
                }
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: infoLabelWidth,
                        child: pw.Text(_pdfText(r[0]), style: label()),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          _pdfDashIfEmpty(r[1]),
                          style: value(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    pw.Widget infoBoxRow(
      String title1,
      List<List<String>> rows1,
      String title2,
      List<List<String>> rows2, {
      int minRows = 0,
    }) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: infoBox(title1, rows1, minRows: minRows)),
          pw.SizedBox(width: 10),
          pw.Expanded(child: infoBox(title2, rows2, minRows: minRows)),
        ],
      );
    }

    pw.Widget logoWidget() {
      if (logoBytes == null) {
        return pw.Text(
          _pdfText(display.businessName),
          style: pw.TextStyle(
            fontSize: logoTextSize,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        );
      }
      try {
        return pw.Image(
          pw.MemoryImage(logoBytes),
          width: logoWidth,
          height: logoHeight,
          fit: pw.BoxFit.contain,
        );
      } catch (_) {
        return pw.Text(
          _pdfText(display.businessName),
          style: pw.TextStyle(
            fontSize: logoTextSize,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        );
      }
    }

    pw.Widget statusChip() {
      final color = _statusColor(po.status);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: color, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              po.status,
              style: pw.TextStyle(
                fontSize: statusFontSize,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (isDraft) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'DRAFT',
              style: pw.TextStyle(
                fontSize: statusFontSize,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey500,
              ),
            ),
          ],
        ],
      );
    }

    pw.Widget tableCell(
      String text, {
      bool header = false,
      pw.TextAlign align = pw.TextAlign.left,
    }) {
      return pw.Padding(
        padding: tableCellPadding,
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: header ? tableHeaderSize : tableCellSize,
            fontWeight: header ? pw.FontWeight.bold : null,
          ),
        ),
      );
    }

    final effectiveDate = _fmtDate(po.createdAt);

    pw.Widget lineItemsTable() {
      const headers = [
        'Sl. No',
        'Item',
        'Description',
        'HSN/SAC\nCode',
        'Qty',
        'UOM',
        'Delivery\nDate',
        'Rate Per\nUnit',
        'Basic\nAmount',
        'Tax\nRate',
        'Tax\nAmount',
        'Gross\nAmount',
      ];

      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: tableColumnWidths,
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: headers.map((h) => tableCell(h, header: true)).toList(),
          ),
          ...display.lines.map((line) {
            final desc = line.description.isNotEmpty
                ? line.description
                : line.rawMaterialName;
            final delivery = line.deliveryDate != null
                ? _fmtShortDate(line.deliveryDate!)
                : effectiveDate;
            return pw.TableRow(
              children: [
                tableCell('${line.lineNumber}'),
                tableCell(_pdfText(line.rawMaterialName)),
                tableCell(_pdfText(desc)),
                tableCell(
                  line.hsnSacCode.isEmpty ? '-' : _pdfText(line.hsnSacCode),
                ),
                tableCell(_fmtNum(line.quantity), align: pw.TextAlign.right),
                tableCell(_pdfText(line.unit)),
                tableCell(delivery),
                tableCell(
                  _fmtMoney(line.unitPrice),
                  align: pw.TextAlign.right,
                ),
                tableCell(
                  _fmtMoney(line.basicAmount),
                  align: pw.TextAlign.right,
                ),
                tableCell('${line.taxRate.toStringAsFixed(0)}%'),
                tableCell(
                  _fmtMoney(line.taxAmount),
                  align: pw.TextAlign.right,
                ),
                tableCell(
                  _fmtMoney(line.grossAmount),
                  align: pw.TextAlign.right,
                ),
              ],
            );
          }),
        ],
      );
    }

    final vendorRows = [
      ['Vendor No', _pdfDashIfEmpty(display.supplier.vendorNo)],
      ['Vendor Name', _pdfText(po.supplierName)],
      ['Vendor Address 1', _pdfDashIfEmpty(display.supplier.addressLine1)],
      ['Vendor Address 2', _pdfDashIfEmpty(display.supplier.addressLine2)],
      ['Vendor GST No', _pdfDashIfEmpty(display.supplier.gstNumber)],
      ['Contact Person', _pdfDashIfEmpty(display.supplier.contactPerson)],
      ['Contact Number', _pdfDashIfEmpty(display.supplier.phone)],
    ];
    final poRows = [
      ['PO Number', _pdfText(po.orderNumber)],
      ['Effective Date', effectiveDate],
      ['Currency', _pdfText(po.currency)],
      ['Payment Terms', _pdfText(po.paymentTerms)],
      [
        'Validity Date',
        po.validityDate != null ? _fmtDate(po.validityDate!) : '-',
      ],
    ];
    final billingRows = [
      ['Name', _pdfText(display.businessName)],
      ['Address Line 1', _pdfDashIfEmpty(display.billing.line1)],
      ['Address Line 2', _pdfDashIfEmpty(display.billing.line2)],
      ['Pin code', _pdfDashIfEmpty(display.billing.pinCode)],
      ['State', _pdfDashIfEmpty(display.billing.state)],
      ['Contact No', _pdfDashIfEmpty(display.billingContact)],
      ['GST No', _pdfDashIfEmpty(display.billingGst)],
    ];
    final shippingRows = [
      ['Name', _pdfText(display.businessName)],
      ['Address Line 1', _pdfDashIfEmpty(display.shipping.line1)],
      ['Address Line 2', _pdfDashIfEmpty(display.shipping.line2)],
      ['Pin Code', _pdfDashIfEmpty(display.shipping.pinCode)],
      ['State', _pdfDashIfEmpty(display.shipping.state)],
      ['Contact No', _pdfDashIfEmpty(display.shippingContact)],
      ['GST No', _pdfDashIfEmpty(display.shippingGst)],
    ];

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: pageMargin,
          buildBackground: (context) {
            if (!isDraft) return pw.SizedBox();
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Transform.rotate(
                  angle: -0.55,
                  child: pw.Text(
                    'DRAFT',
                    style: pw.TextStyle(
                      fontSize: 64,
                      color: PdfColors.grey400,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: logoWidth,
                height: logoHeight,
                alignment: pw.Alignment.centerLeft,
                child: logoWidget(),
              ),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Text(
                    'Purchase Order : ${_pdfText(po.orderNumber)}',
                    style: pw.TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
              statusChip(),
            ],
          ),
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: pageNumFontSize),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'This is a system generated document. Does not require any signature.',
              style: pw.TextStyle(
                fontSize: footerFontSize,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Registered Office Address: ${_pdfText(display.registeredOffice)}',
              style: pw.TextStyle(fontSize: footerFontSize),
            ),
          ],
        ),
        build: (context) => [
          infoBoxRow(
            'Vendor Information',
            vendorRows,
            'PO Details',
            poRows,
            minRows: 7,
          ),
          pw.SizedBox(height: 10),
          infoBoxRow(
            'Billing Details',
            billingRows,
            'Shipping Address',
            shippingRows,
            minRows: 7,
          ),
          pw.SizedBox(height: 14),
          lineItemsTable(),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Sub Total: Rs. ${_fmtMoney(display.subTotal)}',
                  style: value(size: totalFontSize),
                ),
                pw.Text(
                  'Total Tax: Rs. ${_fmtMoney(display.totalTax)}',
                  style: value(size: totalFontSize),
                ),
                pw.Text(
                  'Grand Total: Rs. ${_fmtMoney(display.grossTotal)}',
                  style: value(bold: true, size: grandTotalFontSize),
                ),
              ],
            ),
          ),
          if (po.notes?.trim().isNotEmpty == true) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              '$notesLabel: ${_pdfText(po.notes)}',
              style: pw.TextStyle(fontSize: notesFontSize),
            ),
          ],
          if (display.termsAndConditions.trim().isNotEmpty) ...[
            ...buildPoTermsPdfSection(
              heading: termsHeading,
              intro: termsIntro,
              termsText: display.termsAndConditions,
              bodyStyle: value(size: bodyValueSize),
              headingStyle: value(bold: true, size: sectionTitleSize),
              startOnNewPage: true,
            ),
          ],
        ],
      ),
    );

    return doc;
  }

  static Map<int, pw.TableColumnWidth> _tableColumnWidths(
    double contentWidth,
    bool isLandscape,
  ) {
    final weights = isLandscape
        ? [
            0.05, 0.13, 0.14, 0.07, 0.05, 0.05, 0.08, 0.09, 0.09, 0.05, 0.09,
            0.11,
          ]
        : [
            0.055, 0.12, 0.12, 0.075, 0.055, 0.055, 0.085, 0.085, 0.085, 0.055,
            0.09, 0.105,
          ];
    final sum = weights.fold<double>(0, (total, w) => total + w);
    return {
      for (var i = 0; i < weights.length; i++)
        i: pw.FixedColumnWidth(contentWidth * weights[i] / sum),
    };
  }

  static PdfColor _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RECEIVED':
        return PdfColors.green;
      case 'CANCELLED':
        return PdfColors.red;
      case 'PENDING':
      case 'DRAFT':
        return PdfColors.orange;
      default:
        return PdfColors.blueGrey;
    }
  }

  static Future<Uint8List?> _loadLogoBytes(String? url) async {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(trimmed));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  static String _pdfDashIfEmpty(String value) {
    if (value.trim().isEmpty) return '-';
    return _pdfText(value);
  }

  static String _pdfText(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .replaceAll('\u2014', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2012', '-')
        .replaceAll('\u2212', '-')
        .replaceAll('\u20B9', 'Rs.')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"');
  }

  static String _fmtDate(String iso) {
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String _fmtShortDate(String iso) {
    try {
      return DateFormat('dd-MMM-yy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String _fmtNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  static String _fmtMoney(double v) {
    final fmt = NumberFormat('#,##0.00', 'en_IN');
    return fmt.format(v);
  }
}
