import 'dart:io';
import 'dart:typed_data';

import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/download/download_notification_service.dart';
import 'package:billkaro/app/services/download/file_download_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;

/// Builds and saves the products Excel template / export files.
class MenuProductsTemplateService {
  MenuProductsTemplateService._();

  static const templateFileName = 'products_template.xlsx';

  /// Matches the BillKaro products Excel column layout used on import.
  static const _headers = [
    'Item Code',
    'Category',
    'Item Name',
    'Description',
    'Item Image',
    'Unit',
    'Price (₹)',
    'Tax %',
    'Price Incl. Tax (₹)',
  ];

  static Workbook buildTemplateWorkbook() {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Products';
    _writeHeaderRow(sheet);

    // Sample row so users see the expected format.
    sheet.getRangeByIndex(2, 1).setText('ITM001');
    sheet.getRangeByIndex(2, 2).setText('beverages');
    sheet.getRangeByIndex(2, 3).setText('Sample Item');
    sheet.getRangeByIndex(2, 4).setText('Sample description');
    sheet
        .getRangeByIndex(2, 5)
        .setText('https://example.com/images/sample-item.jpg');
    sheet.getRangeByIndex(2, 6).setText('Each');
    sheet.getRangeByIndex(2, 7).setNumber(100);
    sheet.getRangeByIndex(2, 8).setNumber(5);
    sheet.getRangeByIndex(2, 9).setNumber(105);

    _autoFitColumns(sheet);
    return workbook;
  }

  static Workbook buildExportWorkbook(List<ItemData> items) {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Products';
    _writeHeaderRow(sheet);

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final row = i + 2;
      final code = item.sku.trim().isNotEmpty
          ? item.sku.trim()
          : item.barcode.trim();
      if (code.isNotEmpty) {
        sheet.getRangeByIndex(row, 1).setText(code);
      }

      final category =
          item.category.toLowerCase() == 'none' ? '' : item.category;
      if (category.isNotEmpty) {
        sheet.getRangeByIndex(row, 2).setText(category);
      }

      sheet.getRangeByIndex(row, 3).setText(item.itemName);

      if (item.itemImage.trim().isNotEmpty) {
        sheet.getRangeByIndex(row, 5).setText(item.itemImage.trim());
      }

      if (item.soldBy.trim().isNotEmpty) {
        sheet.getRangeByIndex(row, 6).setText(item.soldBy.trim());
      }

      sheet.getRangeByIndex(row, 7).setNumber(item.salePrice);

      if (item.gst > 0) {
        sheet.getRangeByIndex(row, 8).setNumber(item.gst.toDouble());
      }

      if (item.withTax) {
        sheet.getRangeByIndex(row, 9).setNumber(item.salePrice);
      } else if (item.gst > 0) {
        final incl = item.salePrice * (1 + item.gst / 100);
        sheet.getRangeByIndex(row, 9).setNumber(incl);
      }
    }

    _autoFitColumns(sheet);
    return workbook;
  }

  static void _writeHeaderRow(Worksheet sheet) {
    for (var i = 0; i < _headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(_headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#E8EEF7';
    }
  }

  static void _autoFitColumns(Worksheet sheet) {
    for (var i = 1; i <= _headers.length; i++) {
      sheet.autoFitColumn(i);
    }
  }

  /// Saves workbook bytes via isolate. Retries with a unique name if the file is locked.
  static Future<String> _saveWorkbook(Workbook workbook, String fileName) async {
    final bytes = Uint8List.fromList(workbook.saveAsStream());
    workbook.dispose();

    try {
      final file = await FileDownloadService.instance.saveBytes(
        bytes: bytes,
        fileName: fileName,
        notify: false,
      );
      if (file != null) return file.path;
    } on FileSystemException {
      // Locked by Excel — fall through to unique name.
    }

    final dotIndex = fileName.lastIndexOf('.');
    final base = dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);
    final ext = dotIndex == -1 ? '' : fileName.substring(dotIndex);
    final uniqueName =
        '${base}_${DateTime.now().millisecondsSinceEpoch}$ext';

    final file = await FileDownloadService.instance.saveBytes(
      bytes: bytes,
      fileName: uniqueName,
      notify: false,
    );
    if (file == null) {
      throw Exception('Failed to save workbook');
    }
    return file.path;
  }

  static Future<void> _notifyExcelSaved(String fullPath, String title) {
    final name = p.basename(fullPath);
    return DownloadNotificationService.instance.notifyComplete(
      fileName: name,
      filePath: fullPath,
      title: title,
      body: '$name saved to Downloads',
    );
  }

  static Future<void> downloadTemplate() async {
    final loc = AppLocalizations.of(Get.context!)!;
    try {
      showAppLoader();
      final workbook = buildTemplateWorkbook();
      final fullPath = await _saveWorkbook(workbook, templateFileName);
      await _notifyExcelSaved(fullPath, 'Products template downloaded');
      await OpenFile.open(fullPath);
    } catch (e) {
      showError(description: loc.failed_to_import_file_error(e.toString()));
    } finally {
      dismissAllAppLoader();
    }
  }

  static Future<void> exportItems(List<ItemData> items) async {
    final loc = AppLocalizations.of(Get.context!)!;
    if (items.isEmpty) {
      showError(description: loc.no_items_to_export);
      return;
    }

    final workbook = buildExportWorkbook(items);
    const fileName = 'products-export.xlsx';
    final fullPath = await _saveWorkbook(workbook, fileName);
    await _notifyExcelSaved(fullPath, 'Products export downloaded');
    await OpenFile.open(fullPath);
  }
}
