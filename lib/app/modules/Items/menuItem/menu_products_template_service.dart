import 'dart:io';

import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/download_path_util.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;

/// Builds and saves the products Excel template / export files.
class MenuProductsTemplateService {
  MenuProductsTemplateService._();

  static const templateFileName = 'products_template.xlsx';
  static const _headers = [
    'Name',
    'Price',
    'Category',
    'Tax %',
    'Image Link',
  ];

  static Workbook buildTemplateWorkbook() {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Products';
    _writeHeaderRow(sheet);

    sheet.getRangeByIndex(2, 1).setText('Sample Item');
    sheet.getRangeByIndex(2, 2).setNumber(100);
    sheet.getRangeByIndex(2, 3).setText('beverages');
    sheet.getRangeByIndex(2, 4).setNumber(5);
    sheet
        .getRangeByIndex(2, 5)
        .setText('https://example.com/images/sample-item.jpg');

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
      sheet.getRangeByIndex(row, 1).setText(item.itemName);
      sheet.getRangeByIndex(row, 2).setNumber(item.salePrice);
      final category =
          item.category.toLowerCase() == 'none' ? '' : item.category;
      if (category.isNotEmpty) {
        sheet.getRangeByIndex(row, 3).setText(category);
      }
      if (item.gst > 0) {
        sheet.getRangeByIndex(row, 4).setNumber(item.gst.toDouble());
      }
      if (item.itemImage.trim().isNotEmpty) {
        sheet.getRangeByIndex(row, 5).setText(item.itemImage.trim());
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

  static Future<String> _saveWorkbook(Workbook workbook, String fileName) async {
    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final saveDir = Directory(await DownloadPathUtil.resolveSaveDirectory());
    if (!saveDir.existsSync()) {
      saveDir.createSync(recursive: true);
    }

    var fullPath = '${saveDir.path}/$fileName';
    try {
      await File(fullPath).writeAsBytes(bytes, flush: true);
    } on FileSystemException {
      // The file is locked (e.g. still open in Excel on Windows),
      // so save it under a unique name instead of failing.
      final dotIndex = fileName.lastIndexOf('.');
      final base = dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);
      final ext = dotIndex == -1 ? '' : fileName.substring(dotIndex);
      fullPath =
          '${saveDir.path}/${base}_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(fullPath).writeAsBytes(bytes, flush: true);
    }
    return fullPath;
  }

  static Future<void> downloadTemplate() async {
    final loc = AppLocalizations.of(Get.context!)!;
    try {
      showAppLoader();
      final workbook = buildTemplateWorkbook();
      final fullPath = await _saveWorkbook(workbook, templateFileName);

      final openResult = await OpenFile.open(fullPath);
      if (openResult.type == ResultType.done) {
        showSuccess(description: loc.template_saved_opened);
      } else {
        showSuccess(description: loc.template_saved_to(fullPath));
      }
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
    final fileName =
        'BillKaro_Products_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final fullPath = await _saveWorkbook(workbook, fileName);

    showSuccess(description: loc.excel_saved_to_downloads);

    final openResult = await OpenFile.open(fullPath);
    if (openResult.type != ResultType.done) {
      showSuccess(description: loc.template_saved_to(fullPath));
    }
  }
}
